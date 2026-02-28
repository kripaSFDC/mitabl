<?php

namespace App\Services;

use App\Models\PlatformSetting;

class PlatformSettingRegistry
{
    public const DEFAULT_SETTINGS = [
        [
            'key' => 'onboarding.enabled',
            'value_type' => 'boolean',
            'description' => 'Master onboarding flow toggle.',
            'value' => ['value' => true],
        ],
        [
            'key' => 'onboarding.require_identity_verification',
            'value_type' => 'boolean',
            'description' => 'Require identity verification during onboarding.',
            'value' => ['value' => false],
        ],
        [
            'key' => 'maintenance.read_only_mode',
            'value_type' => 'boolean',
            'description' => 'Enable maintenance read-only mode for operational safety.',
            'value' => ['value' => false],
        ],
        [
            'key' => 'operations.synthetic_checks_enabled',
            'value_type' => 'boolean',
            'description' => 'Enable synthetic health checks scheduling and monitoring.',
            'value' => ['value' => true],
        ],
        [
            'key' => 'incident.degraded_mode',
            'value_type' => 'json',
            'description' => 'Incident-mode degraded operation controls.',
            'value' => ['enabled' => false, 'annotation' => null, 'postmortem_url' => null],
        ],
    ];

    /**
     * @return array<int, array<string, mixed>>
     */
    public function forAdminForm(): array
    {
        $existing = PlatformSetting::query()
            ->orderBy('key')
            ->get()
            ->keyBy(fn (PlatformSetting $setting): string => strtolower((string) $setting->key));

        $rows = [];

        foreach (self::DEFAULT_SETTINGS as $default) {
            $key = strtolower((string) $default['key']);
            $record = $existing->get($key);

            if ($record) {
                $rows[] = $this->toFormRow($record);
                $existing->forget($key);
                continue;
            }

            $rows[] = $this->toFormRow(new PlatformSetting([
                'id' => null,
                'key' => $default['key'],
                'value_type' => $default['value_type'],
                'description' => $default['description'],
                'value' => $default['value'],
            ]));
        }

        foreach ($existing->sortBy(fn (PlatformSetting $setting): string => strtolower((string) $setting->key)) as $setting) {
            $rows[] = $this->toFormRow($setting);
        }

        return $rows;
    }

    /**
     * @return array<string, mixed>
     */
    private function toFormRow(PlatformSetting $setting): array
    {
        return [
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
        ];
    }
}
