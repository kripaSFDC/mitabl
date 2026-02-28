<?php

namespace App\Observers;

use App\Models\Certificate;
use App\Services\KitchenService;

class CertificateObserver
{
    public function created(Certificate $certificate): void
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }

    public function updated(Certificate $certificate): void
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }

    public function deleted(Certificate $certificate): void
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }
}
