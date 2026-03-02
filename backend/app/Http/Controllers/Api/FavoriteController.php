<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Mikitchn;
use App\Models\User;
use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
use App\Http\Resources\User\Favorite as FavoriteResource;
use Auth;

class FavoriteController extends Controller
{
    public $data = [];

    public function toggleFavorite(Request $request){
        $user = Auth::guard('api')->user();
        $kitchen = Mikitchn::find($request->restaurant_id);
        if (! $kitchen) {
            return $this->responser([], 'Restaurant not found.', 404);
        }
        $favorite='';
        $user->toggleFavorite($kitchen);
        if ($user->hasFavorited($kitchen)) {
            $favorite = 1;
        }else{
            $favorite = 0;
        }

        $return = [
            'status' => 200,
            'isSuccess' => true,
            'message' => 'Success.',  
            'data' => ['favorite'=> $favorite]
        ];

        return response()->json($return, 200);


    }

    public function getFavoritesList(Request $request)
    {
        $queryparams = $request->query();
        $limit = max((int) ($queryparams['limit'] ?? 10), 1);
        $user = Auth::guard('api')->user();
        $favorites = $user->getFavoriteItems(Mikitchn::class);

        $this->data['total_count'] = $favorites->count();

        $data = $favorites
            ->with(['addedimage:id,ref_id,model_name,path', 'certificate:id,mikitchn_id,abn,abn_gst,status'])
            ->withAvg('reviews', 'rating')
            ->paginate($limit)
            ->makeHidden(['reviews','addedimage']);
        
        $this->data['favorites'] = RestaurantResource::collection($data);

        return $this->responser($this->data,"favorites List.");

    }
}
