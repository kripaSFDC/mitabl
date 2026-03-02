<?php

namespace App\Services;

use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
use App\Models\Mikitchn;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
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
        $searchQuery = $request->query();
        $limit = min(max((int) ($searchQuery['limit'] ?? 10), 1), 50);
        $page = max(((int) ($searchQuery['page'] ?? 1)) - 1, 0);
        $query = $this->buildBaseDiscoveryQuery($request, true)
            ->where('mikitchns.status', 1)
            ->has('orders')
            ->orderByDesc('orders_count')
            ->orderByDesc('reviews_avg_rating');
        $start = microtime(true);

        $result = $this->remember('recommended', $request, function () use ($query, $limit, $page) {
            $totalCount = $this->countRows($query);
            $data = $query
                ->offset($page * $limit)
                ->limit($limit)
                ->get()
                ->makeHidden(['reviews', 'addedimage', 'certificate']);

            $this->annotateFavorites($data);
            return [
                'total_count' => $totalCount,
                'kitchens' => RestaurantResource::collection($data)->resolve(),
            ];
        });

        $this->logMetrics('recommendedRestaurant', $start, $result['cache_hit']);

        return ['data' => $result['payload']];
    }

    public function nearest(Request $request): array
    {
        if (! $this->hasValidCoordinates($request)) {
            return ['data' => ['total_count' => 0, 'kitchens' => []]];
        }

        $searchQuery = $request->query();
        $limit = min(max((int) ($searchQuery['limit'] ?? 10), 1), 50);
        $page = max(((int) ($searchQuery['page'] ?? 1)) - 1, 0);
        $maxDistance = max((float) $request->input('max_distance', 100), 0.1);

        $query = $this->buildBaseDiscoveryQuery($request, true)
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

            $this->annotateFavorites($kitchens);

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
        $limit = min(max((int) ($searchQuery['limit'] ?? 10), 1), 50);
        $page = max(((int) ($searchQuery['page'] ?? 1)) - 1, 0);

        $query = $this->buildBaseDiscoveryQuery($request, true)
            ->where('mikitchns.status', 1)
            ->orderByDesc('reviews_avg_rating');

        $start = microtime(true);
        $result = $this->remember('top-rated', $request, function () use ($query, $limit, $page) {
            $totalCount = $this->countRows($query);

            $data = $query
                ->offset($page * $limit)
                ->limit($limit)
                ->get()
                ->makeHidden(['reviews', 'addedimage', 'certificate']);

            $this->annotateFavorites($data);

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
        $limit = min(max((int) ($searchQuery['limit'] ?? 10), 1), 50);
        $page = max(((int) ($searchQuery['page'] ?? 1)) - 1, 0);

        $query = $this->buildBaseDiscoveryQuery($request, true)
            ->where('mikitchns.status', 1);

        if ($this->hasValidCoordinates($request)) {
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

            $this->annotateFavorites($data);

            return [
                'total_count' => $totalCount,
                'kitchens' => RestaurantResource::collection($data)->resolve(),
            ];
        });

        $this->logMetrics('filterRestaurant', $start, $result['cache_hit']);

        return ['data' => $result['payload']];
    }

    private function buildBaseDiscoveryQuery(Request $request, bool $withDistance)
    {
        $query = Mikitchn::query()->select(['mikitchns.*']);

        if ($withDistance && $this->hasValidCoordinates($request)) {
            $query->selectRaw(Mikitchn::closest($request->lat, $request->lon));
        }

        $query->with(['addedimage:id,ref_id,model_name,path', 'certificate:id,mikitchn_id,abn,abn_gst,status'])
            ->withAvg('reviews', 'rating')
            ->withCount('orders');

        $this->applyFilters($request, $query);

        return $query;
    }

    private function applyFilters(Request $request, $query): void
    {
        if ($request->has('cooking_styles')) {
            $styles = explode(',', (string) $request->cooking_styles);
            $query->whereExists(function ($subQuery) use ($styles): void {
                $subQuery->selectRaw('1')
                    ->from('foods')
                    ->whereColumn('foods.restaurant_id', 'mikitchns.id')
                    ->whereIn('foods.cookingstyle', $styles);
            });
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
        $havings = $base->getQuery()->havings ?? [];
        if ($havings === []) {
            return (int) $base->toBase()->count();
        }

        return DB::query()->fromSub($base->toBase(), 'discovery_rows')->count();
    }

    private function annotateFavorites(Collection $kitchens): void
    {
        $user = Auth::user();
        if (! $user || $kitchens->isEmpty()) {
            foreach ($kitchens as $kitchen) {
                $kitchen->setAttribute('is_favourited', false);
            }
            return;
        }

        $favoriteIds = Cache::remember(
            'discovery:user:favorites:' . $user->id,
            now()->addMinutes(1),
            fn () => $user->getFavoriteItems(Mikitchn::class)
                ->pluck('id')
                ->map(fn ($id): int => (int) $id)
                ->all()
        );

        $favoriteLookup = array_flip($favoriteIds);
        foreach ($kitchens as $kitchen) {
            $kitchen->setAttribute('is_favourited', isset($favoriteLookup[(int) $kitchen->id]));
        }
    }

    private function hasValidCoordinates(Request $request): bool
    {
        return is_numeric($request->input('lat')) && is_numeric($request->input('lon'));
    }
}
