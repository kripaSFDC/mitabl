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
    public $data=[];
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
    public function foodOfRestaurant($resturantId){

        $mikitchen = Mikitchn::where('id',$resturantId)->first();
        $data = []; $msg = 'Restaurant Not Found';
        if ($mikitchen) {
            $foods = Foods::where('restaurant_id', $resturantId)->where('status', 1)->orderBy('id', 'desc')->get();

             $data = FoodResource::collection($foods);
             
             $msg = 'Restaurant Menu Foods';
        }
        

        return $this->responser($data, $msg);

    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index($resturantId)
    {
        
    }

    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'food_name' => 'required',
            'cookingstyle' => 'required|integer',
            'specialDiet.*' => 'required',
            'price' => 'required|numeric|gt:0',
            
        ]);
        // |image|mimes:jpg,png,jpeg,gif,svg
        if($validator->fails()){
            return $this->responser($this->data,$validator->errors()->first());
            
        }

        $allowedfileExtension=['jpg','jpeg','png','gif','svg'];
        $files = $delete_files = [];
        if ($request->hasFile('pictures')) {
            $files = $request->file('pictures');
        }

        if ($request->has('delete_images')) {
            $delete_files = explode(',', $request->delete_images);

        }
        $url = '';
        $errors = $ImgaesKitch = $ImgaesKitchErrors = array();
        // print_r($request->specialDiet); 
        $specialdiets = '['.json_encode(implode(',', $request->specialDiet)).']';
        // $specialdiets = implode(',', $request->specialDiet);

         
         // print_r($specialdiets); 
         // print_r($delete_files); 
         // die();

        $restaurant = Auth::user()->restaurant;

        $kitchnExist = Mikitchn::find($restaurant->id);

        if (!$kitchnExist) {
            return $this->responser([],'Unauthorized kitchen not found.');
            
        }
        $existFood = Foods::where('id',$request->food_id)->where('restaurant_id',$restaurant->id)->first();
        // if (!$existFood) {
        //     return $this->responser([],'Unauthorized Food not found for this restaurant.');
        // }
        $foodId = null;
        if ($existFood && !empty($request->food_id)) {
            Foods::where('id',$request->food_id)->where('restaurant_id',$restaurant->id)->update([
                'food_name' => $request->food_name,
                'cookingstyle' => $request->cookingstyle,
                'specialDiet' => $specialdiets,
                'price' => $request->price,
                'description' => $request->description,
                'pictures' => json_encode($ImgaesKitch),
            ]);
            $msg = 'Food item Updated succesfully.';
            $foodId = $request->food_id;

            if (!empty($delete_files)) {
                foreach ($delete_files as $key => $delete_file) {
                    $this->deleteImageById($delete_file,'food');
                }
                            
            }

        } else {
            if (!$request->hasFile('pictures')) {
                return $this->responser($this->data,'Pictures required.');
            }
            $foodId = Foods::create([
                'restaurant_id' => $restaurant->id,
                'food_name' => $request->food_name,
                'cookingstyle' => $request->cookingstyle,
                'specialDiet' => $specialdiets,
                'price' => $request->price,
                'description' => $request->description,
                'pictures' => json_encode($ImgaesKitch),
            ])->id;
            $msg = 'Food item created succesfully.';
        }
        $food = Foods::where('id',$foodId)->get()->first()->makeHidden(['addedimage']);
        if (!empty($files)) {

            $addedImages = $this->addImages($files,'kitchen/food','food',$foodId);

        }
        $return = [
            'isSuccess' => true,
            'status' => 200,
            'message' => $msg,
            'data' => $food
        ];

        if (!empty($ImgaesKitchErrors)) {
            $return['isError'] = $ImgaesKitchErrors;
        }


        return response()->json($return, 200);
    }

    /**
     * @OA\Get(
     *      path="/api/v1/food/status/{id}",
     *      operationId="change food item status",
     *      tags={"kitchen"},
     *      summary="change food item status",
     *      description="Returns Food data",
     *      security={ {"Authorization": {} }},
         * @OA\Parameter(
         *          name="id",
         *          description="Food id",
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
    public function statusUpdate($id)
    {
        $data = [];
        if(Foods::find($id)){
            $staus = 1;
            $fExist = Foods::where('id',$id)->where('status',1)->first();
            if ($fExist) {
              $staus = 0;  
            }
            Foods::where('id',$id)->update(['status' => $staus]);
            // $food = Foods::where('id',$id)->get()->first();
            $food = Foods::where('id',$id)->get();
            $data = $food[0];
            $msg = 'Food Status Updated Succesfully.'; 

        } else {
            $msg = 'Food Not Found.'; 
        }

        return $this->responser($data,$msg);

    }
    
    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Foods  $foods
     * @return \Illuminate\Http\Response
     */
    public function show(Foods $foods)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \App\Models\Foods  $foods
     * @return \Illuminate\Http\Response
     */
    public function edit(Foods $foods)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Foods  $foods
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Foods $foods)
    {
        return $this->responser([], 'Not implemented.');
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Foods  $foods
     * @return \Illuminate\Http\Response
     */
    public function destroy(Foods $foods,$id)
    {

        $food=Foods::find($id);
        if($food){
            // delete related   
            $images = $food->addedimage->pluck('path')->toArray();
            if(!empty($images)) {
                $food->addedimage()->delete();
                File::delete($images);

            }
            $food->delete();
            $data = new FoodResource($food);
            return $this->responser($data,"Food item deleted succesfully.");
        }
        return $this->responser([],"Food item not exist.");
    }
}
