<?php

namespace App\Http\Controllers\Api;

use Illuminate\Support\Facades\Http;
use App\Models\Mikitchn;
use App\Models\User;
use App\Models\Review;
use App\Models\Foods;
use App\Models\Order;
use App\Models\Timing;
use App\Models\Image;
use App\Models\Certificate;
use App\Models\Partner;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Validator,DB,Auth;
use Storage,File;
use Carbon\Carbon;
use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
// use App\Http\Resources\Order\Order as OrderResource;
use App\Http\Resources\Restaurant\Food as FoodResource;
use App\Http\Resources\User\User as UserResource;
use App\Traits\StripeTrait;
use App\Traits\GoogleAddress;
use App\Events\KitchenVerified;

class MikitchnController extends Controller
{
    use StripeTrait,GoogleAddress;
    public $data=[];

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */


    public function recommendedRestaurant(Request $request)
    {
        $restaurant = (new Mikitchn)->newQuery(); 
        $queryparams = $request->query();

        $restaurant = $restaurant->join('reviews', 'reviews.mikitchn_id', '=', 'mikitchns.id');

        if($request->has('lat') && $request->has('lon')){
            $closest = Mikitchn::closest($request->lat, $request->lon);
            $restaurant = $restaurant->select('mikitchns.*',
                        DB::raw('AVG(reviews.rating) as rating_count'),
                        DB::raw('(SELECT COUNT(b.id) FROM orders as b WHERE mikitchns.id = b.mikitchn_id) as orders_count'),
                        DB::raw("{$closest}")
                        ); 

        }else{
            $restaurant = $restaurant->select('mikitchns.*',
                        DB::raw('AVG(reviews.rating) as rating_count'),
                        DB::raw('(SELECT COUNT(b.id) FROM orders as b WHERE mikitchns.id = b.mikitchn_id) as orders_count')
                        );
        }
        
                
            $restaurant->having( 'orders_count', '>', 0 )
                ->where('mikitchns.status',1)
                ->orderByRaw("orders_count DESC, rating_count DESC")
                ->groupBy('mikitchns.id');

        if($request->has('cooking_styles')){
            $cStylesAry = explode(',', $request->cooking_styles);
            $kitchenIds = Foods::whereIn('cookingstyle',$cStylesAry)
                            ->get()->pluck('restaurant_id');
            $restaurant->whereIn('mikitchns.id',$kitchenIds);
            // print_r($kitchenIds); die();
        }
        // if($request->has('dine_in') && $request->dine_in != 0){
        if($request->has('dine_in')){
            $restaurant->where('mikitchns.dine_in',$request->dine_in);
        }

        // if($request->has('take_away') && $request->take_away != 0){
        if($request->has('take_away')){
            $restaurant->where('mikitchns.take_away',$request->take_away);
        }

        // $this->data['total_count'] = $restaurant->count();

        $data = $restaurant
                ->get()
                // ->paginate($queryparams['limit'])
                ->makeHidden(['reviews','addedimage','certificate']);
        // echo $data->toSql(); die();
        $data->each->append(
            'is_favourited'
        );
        $this->data = RestaurantResource::collection($data);

        return $this->responser($this->data,'restaurants by recommeded.');

    }

    public function nearestRestaurant(Request $request)
    {
        $restaurant = (new Mikitchn)->newQuery(); 

        $searchQuerey = $request->query();
        $page = 0;
        if($searchQuerey['page']) { $page = (int) $searchQuerey['page'] - 1; }

        $latitude = $request->input('lat');
        $longitude = $request->input('lon');
        $max_distance = $request->input('max_distance');

        if($request->has('lat') && $request->has('lon')){

            
            $closest = Mikitchn::closest($latitude, $longitude);
                                                       
            
        }
        $restaurant->select('mikitchns.*',
                        DB::raw("{$closest}")
                        );

        if($request->has('cooking_styles')){
            $cStylesAry = explode(',', $request->cooking_styles);
            $kitchenIds = Foods::whereIn('cookingstyle',$cStylesAry)
                            ->get()->pluck('restaurant_id');
            $restaurant->whereIn('id',$kitchenIds);
            // print_r($kitchenIds); die();
        }
        // if($request->has('dine_in') && $request->dine_in != 0){
        if($request->has('dine_in')){
            $restaurant->where('dine_in',$request->dine_in);
        }

        // if($request->has('take_away') && $request->take_away != 0){
        if($request->has('take_away')){
            $restaurant->where('take_away',$request->take_away);
        }

        $restaurant = $restaurant->having('distance', '<', $max_distance)
                        ->where('mikitchns.status',1)
                        ->orderBy( 'distance', 'ASC' );

        $this->data['total_count'] = $restaurant->get()->count();
                        // die();
        $restaurant->offset($page*$searchQuerey['limit'])
                    ->limit($searchQuerey['limit']);

        // echo $restaurant->toSql(); die;

        $restaurant = $restaurant->get()->makeHidden(['reviews','addedimage','certificate']);

        // print_r($data); die();
        $restaurant->each->append(
            'is_favourited'
        );
        $this->data['kitchens'] = RestaurantResource::collection($restaurant);

        return $this->responser($this->data,'Nearest Restaurants');
    }


