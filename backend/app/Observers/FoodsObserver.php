<?php

namespace App\Observers;

use App\Models\Foods;
use App\Services\KitchenService;

class FoodsObserver
{
    public function created(Foods $foods): void
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }

    public function updated(Foods $foods): void
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }

    public function deleted(Foods $foods): void
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }
}
