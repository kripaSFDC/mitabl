<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PolicyResource\Pages;
use App\Models\Policy;
use App\Models\PolicyChangeLog;
use App\Services\AdminAuditLogService;
use App\Services\AdminStepUpService;
use App\Services\PolicyDefinitionValidator;
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

class PolicyResource extends Resource
{
    protected static ?string $model = Policy::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';

    protected static ?string $navigationGroup = 'Platform';

    protected static ?int $navigationSort = 20;

    public static function form(Form $form): Form
    {
        return $form->schema([
                Forms\Components\Section::make('Policy')
                    ->schema([
                    Forms\Components\Select::make('name')
                        ->required()
                        ->disabled(fn (?Policy $record): bool => $record !== null)
                        ->dehydrated(fn (?Policy $record): bool => $record === null)
                        ->options(function (): array {
                            $supported = collect(PolicyDefinitionValidator::SUPPORTED_POLICY_NAMES)
                                ->mapWithKeys(fn (string $name): array => [$name => $name]);
                            $existing = Policy::query()
                                ->select('name')
                                ->distinct()
                                ->pluck('name', 'name');

                            return $supported->union($existing)->toArray();
                        })
                        ->searchable()
                        ->helperText('Version auto-increments per policy name.'),
                    Forms\Components\TextInput::make('schema_version')
                        ->required()
                        ->default('1.0')
                        ->maxLength(40),
                    Forms\Components\DateTimePicker::make('effective_at')
                        ->seconds(false),
                    Forms\Components\Textarea::make('definition_json')
                        ->label('Definition (JSON)')
                        ->rows(14)
                        ->required()
                        ->helperText('Draft policy payload. Use valid JSON.')
                        ->formatStateUsing(function (?Policy $record): string {
                            return json_encode($record?->definition ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}';
                        }),
                ])
                ->columns(['default' => 2]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['createdBy', 'publishedBy']))
            ->defaultSort('updated_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('name')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('version')->sortable(),
                Tables\Columns\TextColumn::make('schema_version')->label('Schema')->sortable()->toggleable(),
                Tables\Columns\IconColumn::make('active')
                    ->boolean()
                    ->label('Published')
                    ->sortable(),
                Tables\Columns\TextColumn::make('effective_at')->dateTime('d M Y H:i')->sortable()->toggleable(),
                Tables\Columns\TextColumn::make('published_at')->dateTime('d M Y H:i')->sortable()->toggleable(),
                Tables\Columns\TextColumn::make('createdBy.name')->label('Created by')->placeholder('System')->toggleable(),
                Tables\Columns\TextColumn::make('publishedBy.name')->label('Published by')->placeholder('-')->toggleable(),
                Tables\Columns\TextColumn::make('updated_at')->dateTime('d M Y H:i')->sortable()->toggleable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('active')
                    ->label('Published')
                    ->queries(
                        true: fn (Builder $query): Builder => $query->where('active', true),
                        false: fn (Builder $query): Builder => $query->where('active', false),
                        blank: fn (Builder $query): Builder => $query
                    ),
                Tables\Filters\SelectFilter::make('name')
                    ->options(fn (): array => Policy::query()->select('name')->distinct()->pluck('name', 'name')->toArray()),
            ])
            ->actions([
                Action::make('publish')
                    ->label('Publish')
                    ->icon('heroicon-o-megaphone')
                    ->color('success')
                    ->visible(fn (Policy $record): bool => static::canPublish() && ! $record->active)
                    ->requiresConfirmation()
                    ->modalHeading('Publish Policy Version')
                    ->modalDescription('Publishing will make this version active and deactivate any other active version with the same name.')
                    ->form([
                        Forms\Components\Placeholder::make('blast_radius_warning')
                            ->label('Blast-radius warning')
                            ->content(function (Policy $record): string {
                                $active = Policy::query()
                                    ->where('name', $record->name)
                                    ->where('active', true)
                                    ->where('id', '!=', $record->id)
                                    ->first();

                                return app(PolicyDefinitionValidator::class)->blastRadiusWarning(
                                    (string) $record->name,
                                    (array) $record->definition,
                                    $active?->definition
                                );
                            }),
                        Forms\Components\Textarea::make('change_summary')
                            ->label('Publish summary')
                            ->required()
                            ->maxLength(1000),
                        Forms\Components\Toggle::make('impact_acknowledged')
                            ->label('I acknowledge the blast-radius impact and rollback plan.')
                            ->visible(fn (Policy $record): bool => static::requiresBlastRadiusAcknowledgement($record))
                            ->required(fn (Policy $record): bool => static::requiresBlastRadiusAcknowledgement($record)),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (Policy $record, array $data): void {
                        $active = Policy::query()
                            ->where('name', $record->name)
                            ->where('active', true)
                            ->where('id', '!=', $record->id)
                            ->first();
                        $validator = app(PolicyDefinitionValidator::class);
                        $validator->validateOrFail((string) $record->name, (array) $record->definition);

                        $isHighImpact = $validator->isHighImpact((string) $record->name, (array) $record->definition, $active?->definition);
                        if ($isHighImpact && ! (bool) ($data['impact_acknowledged'] ?? false)) {
                            Notification::make()
                                ->title('Blast-radius acknowledgement is required for high-impact policy changes.')
                                ->danger()
                                ->send();
                            return;
                        }

                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to publish this policy.'
                        )) {
                            return;
                        }

                        try {
                            DB::transaction(function () use ($record, $data): void {
                                Policy::query()
                                    ->where('name', $record->name)
                                    ->lockForUpdate()
                                    ->get(['id']);

                                $record->refresh();
                                if ($record->active) {
                                    throw new \RuntimeException('Policy version is already active.');
                                }

                                $previousActive = Policy::query()
                                    ->where('name', $record->name)
                                    ->where('active', true)
                                    ->where('id', '!=', $record->id)
                                    ->first();

                                $effectiveAt = $record->effective_at ?: now();
                                $shouldActivateNow = $effectiveAt->lessThanOrEqualTo(now());

                                if ($shouldActivateNow) {
                                    Policy::query()
                                        ->where('name', $record->name)
                                        ->where('id', '!=', $record->id)
                                        ->where('active', true)
                                        ->update(['active' => false]);
                                }

                                $record->active = $shouldActivateNow;
                                $record->published_by = Filament::auth()->id();
                                $record->published_at = now();
                                $record->effective_at = $effectiveAt;
                                $record->save();

                                PolicyChangeLog::create([
                                    'policy_id' => $record->id,
                                    'action' => $shouldActivateNow ? 'published' : 'scheduled',
                                    'changed_by' => Filament::auth()->id(),
                                    'from_version' => $previousActive?->version,
                                    'to_version' => $record->version,
                                    'change_summary' => (string) $data['change_summary'],
                                    'before_payload' => $previousActive?->definition,
                                    'after_payload' => $record->definition,
                                    'correlation_id' => null,
                                ]);

                                app(AdminAuditLogService::class)->log('policy.publish', request(), [
                                    'policy_name' => $record->name,
                                    'to_version' => $record->version,
                                    'effective_at' => $effectiveAt->toIso8601String(),
                                    'activated_immediately' => $shouldActivateNow,
                                    'from_version' => $previousActive?->version,
                                    'impact_acknowledged' => (bool) ($data['impact_acknowledged'] ?? false),
                                ]);
                            });

                            Notification::make()
                                ->title('Policy published.')
                                ->body($record->active
                                    ? 'This version is now active.'
                                    : 'This version is scheduled and will activate at its effective date.')
                                ->success()
                                ->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Publish failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('view_diff')
                    ->label('View diff')
                    ->icon('heroicon-o-arrows-right-left')
                    ->color('gray')
                    ->visible(fn (Policy $record): bool => ! $record->active && static::hasActiveVersion($record))
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('Close')
                    ->modalHeading('Policy diff preview')
                    ->modalDescription('Compare this draft against the currently active version before publishing.')
                    ->modalContent(function (Policy $record): \Illuminate\Contracts\View\View {
                        $active = Policy::query()
                            ->where('name', $record->name)
                            ->where('active', true)
                            ->first();

                        return view('filament.resources.policy-resource.diff-preview', [
                            'active' => $active,
                            'draft' => $record,
                            'activeJson' => json_encode($active?->definition ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}',
                            'draftJson' => json_encode($record->definition ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}',
                        ]);
                    }),
                Action::make('create_version')
                    ->label('Create new draft')
                    ->icon('heroicon-o-document-duplicate')
                    ->color('warning')
                    ->visible(fn (): bool => (bool) Filament::auth()->user()?->can('policies.edit'))
                    ->form([
                        Forms\Components\Textarea::make('definition_json')
                            ->label('Definition (JSON)')
                            ->rows(14)
                            ->required()
                            ->default(fn (Policy $record): string => json_encode($record->definition ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}'),
                        Forms\Components\Textarea::make('change_summary')
                            ->label('Draft summary')
                            ->required()
                            ->maxLength(1000),
                    ])
                    ->action(function (Policy $record, array $data): void {
                        try {
                            $definition = json_decode((string) $data['definition_json'], true, 512, JSON_THROW_ON_ERROR);
                            app(PolicyDefinitionValidator::class)->validateOrFail((string) $record->name, (array) $definition);

                            DB::transaction(function () use ($record, $definition, $data): void {
                                Policy::query()
                                    ->where('name', $record->name)
                                    ->lockForUpdate()
                                    ->get(['id', 'version']);

                                $nextVersion = (int) Policy::query()
                                        ->where('name', $record->name)
                                        ->max('version') + 1;

                                $draft = Policy::create([
                                    'name' => $record->name,
                                    'version' => $nextVersion,
                                    'schema_version' => $record->schema_version,
                                    'definition' => $definition,
                                    'effective_at' => null,
                                    'active' => false,
                                    'created_by' => Filament::auth()->id(),
                                ]);

                                PolicyChangeLog::create([
                                    'policy_id' => $draft->id,
                                    'action' => 'draft_created',
                                    'changed_by' => Filament::auth()->id(),
                                    'from_version' => $record->version,
                                    'to_version' => $draft->version,
                                    'change_summary' => (string) $data['change_summary'],
                                    'before_payload' => $record->definition,
                                    'after_payload' => $draft->definition,
                                    'correlation_id' => null,
                                ]);

                                app(AdminAuditLogService::class)->log('policy.create_version', request(), [
                                    'policy_name' => $record->name,
                                    'from_version' => $record->version,
                                    'to_version' => $draft->version,
                                    'change_summary' => (string) $data['change_summary'],
                                ]);
                            });

                            Notification::make()->title('Draft version created.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Draft creation failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('rollback')
                    ->label('Rollback')
                    ->icon('heroicon-o-arrow-uturn-left')
                    ->color('danger')
                    ->visible(fn (Policy $record): bool => static::canPublish() && $record->active)
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Select::make('target_version')
                            ->label('Rollback target version')
                            ->required()
                            ->options(fn (Policy $record): array => Policy::query()
                                ->where('name', $record->name)
                                ->where('id', '!=', $record->id)
                                ->orderByDesc('version')
                                ->pluck('version', 'version')
                                ->toArray()),
                        Forms\Components\Textarea::make('change_summary')
                            ->label('Rollback reason')
                            ->required()
                            ->maxLength(1000),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (Policy $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to roll back this policy.'
                        )) {
                            return;
                        }

                        try {
                            DB::transaction(function () use ($record, $data): void {
                                Policy::query()
                                    ->where('name', $record->name)
                                    ->lockForUpdate()
                                    ->get(['id']);

                                $record->refresh();
                                if (! $record->active) {
                                    throw new \RuntimeException('Only active policies can be rolled back.');
                                }

                                $target = Policy::query()
                                    ->where('name', $record->name)
                                    ->where('version', (int) $data['target_version'])
                                    ->where('id', '!=', $record->id)
                                    ->firstOrFail();
                                app(PolicyDefinitionValidator::class)->validateOrFail((string) $target->name, (array) $target->definition);

                                Policy::query()
                                    ->where('name', $record->name)
                                    ->where('active', true)
                                    ->update(['active' => false]);

                                $target->active = true;
                                $target->published_by = Filament::auth()->id();
                                $target->published_at = now();
                                $target->effective_at = now();
                                $target->save();

                                PolicyChangeLog::create([
                                    'policy_id' => $target->id,
                                    'action' => 'rolled_back',
                                    'changed_by' => Filament::auth()->id(),
                                    'from_version' => $record->version,
                                    'to_version' => $target->version,
                                    'change_summary' => (string) $data['change_summary'],
                                    'before_payload' => $record->definition,
                                    'after_payload' => $target->definition,
                                    'correlation_id' => null,
                                ]);

                                app(AdminAuditLogService::class)->log('policy.rollback', request(), [
                                    'policy_name' => $record->name,
                                    'from_version' => $record->version,
                                    'to_version' => $target->version,
                                ]);
                            });

                            Notification::make()->title('Policy rolled back successfully.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Rollback failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
            ])
            ->bulkActions([]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPolicies::route('/'),
            'create' => Pages\CreatePolicy::route('/create'),
            'edit' => Pages\EditPolicy::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        $user = Filament::auth()->user();

        return (bool) (
            $user?->can('policies.view')
            || static::hasAdminRole($user, ['super_admin', 'platform_admin', 'super admin', 'platform admin'])
        );
    }

    public static function canCreate(): bool
    {
        $user = Filament::auth()->user();

        return (bool) (
            $user?->can('policies.edit')
            || static::hasAdminRole($user, ['super_admin', 'platform_admin', 'super admin', 'platform admin'])
        );
    }

    public static function canEdit($record): bool
    {
        $user = Filament::auth()->user();
        $canEdit = (bool) (
            $user?->can('policies.edit')
            || static::hasAdminRole($user, ['super_admin', 'platform_admin', 'super admin', 'platform admin'])
        );

        if (! $canEdit) {
            return false;
        }

        return ! (bool) $record?->active;
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    private static function canPublish(): bool
    {
        return (bool) Filament::auth()->user()?->can('policy_changes.publish');
    }

    private static function hasActiveVersion(Policy $record): bool
    {
        return Policy::query()
            ->where('name', $record->name)
            ->where('active', true)
            ->where('id', '!=', $record->id)
            ->exists();
    }

    private static function requiresBlastRadiusAcknowledgement(Policy $record): bool
    {
        $active = Policy::query()
            ->where('name', $record->name)
            ->where('active', true)
            ->where('id', '!=', $record->id)
            ->first();

        return app(PolicyDefinitionValidator::class)->isHighImpact(
            (string) $record->name,
            (array) $record->definition,
            $active?->definition
        );
    }

    private static function hasAdminRole($user, array $roles): bool
    {
        if (! $user || ! method_exists($user, 'hasRole')) {
            return false;
        }

        foreach ($roles as $role) {
            if ($user->hasRole($role)) {
                return true;
            }
        }

        return false;
    }
}