    public function topRatedRestaurant(Request $request)
    {
       
        $restaurant = (new Mikitchn)->newQuery(); 
        $searchQuerey = $request->query();
        $page = 0;
        if($searchQuerey['page']) { $page = (int) $searchQuerey['page'] - 1; }

        $restaurant = $restaurant->join('reviews', 'reviews.mikitchn_id', '=', 'mikitchns.id');

        if($request->has('lat') && $request->has('lon')){
            $closest = Mikitchn::closest($request->lat, $request->lon);
            $restaurant = $restaurant->select('mikitchns.*',
                            DB::raw('AVG(reviews.rating) as rating_count'),
                            DB::raw("{$closest}")
                            ); 
        }else{
            $restaurant = $restaurant->select('mikitchns.*',
                            DB::raw('AVG(reviews.rating) as rating_count'),
                            );
        }

        if($request->has('cooking_styles')){
            $cStylesAry = explode(',', $request->cooking_styles);
            $kitchenIds = Foods::whereIn('cookingstyle',$cStylesAry)
                            ->get()->pluck('restaurant_id');
            $restaurant->whereIn('mikitchns.id',$kitchenIds);
            // print_r($kitchenIds); die();
        }
        // if($request->has('dine_in') && $request->dine_in != 0){
        if($request->has('dine_in')){
            $restaurant->where('mikitchns.dine_in',$request->dine_in);
        }

        // if($request->has('take_away') && $request->take_away != 0){
        if($request->has('take_away')){
            $restaurant->where('mikitchns.take_away',$request->take_away);
        }

        // $restaurant = $restaurant->having( 'distance', '<', $max_distance )
        //                         ->where('mikitchns.status',1)
        //                         ->orderByRaw("distance , rating_count DESC")
        //                         ->groupBy('mikitchns.id')
        //                         ->offset($page*$searchQuerey['limit'])
        //                         ->limit($searchQuerey['limit'])
        //                         ->get()->makeHidden(['reviews','addedimage']);
        // echo $restaurant->where('mikitchns.status',1)->orderByRaw("rating_count DESC")->groupBy('mikitchns.id')->count();
        // die();
        $restaurant = $restaurant->where('mikitchns.status',1)
                                ->orderByRaw("rating_count DESC")
                                ->groupBy('mikitchns.id');

        $this->data['total_count'] = $restaurant->get()->count();

        $data = $restaurant->offset($page*$searchQuerey['limit'])
                                ->limit($searchQuerey['limit'])
                                ->get()->makeHidden(['reviews','addedimage','certificate']);
        $data->each->append(
            'is_favourited'
        );
        $this->data['kitchens'] = RestaurantResource::collection($data);

        return $this->responser($this->data,'restaurants by rating');
    }

