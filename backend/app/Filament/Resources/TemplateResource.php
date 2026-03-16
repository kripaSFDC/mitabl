<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TemplateResource\Pages;
use App\Models\Template;
use App\Services\AdminAuditLogService;
use Filament\Facades\Filament;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TemplateResource extends Resource
{
    protected static ?string $model = Template::class;

    protected static ?string $navigationIcon = 'heroicon-o-envelope';

    protected static ?string $navigationGroup = 'Platform';

    protected static ?int $navigationSort = 30;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Template Identity')
                ->description('The name is the stable template key used in code. Channel controls routing (email, push notification, or internal system). Name is locked after creation to prevent orphan references in code.')
                ->icon('heroicon-o-document-text')
                ->schema([
                    Forms\Components\TextInput::make('name')
                        ->required()
                        ->maxLength(255)
                        ->disabled(fn (?Template $record): bool => $record !== null)
                        ->dehydrated(fn (?Template $record): bool => $record === null)
                        ->helperText('Matches the template key used in application code. Cannot be changed after creation.'),
                    Forms\Components\Select::make('channel')
                        ->required()
                        ->options([
                            'email' => 'Email',
                            'notification' => 'Notification',
                            'system' => 'System',
                        ])
                        ->default('email')
                        ->helperText('Email = outbound mail; Notification = push/in-app; System = internal events.'),
                    Forms\Components\TextInput::make('subject')
                        ->maxLength(255)
                        ->visible(fn (Forms\Get $get): bool => (string) $get('channel') === 'email')
                        ->helperText('Email subject line shown to the recipient.'),
                    Forms\Components\Placeholder::make('current_version')
                        ->label('Current version')
                        ->content(fn (?Template $record): string => $record ? 'v' . $record->version : 'New template')
                        ->visible(fn (?Template $record): bool => $record !== null),
                ])
                ->columns(['default' => 2]),

            Forms\Components\Section::make('Template Body')
                ->description('JSON payload defining the template content and variable placeholders. Use {{ variable }} syntax for interpolated values. Click "Create new draft" on the list to version this template safely.')
                ->icon('heroicon-o-code-bracket')
                ->schema([
                    Forms\Components\Textarea::make('body_json')
                        ->label('Body (JSON)')
                        ->rows(18)
                        ->required()
                        ->columnSpanFull()
                        ->helperText('Must be valid JSON. Variables use {{ double braces }}. The "Create new draft" row action creates a versioned copy.')
                        ->formatStateUsing(function (?Template $record): string {
                            return json_encode($record?->body ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}';
                        }),
                ])
                ->columns(['default' => 1]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['createdBy', 'updatedBy']))
            ->defaultSort('updated_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable()
                    ->weight(\Filament\Support\Enums\FontWeight::SemiBold),
                Tables\Columns\IconColumn::make('active')
                    ->label('Published')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\TextColumn::make('channel')
                    ->badge()
                    ->colors([
                        'info' => 'email',
                        'warning' => 'notification',
                        'gray' => 'system',
                    ])
                    ->sortable(),
                Tables\Columns\TextColumn::make('version')
                    ->badge()
                    ->color('gray')
                    ->sortable(),
                Tables\Columns\TextColumn::make('subject')
                    ->placeholder('-')
                    ->limit(40)
                    ->toggleable(),
                Tables\Columns\TextColumn::make('updatedBy.name')
                    ->label('Updated by')
                    ->placeholder('-')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Last updated')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('active')->label('Published'),
                Tables\Filters\SelectFilter::make('channel')
                    ->options(Template::query()->select('channel')->distinct()->pluck('channel', 'channel')->toArray()),
            ])
            ->actions([
                Action::make('publish')
                    ->label('Publish')
                    ->icon('heroicon-o-megaphone')
                    ->color('success')
                    ->visible(fn (Template $record): bool => static::canEditTemplates() && ! $record->active)
                    ->requiresConfirmation()
                    ->action(function (Template $record): void {
                        DB::transaction(function () use ($record): void {
                            Template::query()->where('name', $record->name)->lockForUpdate()->get(['id']);

                            Template::query()
                                ->where('name', $record->name)
                                ->where('id', '!=', $record->id)
                                ->where('active', true)
                                ->update(['active' => false]);

                            $record->refresh();
                            $record->active = true;
                            $record->updated_by = Filament::auth()->id();
                            $record->save();
                        });

                        app(AdminAuditLogService::class)->log('templates.publish', request(), [
                            'template_name' => $record->name,
                            'version' => $record->version,
                        ]);

                        Notification::make()->title('Template published.')->success()->send();
                    }),
                Action::make('create_version')
                    ->label('Create new draft')
                    ->icon('heroicon-o-document-duplicate')
                    ->visible(fn (): bool => static::canEditTemplates())
                    ->form([
                        Forms\Components\TextInput::make('subject')
                            ->maxLength(255)
                            ->default(fn (Template $record): ?string => $record->subject),
                        Forms\Components\Textarea::make('body_json')
                            ->label('Body (JSON)')
                            ->rows(12)
                            ->required()
                            ->default(fn (Template $record): string => json_encode($record->body ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}'),
                    ])
                    ->action(function (Template $record, array $data): void {
                        try {
                            $body = static::decodeBodyJson((string) ($data['body_json'] ?? '{}'));

                            DB::transaction(function () use ($record, $body): void {
                                Template::query()->where('name', $record->name)->lockForUpdate()->get(['id']);
                                $nextVersion = (int) Template::query()->where('name', $record->name)->max('version') + 1;

                                Template::create([
                                    'name' => $record->name,
                                    'version' => $nextVersion,
                                    'channel' => $record->channel,
                                    'subject' => $data['subject'] ?? $record->subject,
                                    'body' => $body,
                                    'active' => false,
                                    'created_by' => Filament::auth()->id(),
                                    'updated_by' => Filament::auth()->id(),
                                ]);
                            });

                            app(AdminAuditLogService::class)->log('templates.create_version', request(), [
                                'template_name' => $record->name,
                                'from_version' => $record->version,
                            ]);

                            Notification::make()->title('Template draft version created.')->success()->send();
                        } catch (ValidationException $exception) {
                            throw $exception;
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Version creation failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Tables\Actions\EditAction::make()
                    ->visible(fn (Template $record): bool => static::canEditTemplates() && ! $record->active),
            ])
            ->bulkActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListTemplates::route('/'),
            'create' => Pages\CreateTemplate::route('/create'),
            'edit' => Pages\EditTemplate::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        return (bool) Filament::auth()->user()?->can('templates.view');
    }

    public static function canCreate(): bool
    {
        return static::canEditTemplates();
    }

    public static function canEdit($record): bool
    {
        return static::canEditTemplates() && ! (bool) $record?->active;
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    public static function decodeBodyJson(string $json): array
    {
        try {
            $decoded = json_decode($json === '' ? '{}' : $json, true, 512, JSON_THROW_ON_ERROR);
        } catch (\Throwable $throwable) {
            throw ValidationException::withMessages([
                'body_json' => 'Template body must be valid JSON.',
            ]);
        }

        return is_array($decoded) ? $decoded : ['content' => $decoded];
    }

    private static function canEditTemplates(): bool
    {
        return (bool) Filament::auth()->user()?->can('templates.edit');
    }
}
