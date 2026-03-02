<?php

namespace App\Http\Controllers\Api;

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
use App\Traits\GoogleAddress;
use App\Services\DiscoveryService;
use App\Services\KitchenService;
use App\Services\PaymentService;

class MikitchnController extends Controller
{
    use GoogleAddress;
    public $data=[];
    private DiscoveryService $discoveryService;
    private KitchenService $kitchenService;
    private PaymentService $paymentService;

    public function __construct(
        DiscoveryService $discoveryService,
        KitchenService $kitchenService,
        PaymentService $paymentService
    ) {
        $this->discoveryService = $discoveryService;
        $this->kitchenService = $kitchenService;
        $this->paymentService = $paymentService;
    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */


    public function recommendedRestaurant(Request $request)
    {
        $this->data = $this->discoveryService->recommended($request)['data'];
        return $this->responser($this->data,'restaurants by recommeded.');

    }

    public function nearestRestaurant(Request $request)
    {
        $this->data = $this->discoveryService->nearest($request)['data'];
        return $this->responser($this->data,'Nearest Restaurants');
    }


    public function topRatedRestaurant(Request $request)
    {
        $this->data = $this->discoveryService->topRated($request)['data'];
        return $this->responser($this->data,'restaurants by rating');
    }

    public function filterRestaurant(Request $request)
    {
        $this->data = $this->discoveryService->filtered($request)['data'];
        return $this->responser($this->data, 'restaurants filtered.');
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
            return $this->responser($this->data,$validator->errors()->first(), 422);
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
            return $this->responser([],'Unauthorized user not found.', 401);
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

            $this->kitchenService->invalidateDiscoveryCaches();

            if (!empty($delete_files)) {
                foreach ($delete_files as $key => $delete_file) {
                    $this->deleteImageById($delete_file,'mikitchns');
                }
                            
            }

        } else {

            if (!$request->hasFile('images')) {
                return $this->responser([],'Images required.', 422);
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

            $this->kitchenService->invalidateDiscoveryCaches();

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

        if (isset($searchQuerey['lat'], $searchQuerey['lon']) && is_numeric($searchQuerey['lat']) && is_numeric($searchQuerey['lon'])) {

            $closest = Mikitchn::closest($searchQuerey['lat'], $searchQuerey['lon']);
            $getRestaurant = $getRestaurant->select('mikitchns.*',
                        DB::raw("{$closest}")
                        ); 

        } 

        $restaurant = $getRestaurant
            ->with(['addedimage:id,ref_id,model_name,path', 'certificate:id,mikitchn_id,abn,abn_gst,status', 'weektimings'])
            ->withAvg('reviews', 'rating')
            ->where('id', $id )
            ->get()
            ->makeHidden(['addedimage','reviews','certificate'])
            ->first();
        if (!$restaurant) {
            return $this->responser([], 'restaurant not found.', 404);
        }
        // echo "<pre>"; print_r(expression)
        $cock = User::find($restaurant->user_id);
        if (!$cock) {
            return $this->responser([], 'cook profile not found.', 404);
        }

        $restaurant['weektimings'] = $restaurant->weektimings;

        $restaurant['cock'] = [
                        'id' => $cock->id,
                        'name' => $cock->first_name.' '.$cock->last_name,
                        'avatar' => $cock->avatar,
                        'role_id' => $cock->role_id,
                        'description' => $cock->description,
                    ];
        $restaurant['gst'] = [
                        'gst_enable' => optional($restaurant->certificate)->abn_gst,
                        'gst_amount' => 10
                    ];
                    
        $restaurant->setAttribute(
            'is_favourited',
            Auth::guard('api')->check() ? Auth::guard('api')->user()->hasFavorited($restaurant) : false
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
            $foods = Foods::with('addedimage:id,ref_id,model_name,path')
                ->where('restaurant_id', $mikitchen->id)
                ->orderBy('id', 'desc')
                ->get();

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
            return $this->responser([],'Image Not found.', 404);
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
            'certificate_doc' => 'required|mimes:jpeg,png,jpg,pdf,webp',
        ],[
            'abn_gst.required' => "GST for ABN is required"
        ]);
        
        if($validator->fails()){
            return $this->responser($this->data,$validator->errors()->first(), 422);
        }

        $status = 0;
        $msg = 'Certificate submitted and pending review.';
        $kitchen = Auth::guard('api')->user()->restaurant;
        if (! $kitchen) {
            return response()->json([
                'status' => 422,
                'isSuccess' => false,
                'isError' => 'Kitchen profile is required before certificate submission.',
                'data' => [],
            ], 422);
        }

        if ($request->hasFile('certificate_doc')) {

            $file = $request->file('certificate_doc');
        }

        // if ($request->has('abn_gst')) {

        //     $abn_gst = $request->file('certificate_doc');
        // }
        
        $returnFlSts = $this->uploadImageOrDoc($file,'certificates');
        if ($returnFlSts['success']) {
            $certificate = DB::transaction(function () use ($kitchen, $request, $returnFlSts, $status) {
                $certificate = Certificate::query()
                    ->where('mikitchn_id', $kitchen->id)
                    ->lockForUpdate()
                    ->first();

                if (! $certificate) {
                    $certificate = new Certificate();
                    $certificate->mikitchn_id = $kitchen->id;
                }

                $certificate->first_name = $request->first_name;
                $certificate->last_name = $request->last_name;
                $certificate->certificate_no = $request->certificate_no;
                $certificate->certificate_doc = $returnFlSts['path'];
                $certificate->abn_gst = $request->abn_gst;
                $certificate->status = $status;
                $certificate->abn = $request->abn;
                $certificate->rejection_reason = null;
                $certificate->reviewed_at = null;
                $certificate->reviewed_by = null;
                $certificate->save();

                return $certificate;
            });

            $this->kitchenService->invalidateDiscoveryCaches();

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
        $response = $this->paymentService->safely(fn () => $this->paymentService->getVendorLifetimeAmount(Auth::user()));
        $transfers = is_object($response) && isset($response->data) ? $response->data : [];
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
        $statusArry = [
            Order::STATUS_LEGACY_CANCELLED,
            Order::STATUS_COMPLETED,
            Order::STATUS_CANCELLED,
        ];
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

        $upcoming = Order::where('mikitchn_id', $kitchen->id)
            ->where('delivery_date', '>=', $currntdate)
            ->where('status', Order::STATUS_CONFIRMED)
            ->count();

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
            return $this->responser($this->data,$validator->errors()->first(), 422);
        }
        $kitchen = Auth::guard('api')->user()->restaurant;
        $kitchen->open = $request->open;
        $kitchen->save();
        return $this->responser($kitchen, "Open status updated.");
    }

}
