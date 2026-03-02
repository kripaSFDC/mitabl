<x-filament-panels::page>

{{-- Page description --}}
<p class="mb-6 text-sm text-gray-600 dark:text-gray-400">
    Periodic access review dashboard. Dormant accounts should be deactivated or re-certified per the
    IAM and secret-rotation runbooks. Key metrics are shown below.
</p>

{{-- ── Access Review KPI tiles ─────────────────────────────────────────── --}}
<div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-6">
    @php
        $tile = fn(string $label, $val, string $color = 'gray', ?string $sub = null): array =>
            compact('label', 'val', 'color', 'sub');
        $dormantCount = $accessReview['dormant_active_admins'] ?? 0;
        $tiles = [
            $tile('Total Admins',    $accessReview['admins_total']            ?? 0, 'blue'),
            $tile('Active Admins',  $accessReview['admins_active']            ?? 0, 'emerald'),
            $tile('IAM Managers',   $accessReview['iam_manager_candidates']   ?? 0, 'violet'),
            $tile('Dormant Active', $dormantCount,                              $dormantCount > 0 ? 'red' : 'gray',
                  $dormantCount > 0 ? 'Review required' : 'None found'),
            $tile('Defined Roles',  $accessReview['defined_roles']             ?? 0, 'sky'),
            $tile('Re-auth (min)',  $sessionPolicy['step_up_reauth_minutes']   ?? 15, 'gray',
                  'Sensitive actions'),
        ];
        $tileColors = [
            'blue'   => 'border-blue-200 bg-blue-50 dark:border-blue-800 dark:bg-blue-950/30',
            'emerald'=> 'border-emerald-200 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-950/30',
            'violet' => 'border-violet-200 bg-violet-50 dark:border-violet-800 dark:bg-violet-950/30',
            'red'    => 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950/30',
            'sky'    => 'border-sky-200 bg-sky-50 dark:border-sky-800 dark:bg-sky-950/30',
            'gray'   => 'border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/40',
        ];
        $tileValColors = [
            'blue'   => 'text-blue-700 dark:text-blue-300',
            'emerald'=> 'text-emerald-700 dark:text-emerald-300',
            'violet' => 'text-violet-700 dark:text-violet-300',
            'red'    => 'text-red-700 dark:text-red-300',
            'sky'    => 'text-sky-700 dark:text-sky-300',
            'gray'   => 'text-gray-700 dark:text-gray-300',
        ];
    @endphp
    @foreach ($tiles as $t)
        <div class="rounded-xl border px-5 py-4 shadow-sm {{ $tileColors[$t['color']] }}">
            <p class="text-[10px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">{{ $t['label'] }}</p>
            <p class="mt-1 text-2xl font-bold {{ $tileValColors[$t['color']] }}">{{ $t['val'] }}</p>
            @if ($t['sub'])
                <p class="mt-0.5 text-[10px] text-gray-400">{{ $t['sub'] }}</p>
            @endif
        </div>
    @endforeach
</div>

{{-- ── Two-column section ─────────────────────────────────────────────── --}}
<div class="mb-6 grid gap-4 md:grid-cols-2">

    {{-- Session Policy --}}
    <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
        <div class="border-b border-gray-200 bg-gray-50 px-5 py-3 dark:border-gray-700 dark:bg-gray-800">
            <h2 class="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-white">
                <x-filament::icon icon="heroicon-o-clock" class="h-4 w-4 text-gray-500" />
                Session Policy
            </h2>
        </div>
        <dl class="divide-y divide-gray-100 dark:divide-gray-800 text-sm">
            @php
                $policyRows = [
                    ['Session lifetime', ($sessionPolicy['lifetime_minutes'] ?? 0) . ' minutes'],
                    ['Expire on browser close', ($sessionPolicy['expire_on_close'] ?? false) ? 'Yes' : 'No'],
                    ['Sensitive-action re-auth', ($sessionPolicy['step_up_reauth_minutes'] ?? 15) . ' minutes'],
                    ['Dormant threshold', ($sessionPolicy['dormant_threshold_days'] ?? 30) . ' days'],
                ];
            @endphp
            @foreach ($policyRows as [$label, $value])
                <div class="flex items-center justify-between px-5 py-3">
                    <dt class="text-gray-500 dark:text-gray-400">{{ $label }}</dt>
                    <dd class="font-semibold text-gray-800 dark:text-gray-200">{{ $value }}</dd>
                </div>
            @endforeach
        </dl>
    </div>

    {{-- Runbooks & References --}}
    <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
        <div class="border-b border-gray-200 bg-gray-50 px-5 py-3 dark:border-gray-700 dark:bg-gray-800">
            <h2 class="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-white">
                <x-filament::icon icon="heroicon-o-book-open" class="h-4 w-4 text-gray-500" />
                Runbook References
            </h2>
        </div>
        <div class="space-y-3 px-5 py-4 text-sm">
            <div class="rounded-lg border border-gray-100 bg-gray-50 px-4 py-3 dark:border-gray-700 dark:bg-gray-800">
                <p class="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400 mb-1">Secret Rotation Runbook</p>
                <code class="text-xs text-blue-600 dark:text-blue-400">{{ $accessReview['rotation_runbook'] ?? 'docs/secrets-management.md' }}</code>
            </div>
            <div class="text-xs text-gray-500 dark:text-gray-400 space-y-1">
                <p>• Rotate API keys, Stripe secrets, and JWT signing keys at least every 90 days.</p>
                <p>• Deactivate dormant admin identities immediately upon discovery.</p>
                <p>• Super-admin count should be kept to a minimum (≤ 3 active).</p>
            </div>
        </div>
    </div>
