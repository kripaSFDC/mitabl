<?php

namespace App\Filament\Pages;

use App\Models\AdminUser;
use Filament\Facades\Filament;
use Filament\Pages\Page;
use Spatie\Permission\Models\Role;

class SecurityAdminPage extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-shield-check';

    protected static ?string $navigationGroup = 'Platform';

    protected static ?int $navigationSort = 60;

    protected static ?string $title = 'Security Admin';

    protected static string $view = 'filament.pages.security-admin-page';

    public array $sessionPolicy = [];
    public array $accessReview = [];
    public array $dormantAdmins = [];

    public function mount(): void
    {
        $now = now();
        $dormantThresholdDays = 30;
        $cutoff = $now->copy()->subDays($dormantThresholdDays);

        $this->sessionPolicy = [
            'lifetime_minutes' => (int) config('session.lifetime', 120),
            'expire_on_close' => (bool) config('session.expire_on_close', false),
            'dormant_threshold_days' => $dormantThresholdDays,
        ];

        $this->dormantAdmins = AdminUser::query()
            ->where('is_active', true)
            ->where(function ($query) use ($cutoff) {
                $query->whereNull('last_login_at')
                    ->orWhere('last_login_at', '<', $cutoff);
            })
            ->orderBy('last_login_at')
            ->get(['id', 'name', 'email', 'last_login_at'])
            ->map(function (AdminUser $admin): array {
                return [
                    'id' => $admin->id,
                    'name' => $admin->name,
                    'email' => $admin->email,
                    'last_login_at' => optional($admin->last_login_at)?->toDateTimeString(),
                ];
            })
            ->toArray();

        $adminsTotal = AdminUser::query()->count();
        $adminsActive = AdminUser::query()->where('is_active', true)->count();
        $iamManagers = AdminUser::query()
            ->whereHas('roles', fn ($query) => $query->where('name', 'super_admin')->orWhere('name', 'platform_admin'))
            ->count();
        $definedRoles = Role::query()->where('guard_name', 'admin')->count();

        $this->accessReview = [
            'admins_total' => $adminsTotal,
            'admins_active' => $adminsActive,
            'iam_manager_candidates' => $iamManagers,
            'dormant_active_admins' => count($this->dormantAdmins),
            'defined_roles' => $definedRoles,
            'rotation_runbook' => 'docs/secrets-management.md',
        ];
    }

    public static function canAccess(): bool
    {
        return (bool) Filament::auth()->user()?->can('iam.manage');
    }
}


