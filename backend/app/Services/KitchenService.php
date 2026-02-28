<?php

namespace App\Services;

class KitchenService
{
    public function __construct(private DiscoveryCacheService $discoveryCache)
    {
    }

    public function invalidateDiscoveryCaches(): void
    {
        $this->discoveryCache->invalidateAll();
    }
}
