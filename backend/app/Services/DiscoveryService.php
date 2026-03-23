<?php

namespace App\Services;

use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
use App\Http\Resources\Restaurant\Food as FoodResource;
use App\Models\Foods;
use App\Models\Mikitchn;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Database\QueryException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Str;

class DiscoveryService
{
    public function __construct(private DiscoveryCacheService $cache)
    {
    }

    public function recommended(Request $request): array
    {
        $searchQuery = $request->query();
        $limit = min(max((int) ($searchQuery['limit'] ?? 10), 1), 50);
        $page = max((int) ($searchQuery['page'] ?? 1), 1);
        $query = $this->buildBaseDiscoveryQuery($request, true)
            ->where('mikitchns.status', 1)
            ->has('orders')
            ->orderByDesc('orders_count')
            ->orderByDesc('reviews_avg_rating');
        $start = microtime(true);

        $result = $this->remember('recommended', $request, function () use ($query, $limit, $page) {
            [$data, $totalCount] = $this->executePagedQuery($query, $limit, $page);
            $data = $data->makeHidden(['reviews', 'addedimage', 'certificate']);

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
        $page = max((int) ($searchQuery['page'] ?? 1), 1);
        $maxDistance = max((float) $request->input('max_distance', 100), 0.1);

        $query = $this->buildBaseDiscoveryQuery($request, true)
            ->having('distance', '<', $maxDistance)
            ->where('mikitchns.status', 1)
            ->orderBy('distance', 'ASC');

        $start = microtime(true);
        $result = $this->remember('nearest', $request, function () use ($query, $limit, $page) {
            [$kitchens, $totalCount] = $this->executePagedQuery($query, $limit, $page);
            $kitchens = $kitchens->makeHidden(['reviews', 'addedimage', 'certificate']);

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
        $page = max((int) ($searchQuery['page'] ?? 1), 1);

        $query = $this->buildBaseDiscoveryQuery($request, true)
            ->where('mikitchns.status', 1)
            ->orderByDesc('reviews_avg_rating');

        $start = microtime(true);
        $result = $this->remember('top-rated', $request, function () use ($query, $limit, $page) {
            [$data, $totalCount] = $this->executePagedQuery($query, $limit, $page);
            $data = $data->makeHidden(['reviews', 'addedimage', 'certificate']);

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
        $page = max((int) ($searchQuery['page'] ?? 1), 1);

        $query = $this->buildBaseDiscoveryQuery($request, true)
            ->where('mikitchns.status', 1);

        if ($this->hasValidCoordinates($request)) {
            $query->orderBy('distance', 'ASC');
        } else {
            $query->orderBy('mikitchns.id', 'DESC');
        }

        $start = microtime(true);
        $result = $this->remember('filtered', $request, function () use ($query, $limit, $page) {
            [$data, $totalCount] = $this->executePagedQuery($query, $limit, $page);
            $data = $data->makeHidden(['reviews', 'addedimage', 'certificate']);

            $this->annotateFavorites($data);

            return [
                'total_count' => $totalCount,
                'kitchens' => RestaurantResource::collection($data)->resolve(),
            ];
        });

        $this->logMetrics('filterRestaurant', $start, $result['cache_hit']);

        return ['data' => $result['payload']];
    }

    public function menu(Request $request, int $restaurantId): array
    {
        $foods = Foods::query()
            ->with('addedimage:id,ref_id,model_name,path')
            ->forRestaurant($restaurantId)
            ->active();

        $this->applyFoodAvailabilityFilters($request, $foods);

        $foodCollection = $foods->orderBy('food_name')->get();
        $foodCollection = $this->filterScheduledFoods($foodCollection, $request);

        return [
            'data' => FoodResource::collection($foodCollection)->resolve(),
        ];
    }

    public function search(Request $request): array
    {
        $term = trim((string) $request->query('q', ''));
        if ($term === '') {
            return ['data' => ['total_count' => 0, 'kitchens' => []]];
        }

        $limit = min(max((int) ($request->query('limit', 10)), 1), 50);
        $page = max((int) ($request->query('page', 1)), 1);
        $likeTerm = '%' . $term . '%';
        $dineIn = $request->has('dine_in') ? (int) $request->query('dine_in') : null;
        $takeAway = $request->has('take_away') ? (int) $request->query('take_away') : null;

        $query = $this->buildBaseDiscoveryQuery($request, true)
            ->where('mikitchns.status', 1)
            ->where(function ($subQuery) use ($likeTerm, $dineIn, $takeAway): void {
                $subQuery->where('mikitchns.name', 'like', $likeTerm)
                    ->orWhere('mikitchns.description', 'like', $likeTerm)
                    ->orWhereExists(function ($foodQuery) use ($likeTerm, $dineIn, $takeAway): void {
                        $foodQuery->selectRaw('1')
                            ->from('foods')
                            ->whereColumn('foods.restaurant_id', 'mikitchns.id')
                            ->where('foods.status', 1)
                            ->when($dineIn !== null, fn ($innerQuery) => $innerQuery->where('foods.dine_in', $dineIn))
                            ->when($takeAway !== null, fn ($innerQuery) => $innerQuery->where('foods.take_away', $takeAway))
                            ->where(function ($matchQuery) use ($likeTerm): void {
                                $matchQuery->where('foods.food_name', 'like', $likeTerm)
                                    ->orWhere('foods.description', 'like', $likeTerm);
                            });
                    });
            });

        if ($this->hasValidCoordinates($request)) {
            $query->orderBy('distance', 'ASC');
        } else {
            $query->orderByDesc('reviews_avg_rating')
                ->orderBy('mikitchns.name');
        }

        $start = microtime(true);
        $result = $this->remember('search', $request, function () use ($query, $limit, $page, $term, $dineIn, $takeAway, $request) {
            if ($request->filled('delivery_date')) {
                $allMatchingKitchens = $query->get();
                $allMatchingKitchens->load([
                    'foods' => function ($foodQuery) use ($term, $dineIn, $takeAway): void {
                        $foodQuery->active()
                            ->searchTerm($term)
                            ->availableForOrderType($dineIn, $takeAway)
                            ->with('addedimage:id,ref_id,model_name,path')
                            ->orderBy('food_name');
                    },
                ]);

                $this->applyScheduledFoodFilteringToKitchens($allMatchingKitchens, $request);
                return $this->buildFilteredSearchPayload($allMatchingKitchens, $limit, $page, $term);
            }

            $allMatchingKitchens = $query->get();
            $allMatchingKitchens->load([
                'foods' => function ($foodQuery) use ($term, $dineIn, $takeAway): void {
                    $foodQuery->active()
                        ->searchTerm($term)
                        ->availableForOrderType($dineIn, $takeAway)
                        ->with('addedimage:id,ref_id,model_name,path')
                        ->orderBy('food_name');
                },
            ]);

            $this->applyScheduledFoodFilteringToKitchens($allMatchingKitchens, $request);

            return $this->buildFilteredSearchPayload($allMatchingKitchens, $limit, $page, $term);
        });

        $this->logMetrics('searchRestaurant', $start, $result['cache_hit']);

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

        $specialDiets = $request->input('special_diets');
        if (!empty($specialDiets)) {
            $dietIds = array_filter(array_map('intval', explode(',', $specialDiets)));
            if (!empty($dietIds)) {
                $query->whereHas('foods', function ($foodQuery) use ($dietIds) {
                    $foodQuery->where('status', 1);
                    foreach ($dietIds as $dietId) {
                        $foodQuery->whereJsonContains('specialDiet', $dietId);
                    }
                });
            }
        }

        if ($request->has('dine_in')) {
            $query->where('mikitchns.dine_in', $request->dine_in);
        }

        if ($request->has('take_away')) {
            $query->where('mikitchns.take_away', $request->take_away);
        }
    }

    private function applyFoodAvailabilityFilters(Request $request, $query): void
    {
        $dineIn = $request->has('dine_in') ? (int) $request->query('dine_in') : null;
        $takeAway = $request->has('take_away') ? (int) $request->query('take_away') : null;

        $query->availableForOrderType($dineIn, $takeAway);
    }

    private function applyScheduledFoodFilteringToKitchens(Collection $kitchens, Request $request): void
    {
        foreach ($kitchens as $kitchen) {
            if (! $kitchen->relationLoaded('foods')) {
                continue;
            }

            $kitchen->setRelation('foods', $this->filterScheduledFoods($kitchen->foods, $request));
        }
    }

    private function filterScheduledFoods(Collection $foods, Request $request): Collection
    {
        if (! $request->filled('delivery_date')) {
            return $foods->values();
        }

        $deliveryDate = Carbon::parse((string) $request->query('delivery_date'))->startOfDay();
        $deliveryTimeFrom = $request->query('delivery_time_from');
        $deliveryTimeTo = $request->query('delivery_time_to');

        return $foods
            ->filter(fn (Foods $food): bool => $food->isScheduledFor($deliveryDate, $deliveryTimeFrom, $deliveryTimeTo))
            ->values();
    }

    private function buildFilteredSearchPayload(Collection $kitchens, int $limit, int $page, string $term): array
    {
        $filteredKitchens = $kitchens
            ->filter(fn ($kitchen) => $this->kitchenMatchesSearchTerm($kitchen, $term) || $kitchen->foods->isNotEmpty())
            ->values();

        $totalCount = $filteredKitchens->count();
        $paginator = new LengthAwarePaginator(
            $filteredKitchens->slice(($page - 1) * $limit, $limit)->values(),
            $totalCount,
            $limit,
            $page,
            ['path' => LengthAwarePaginator::resolveCurrentPath()]
        );

        $pagedKitchens = collect($paginator->items())->each(function ($kitchen): void {
            $kitchen->makeHidden(['reviews', 'addedimage', 'certificate']);
        });

        $this->annotateFavorites($pagedKitchens);

        return [
            'total_count' => $totalCount,
            'kitchens' => RestaurantResource::collection($pagedKitchens)->resolve(),
        ];
    }

    private function kitchenMatchesSearchTerm($kitchen, string $term): bool
    {
        $normalizedTerm = Str::lower(trim($term));
        if ($normalizedTerm === '') {
            return false;
        }

        return Str::contains(Str::lower((string) ($kitchen->name ?? '')), $normalizedTerm)
            || Str::contains(Str::lower((string) ($kitchen->description ?? '')), $normalizedTerm);
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

    private function executePagedQuery($query, int $limit, int $page): array
    {
        $paged = clone $query;

        try {
            $rows = $paged
                ->forPage($page, $limit)
                ->selectRaw('COUNT(*) OVER() AS total_rows_window')
                ->get();

            $totalCount = (int) ($rows->first()->total_rows_window ?? 0);
            foreach ($rows as $row) {
                unset($row->total_rows_window);
            }

            return [$rows, $totalCount];
        } catch (QueryException $exception) {
            report($exception);
        }

        $fallbackTotal = $this->countRows($query);
        $fallbackRows = (clone $query)
            ->forPage($page, $limit)
            ->get();

        return [$fallbackRows, $fallbackTotal];
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
        $latInput = $request->input('lat');
        $lonInput = $request->input('lon');

        if (! is_numeric($latInput) || ! is_numeric($lonInput)) {
            return false;
        }

        $lat = (float) $latInput;
        $lon = (float) $lonInput;

        if (! is_finite($lat) || ! is_finite($lon)) {
            return false;
        }

        return $lat >= -90.0 && $lat <= 90.0
            && $lon >= -180.0 && $lon <= 180.0;
    }
}
