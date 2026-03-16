<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Foods;
use App\Models\Mikitchn;
use Illuminate\Http\Request;
use Validator;
use Storage,File;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;
use App\Http\Resources\Restaurant\Food as FoodResource;

class FoodsController extends Controller
{
    /**
     * @OA\Get(
     *      path="/api/v1/restaurant/menu/{resturantId}",
     *      operationId="restaurant Menu",
     *      tags={"kitchen"},
     *      summary="Restaurant Menu",
     *      description="Returns Food data",
     *      security={ {"Authorization": {} }},
         * @OA\Parameter(
         *          name="resturantId",
         *          description="Resturant id",
         *          required=true,
         *          in="path",
         *          @OA\Schema(
         *              type="integer"
         *          )
         *      ),
     *     @OA\Response(
    *          response=201,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=200,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=422,
    *          description="Unprocessable Entity",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(response=400, description="Bad request"),
    *      @OA\Response(response=404, description="Resource Not Found"),
     * )
     */
    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    

    public function store(Request $request)
    {
        if ($request->filled('food_id')) {
            return $this->updateFood($request);
        }

        return $this->createFood($request);
    }

    public function createFood(Request $request)
    {
        return $this->saveFood($request, false);
    }

    public function updateFood(Request $request)
    {
        if (! $request->filled('food_id')) {
            return $this->responser([], 'food_id is required for updating food item.', 422);
        }

        return $this->saveFood($request, true);
    }

