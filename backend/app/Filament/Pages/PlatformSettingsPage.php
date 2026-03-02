<?php

namespace App\Filament\Pages;

use App\Models\PlatformSetting;
use App\Models\PlatformSettingChangeRequest;
use App\Services\AdminAuditLogService;
use App\Services\AdminStepUpService;
use App\Services\PlatformSettingRegistry;
use Filament\Facades\Filament;
use Filament\Forms;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\DB;
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
        $this->form->fill([
            'settings' => app(PlatformSettingRegistry::class)->forAdminForm(),
            'change_reason' => '',
        ]);

        $this->loadPendingApprovals();
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
                            ->default([])
                            ->schema([
                                Forms\Components\Hidden::make('id'),
                                Forms\Components\TextInput::make('key')
                                    ->required()
                                    ->maxLength(255)
                                    ->placeholder('feature.flag_name')
                                    ->helperText('Use stable dot-notation keys (for example auth.lockout.window_minutes). Keys under support/session/admin/stripe are platform-managed runtime controls.'),
                                Forms\Components\Select::make('value_type')
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
                                    ->rows(2)
                                    ->maxLength(1000)
                                    ->helperText('Describe impact, safe ranges, and rollback hints for operators. This text serves as inline admin guidance.'),
                                Forms\Components\Toggle::make('value_boolean')
                                    ->label('Boolean value')
                                    ->helperText(fn (Forms\Get $get): string => $this->settingHelpForKey((string) $get('key')))
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'boolean'),
                                Forms\Components\TextInput::make('value_integer')
                                    ->label('Integer value')
                                    ->numeric()
                                    ->helperText(fn (Forms\Get $get): string => $this->settingHelpForKey((string) $get('key')))
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'integer'),
                                Forms\Components\Textarea::make('value_string')
                                    ->label('String value')
                                    ->rows(3)
                                    ->helperText(fn (Forms\Get $get): string => $this->settingHelpForKey((string) $get('key')))
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'string'),
                                Forms\Components\Textarea::make('value_json')
                                    ->label('JSON value')
                                    ->rows(8)
                                    ->helperText(fn (Forms\Get $get): string => 'Must be valid JSON. ' . $this->settingHelpForKey((string) $get('key')))
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'json'),
                            ])
                            ->columns(2)
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

            if (! $existing) {
                $changedOrAddedKeys[] = $key;
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
            ->filter(fn (PlatformSetting $setting): bool => ! in_array((int) $setting->id, $retainedIds, true))
            ->pluck('key')
            ->map(fn ($key): string => (string) $key)
            ->values()
            ->all();

        $highRiskCandidates = collect(array_merge($changedOrAddedKeys, $deletedKeys))
            ->filter(fn (string $key): bool => $this->isHighRiskKey($key))
            ->unique()
            ->values();

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

            $this->createApprovalRequests($rows, $highRiskCandidates->all(), $deletedKeys, $changeReason);

            Notification::make()
                ->title('High-risk changes validated and submitted for approval. Activate after approver sign-off.')
                ->warning()
                ->send();

            app(AdminAuditLogService::class)->log('platform_settings.validated', request(), [
                'high_risk_keys' => $highRiskCandidates->all(),
                'change_reason' => $changeReason,
            ]);

            $this->mount();

            return;
        }

        try {
            DB::transaction(function () use ($rows, &$changedKeys, &$deletedCount): void {
                $existingSettings = PlatformSetting::query()->lockForUpdate()->get();
                $existingById = $existingSettings->keyBy('id');
                $existingByKey = $existingSettings->keyBy(fn (PlatformSetting $setting): string => strtolower((string) $setting->key));
                $retainedIds = $this->calculateRetainedIds($rows, $existingByKey);

                $toDelete = $existingSettings
                    ->filter(fn (PlatformSetting $setting): bool => ! in_array((int) $setting->id, $retainedIds, true))
                    ->pluck('id')
                    ->map(fn ($id): int => (int) $id)
                    ->all();

                if (count($toDelete) > 0) {
                    PlatformSetting::query()->whereIn('id', $toDelete)->delete();
                    $deletedCount = count($toDelete);
                }

                foreach ($rows as $row) {
                    $key = trim((string) ($row['key'] ?? ''));
                    if ($key === '') {
                        continue;
                    }

                    $valueType = (string) ($row['value_type'] ?? 'json');
                    $normalizedValue = $this->normalizeValue($valueType, $row);

                    $record = $this->resolveExistingSetting($row, $existingById, $existingByKey);

                    $isNewRecord = false;
                    if (! $record) {
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

                    $existingById->put((int) $record->id, $record);
                    $existingByKey->put(strtolower((string) $record->key), $record);
                }
            });
        } catch (ValidationException $exception) {
            throw $exception;
        } catch (\Throwable $throwable) {
            Notification::make()->title('Save failed: ' . $throwable->getMessage())->danger()->send();
            return;
        }

        app(AdminAuditLogService::class)->log('platform_settings.save', request(), [
            'changed_keys' => array_values(array_unique($changedKeys)),
            'changed_count' => count(array_unique($changedKeys)),
            'deleted_count' => $deletedCount,
            'high_risk_keys' => $highRiskCandidates->all(),
            'change_reason' => $changeReason === '' ? null : $changeReason,
        ]);

        Notification::make()->title('Platform settings saved.')->success()->send();
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

        $actorId = Filament::auth()->id();
        if ((int) $request->requested_by === (int) $actorId) {
            Notification::make()->title('Two-person control: requester cannot approve their own high-risk change.')->danger()->send();
            return;
        }

        $request->status = PlatformSettingChangeRequest::STATUS_APPROVED;
        $request->approved_by = $actorId;
        $request->approved_at = now();
        $request->save();

        app(AdminAuditLogService::class)->log('platform_settings.approved', request(), [
            'request_id' => $request->id,
            'setting_key' => $request->setting_key,
        ]);

        Notification::make()->title('High-risk change approved.')->success()->send();
        $this->loadPendingApprovals();
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

        DB::transaction(function () use ($request): void {
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
                $setting->updated_by = Filament::auth()->id();
                $setting->version = $setting->exists ? ((int) $setting->version + 1) : 1;
                $setting->save();
            }

            $request->status = PlatformSettingChangeRequest::STATUS_ACTIVATED;
            $request->activated_by = Filament::auth()->id();
            $request->activated_at = now();
            $request->save();
        });

        app(AdminAuditLogService::class)->log('platform_settings.activated', request(), [
            'request_id' => $request->id,
            'setting_key' => $request->setting_key,
        ]);

        Notification::make()->title('Approved high-risk change activated.')->success()->send();
        $this->mount();
    }

    private function createApprovalRequests(array $rows, array $keys, array $deletedKeys, string $changeReason): void
    {
        $highRisk = array_map('strtolower', $keys);

        DB::transaction(function () use ($rows, $highRisk, $deletedKeys, $changeReason): void {
            foreach ($rows as $row) {
                $key = trim((string) ($row['key'] ?? ''));
                if ($key === '' || ! in_array(strtolower($key), $highRisk, true)) {
                    continue;
                }

                $valueType = (string) ($row['value_type'] ?? 'json');
                $normalizedValue = $this->normalizeValue($valueType, $row);

                PlatformSettingChangeRequest::query()->create([
                    'setting_key' => $key,
                    'proposed_value' => $normalizedValue,
                    'value_type' => $valueType,
                    'change_reason' => $changeReason,
                    'risk_level' => 'high',
                    'status' => PlatformSettingChangeRequest::STATUS_VALIDATED,
                    'requested_by' => Filament::auth()->id(),
                    'validated_at' => now(),
                ]);
            }

            foreach ($deletedKeys as $deletedKey) {
                $normalizedDeletedKey = strtolower(trim((string) $deletedKey));
                if ($normalizedDeletedKey === '' || ! in_array($normalizedDeletedKey, $highRisk, true)) {
                    continue;
                }

                PlatformSettingChangeRequest::query()->create([
                    'setting_key' => (string) $deletedKey,
                    'proposed_value' => null,
                    'value_type' => 'json',
                    'change_reason' => $changeReason,
                    'risk_level' => 'high',
                    'status' => PlatformSettingChangeRequest::STATUS_VALIDATED,
                    'requested_by' => Filament::auth()->id(),
                    'validated_at' => now(),
                ]);
            }
        });
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
                'validated_at' => optional($request->validated_at)?->toDateTimeString(),
            ])->all();
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
                $retained->push((int) $record->id);
            }
        }

        return $retained->unique()->values()->all();
    }
}
