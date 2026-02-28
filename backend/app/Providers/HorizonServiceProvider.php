<?php

namespace App\Providers;

use App\Models\AdminUser;
use Illuminate\Support\Facades\Gate;
use Laravel\Horizon\Horizon;
use Laravel\Horizon\HorizonApplicationServiceProvider;

class HorizonServiceProvider extends HorizonApplicationServiceProvider
{
    public function boot(): void
    {
        parent::boot();

        Horizon::auth(function ($request): bool {
            if (app()->environment(['local', 'development', 'testing'])) {
                return true;
            }

            $user = $request->user('admin');

            return $this->canViewHorizon($user);
        });
    }

    protected function gate(): void
    {
        Gate::define('viewHorizon', function ($user = null): bool {
            return $this->canViewHorizon($user);
        });
    }

    private function canViewHorizon(mixed $user): bool
    {
        return $user instanceof AdminUser
            && $user->hasAnyPermission(['queue_ops.view', 'health.view']);
    }
}