    private function saveFood(Request $request, bool $isUpdate)
    {
        if ($request->filled('available_days_json')) {
            $decodedAvailableDays = json_decode((string) $request->input('available_days_json'), true);
            if (! is_array($decodedAvailableDays)) {
                return $this->responser([], 'available_days_json must be valid JSON.', 422);
            }

            $request->merge([
                'available_days' => $decodedAvailableDays,
            ]);
        }

        $validator = Validator::make($request->all(), [
            'food_name' => 'required',
            'cookingstyle' => 'required|integer',
            'specialDiet' => 'required|array|min:1',
            'specialDiet.*' => 'required|integer',
            'price' => 'required|numeric|gt:0',
            'dine_in' => 'nullable|integer|in:0,1',
            'take_away' => 'nullable|integer|in:0,1',
            'available_date' => 'nullable|date_format:Y-m-d',
            'available_days' => 'nullable|array',
            'available_days.*' => 'integer|between:0,6',
            'available_days_json' => 'nullable|string',
            'available_from_time' => 'nullable|date_format:H:i|required_with:available_to_time',
            'available_to_time' => 'nullable|date_format:H:i|after:available_from_time|required_with:available_from_time',
        ]);
        // |image|mimes:jpg,png,jpeg,gif,svg
        if($validator->fails()){
            return $this->responser([],$validator->errors()->first(), 422);
            
        }

        $files = $delete_files = [];
        if ($request->hasFile('pictures')) {
            $files = $request->file('pictures');
        }

        if ($request->has('delete_images')) {
            $delete_files = explode(',', $request->delete_images);

        }
        $url = '';
        $errors = $ImgaesKitch = $ImgaesKitchErrors = array();
        $specialdiets = json_encode(array_values(array_map('intval', (array) $request->specialDiet)));

         
         // print_r($specialdiets); 
         // print_r($delete_files); 
         // die();

        $restaurant = Auth::user()->restaurant;

        $kitchnExist = Mikitchn::find($restaurant->id);

        if (!$kitchnExist) {
            return $this->responser([],'Unauthorized kitchen not found.', 403);
            
        }
        $existFood = Foods::where('id',$request->food_id)->where('restaurant_id',$restaurant->id)->first();
        if ($isUpdate && ! $existFood) {
            return $this->responser([], 'Food item not found for this restaurant.', 404);
        }
        $foodId = null;
        $dishDineIn = $request->has('dine_in')
            ? (int) $request->dine_in
            : (int) ($isUpdate ? $existFood?->dine_in : $restaurant->dine_in);
        $dishTakeAway = $request->has('take_away')
            ? (int) $request->take_away
            : (int) ($isUpdate ? $existFood?->take_away : $restaurant->take_away);

        if ($dishDineIn !== 1 && $dishTakeAway !== 1) {
            return $this->responser([], 'At least one of dine_in or take_away must be enabled for a food item.', 422);
        }
        if ($dishDineIn === 1 && (int) $restaurant->dine_in !== 1) {
            return $this->responser([], 'Food item cannot enable dine_in when the kitchen does not support dine-in.', 422);
        }
        if ($dishTakeAway === 1 && (int) $restaurant->take_away !== 1) {
            return $this->responser([], 'Food item cannot enable take_away when the kitchen does not support take-away.', 422);
        }

        $availableDate = $request->filled('available_date')
            ? Carbon::parse((string) $request->input('available_date'))->toDateString()
            : ($request->has('available_date') ? null : $existFood?->available_date?->toDateString());
        $availableDays = $request->has('available_days')
            ? array_values(array_unique(array_map('intval', (array) $request->input('available_days', []))))
            : ($isUpdate ? $existFood?->available_days : null);
        $availableFromTime = $request->filled('available_from_time')
            ? Carbon::parse((string) $request->input('available_from_time'))->format('H:i:s')
            : ($request->has('available_from_time') ? null : $existFood?->available_from_time);
        $availableToTime = $request->filled('available_to_time')
            ? Carbon::parse((string) $request->input('available_to_time'))->format('H:i:s')
            : ($request->has('available_to_time') ? null : $existFood?->available_to_time);

        $requestHasAvailableDate = $request->has('available_date');
        $requestHasAvailableDays = $request->has('available_days') || $request->filled('available_days_json');
        if (
            $requestHasAvailableDate &&
            $requestHasAvailableDays &&
            $availableDate !== null &&
            $availableDays !== null &&
            $availableDays !== []
        ) {
            return $this->responser([], 'Choose either a specific available date or recurring available days for a food item, not both.', 422);
        }

        if ($isUpdate) {
            Foods::where('id',$request->food_id)->where('restaurant_id',$restaurant->id)->update([
                'food_name' => $request->food_name,
                'cookingstyle' => $request->cookingstyle,
                'specialDiet' => $specialdiets,
                'price' => $request->price,
                'description' => $request->description,
                'pictures' => json_encode($ImgaesKitch),
                'dine_in' => $dishDineIn,
                'take_away' => $dishTakeAway,
                'available_date' => $availableDate,
                'available_days' => $availableDays !== null ? json_encode($availableDays) : null,
                'available_from_time' => $availableFromTime,
                'available_to_time' => $availableToTime,
            ]);
            $msg = 'Food item Updated succesfully.';
            $foodId = $request->food_id;

            if (!empty($delete_files)) {
                foreach ($delete_files as $key => $delete_file) {
                    $this->deleteImageById($delete_file,'food');
                }
                            
            }

        } else {
            if (! $request->hasFile('pictures')) {
                return $this->responser([], 'Pictures required.', 422);
            }

            $foodId = Foods::create([
                'restaurant_id' => $restaurant->id,
                'food_name' => $request->food_name,
                'cookingstyle' => $request->cookingstyle,
                'specialDiet' => $specialdiets,
                'price' => $request->price,
                'description' => $request->description,
                'pictures' => json_encode($ImgaesKitch),
                'dine_in' => $dishDineIn,
                'take_away' => $dishTakeAway,
                'available_date' => $availableDate,
                'available_days' => $availableDays !== null ? json_encode($availableDays) : null,
                'available_from_time' => $availableFromTime,
                'available_to_time' => $availableToTime,
            ])->id;

            $msg = 'Food item added succesfully.';
        }

        $food = Foods::query()->find($foodId);
        if (! $food) {
            return $this->responser([], 'Food item not found after save.', 500);
        }

        $data = new FoodResource($food);

        return $this->responser($data, $msg ?? 'Food item saved succesfully.');
    }
}