    public function index()
    {
        //
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
    /**
    * @OA\Post(
    * path="/api/v1/mikitchn/store",
    * summary="Register kitchen",
    * description="kitchen Registration",
    * operationId="kitchen-register",
    * tags={"kitchen"},
    * security={{"Authorization":{}}},
    * @OA\RequestBody(
    *         @OA\MediaType(
    *            mediaType="multipart/form-data",
    *           @OA\Schema(
    *               type="object",
    *               required={"images"}, 
    *               @OA\Property(
    *                  property="images",
    *                  type="array",
    *                  @OA\Items(
    *                       type="file",
    *                       format="binary",
    *                       collectionFormat="multi",
    *                  ),
    *               ),
    *           ),
    *        ),
    *        @OA\MediaType(
    *            mediaType="application/json",
    *            @OA\Schema(
    *               type="object",
    *               required={"images"},
    *               @OA\Property(property="images", type="file"),
    *            ),
    *        ),
    *    ),
    *      @OA\Response(
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
    public function store(Request $request)
    {
        $user = Auth::user();
        $userKitchen = $user->restaurant;
        if ($userKitchen) {
            $user = $userKitchen;
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required',
            'address' => 'required',
            'no_of_seats' => 'required|integer',
            'timings' => 'required',
            'phone' => 'required|string',
            // 'lat' => 'required|numeric|unique:mikitchns,latitude,'.$user->id,
            // 'lng' => 'required|numeric|unique:mikitchns,longitude,'.$user->id,
        ]
        // ,[
        //     'lat.unique'=> 'Address already taken', // custom message
        //     'lng.unique'=> 'Address already taken'
        //    ]
       );
        // |image|mimes:jpg,png,jpeg,gif,svg
        
        if($validator->fails()){
            return $this->responser($this->data,$validator->errors()->first());
        }
        // print_r(Auth::user()->restaurant->id);
        $timings = json_decode($request->timings)->days;

        $allowedfileExtension=['jpg','jpeg','png','gif','svg'];
        $files = $delete_files = [];
        if ($request->hasFile('images')) {
            $files = $request->file('images');
        }

        if ($request->has('delete_images')) {
            $delete_files = explode(',', $request->delete_images);
        }
    
        $ImgaesKitch = array();
        
        $user = Auth::user();
        $userExist = User::find($user->id);
        if (!$userExist) {
            return $this->responser([],'Unauthorized user not found.');
        }
        
        $existKitchen = Mikitchn::where('user_id',$user->id)->first();


        if ($existKitchen) {
            $mikitchn = Mikitchn::where('user_id',$user->id)->update(['name' => $request->name,
                'address' => $request->address,
                'no_of_seats' => $request->no_of_seats,
                'timings' => $request->timings,
                'phone' => $request->phone,
                'dine_in' => $request->dine_in,
                'take_away' => $request->take_away,
                'description' => $request->description,
                'latitude' => $request->lat,
                'longitude' => $request->lng,
            ]);

            foreach ($timings as $key1 => $timing) {

                $fromTime = Carbon::parse($timing->timing->start_time)->format('H:i:s');
                $toTime = Carbon::parse($timing->timing->end_time)->format('H:i:s');

                switch ($timing->day) {
                    case 'Mon':
                        $day = 'Monday';
                        break;
                    case 'Tue':
                        $day = 'Tuesday';
                        break;
                    case 'Wed':
                        $day = 'Wednesday';
                        break;
                    case 'Thus':
                        $day = 'Thursday';
                        break;
                    case 'Fri':
                        $day = 'Friday';
                        break;
                    case 'Sat':
                        $day = 'Saturday';
                        break;
                    case 'Sun':
                        $day = 'Sunday';
                        break;
                    
                    default:
                        $day = 'Monday';
                        break;
                }

                $Timing = Timing::where('mikitchn_id',Auth::user()->restaurant->id)->where('day',$day)->update(['status' => $timing->isOn, 'start_time' => $fromTime, 'end_time' => $toTime]);
            }
            $msg = 'Kitchecn Updated succesfully.';

            $kitchen = Auth::guard('api')->user()->restaurant;
            $salesStatus = 'Activation Pending';
            if ($kitchen->certificate && $kitchen->certificate->status) {
                $salesStatus = 'Active';
            }

            $kitchnAddress = $this->Get_Address_From_Google_Maps($kitchen->latitude,$kitchen->longitude);
            event(new KitchenVerified(Auth::guard('api')->user(),$kitchen,$kitchnAddress,$salesStatus));

            if (!empty($delete_files)) {
                foreach ($delete_files as $key => $delete_file) {
                    $this->deleteImageById($delete_file,'mikitchns');
                }
                            
            }

        } else {

            if (!$request->hasFile('images')) {
                return $this->responser([],'Images required.');
            }

            $mikitchn = Mikitchn::create([
                'user_id' => $user->id,
                'name' => $request->name,
                'address' => $request->address,
                'no_of_seats' => $request->no_of_seats,
                'timings' => $request->timings,
                'phone' => $request->phone,
                'description' => $request->description,
                'latitude' => $request->lat,
                'longitude' => $request->lng,
            ]);

            foreach ($timings as $key1 => $timing) {

                $fromTime = Carbon::parse($timing->timing->start_time)->format('H:i:s');
                $toTime = Carbon::parse($timing->timing->end_time)->format('H:i:s');

                switch ($timing->day) {
                    case 'Mon':
                        $day = 'Monday';
                        break;
                    case 'Tue':
                        $day = 'Tuesday';
                        break;
                    case 'Wed':
                        $day = 'Wednesday';
                        break;
                    case 'Thus':
                        $day = 'Thursday';
                        break;
                    case 'Fri':
                        $day = 'Friday';
                        break;
                    case 'Sat':
                        $day = 'Saturday';
                        break;
                    case 'Sun':
                        $day = 'Sunday';
                        break;
                    
                    default:
                        $day = 'Monday';
                        break;
                }
                // print_r(Auth::guard('api')->user()->restaurant); die();
                $Timing = new Timing();
                $Timing->mikitchn_id = $mikitchn->id;
                $Timing->day = $day;
                $Timing->status = $timing->isOn;
                $Timing->start_time = $fromTime;
                $Timing->end_time = $toTime;

                $Timing->save();
            }

            $msg = 'Kitchen created succesfully.';

            $kitchen = Mikitchn::find($mikitchn->id);

            $kitchnAddress = $this->Get_Address_From_Google_Maps($kitchen->latitude,$kitchen->longitude);
            event(new KitchenVerified(Auth::user(),$kitchen,$kitchnAddress,'Activation Pending'));

        }

        $miKitchen = Mikitchn::where('user_id',$user->id)->get()->makeHidden('addedimage')->first();

        if (!empty($files)) {

            $addedImages = $this->addImages($files,'kitchen','mikitchns',$miKitchen->id);
            
        }

        $return = [
            'isSuccess' => true,
            'status' => 200,
            'message' => $msg,  
            'data' => $miKitchen
        ];

        return response()->json($return, 200);

    }

    public function viewRestaurant(Request $request, $id ) {

        $getRestaurant = (new Mikitchn)->newQuery();
        $searchQuerey = $request->query();

        if(!empty($searchQuerey['lat']) && !empty($searchQuerey['lon'])){

            $closest = Mikitchn::closest($searchQuerey['lat'], $searchQuerey['lon']);
            $getRestaurant = $getRestaurant->select('mikitchns.*',
                        DB::raw("{$closest}")
                        ); 

        } 

        $restaurant = $getRestaurant->where('id', $id )->get()->makeHidden(['addedimage','reviews','certificate'])->first();
        // echo "<pre>"; print_r(expression)
        $cock = User::find($restaurant->user_id);

        $restaurant['weektimings'] = $restaurant->weektimings;

        $restaurant['cock'] = [
                        'id' => $cock->id,
                        'name' => $cock->first_name.' '.$cock->last_name,
                        'avatar' => $cock->avatar,
                        'role_id' => $cock->role_id,
                        'description' => $cock->description,
                    ];
        $restaurant['gst'] = [
                        'gst_enable' => $restaurant->certificate->abn_gst,
                        'gst_amount' => 10
                    ];
                    
        $restaurant->append(
            'is_favourited'
        );

        $data = new RestaurantResource($restaurant);
        
        $return = [
            'status' => 200,
            'isSuccess' => true,
            'message' => 'restaurant data.',  
            'data' => $data
        ];

        return response()->json($return, 200);

    }

    public function getMyMenu(){
        $mikitchen = Auth::user()->restaurant;
        $data = []; $msg = 'Menu Foods Not Found';
        if ($mikitchen) {
            $foods = Foods::where('restaurant_id', $mikitchen->id)->orderBy('id', 'desc')->get();

             $data = FoodResource::collection($foods);

             $msg = 'Menu Foods';
             
        }
        
        if (empty($data)) {
            $msg = 'Menu Foods Not Found';
         }
        return $this->responser($data, $msg);
    }

    public function deleteImage(Request $request)
    {
        $image = Image::where('id',$request->id)->where('model_name',$request->type)->get()->first();
        if (!$image) {
            return $this->responser([],'Image Not found.');
        }
        if(File::exists($image->path)) {
            File::delete($image->path);
        }
        $image->delete();
        return $this->responser($image,'Image deleted successfully.');
        
    }


    public function addCertificate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required',
            'last_name' => 'required',
            'certificate_no' => 'required',
            'abn' => 'required',
            'abn_gst' => 'required',
            'certificate_doc' => 'required|mimes:jpeg,png,jpg,svg,pdf',
        ],[
            'abn_gst.required' => "GST for ABN is required"
        ]);
        
        if($validator->fails()){
            return $this->responser($this->data,$validator->errors()->first());
        }

        // ?certId=FSA1717011&fName=Oraya&lName=Tubutda

        $endpoint = "https://9nxccxu88j.execute-api.ap-southeast-2.amazonaws.com/dev/isValidCertificate";
        // $client = new \GuzzleHttp\Client();
        $query = [
            'certId' => $request->certificate_no, 
            'fName' => $request->first_name,
            'lName' => $request->last_name,
        ];
        // $response = $client->request('GET', $endpoint, ['query' => $query]);
        $response = Http::get($endpoint, $query);
        // print_r($response->failed()); die();
        $status = 1;
        $salesStatus = 'Active';
        $msg = 'Certificate Added';
        if ($response->failed()) {
            $status = 0;
            $salesStatus = 'Not Verified';
            $msg = 'Hold tight! We are reviewing your request';
        }

        if ($request->hasFile('certificate_doc')) {

            $file = $request->file('certificate_doc');
        }

        // if ($request->has('abn_gst')) {

        //     $abn_gst = $request->file('certificate_doc');
        // }
        
        $returnFlSts = $this->uploadImageOrDoc($file,'certificates');
        $kitchen = Auth::guard('api')->user()->restaurant;
        if ($returnFlSts['success']) {
            
            $kitchen->certificate()->delete();
            $certificate = new Certificate();
            $certificate->mikitchn_id = $kitchen->id;
            $certificate->first_name = $request->first_name;
            $certificate->last_name = $request->last_name;
            $certificate->certificate_no = $request->certificate_no;
            $certificate->certificate_doc = $returnFlSts['path'];
            $certificate->abn_gst = $request->abn_gst;
            $certificate->status = $status;
            $certificate->abn = $request->abn;
            $certificate->save();

            

            $kitchnAddress = $this->Get_Address_From_Google_Maps($kitchen->latitude,$kitchen->longitude);
            event(new KitchenVerified(Auth::user(),$kitchen,$kitchnAddress,$salesStatus));

        } else {

            

            return response()->json([
                'status' => 404,
                'isSuccess' => false,
                'isError' => 'File not uploaded please try again.',
            ],404);

        }

        

        return $this->responser($certificate,$msg);
        

        
    }

    public function checkCertificate()
    {
        $exists = false;
        if (!Auth::guard('api')->user()->restaurant) {
            $this->data['exists'] = $exists;
            return $this->responser($this->data,'Check kitchen certificate exists.');
        }
        $certificate = Auth::guard('api')->user()->restaurant->certificate;
        $status = 0;
        if ($certificate) {
            $exists = true;
            $status = $certificate->status;
        }
        $this->data['exists'] = $exists;
        $this->data['status'] = $status;
        
        return $this->responser($this->data,'Check kitchen certificate exists.');
    }

    public function getVendorEarnings()
    {
        $response = $this->getVendorLifetimeAmount();
        $transfers = $response->data;
        $earning = 0;
        foreach ($transfers as $key => $transfer) {
            // echo $transfer->amount / 100; die();
            $earning += $transfer->amount / 100;
        }

        return $earning;

    }

    public function getDashboardData()
    {
        $currntdate = date('Y-m-d');
        $statusArry = array('0' => 0,'1' => 1,);
        $kitchen = Auth::guard('api')->user()->restaurant;

        if (!$kitchen) {
            return $this->responser(['total_earning'=> 0, 'n_bookings' => 0, 'n_upcoming_bookings' => 0], 'kitchen dashboard data.');
        }
        $orders = Order::where('mikitchn_id',$kitchen->id);
        $earnings = 0;
        if (Auth::user()->vendor && Auth::user()->vendor->account_id) {
            $earnings = $this->getVendorEarnings();
        }

        $allOrders = $orders->whereIn('status',$statusArry)->count();

        $upcoming = Order::where('mikitchn_id',$kitchen->id)->where('delivery_date', '>=', $currntdate)->where('status',3)->count();

        $data = ['total_earning'=> $earnings, 'n_bookings' => $allOrders, 'n_upcoming_bookings' => $upcoming];

        return $this->responser($data, 'kitchen dashboard data.');
    }

    public function getPartners(Request $request)
    {
        $partners = Partner::all();

        return $this->responser($partners, "All partners");
    }

    public function updateOpenMikitchen(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'open' => 'required'
        ]);
        
        if($validator->fails()){
            return $this->responser($this->data,$validator->errors()->first());
        }
        $kitchen = Auth::guard('api')->user()->restaurant;
        $kitchen->open = $request->open;
        $kitchen->save();
        return $this->responser($kitchen, "Open status updated.");
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return \Illuminate\Http\Response
     */
    public function show(Mikitchn $mikitchn)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return \Illuminate\Http\Response
     */
    public function edit(Mikitchn $mikitchn)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Mikitchn $mikitchn)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return \Illuminate\Http\Response
     */
    public function destroy(Mikitchn $mikitchn)
    {
        //
    }


}
