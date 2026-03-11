<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
use App\Models\Mikitchn;
use App\Services\DiscoveryService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class DiscoveryController extends Controller
{
    public function __construct(private DiscoveryService $discoveryService)
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
            ->with(['addedimage:id,ref_id,model_name,path', 'certificate:id,mikitchn_id,abn,abn_gst,status', 'weektimings', 'user:id,first_name,last_name,avatar,role_id,description'])
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

        return $this->responser(new RestaurantResource($restaurant), 'restaurant data.');
    }
}
