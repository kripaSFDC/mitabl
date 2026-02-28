<?php

namespace App\Filament\Pages;

use App\Models\PlatformSetting;
use App\Services\AdminAuditLogService;
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

    public function mount(): void
    {
        $this->form->fill([
            'settings' => PlatformSetting::query()
                ->orderBy('key')
                ->get()
                ->map(fn (PlatformSetting $setting): array => [
                    'id' => $setting->id,
                    'key' => $setting->key,
                    'value_type' => $setting->value_type,
                    'description' => $setting->description,
                    'value_string' => $setting->value_type === 'string' ? (string) data_get($setting->value, 'value', '') : null,
                    'value_integer' => $setting->value_type === 'integer' ? (int) data_get($setting->value, 'value', 0) : null,
                    'value_boolean' => $setting->value_type === 'boolean' ? (bool) data_get($setting->value, 'value', false) : false,
                    'value_json' => $setting->value_type === 'json'
                        ? (json_encode($setting->value ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}')
                        : '{}',
                ])
                ->toArray(),
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
                            ->default([])
                            ->schema([
                                Forms\Components\Hidden::make('id'),
                                Forms\Components\TextInput::make('key')
                                    ->required()
                                    ->maxLength(255)
                                    ->placeholder('feature.flag_name'),
                                Forms\Components\Select::make('value_type')
                                    ->required()
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
                                    ->maxLength(1000),
                                Forms\Components\Toggle::make('value_boolean')
                                    ->label('Boolean value')
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'boolean'),
                                Forms\Components\TextInput::make('value_integer')
                                    ->label('Integer value')
                                    ->numeric()
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'integer'),
                                Forms\Components\Textarea::make('value_string')
                                    ->label('String value')
                                    ->rows(3)
                                    ->visible(fn (Forms\Get $get): bool => $get('value_type') === 'string'),
                                Forms\Components\Textarea::make('value_json')
                                    ->label('JSON value')
                                    ->rows(8)
                                    ->helperText('Must be valid JSON.')
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
                    ]),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        if (! Filament::auth()->user()?->can('platform_settings.edit')) {
            Notification::make()->title('You do not have permission to modify platform settings.')->danger()->send();
            return;
        }

        $state = $this->form->getState();
        $rows = (array) ($state['settings'] ?? []);
        $changeReason = trim((string) ($state['change_reason'] ?? ''));
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
            if (! Filament::auth()->user()?->can('policy_changes.publish')) {
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
        return (bool) Filament::auth()->user()?->can('platform_settings.view');
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

