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
use App\Http\Resources\Restaurant\Food as FoodResource;
use App\Http\Resources\User\User as UserResource;
use App\Traits\GoogleAddress;
use App\Services\DiscoveryService;
use App\Services\KitchenService;
use App\Services\PaymentService;
use Illuminate\Support\Facades\Cache;
use Throwable;

class MikitchnController extends Controller
{
    use GoogleAddress;
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
        $hasKitchen = Mikitchn::query()->where('user_id', $user->id)->exists();

        if ($hasKitchen) {
            return $this->updateKitchen($request);
        }

        return $this->createKitchen($request);
    }

    public function createKitchen(Request $request)
    {
        $user = Auth::user();
        if (Mikitchn::query()->where('user_id', $user->id)->exists()) {
            return $this->responser([], 'Kitchen already exists. Use editkitchen endpoint.', 409);
        }

        return $this->saveKitchen($request, false);
    }

    public function updateKitchen(Request $request)
    {
        $user = Auth::user();
        if (! Mikitchn::query()->where('user_id', $user->id)->exists()) {
            return $this->responser([], 'Kitchen not found for this user.', 404);
        }

        return $this->saveKitchen($request, true);
    }

    private function saveKitchen(Request $request, bool $isUpdate)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required',
            'address' => 'required',
            'no_of_seats' => 'required|integer',
            'timings' => 'required|string',
            'phone' => 'required|string',
        ]
       );
        
        if($validator->fails()){
            return $this->responser([],$validator->errors()->first(), 422);
        }
        $decodedTimings = json_decode((string) $request->timings);
        $timings = is_object($decodedTimings) && isset($decodedTimings->days) && is_array($decodedTimings->days)
            ? $decodedTimings->days
            : null;
        if ($timings === null) {
            return $this->responser([], 'timings must be valid JSON with a days array.', 422);
        }

        $files = $delete_files = [];
        if ($request->hasFile('images')) {
            $files = $request->file('images');
        }

        if ($request->has('delete_images')) {
            $delete_files = explode(',', $request->delete_images);
        }
    
        $user = Auth::user();
        $userExist = User::find($user->id);
        if (!$userExist) {
            return $this->responser([],'Unauthorized user not found.', 401);
        }
        $existKitchen = Mikitchn::where('user_id',$user->id)->first();
        if (! $isUpdate && ! $existKitchen && ! $request->hasFile('images')) {
            return $this->responser([],'Images required.', 422);
        }

        $miKitchen = DB::transaction(function () use ($request, $timings, $user, $existKitchen) {
            $kitchen = $existKitchen ?: new Mikitchn();
            $kitchen->user_id = $user->id;
            $kitchen->name = $request->name;
            $kitchen->address = $request->address;
            $kitchen->no_of_seats = $request->no_of_seats;
            $kitchen->timings = $request->timings;
            $kitchen->phone = $request->phone;
            $kitchen->dine_in = $request->dine_in;
            $kitchen->take_away = $request->take_away;
            $kitchen->description = $request->description;
            $kitchen->latitude = $request->lat;
            $kitchen->longitude = $request->lng;
            $kitchen->save();

            foreach ($timings as $timing) {
                $day = $this->normalizeTimingDay((string) ($timing->day ?? ''));
                if ($day === null) {
                    continue;
                }
                $fromTime = Carbon::parse($timing->timing->start_time ?? '00:00')->format('H:i:s');
                $toTime = Carbon::parse($timing->timing->end_time ?? '00:00')->format('H:i:s');
                Timing::query()->updateOrCreate(
                    ['mikitchn_id' => $kitchen->id, 'day' => $day],
                    [
                        'status' => (int) ($timing->isOn ?? 0),
                        'start_time' => $fromTime,
                        'end_time' => $toTime,
                    ]
                );
            }

            return $kitchen;
        });

        if (!empty($delete_files)) {
            foreach ($delete_files as $delete_file) {
                $this->deleteImageById($delete_file,'mikitchns');
            }
        }

        $msg = $existKitchen ? 'Kitchecn Updated succesfully.' : 'Kitchen created succesfully.';

        $this->kitchenService->invalidateDiscoveryCaches();
        if ($miKitchen) {
            $miKitchen->makeHidden('addedimage');
        }

        if (!empty($files)) {
            $this->addImages($files,'kitchen','mikitchns',$miKitchen->id);
        }
        return $this->responser($miKitchen, $msg);
    }

    private function normalizeTimingDay(string $shortDay): ?string
    {
        return [
            'Mon' => 'Monday',
            'Tue' => 'Tuesday',
            'Wed' => 'Wednesday',
            'Thus' => 'Thursday',
            'Thu' => 'Thursday',
            'Fri' => 'Friday',
            'Sat' => 'Saturday',
            'Sun' => 'Sunday',
        ][$shortDay] ?? null;
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
        $image = Image::where('id',$request->id)->where('model_name',$request->type)->first();
        if (!$image) {
            return $this->responser([],'Image Not found.', 404);
        }
        $disk = Storage::disk('my_files');
        if ($disk->exists((string) $image->path)) {
            $disk->delete((string) $image->path);
        } elseif (File::exists((string) $image->path)) {
            File::delete((string) $image->path);
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
            return $this->responser([],$validator->errors()->first(), 422);
        }

        $status = 0;
        $msg = 'Certificate submitted and pending review.';
        $kitchen = Auth::guard('api')->user()->restaurant;
        if (! $kitchen) {
            return $this->responser([], 'Kitchen profile is required before certificate submission.', 422);
        }

        if ($request->hasFile('certificate_doc')) {

            $file = $request->file('certificate_doc');
        }

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
            return $this->responser([], 'File not uploaded please try again.', 404);
        }
        return $this->responser($certificate,$msg);
    }

    public function checkCertificate()
    {
        $data = ['exists' => false, 'status' => 0];
        if (!Auth::guard('api')->user()->restaurant) {
            return $this->responser($data,'Check kitchen certificate exists.');
        }
        $certificate = Auth::guard('api')->user()->restaurant->certificate;
        if ($certificate) {
            $data['exists'] = true;
            $data['status'] = $certificate->status;
        }
        
        return $this->responser($data,'Check kitchen certificate exists.');
    }

    public function getVendorEarnings()
    {
        $userId = (int) Auth::id();
        return (float) Cache::remember(
            'vendor_earnings_total_' . $userId,
            now()->addMinutes(5),
            function (): float {
                try {
                    $transfers = $this->paymentService->getVendorLifetimeAmount(Auth::user(), 10);
                } catch (Throwable $throwable) {
                    report($throwable);
                    return 0.0;
                }
                $earning = 0.0;
                foreach ($transfers as $transfer) {
                    $earning += ((float) ($transfer->amount ?? 0)) / 100;
                }
                return round($earning, 2);
            }
        );

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
            return $this->responser([],$validator->errors()->first(), 422);
        }
        $kitchen = Auth::guard('api')->user()->restaurant;
        $kitchen->open = $request->open;
        $kitchen->save();
        return $this->responser($kitchen, "Open status updated.");
    }

}

