<?php

namespace App\Services;

use Illuminate\Validation\ValidationException;

class PolicyDefinitionValidator
{
    public const SUPPORTED_POLICY_NAMES = [
        'sla_policy',
        'escalation_policy',
        'suspension_policy',
        'refund_policy',
        'document_retention_policy',
    ];

    public function validateOrFail(string $policyName, array $definition): void
    {
        $name = strtolower(trim($policyName));

        if ($name === '') {
            throw ValidationException::withMessages([
                'name' => 'Policy name is required.',
            ]);
        }

        if (! in_array($name, self::SUPPORTED_POLICY_NAMES, true)) {
            throw ValidationException::withMessages([
                'name' => 'Unsupported policy name. Supported names: ' . implode(', ', self::SUPPORTED_POLICY_NAMES) . '.',
            ]);
        }

        $errors = match ($name) {
            'sla_policy' => $this->validateSlaPolicy($definition),
            'escalation_policy' => $this->validateEscalationPolicy($definition),
            'suspension_policy' => $this->validateSuspensionPolicy($definition),
            'refund_policy' => $this->validateRefundPolicy($definition),
            'document_retention_policy' => $this->validateRetentionPolicy($definition),
            default => [],
        };

        if ($errors !== []) {
            throw ValidationException::withMessages([
                'definition_json' => implode(' ', $errors),
            ]);
        }
    }

    public function isHighImpact(string $policyName, array $definition, ?array $activeDefinition = null): bool
    {
        $name = strtolower(trim($policyName));
        $highImpactNames = [
            'escalation_policy',
            'suspension_policy',
            'refund_policy',
        ];

        if (in_array($name, $highImpactNames, true)) {
            return true;
        }

        return $this->flattenCount($definition) >= 10
            || ($activeDefinition !== null && $this->definitionDistance($activeDefinition, $definition) >= 5);
    }

    public function blastRadiusWarning(string $policyName, array $definition, ?array $activeDefinition = null): string
    {
        $name = strtolower(trim($policyName));
        $changedNodes = $activeDefinition === null ? $this->flattenCount($definition) : $this->definitionDistance($activeDefinition, $definition);

        $base = match ($name) {
            'refund_policy' => 'This can immediately change refund outcomes for new and in-progress support cases.',
            'suspension_policy' => 'This can affect account eligibility and automatic enforcement paths.',
            'escalation_policy' => 'This can alter support routing, on-call load, and SLA breach handling.',
            default => 'This policy has broad operational impact and should be rolled out carefully.',
        };

        return $base . ' Estimated changed policy nodes: ' . $changedNodes . '.';
    }

    private function validateSlaPolicy(array $definition): array
    {
        $errors = [];

        $firstResponse = $definition['first_response_minutes'] ?? null;
        if (! is_int($firstResponse) || $firstResponse < 1) {
            $errors[] = 'SLA policy requires integer first_response_minutes >= 1.';
        }

        $resolution = $definition['resolution_minutes'] ?? null;
        if (! is_int($resolution) || $resolution < 1) {
            $errors[] = 'SLA policy requires integer resolution_minutes >= 1.';
        }

        return $errors;
    }

    private function validateEscalationPolicy(array $definition): array
    {
        $errors = [];

        $levels = $definition['levels'] ?? null;
        if (! is_array($levels) || $levels === []) {
            $errors[] = 'Escalation policy requires a non-empty levels array.';
            return $errors;
        }

        foreach ($levels as $idx => $level) {
            if (! is_array($level)) {
                $errors[] = 'Escalation level #' . $idx . ' must be an object.';
                continue;
            }

            if (! isset($level['after_minutes']) || ! is_int($level['after_minutes']) || $level['after_minutes'] < 1) {
                $errors[] = 'Escalation level #' . $idx . ' must include integer after_minutes >= 1.';
            }

            if (! isset($level['target']) || trim((string) $level['target']) === '') {
                $errors[] = 'Escalation level #' . $idx . ' must include target.';
            }
        }

        return $errors;
    }

    private function validateSuspensionPolicy(array $definition): array
    {
        $errors = [];

        $threshold = $definition['auto_suspend_after_violations'] ?? null;
        if (! is_int($threshold) || $threshold < 1) {
            $errors[] = 'Suspension policy requires integer auto_suspend_after_violations >= 1.';
        }

        $cooldown = $definition['cooldown_days'] ?? null;
        if ($cooldown !== null && (! is_int($cooldown) || $cooldown < 0)) {
            $errors[] = 'Suspension policy cooldown_days must be an integer >= 0.';
        }

        return $errors;
    }

    private function validateRefundPolicy(array $definition): array
    {
        $errors = [];

        $maxPercent = $definition['max_refund_percentage'] ?? null;
        if (! is_int($maxPercent) || $maxPercent < 0 || $maxPercent > 100) {
            $errors[] = 'Refund policy requires integer max_refund_percentage between 0 and 100.';
        }

        $requiresApproval = $definition['require_admin_approval_above_percentage'] ?? null;
        if ($requiresApproval !== null && (! is_int($requiresApproval) || $requiresApproval < 0 || $requiresApproval > 100)) {
            $errors[] = 'Refund policy require_admin_approval_above_percentage must be an integer between 0 and 100.';
        }

        return $errors;
    }

    private function validateRetentionPolicy(array $definition): array
    {
        $errors = [];

        $days = $definition['retention_days'] ?? null;
        if (! is_int($days) || $days < 1) {
            $errors[] = 'Document retention policy requires integer retention_days >= 1.';
        }

        $purgeMode = $definition['purge_mode'] ?? null;
        if ($purgeMode !== null && ! in_array($purgeMode, ['soft_delete', 'hard_delete'], true)) {
            $errors[] = 'Document retention policy purge_mode must be soft_delete or hard_delete.';
        }

        return $errors;
    }

    private function flattenCount(array $payload): int
    {
        $count = 0;
        array_walk_recursive($payload, function () use (&$count): void {
            $count++;
        });

        return $count;
    }

    private function definitionDistance(array $before, array $after): int
    {
        $beforeFlat = $this->flattenAssoc($before);
        $afterFlat = $this->flattenAssoc($after);

        $keys = array_unique(array_merge(array_keys($beforeFlat), array_keys($afterFlat)));

        $distance = 0;
        foreach ($keys as $key) {
            if (! array_key_exists($key, $beforeFlat) || ! array_key_exists($key, $afterFlat) || $beforeFlat[$key] !== $afterFlat[$key]) {
                $distance++;
            }
        }

        return $distance;
    }

    private function flattenAssoc(array $payload, string $prefix = ''): array
    {
        $flat = [];
        foreach ($payload as $key => $value) {
            $path = $prefix === '' ? (string) $key : $prefix . '.' . $key;
            if (is_array($value)) {
                $flat += $this->flattenAssoc($value, $path);
                continue;
            }

            $flat[$path] = is_scalar($value) || $value === null ? $value : json_encode($value);
        }

        return $flat;
    }
}
