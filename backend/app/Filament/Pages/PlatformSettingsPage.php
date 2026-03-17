<?php

namespace App\Filament\Pages;

use App\Models\PlatformSetting;
use App\Models\PlatformSettingChangeRequest;
use App\Services\AdminAuditLogService;
use App\Services\AdminStepUpService;
use App\Services\PlatformRuntimeConfigService;
use App\Services\PlatformSettingRegistry;
use Filament\Facades\Filament;
use Filament\Forms;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

class PlatformSettingsPage extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';

    protected static ?string $navigationGroup = 'Platform';

    protected static ?int $navigationSort = 10;

    protected static ?string $title = 'Platform Settings';

    protected static string $view = 'filament.pages.platform-settings-page';

    public ?array $data = [];
    public array $pendingApprovals = [];

    public function mount(): void
    {
        $rows = app(PlatformSettingRegistry::class)->forAdminForm();

        $this->loadPendingApprovals();

        $this->form->fill([
            'settings' => $this->overlayPendingChanges($rows),
            'change_reason' => '',
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Runtime Settings')
                    ->description('Manage runtime toggles and operational configurations.')
                    ->schema([
                        Forms\Components\Repeater::make('settings')
                            ->label('Settings')
                            ->helperText('Each card is titled from its runtime key so admins can quickly identify the setting domain before editing.')
                            ->default([])
                            ->itemLabel(fn (array $state): ?string => $this->settingCardHeading((string) ($state['key'] ?? '')))
                            ->schema([
                                Forms\Components\Hidden::make('id'),
                                Forms\Components\TextInput::make('key')
                                    ->hintIcon('heroicon-m-question-mark-circle')
                                    ->hintIconTooltip('Stable runtime identifier used by the application code and config loaders.')
                                    ->required()
                                    ->maxLength(255)
                                    ->placeholder('feature.flag_name')
                                    ->helperText(fn (Forms\Get $get): string => 'Section: ' . $this->settingCardHeading((string) $get('key')) . '. Use stable dot-notation keys (for example auth.lockout.window_minutes). Keys under support/session/admin/stripe are platform-managed runtime controls.'),
                                Forms\Components\Select::make('value_type')
                                    ->hintIcon('heroicon-m-question-mark-circle')
                                    ->hintIconTooltip('Controls how the value is validated, stored, and parsed at runtime.')
                                    ->required()
                                    ->helperText('Choose the expected backend type so runtime parsing stays safe.')
                                    ->options([
                                        'boolean' => 'Boolean',
                                        'integer' => 'Integer',
                                        'string' => 'String',
                                        'json' => 'JSON',
                                    ])
                                    ->default('boolean')
                                    ->live(),
                                Forms\Components\Textarea::make('description')
                                    ->hintIcon('heroicon-m-question-mark-circle')
                                    ->hintIconTooltip('Visible admin guidance for when to use this setting, safe ranges, and rollback notes.')
                                    ->rows(2)
                                    ->maxLength(1000)
                                    ->helperText(fn (Forms\Get $get): string => 'Explain when to use ' . $this->settingCardHeading((string) $get('key')) . ', which values are safe, and how to roll it back if needed.'),
                                Forms\Components\Toggle::make('value_boolean')
                                    ->label('Boolean value')
                                    ->hintIcon('heroicon-m-question-mark-circle')
                                    ->hintIconTooltip('Use for on/off runtime controls. Changes may take effect immediately after save or activation.')
                                    ->helperText(fn (Forms\Get $get): string => $this->settingHelpForKey((string) $get('key')))
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'boolean'),
                                Forms\Components\TextInput::make('value_integer')
                                    ->label('Integer value')
                                    ->hintIcon('heroicon-m-question-mark-circle')
                                    ->hintIconTooltip('Use whole numbers only. Prefer documenting units such as minutes, hours, retries, or seconds.')
                                    ->numeric()
                                    ->helperText(fn (Forms\Get $get): string => $this->settingHelpForKey((string) $get('key')))
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'integer'),
                                Forms\Components\Textarea::make('value_string')
                                    ->label('String value')
                                    ->hintIcon('heroicon-m-question-mark-circle')
                                    ->hintIconTooltip('Use plain text for keys, URLs, provider names, and other non-structured values.')
                                    ->rows(3)
                                    ->helperText(fn (Forms\Get $get): string => $this->settingHelpForKey((string) $get('key')))
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'string'),
                                Forms\Components\Textarea::make('value_json')
                                    ->label('JSON value')
                                    ->hintIcon('heroicon-m-question-mark-circle')
                                    ->hintIconTooltip('Use structured JSON objects or arrays for grouped runtime controls.')
                                    ->rows(8)
                                    ->helperText(fn (Forms\Get $get): string => 'Must be valid JSON. ' . $this->settingHelpForKey((string) $get('key')))
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'json'),
                            ])
                            ->columns(['default' => 2])
                            ->collapsible()
                            ->cloneable()
                            ->reorderable(false),
                        Forms\Components\Textarea::make('change_reason')
                            ->label('Change reason')
                            ->rows(3)
                            ->maxLength(1000)
                            ->helperText('Required for high-risk configuration keys (for example, maintenance/auth/payment/queue/cache/incident).'),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password for high-risk changes')
                            ->password()
                            ->revealable(false),
                    ]),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        if (! $this->canManagePlatformConfiguration()) {
            Notification::make()->title('You do not have permission to modify platform settings.')->danger()->send();
            return;
        }

        $state = $this->form->getState();
        $rows = (array) ($state['settings'] ?? []);
        $changeReason = trim((string) ($state['change_reason'] ?? ''));
        $currentPassword = $state['current_password'] ?? null;
        $changedKeys = [];
        $deletedCount = 0;
        $pendingRequestsByKey = $this->latestPendingRequestsByKey();

        $keys = collect($rows)
            ->pluck('key')
            ->map(fn ($key) => trim((string) $key))
            ->map(fn (string $key) => strtolower($key))
            ->filter()
            ->values();

        if ($keys->count() !== $keys->unique()->count()) {
            Notification::make()->title('Duplicate setting keys are not allowed.')->danger()->send();
            return;
        }

        $existingSettings = PlatformSetting::query()->get();
        $existingById = $existingSettings->keyBy('id');
        $existingByKey = $existingSettings->keyBy(fn (PlatformSetting $setting): string => strtolower((string) $setting->key));

        $retainedIds = $this->calculateRetainedIds($rows, $existingByKey);
        $changedOrAddedKeys = [];
        foreach ($rows as $row) {
            $key = trim((string) ($row['key'] ?? ''));
            if ($key === '') {
                continue;
            }

            $valueType = (string) ($row['value_type'] ?? 'json');
            $normalizedValue = $this->normalizeValue($valueType, $row);
            $existing = $this->resolveExistingSetting($row, $existingById, $existingByKey);
            $pendingRequest = $pendingRequestsByKey->get(strtolower($key));

            if ($pendingRequest instanceof PlatformSettingChangeRequest
                && $this->matchesPendingRequest($pendingRequest, $valueType, $row['description'] ?? null, $normalizedValue)
            ) {
                continue;
            }

            if (! $existing) {
                if (! $this->matchesDefaultSetting($key, $valueType, $row['description'] ?? null, $normalizedValue)) {
                    $changedOrAddedKeys[] = $key;
                }
                continue;
            }

            $description = $row['description'] ?? null;
            if (
                (string) $existing->key !== $key
                || (string) $existing->value_type !== $valueType
                || ($existing->description ?? null) !== $description
                || $existing->value !== $normalizedValue
            ) {
                $changedOrAddedKeys[] = $key;
            }
        }

        $deletedKeys = $existingSettings
            ->filter(function (PlatformSetting $setting) use ($retainedIds, $pendingRequestsByKey): bool {
                if (in_array((int) $setting->id, $retainedIds, true)) {
                    return false;
                }

                /** @var PlatformSettingChangeRequest|null $pendingRequest */
                $pendingRequest = $pendingRequestsByKey->get(strtolower((string) $setting->key));

                return ! ($pendingRequest instanceof PlatformSettingChangeRequest
                    && $pendingRequest->proposed_value === null);
            })
            ->pluck('key')
            ->map(fn ($key): string => (string) $key)
            ->values()
            ->all();

        $highRiskCandidates = collect(array_merge($changedOrAddedKeys, $deletedKeys))
            ->filter(fn (string $key): bool => $this->isHighRiskKey($key))
            ->unique()
            ->values();
        $highRiskLookup = $highRiskCandidates
            ->map(fn (string $key): string => strtolower($key))
            ->all();

        $restrictedCandidates = collect(array_merge($changedOrAddedKeys, $deletedKeys))
            ->filter(fn (string $key): bool => $this->isSuperAdminOnlyIntegrationKey($key))
            ->unique()
            ->values();

        if ($restrictedCandidates->isNotEmpty() && ! $this->isSuperAdmin()) {
            Notification::make()
                ->title('Only super admins can change OTP, email, maps, and payment integration settings.')
                ->danger()
                ->send();
            return;
        }

        $directRows = array_values(array_filter($rows, function (array $row) use ($highRiskLookup): bool {
            $key = strtolower(trim((string) ($row['key'] ?? '')));

            return $key !== '' && ! in_array($key, $highRiskLookup, true);
        }));
        $directDeletedKeys = array_values(array_filter($deletedKeys, fn (string $key): bool => ! in_array(strtolower($key), $highRiskLookup, true)));

        if ($highRiskCandidates->isNotEmpty()) {
            if (! $this->canManagePlatformConfiguration() || ! Filament::auth()->user()?->can('policy_changes.publish')) {
                Notification::make()
                    ->title('High-risk settings require publish-level approval permission.')
                    ->danger()
                    ->send();
                return;
            }

            if ($changeReason === '') {
                Notification::make()
                    ->title('Change reason is required for high-risk settings.')
                    ->danger()
                    ->send();
                return;
            }

            if (! app(AdminStepUpService::class)->validateCurrentPassword(
                is_string($currentPassword) ? $currentPassword : null,
                'Step-up authentication failed during high-risk validation stage.'
            )) {
                return;
            }

        }

        try {
            DB::transaction(function () use ($directRows, $directDeletedKeys, $highRiskCandidates, $rows, $deletedKeys, $changeReason, &$changedKeys, &$deletedCount): void {
                $existingSettings = PlatformSetting::query()->lockForUpdate()->get();
                $existingById = $existingSettings->keyBy('id');
                $existingByKey = $existingSettings->keyBy(fn (PlatformSetting $setting): string => strtolower((string) $setting->key));

                $toDelete = $existingSettings
                    ->filter(fn (PlatformSetting $setting): bool => in_array(strtolower((string) $setting->key), array_map('strtolower', $directDeletedKeys), true))
                    ->pluck('id')
                    ->map(fn ($id): int => (int) $id)
                    ->all();

                if (count($toDelete) > 0) {
                    PlatformSetting::query()->whereIn('id', $toDelete)->delete();
                    $deletedCount = count($toDelete);
                }

                foreach ($directRows as $row) {
                    $key = trim((string) ($row['key'] ?? ''));
                    if ($key === '') {
                        continue;
                    }

                    $valueType = (string) ($row['value_type'] ?? 'json');
                    $normalizedValue = $this->normalizeValue($valueType, $row);

                    $record = $this->resolveExistingSetting($row, $existingById, $existingByKey);

                    $isNewRecord = false;
                    if (! $record) {
                        if ($this->matchesDefaultSetting($key, $valueType, $row['description'] ?? null, $normalizedValue)) {
                            continue;
                        }

                        $record = new PlatformSetting();
                        $record->key = $key;
                        $record->version = 1;
                        $isNewRecord = true;
                    }

                    $beforeValue = $record->value;
                    $beforeType = $record->value_type;

                    $record->key = $key;
                    $record->value_type = $valueType;
                    $record->description = $row['description'] ?? null;
                    $record->value = $normalizedValue;
                    $record->updated_by = Filament::auth()->id();
                    if (! $isNewRecord && ($beforeValue !== $normalizedValue || $beforeType !== $valueType)) {
                        $record->version = (int) $record->version + 1;
                    }
                    $record->save();

                    if ($isNewRecord || $beforeValue !== $normalizedValue || $beforeType !== $valueType) {
                        $changedKeys[] = $record->key;
                    }

                    $existingById[(int) $record->id] = $record;
                    $existingByKey[strtolower((string) $record->key)] = $record;
                }

                if ($highRiskCandidates->isNotEmpty()) {
                    $this->createApprovalRequests($rows, $highRiskCandidates->all(), $deletedKeys, $changeReason);
                }
            });
        } catch (ValidationException $exception) {
            throw $exception;
        } catch (\Throwable $throwable) {
            Notification::make()->title('Save failed: ' . $throwable->getMessage())->danger()->send();
            return;
        }

        if ($highRiskCandidates->isNotEmpty()) {
            app(AdminAuditLogService::class)->log('platform_settings.validated', request(), [
                'high_risk_keys' => $highRiskCandidates->all(),
                'change_reason' => $changeReason,
            ]);
        }

        if ($highRiskCandidates->isNotEmpty() && count(array_unique($changedKeys)) > 0) {
            Notification::make()
                ->title('Low-risk settings saved. High-risk changes are waiting for a second admin to approve and activate them.')
                ->warning()
                ->send();
        } elseif ($highRiskCandidates->isNotEmpty()) {
            Notification::make()
                ->title('High-risk changes validated and are waiting for a second admin to approve and activate them.')
                ->warning()
                ->send();
        } else {
            Notification::make()->title('Platform settings saved.')->success()->send();
        }

        app(AdminAuditLogService::class)->log('platform_settings.save', request(), [
            'changed_keys' => array_values(array_unique($changedKeys)),
            'changed_count' => count(array_unique($changedKeys)),
            'deleted_count' => $deletedCount,
            'high_risk_keys' => $highRiskCandidates->all(),
            'change_reason' => $changeReason === '' ? null : $changeReason,
        ]);

        app(PlatformRuntimeConfigService::class)->apply();

        $this->mount();
    }

    public function approveRequest(int $requestId): void
    {
        if (! $this->canManagePlatformConfiguration() || ! Filament::auth()->user()?->can('policy_changes.publish')) {
            Notification::make()->title('You do not have permission to approve high-risk settings changes.')->danger()->send();
            return;
        }

        $request = PlatformSettingChangeRequest::query()->find($requestId);
        if (! $request || $request->status !== PlatformSettingChangeRequest::STATUS_VALIDATED) {
            return;
        }

        if ($this->isSuperAdminOnlyIntegrationKey((string) $request->setting_key) && ! $this->isSuperAdmin()) {
            Notification::make()
                ->title('Only super admins can approve OTP, email, maps, and payment integration setting changes.')
                ->danger()
                ->send();
            return;
        }

        $actorId = Filament::auth()->id();
        if ((int) $request->requested_by === (int) $actorId) {
            Notification::make()->title('Two-person control: requester cannot approve their own high-risk change.')->danger()->send();
            return;
        }

        $this->applyApprovedRequest($request, $actorId);

        Notification::make()->title('High-risk change approved and activated.')->success()->send();
        $this->mount();
    }

    public function activateRequest(int $requestId): void
    {
        if (! $this->canManagePlatformConfiguration() || ! Filament::auth()->user()?->can('policy_changes.publish')) {
            Notification::make()->title('You do not have permission to activate high-risk settings changes.')->danger()->send();
            return;
        }

        $request = PlatformSettingChangeRequest::query()->find($requestId);
        if (! $request || $request->status !== PlatformSettingChangeRequest::STATUS_APPROVED) {
            return;
        }

        if ($this->isSuperAdminOnlyIntegrationKey((string) $request->setting_key) && ! $this->isSuperAdmin()) {
            Notification::make()
                ->title('Only super admins can activate OTP, email, maps, and payment integration setting changes.')
                ->danger()
                ->send();
            return;
        }

        DB::transaction(function () use ($request): void {
            $this->activateApprovedRequest($request, Filament::auth()->id());
        });

        app(AdminAuditLogService::class)->log('platform_settings.activated', request(), [
            'request_id' => $request->id,
            'setting_key' => $request->setting_key,
        ]);

        app(PlatformRuntimeConfigService::class)->apply();

        Notification::make()->title('Approved high-risk change activated.')->success()->send();
        $this->mount();
    }

    private function createApprovalRequests(array $rows, array $keys, array $deletedKeys, string $changeReason): void
    {
        $highRisk = array_map('strtolower', $keys);

        foreach ($rows as $row) {
            $key = trim((string) ($row['key'] ?? ''));
            if ($key === '' || ! in_array(strtolower($key), $highRisk, true)) {
                continue;
            }

            $valueType = (string) ($row['value_type'] ?? 'json');
            $normalizedValue = $this->normalizeValue($valueType, $row);

            $this->upsertApprovalRequest($key, $normalizedValue, $valueType, $row['description'] ?? null, $changeReason);
        }

        foreach ($deletedKeys as $deletedKey) {
            $normalizedDeletedKey = strtolower(trim((string) $deletedKey));
            if ($normalizedDeletedKey === '' || ! in_array($normalizedDeletedKey, $highRisk, true)) {
                continue;
            }

            $existingSetting = PlatformSetting::query()->where('key', (string) $deletedKey)->first();

            $this->upsertApprovalRequest(
                (string) $deletedKey,
                null,
                'json',
                $existingSetting?->description,
                $changeReason
            );
        }
    }

    private function loadPendingApprovals(): void
    {
        $this->pendingApprovals = PlatformSettingChangeRequest::query()
            ->whereIn('status', [
                PlatformSettingChangeRequest::STATUS_VALIDATED,
                PlatformSettingChangeRequest::STATUS_APPROVED,
            ])
            ->latest('id')
            ->limit(50)
            ->get()
            ->map(fn (PlatformSettingChangeRequest $request): array => [
                'id' => $request->id,
                'setting_key' => $request->setting_key,
                'status' => $request->status,
                'reason' => (string) $request->change_reason,
                'requested_by' => (int) ($request->requested_by ?? 0),
                'approved_by' => (int) ($request->approved_by ?? 0),
                'activated_by' => (int) ($request->activated_by ?? 0),
                'validated_at' => optional($request->validated_at)?->toDateTimeString(),
            ])->all();
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     * @return array<int, array<string, mixed>>
     */
    private function overlayPendingChanges(array $rows): array
    {
        $pendingByKey = PlatformSettingChangeRequest::query()
            ->whereIn('status', [
                PlatformSettingChangeRequest::STATUS_VALIDATED,
                PlatformSettingChangeRequest::STATUS_APPROVED,
            ])
            ->latest('id')
            ->get()
            ->unique(fn (PlatformSettingChangeRequest $request): string => strtolower((string) $request->setting_key))
            ->keyBy(fn (PlatformSettingChangeRequest $request): string => strtolower((string) $request->setting_key));

        $merged = [];
        foreach ($rows as $row) {
            $key = strtolower(trim((string) ($row['key'] ?? '')));
            /** @var PlatformSettingChangeRequest|null $pending */
            $pending = $key !== '' ? $pendingByKey->get($key) : null;

            $merged[] = $pending ? $this->applyPendingRequestToRow($row, $pending) : $row;

            if ($pending) {
                $pendingByKey->forget($key);
            }
        }

        foreach ($pendingByKey as $pending) {
            $merged[] = $this->applyPendingRequestToRow([
                'id' => null,
                'key' => $pending->setting_key,
                'value_type' => $pending->value_type,
                'description' => null,
                'value_string' => null,
                'value_integer' => null,
                'value_boolean' => false,
                'value_json' => '{}',
            ], $pending);
        }

        return $merged;
    }

    /**
     * @param  array<string, mixed>  $row
     * @return array<string, mixed>
     */
    private function applyPendingRequestToRow(array $row, PlatformSettingChangeRequest $request): array
    {
        $row['description'] = $request->description ?? $row['description'] ?? null;

        if ($request->proposed_value === null) {
            return $row;
        }

        $row['value_type'] = $request->value_type;
        $row['value_string'] = null;
        $row['value_integer'] = null;
        $row['value_boolean'] = false;
        $row['value_json'] = '{}';

        return match ($request->value_type) {
            'boolean' => array_merge($row, [
                'value_boolean' => (bool) data_get($request->proposed_value, 'value', false),
            ]),
            'integer' => array_merge($row, [
                'value_integer' => (int) data_get($request->proposed_value, 'value', 0),
            ]),
            'string' => array_merge($row, [
                'value_string' => (string) data_get($request->proposed_value, 'value', ''),
            ]),
            default => array_merge($row, [
                'value_json' => json_encode($request->proposed_value ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}',
            ]),
        };
    }

    private function matchesDefaultSetting(string $key, string $valueType, mixed $description, array $normalizedValue): bool
    {
        $default = app(PlatformSettingRegistry::class)->defaultForKey($key);
        if ($default === null) {
            return false;
        }

        return (string) ($default['value_type'] ?? '') === $valueType
            && ($default['description'] ?? null) === $description
            && (array) ($default['value'] ?? []) === $normalizedValue;
    }

    private function matchesPendingRequest(PlatformSettingChangeRequest $request, string $valueType, mixed $description, array $normalizedValue): bool
    {
        if (($request->value_type ?? null) !== $valueType) {
            return false;
        }

        return $request->proposed_value === $normalizedValue
            && ($request->description ?? null) === $description;
    }

    private function normalizeValue(string $valueType, array $row): array
    {
        return match ($valueType) {
            'boolean' => ['value' => (bool) ($row['value_boolean'] ?? false)],
            'integer' => ['value' => (int) ($row['value_integer'] ?? 0)],
            'string' => ['value' => (string) ($row['value_string'] ?? '')],
            'json' => $this->decodeJson((string) ($row['value_json'] ?? '{}')),
            default => ['value' => $row['value_string'] ?? null],
        };
    }

    private function decodeJson(string $json): array
    {
        try {
            $decoded = json_decode($json === '' ? '{}' : $json, true, 512, JSON_THROW_ON_ERROR);
        } catch (\Throwable $throwable) {
            throw ValidationException::withMessages([
                'data.settings' => 'One or more JSON setting values are invalid.',
            ]);
        }

        return is_array($decoded) ? $decoded : ['value' => $decoded];
    }

    public static function canAccess(): bool
    {
        $user = Filament::auth()->user();

        return (bool) ($user?->can('platform_settings.view')
            && ($user->hasRole('super_admin') || $user->hasRole('platform_admin')));
    }


    private function canManagePlatformConfiguration(): bool
    {
        $user = Filament::auth()->user();

        return (bool) ($user?->can('platform_settings.edit')
            && ($user->hasRole('super_admin') || $user->hasRole('platform_admin')));
    }

    private function isSuperAdmin(): bool
    {
        $user = Filament::auth()->user();

        return (bool) ($user && $user->hasRole('super_admin'));
    }

    private function settingCardHeading(string $key): string
    {
        $normalized = strtolower(trim($key));

        return match (true) {
            $normalized === '' => 'New Runtime Setting',
            $normalized === 'onboarding.enabled' => 'Onboarding Availability',
            $normalized === 'onboarding.require_identity_verification' => 'Onboarding Identity Verification',
            $normalized === 'maintenance.read_only_mode' => 'Maintenance Read-Only Mode',
            $normalized === 'operations.synthetic_checks_enabled' => 'Synthetic Health Monitoring',
            $normalized === 'incident.degraded_mode' => 'Incident Degraded Mode',
            str_starts_with($normalized, 'support.sla.') => 'Support SLA Targets',
            str_starts_with($normalized, 'support.duplicate_') => 'Support Duplicate Protection',
            $normalized === 'support.reopen_window_hours' => 'Support Reopen Policy',
            $normalized === 'support.honeypot_field' => 'Support Spam Protection',
            $normalized === 'admin.security.reauth_minutes' => 'Admin Step-Up Authentication',
            str_starts_with($normalized, 'session.') => 'Session Management',
            str_starts_with($normalized, 'otp.') => 'OTP Security Controls',
            str_starts_with($normalized, 'stripe.') => 'Stripe Payment Integration',
            str_starts_with($normalized, 'integrations.google_maps.') => 'Google Maps Integration',
            str_starts_with($normalized, 'integrations.fcm.') => 'Push Notification Delivery',
            str_starts_with($normalized, 'email.') => 'Email Delivery Configuration',
            str_starts_with($normalized, 'support.') => 'Support Operations',
            str_starts_with($normalized, 'onboarding.') => 'Onboarding Controls',
            str_starts_with($normalized, 'operations.') => 'Operations Monitoring',
            str_starts_with($normalized, 'maintenance.') => 'Maintenance Controls',
            str_starts_with($normalized, 'incident.') => 'Incident Response',
            str_starts_with($normalized, 'admin.') => 'Admin Security',
            default => str($normalized)
                ->replace(['.', '_', '-'], ' ')
                ->title()
                ->toString(),
        };
    }

    private function settingHelpForKey(string $key): string
    {
        $normalized = strtolower(trim($key));

        return match (true) {
            str_contains($normalized, 'support.sla') => 'SLA values are in minutes. Lower values tighten response/resolution targets and can increase staffing pressure.',
            $normalized === 'support.duplicate_window_minutes' => 'Defines the deduplication lookback window (minutes) for newly submitted support tickets.',
            $normalized === 'support.reopen_window_hours' => 'Defines how long a resolved ticket can be reopened after resolution (hours).',
            $normalized === 'support.honeypot_field' => 'Set to a hidden field name rendered in forms. Bots filling this field are treated as spam.',
            $normalized === 'admin.security.reauth_minutes' => 'Step-up auth window for sensitive actions in admin. Keep low for stronger security.',
            $normalized === 'session.lifetime_minutes' => 'Admin/API session idle timeout in minutes.',
            $normalized === 'session.expire_on_close' => 'When enabled, session cookies expire when the browser closes.',
            $normalized === 'otp.expire_minutes' => 'OTP validity duration in minutes before a code expires.',
            $normalized === 'otp.max_attempts' => 'Maximum invalid OTP attempts before temporary lockout.',
            $normalized === 'otp.lock_minutes' => 'Lockout duration in minutes after OTP max attempts is reached.',
            $normalized === 'otp.mail_subject' => 'Subject used for OTP emails sent to users.',
            $normalized === 'stripe.secret_key' => 'Secret credential for backend Stripe API calls. Rotate carefully and verify webhooks/payments after update.',
            $normalized === 'stripe.publishable_key' => 'Public key used by front-end Stripe SDK flows.',
            $normalized === 'stripe.client_id' => 'Stripe Connect client identifier for OAuth flows.',
            $normalized === 'stripe.redirect_uri' => 'OAuth callback URL. Use absolute URL or a relative path (for example /api/stripe/callback).',
            $normalized === 'stripe.dashboard_base_url' => 'Base URL used for admin links to Stripe dashboard payment pages.',
            $normalized === 'stripe.webhook_signing_secret' => 'Signing secret used to verify Stripe webhook payload authenticity. Keep restricted to platform/security admins.',
            $normalized === 'stripe.currency' => 'Default Stripe currency for intents/transfers (ISO 4217 lowercase, for example aud or usd).',
            $normalized === 'stripe.connected_account_country' => 'Two-letter country code used for Stripe Connect account and bank account setup (for example AU, US).',
            $normalized === 'integrations.google_maps.api_key' => 'Google Maps API key used for geocoding/address enrichment. Rotate with provider console and validate geocoding flows post-change.',
            $normalized === 'integrations.fcm.server_key' => 'FCM server key used for push notifications. Treat as secret and validate push delivery after rotation.',
            $normalized === 'email.mailer' => 'Default mail transport used by Laravel (for example smtp, log, ses, mailgun).',
            $normalized === 'email.smtp.host' => 'SMTP hostname used for outbound email.',
            $normalized === 'email.smtp.port' => 'SMTP port (commonly 587 for TLS or 465 for SSL).',
            $normalized === 'email.smtp.encryption' => 'SMTP encryption mode (tls, ssl, or empty for none).',
            $normalized === 'email.smtp.username' => 'SMTP account username.',
            $normalized === 'email.smtp.password' => 'SMTP account password. Keep restricted and rotate periodically.',
            $normalized === 'email.from.address' => 'Global sender email address for outgoing platform emails.',
            $normalized === 'email.from.name' => 'Global sender display name for outgoing platform emails.',
            default => 'Document intended use, safe values, and rollback steps before saving.',
        };
    }

    private function isHighRiskKey(string $key): bool
    {
        $normalized = strtolower(trim($key));
        if ($normalized === '') {
            return false;
        }

        $tokens = [
            'maintenance',
            'incident',
            'auth',
            'password',
            'session',
            'feature',
            'flag',
            'integration',
            'policy',
            'payment',
            'stripe',
            'queue',
            'cache',
            'security',
        ];

        foreach ($tokens as $token) {
            if (str_contains($normalized, $token)) {
                return true;
            }
        }

        return false;
    }

    private function isSuperAdminOnlyIntegrationKey(string $key): bool
    {
        $normalized = strtolower(trim($key));
        if ($normalized === '') {
            return false;
        }

        return str_starts_with($normalized, 'otp.')
            || str_starts_with($normalized, 'email.')
            || str_starts_with($normalized, 'integrations.google_maps.')
            || str_starts_with($normalized, 'stripe.')
            || str_starts_with($normalized, 'payment.');
    }

    private function applyApprovedRequest(PlatformSettingChangeRequest $request, int $actorId): void
    {
        DB::transaction(function () use ($request, $actorId): void {
            $request->approved_by = $actorId;
            $request->approved_at = now();
            $request->status = PlatformSettingChangeRequest::STATUS_APPROVED;
            $request->save();

            $this->activateApprovedRequest($request, $actorId);
        });

        app(AdminAuditLogService::class)->log('platform_settings.approved', request(), [
            'request_id' => $request->id,
            'setting_key' => $request->setting_key,
        ]);

        app(AdminAuditLogService::class)->log('platform_settings.activated', request(), [
            'request_id' => $request->id,
            'setting_key' => $request->setting_key,
        ]);

        app(PlatformRuntimeConfigService::class)->apply();
    }

    private function activateApprovedRequest(PlatformSettingChangeRequest $request, int $actorId): void
    {
        /** @var PlatformSetting $setting */
        $setting = PlatformSetting::query()->firstOrNew([
            'key' => $request->setting_key,
        ]);

        $isDeletion = $request->proposed_value === null;
        if ($isDeletion) {
            if ($setting->exists) {
                $setting->delete();
            }
        } else {
            $setting->value = $request->proposed_value;
            $setting->value_type = $request->value_type;
            $setting->description = $request->description;
            $setting->updated_by = $actorId;
            $setting->version = $setting->exists ? ((int) $setting->version + 1) : 1;
            $setting->save();
        }

        $request->status = PlatformSettingChangeRequest::STATUS_ACTIVATED;
        $request->activated_by = $actorId;
        $request->activated_at = now();
        $request->save();
    }

    private function resolveExistingSetting(array $row, \Illuminate\Support\Collection $existingById, \Illuminate\Support\Collection $existingByKey): ?PlatformSetting
    {
        $id = ! empty($row['id']) ? (int) $row['id'] : null;
        if ($id !== null && $existingById->has($id)) {
            /** @var PlatformSetting $record */
            $record = $existingById->get($id);
            return $record;
        }

        $key = strtolower(trim((string) ($row['key'] ?? '')));
        if ($key !== '' && $existingByKey->has($key)) {
            /** @var PlatformSetting $record */
            $record = $existingByKey->get($key);
            return $record;
        }

        return null;
    }

    /**
     * @return \Illuminate\Support\Collection<string, PlatformSettingChangeRequest>
     */
    private function latestPendingRequestsByKey(): \Illuminate\Support\Collection
    {
        return PlatformSettingChangeRequest::query()
            ->whereIn('status', [
                PlatformSettingChangeRequest::STATUS_VALIDATED,
                PlatformSettingChangeRequest::STATUS_APPROVED,
            ])
            ->latest('id')
            ->get()
            ->unique(fn (PlatformSettingChangeRequest $request): string => strtolower((string) $request->setting_key))
            ->keyBy(fn (PlatformSettingChangeRequest $request): string => strtolower((string) $request->setting_key));
    }

    private function upsertApprovalRequest(string $key, ?array $proposedValue, string $valueType, ?string $description, string $changeReason): void
    {
        PlatformSettingChangeRequest::query()
            ->where('setting_key', $key)
            ->whereIn('status', [
                PlatformSettingChangeRequest::STATUS_VALIDATED,
                PlatformSettingChangeRequest::STATUS_APPROVED,
            ])
            ->delete();

        $payload = [
            'setting_key' => $key,
            'proposed_value' => $proposedValue,
            'value_type' => $valueType,
            'change_reason' => $changeReason,
            'risk_level' => 'high',
            'status' => PlatformSettingChangeRequest::STATUS_VALIDATED,
            'requested_by' => Filament::auth()->id(),
            'approved_by' => null,
            'activated_by' => null,
            'validated_at' => now(),
            'approved_at' => null,
            'activated_at' => null,
        ];

        if (Schema::hasColumn('platform_setting_change_requests', 'description')) {
            $payload['description'] = $description;
        }

        PlatformSettingChangeRequest::query()->create($payload);
    }

    private function calculateRetainedIds(array $rows, \Illuminate\Support\Collection $existingByKey): array
    {
        $retained = collect($rows)
            ->pluck('id')
            ->filter()
            ->map(fn ($id): int => (int) $id)
            ->values();

        foreach ($rows as $row) {
            if (! empty($row['id'])) {
                continue;
            }

            $key = strtolower(trim((string) ($row['key'] ?? '')));
            if ($key === '') {
                continue;
            }

            if ($existingByKey->has($key)) {
                /** @var PlatformSetting $record */
                $record = $existingByKey->get($key);
                $retained[] = (int) $record->id;
            }
        }

        return $retained->unique()->values()->all();
    }

}
