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
        $user = Auth::guard('api')->user();
        $favorites = $user->getFavoriteItems(Mikitchn::class);

        $this->data['total_count'] = $favorites->count();

        $data = $favorites->paginate($queryparams['limit'])->makeHidden(['reviews','addedimage']);
        
        $this->data['favorites'] = RestaurantResource::collection($data);

        return $this->responser($this->data,"favorites List.");

    }
}
