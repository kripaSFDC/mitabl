<?php

namespace App\Filament\Pages;

use App\Models\AdminUser;
use Filament\Facades\Filament;
use Filament\Pages\Page;
use Illuminate\Database\Eloquent\Builder;
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
            'step_up_reauth_minutes' => (int) config('admin_security.reauth_minutes', 15),
            'dormant_threshold_days' => $dormantThresholdDays,
        ];

        $this->dormantAdmins = AdminUser::query()
            ->where('is_active', true)
            ->whereRaw("(last_login_at IS NULL OR last_login_at < ?)", [$cutoff])
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
            ->whereHas('roles', fn (Builder $query): Builder => $query->where('name', 'super_admin')->orWhere('name', 'platform_admin'))
            ->count();
        $definedRoles = Role::query()->where('guard_name', 'admin')->count();

        $this->accessReview = [
            'admins_total' => $adminsTotal,
            'admins_active' => $adminsActive,
            'iam_manager_candidates' => $iamManagers,
            'dormant_active_admins' => count($this->dormantAdmins),
            'defined_roles' => $definedRoles,
            'rotation_runbook' => 'docs/api-key-secret-rotation-runbook.md',
        ];
    }

    public static function canAccess(): bool
    {
        $user = Filament::auth()->user();

        return (bool) ($user?->can('iam.manage')
            && ($user->hasRole('super_admin') || $user->hasRole('platform_admin')));
    }
}

