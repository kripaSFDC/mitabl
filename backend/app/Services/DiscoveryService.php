<?php

namespace App\Services;

use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
use App\Models\Foods;
use App\Models\Mikitchn;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DiscoveryService
{
    public function __construct(private DiscoveryCacheService $cache)
    {
    }

    public function recommended(Request $request): array
    {
        $query = $this->buildBaseDiscoveryQuery($request, true, true);
        $start = microtime(true);

        $result = $this->remember('recommended', $request, function () use ($query) {
            $data = $query
                ->having('orders_count', '>', 0)
                ->where('mikitchns.status', 1)
                ->orderByRaw('orders_count DESC, rating_count DESC')
                ->groupBy('mikitchns.id')
                ->get()
                ->makeHidden(['reviews', 'addedimage', 'certificate']);

            $data->each->append('is_favourited');
            return RestaurantResource::collection($data)->resolve();
        });

        $this->logMetrics('recommendedRestaurant', $start, $result['cache_hit']);

        return ['data' => $result['payload']];
    }

    public function nearest(Request $request): array
    {
        if (!$request->has('lat') || !$request->has('lon')) {
            return ['data' => ['total_count' => 0, 'kitchens' => []]];
        }

        $searchQuery = $request->query();
        $limit = max((int) ($searchQuery['limit'] ?? 10), 1);
        $page = max(((int) ($searchQuery['page'] ?? 1)) - 1, 0);
        $maxDistance = $request->input('max_distance', 100);

        $query = $this->buildBaseDiscoveryQuery($request, true, false)
            ->having('distance', '<', $maxDistance)
            ->where('mikitchns.status', 1)
            ->orderBy('distance', 'ASC');

        $start = microtime(true);
        $result = $this->remember('nearest', $request, function () use ($query, $limit, $page) {
            $totalCount = $this->countRows($query);

            $kitchens = $query->offset($page * $limit)
                ->limit($limit)
                ->get()
                ->makeHidden(['reviews', 'addedimage', 'certificate']);

            $kitchens->each->append('is_favourited');

            return [
                'total_count' => $totalCount,
                'kitchens' => RestaurantResource::collection($kitchens)->resolve(),
            ];
        });

        $this->logMetrics('nearestRestaurant', $start, $result['cache_hit']);

        return ['data' => $result['payload']];
    }

    public function topRated(Request $request): array
    {
        $searchQuery = $request->query();
        $limit = max((int) ($searchQuery['limit'] ?? 10), 1);
        $page = max(((int) ($searchQuery['page'] ?? 1)) - 1, 0);

        $query = $this->buildBaseDiscoveryQuery($request, true, true)
            ->where('mikitchns.status', 1)
            ->orderByRaw('rating_count DESC')
            ->groupBy('mikitchns.id');

        $start = microtime(true);
        $result = $this->remember('top-rated', $request, function () use ($query, $limit, $page) {
            $totalCount = $this->countRows($query);

            $data = $query
                ->offset($page * $limit)
                ->limit($limit)
                ->get()
                ->makeHidden(['reviews', 'addedimage', 'certificate']);

            $data->each->append('is_favourited');

            return [
                'total_count' => $totalCount,
                'kitchens' => RestaurantResource::collection($data)->resolve(),
            ];
        });

        $this->logMetrics('topRatedRestaurant', $start, $result['cache_hit']);

        return ['data' => $result['payload']];
    }

    public function filtered(Request $request): array
    {
        $searchQuery = $request->query();
        $limit = max((int) ($searchQuery['limit'] ?? 10), 1);
        $page = max(((int) ($searchQuery['page'] ?? 1)) - 1, 0);

        $query = $this->buildBaseDiscoveryQuery($request, true, false)
            ->where('mikitchns.status', 1);

        if ($request->has('lat') && $request->has('lon')) {
            $query->orderBy('distance', 'ASC');
        } else {
            $query->orderBy('mikitchns.id', 'DESC');
        }

        $start = microtime(true);
        $result = $this->remember('filtered', $request, function () use ($query, $limit, $page) {
            $totalCount = $this->countRows($query);

            $data = $query->offset($page * $limit)
                ->limit($limit)
                ->get()
                ->makeHidden(['reviews', 'addedimage', 'certificate']);

            $data->each->append('is_favourited');

            return [
                'total_count' => $totalCount,
                'kitchens' => RestaurantResource::collection($data)->resolve(),
            ];
        });

        $this->logMetrics('filterRestaurant', $start, $result['cache_hit']);

        return ['data' => $result['payload']];
    }

    private function buildBaseDiscoveryQuery(Request $request, bool $withDistance, bool $withReviews)
    {
        $query = Mikitchn::query();

        if ($withReviews) {
            $query->join('reviews', 'reviews.mikitchn_id', '=', 'mikitchns.id');
        }

        $select = ['mikitchns.*'];

        if ($withReviews) {
            $select[] = DB::raw('AVG(reviews.rating) as rating_count');
        }

        if ($withDistance && $request->has('lat') && $request->has('lon')) {
            $select[] = DB::raw(Mikitchn::closest($request->lat, $request->lon));
        }

        if ($withReviews) {
            $select[] = DB::raw('(SELECT COUNT(b.id) FROM orders as b WHERE mikitchns.id = b.mikitchn_id) as orders_count');
        }

        $query->select($select);

        $this->applyFilters($request, $query);

        return $query;
    }

    private function applyFilters(Request $request, $query): void
    {
        if ($request->has('cooking_styles')) {
            $styles = explode(',', (string) $request->cooking_styles);
            $kitchenIds = Foods::whereIn('cookingstyle', $styles)->pluck('restaurant_id');
            $query->whereIn('mikitchns.id', $kitchenIds);
        }

        if ($request->has('dine_in')) {
            $query->where('mikitchns.dine_in', $request->dine_in);
        }

        if ($request->has('take_away')) {
            $query->where('mikitchns.take_away', $request->take_away);
        }
    }

    private function remember(string $segment, Request $request, callable $callback): array
    {
        $userId = Auth::id();
        $payload = array_merge($request->all(), ['user_id' => $userId]);
        $key = $this->cache->cacheKey($segment, $payload);

        if (Cache::has($key)) {
            $this->cache->incrementMetric('hits');
            return ['payload' => Cache::get($key), 'cache_hit' => true];
        }

        $this->cache->incrementMetric('misses');
        $data = $callback();
        Cache::put($key, $data, now()->addMinutes(3));

        return ['payload' => $data, 'cache_hit' => false];
    }

    private function logMetrics(string $endpoint, float $start, bool $cacheHit): void
    {
        $latencyMs = (int) ((microtime(true) - $start) * 1000);
        $hits = (int) Cache::get('discovery:metrics:hits', 0);
        $misses = (int) Cache::get('discovery:metrics:misses', 0);
        $total = $hits + $misses;
        $hitRatio = $total > 0 ? round($hits / $total, 4) : null;

        Log::info('discovery.api.metrics', [
            'endpoint' => $endpoint,
            'latency_ms' => $latencyMs,
            'cache_hit' => $cacheHit,
            'cache_hits_total' => $hits,
            'cache_misses_total' => $misses,
            'cache_hit_ratio' => $hitRatio,
        ]);
    }

    private function countRows($query): int
    {
        $base = clone $query;

        return DB::query()->fromSub($base->toBase(), 'discovery_rows')->count();
    }
}