</div>

{{-- ── Dormant Admins table ────────────────────────────────────────────── --}}
<div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
    <div class="border-b border-gray-200 bg-gray-50 px-5 py-3 dark:border-gray-700 dark:bg-gray-800">
        <div class="flex items-center justify-between">
            <div>
                <h2 class="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-white">
                    <x-filament::icon icon="heroicon-o-user-circle" class="h-4 w-4 text-gray-500" />
                    Dormant Active Admins
                    @if (count($dormantAdmins) > 0)
                        <span class="ml-1 inline-flex items-center rounded-full bg-red-100 px-2 py-0.5 text-xs font-bold text-red-700 dark:bg-red-900/40 dark:text-red-300">
                            {{ count($dormantAdmins) }}
                        </span>
                    @endif
                </h2>
                <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
                    Active admin identities with no login activity in the last {{ $sessionPolicy['dormant_threshold_days'] ?? 30 }} days
                </p>
            </div>
        </div>
    </div>

    @if (count($dormantAdmins) > 0)
        <div class="overflow-x-auto">
            <table class="w-full text-sm" role="grid">
                <thead>
                    <tr class="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/60 text-left">
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">ID</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Name</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Email</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Last Login</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Risk</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                    @foreach ($dormantAdmins as $admin)
                        @php
                            $neverLogged = $admin['last_login_at'] === null;
                            $risk = $neverLogged ? 'High' : 'Dormant';
                            $riskClass = $neverLogged
                                ? 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300'
                                : 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/40 dark:text-yellow-300';
                        @endphp
                        <tr class="bg-white hover:bg-gray-50/80 transition-colors dark:bg-gray-900 dark:hover:bg-gray-800/50">
                            <td class="px-5 py-3 font-mono text-xs text-gray-500 dark:text-gray-400">{{ $admin['id'] }}</td>
                            <td class="px-5 py-3 font-medium text-gray-800 dark:text-gray-200">{{ $admin['name'] }}</td>
                            <td class="px-5 py-3 text-gray-600 dark:text-gray-300">{{ $admin['email'] }}</td>
                            <td class="px-5 py-3 text-gray-600 dark:text-gray-300">
                                @if ($neverLogged)
                                    <span class="italic text-gray-400">Never logged in</span>
                                @else
                                    {{ $admin['last_login_at'] }}
                                @endif
                            </td>
                            <td class="px-5 py-3">
                                <span class="inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold {{ $riskClass }}">{{ $risk }}</span>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        <div class="border-t border-gray-100 bg-amber-50 px-5 py-3 dark:border-gray-700 dark:bg-amber-950/20">
            <p class="text-xs text-amber-700 dark:text-amber-400">
                ⚠ {{ count($dormantAdmins) }} admin account(s) require review. Deactivate unused identities via the Admin Users section.
            </p>
        </div>
    @else
        <div class="flex flex-col items-center justify-center py-12">
            <x-filament::icon icon="heroicon-o-check-badge" class="h-9 w-9 text-emerald-400 mb-2" />
            <p class="text-sm font-medium text-gray-600 dark:text-gray-300">No dormant admins found</p>
            <p class="mt-0.5 text-xs text-gray-400">All active admin identities have recent login activity</p>
        </div>
    @endif
</div>

</x-filament-panels::page>
