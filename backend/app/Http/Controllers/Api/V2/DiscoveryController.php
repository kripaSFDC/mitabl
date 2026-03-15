<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
use App\Http\Resources\Restaurant\DineInSlot as DineInSlotResource;
use App\Models\Mikitchn;
use App\Services\DineInSlotService;
use App\Services\DiscoveryService;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class DiscoveryController extends Controller
{
    public function __construct(
        private DiscoveryService $discoveryService,
        private DineInSlotService $dineInSlotService
    )
    {
    }

    public function filtered(Request $request)
    {
        $data = $this->discoveryService->filtered($request)['data'];
        return $this->responser($data, 'restaurants filtered.');
    }

    public function nearest(Request $request)
    {
        $data = $this->discoveryService->nearest($request)['data'];
        return $this->responser($data,'Nearest Restaurants');
    }

    public function topRated(Request $request)
    {
        $data = $this->discoveryService->topRated($request)['data'];
        return $this->responser($data,'restaurants by rating');
    }

    public function recommended(Request $request)
    {
        $data = $this->discoveryService->recommended($request)['data'];
        return $this->responser($data,'restaurants by recommeded.');
    }

    public function show(Request $request, int $id)
    {
        if ($response = $this->validateDiscoveryQuery($request, false)) {
            return $response;
        }

        $query = Mikitchn::query();
        $latInput = $request->query('lat');
        $lonInput = $request->query('lon');
        if (is_numeric($latInput) && is_numeric($lonInput)) {
            $lat = (float) $latInput;
            $lon = (float) $lonInput;
            if ($lat >= -90.0 && $lat <= 90.0 && $lon >= -180.0 && $lon <= 180.0) {
                $closest = Mikitchn::closest($lat, $lon);
                $query->select('mikitchns.*', DB::raw($closest));
            }
        }

        $restaurant = $query
            ->with([
                'addedimage:id,ref_id,model_name,path',
                'certificate:id,mikitchn_id,abn,abn_gst,status',
                'weektimings',
                'dineInSlots',
                'user:id,first_name,last_name,avatar,role_id,description',
                'foods' => function ($foodQuery) use ($request): void {
                    $foodQuery->active()
                        ->availableForOrderType(
                            $request->has('dine_in') ? (int) $request->query('dine_in') : null,
                            $request->has('take_away') ? (int) $request->query('take_away') : null
                        )
                        ->with('addedimage:id,ref_id,model_name,path')
                        ->orderBy('food_name');
                },
            ])
            ->withAvg('reviews', 'rating')
            ->find($id);

        if (! $restaurant) {
            return $this->responser([], 'restaurant not found.', 404);
        }

        $cook = $restaurant->user;
        if ($cook) {
            $restaurant['cock'] = [
                'id' => $cook->id,
                'name' => trim($cook->first_name . ' ' . $cook->last_name),
                'avatar' => $cook->avatar,
                'role_id' => $cook->role_id,
                'description' => $cook->description,
            ];
        }

        $restaurant['gst'] = [
            'gst_enable' => optional($restaurant->certificate)->abn_gst,
            'gst_amount' => 10,
        ];

        $restaurant->setAttribute(
            'is_favourited',
            Auth::guard('api')->check() ? Auth::guard('api')->user()->hasFavorited($restaurant) : false
        );
        if ($restaurant->relationLoaded('foods')) {
            $restaurant->setRelation('foods', collect($restaurant->foods)->filter(function ($food) use ($request) {
                if (! $request->filled('delivery_date')) {
                    return true;
                }

                return $food->isScheduledFor(
                    Carbon::parse((string) $request->query('delivery_date'))->startOfDay(),
                    $request->query('delivery_time_from'),
                    $request->query('delivery_time_to')
                );
            })->values());
        }

        return $this->responser(new RestaurantResource($restaurant), 'restaurant data.');
    }

    public function menu(Request $request, int $id)
    {
        if ($response = $this->validateDiscoveryQuery($request, false)) {
            return $response;
        }

        if (! Mikitchn::query()->whereKey($id)->where('status', 1)->exists()) {
            return $this->responser([], 'restaurant not found.', 404);
        }

        $data = $this->discoveryService->menu($request, $id)['data'];

        return $this->responser($data, 'restaurant menu.');
    }

    public function dineInSlots(Request $request, int $id)
    {
        $validator = Validator::make($request->query(), [
            'date' => ['required', 'date_format:Y-m-d', 'after_or_equal:today'],
            'persons' => ['nullable', 'integer', 'min:1'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $restaurant = Mikitchn::query()
            ->whereKey($id)
            ->where('status', 1)
            ->where('dine_in', 1)
            ->first();

        if (! $restaurant) {
            return $this->responser([], 'restaurant not found.', 404);
        }

        $slots = $this->dineInSlotService->getAvailabilityForDate(
            $restaurant,
            Carbon::parse((string) $request->query('date')),
            $request->filled('persons') ? (int) $request->query('persons') : null
        );

        return $this->responser(DineInSlotResource::collection($slots), 'restaurant dine-in slots.');
    }

    public function search(Request $request)
    {
        if ($response = $this->validateDiscoveryQuery($request, true)) {
            return $response;
        }

        $data = $this->discoveryService->search($request)['data'];

        return $this->responser($data, 'restaurants search results.');
    }

    private function validateDiscoveryQuery(Request $request, bool $includeSearchTerm)
    {
        $rules = [
            'dine_in' => ['nullable', 'integer', 'in:0,1'],
            'take_away' => ['nullable', 'integer', 'in:0,1'],
            'lat' => ['nullable', 'numeric', 'between:-90,90', 'required_with:lon'],
            'lon' => ['nullable', 'numeric', 'between:-180,180', 'required_with:lat'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:50'],
            'page' => ['nullable', 'integer', 'min:1'],
            'delivery_date' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:today'],
            'delivery_time_from' => ['nullable', 'date_format:H:i', 'required_with:delivery_time_to'],
            'delivery_time_to' => ['nullable', 'date_format:H:i', 'after:delivery_time_from', 'required_with:delivery_time_from'],
        ];

        if ($includeSearchTerm) {
            $rules['q'] = ['nullable', 'string', 'max:255'];
        }

        $validator = Validator::make($request->query(), $rules);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        return null;
    }
}
