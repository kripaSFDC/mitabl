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
            Forms\Components\Section::make('Template')
                ->schema([
                    Forms\Components\TextInput::make('name')
                        ->required()
                        ->maxLength(255)
                        ->disabled(fn (?Template $record): bool => $record !== null)
                        ->dehydrated(fn (?Template $record): bool => $record === null),
                    Forms\Components\Select::make('channel')
                        ->required()
                        ->options([
                            'email' => 'Email',
                            'notification' => 'Notification',
                            'system' => 'System',
                        ])
                        ->default('email'),
                    Forms\Components\TextInput::make('subject')
                        ->maxLength(255)
                        ->visible(fn (Forms\Get $get): bool => (string) $get('channel') === 'email'),
                    Forms\Components\Textarea::make('body_json')
                        ->label('Body (JSON)')
                        ->rows(12)
                        ->required()
                        ->helperText('Use valid JSON payload for template body and variables.')
                        ->formatStateUsing(function (?Template $record): string {
                            return json_encode($record?->body ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}';
                        }),
                ])
                ->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['createdBy', 'updatedBy']))
            ->defaultSort('updated_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('name')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('version')->sortable(),
                Tables\Columns\TextColumn::make('channel')->badge()->sortable(),
                Tables\Columns\IconColumn::make('active')->boolean()->label('Published')->sortable(),
                Tables\Columns\TextColumn::make('subject')->placeholder('-')->toggleable(),
                Tables\Columns\TextColumn::make('updatedBy.name')->label('Updated by')->placeholder('-')->toggleable(),
                Tables\Columns\TextColumn::make('updated_at')->dateTime('d M Y H:i')->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('active')->label('Published'),
                Tables\Filters\SelectFilter::make('channel')
                    ->options(fn (): array => Template::query()->select('channel')->distinct()->pluck('channel', 'channel')->toArray()),
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
