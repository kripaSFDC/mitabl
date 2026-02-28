<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

class DiscoveryCacheService
{
    private const VERSION_KEY = 'discovery:cache:version';

    public function cacheKey(string $segment, array $payload): string
    {
        $version = Cache::get(self::VERSION_KEY, 1);
        ksort($payload);

        return sprintf('discovery:%d:%s:%s', $version, $segment, md5(json_encode($payload)));
    }

    public function invalidateAll(): void
    {
        $current = (int) Cache::get(self::VERSION_KEY, 1);
        Cache::forever(self::VERSION_KEY, $current + 1);
    }

    public function incrementMetric(string $metric): void
    {
        $key = 'discovery:metrics:' . $metric;
        if (!Cache::has($key)) {
            Cache::forever($key, 0);
        }
        Cache::increment($key);
    }
}
