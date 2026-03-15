<?php

namespace App\Http\Controllers\Api;

use App\Models\Mikitchn;
use App\Models\Certificate;
use App\Models\User;
use App\Models\Review;
use App\Models\Foods;
use App\Models\Order;
use App\Models\Timing;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Validator,DB,Auth;
use Carbon\Carbon;
use App\Services\DineInSlotService;
use App\Http\Resources\Restaurant\Restaurant as RestaurantResource;
use App\Http\Resources\Restaurant\Food as FoodResource;
use App\Http\Resources\Restaurant\DineInSlot as DineInSlotResource;
use App\Http\Resources\User\User as UserResource;
use App\Services\DiscoveryService;
use App\Services\KitchenService;
use App\Services\PaymentService;
use Illuminate\Support\Facades\Cache;
use Throwable;

class MikitchnController extends Controller
{
    private DiscoveryService $discoveryService;
    private KitchenService $kitchenService;
    private PaymentService $paymentService;
    private DineInSlotService $dineInSlotService;

    public function __construct(
        DiscoveryService $discoveryService,
        KitchenService $kitchenService,
        PaymentService $paymentService,
        DineInSlotService $dineInSlotService
    ) {
        $this->discoveryService = $discoveryService;
        $this->kitchenService = $kitchenService;
        $this->paymentService = $paymentService;
        $this->dineInSlotService = $dineInSlotService;
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
            'no_of_seats' => 'required|integer|min:1',
            'timings' => 'required|string',
            'phone' => ['required', 'string', 'max:20', 'regex:/^\+[1-9]\d{6,14}$/'],
            'abn' => 'nullable|string',
            'certificate_no' => 'nullable|string',
            'lat' => 'nullable|numeric|between:-90,90|required_with:lng',
            'lng' => 'nullable|numeric|between:-180,180|required_with:lat',
            'dine_in' => 'nullable|integer|in:0,1',
            'take_away' => 'nullable|integer|in:0,1',
            'dine_in_slots' => 'nullable|string',
        ]
       );
        
        if($validator->fails()){
            return $this->responser([],$validator->errors()->first(), 422);
        }
        $user = Auth::user();
        $existKitchen = Mikitchn::where('user_id',$user->id)->first();

        $decodedTimings = json_decode((string) $request->timings);
        $timings = is_object($decodedTimings) && isset($decodedTimings->days) && is_array($decodedTimings->days)
            ? $decodedTimings->days
            : null;
        if ($timings === null) {
            return $this->responser([], 'timings must be valid JSON with a days array.', 422);
        }

        $requestedDineIn = $request->has('dine_in')
            ? (int) $request->input('dine_in')
            : (int) optional($existKitchen ?? null)->dine_in;

        $dineInSlots = null;
        if ($request->filled('dine_in_slots')) {
            if ($requestedDineIn !== 1) {
                return $this->responser([], 'dine_in_slots can only be configured when dine-in is enabled for the kitchen.', 422);
            }

            $decodedSlots = json_decode((string) $request->dine_in_slots, true);
            if (! is_array($decodedSlots)) {
                return $this->responser([], 'dine_in_slots must be valid JSON.', 422);
            }

            $slotValidator = Validator::make(['slots' => $decodedSlots], [
                'slots' => 'array',
                'slots.*.day_of_week' => 'required|integer|between:0,6',
                'slots.*.start_time' => 'required|date_format:H:i',
                'slots.*.end_time' => 'required|date_format:H:i',
                'slots.*.seat_capacity' => 'nullable|integer|min:1',
                'slots.*.status' => 'nullable|integer|in:0,1',
            ]);

            if ($slotValidator->fails()) {
                return $this->responser([], $slotValidator->errors()->first(), 422);
            }

            $timingWindows = collect($timings)
                ->mapWithKeys(function ($timing): array {
                    $day = $this->normalizeTimingDay((string) ($timing->day ?? ''));
                    if ($day === null) {
                        return [];
                    }

                    return [[
                        'Monday' => 1,
                        'Tuesday' => 2,
                        'Wednesday' => 3,
                        'Thursday' => 4,
                        'Friday' => 5,
                        'Saturday' => 6,
                        'Sunday' => 0,
                    ][$day] => [
                        'is_on' => (int) ($timing->isOn ?? 0) === 1,
                        'start_time' => Carbon::parse($timing->timing->start_time ?? '00:00')->format('H:i'),
                        'end_time' => Carbon::parse($timing->timing->end_time ?? '00:00')->format('H:i'),
                    ]];
                })
                ->all();

            foreach ($decodedSlots as $slot) {
                if (Carbon::parse((string) $slot['end_time'])->lte(Carbon::parse((string) $slot['start_time']))) {
                    return $this->responser([], 'Each dine-in slot end_time must be after start_time.', 422);
                }

                $window = $timingWindows[(int) $slot['day_of_week']] ?? null;
                if (! $window || ! $window['is_on']) {
                    return $this->responser([], 'Dine-in slots can only be created on kitchen opening days.', 422);
                }

                if ((string) $slot['start_time'] < $window['start_time'] || (string) $slot['end_time'] > $window['end_time']) {
                    return $this->responser([], 'Dine-in slots must stay within the configured kitchen opening hours.', 422);
                }
            }

            if ($this->hasOverlappingDineInSlots($decodedSlots)) {
                return $this->responser([], 'Dine-in slots for the same day cannot overlap.', 422);
            }

            $dineInSlots = $decodedSlots;
        }

        $files = $delete_files = [];
        if ($request->hasFile('images')) {
            $files = $request->file('images');
        }

        if ($request->has('delete_images')) {
            $delete_files = explode(',', $request->delete_images);
        }
    
        $userExist = User::find($user->id);
        if (!$userExist) {
            return $this->responser([],'Unauthorized user not found.', 401);
        }
        if (! $isUpdate && ! $existKitchen && ! $request->hasFile('images')) {
            return $this->responser([],'Images required.', 422);
        }

        $miKitchen = DB::transaction(function () use ($request, $timings, $user, $existKitchen, $dineInSlots) {
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
            if ($request->has('lat')) {
                $kitchen->latitude = (float) $request->lat;
            }
            if ($request->has('lng')) {
                $kitchen->longitude = (float) $request->lng;
            }
            $kitchen->save();

            $abn = trim((string) $request->input('abn', ''));
            $certificateNo = trim((string) $request->input('certificate_no', ''));
            $existingCertificate = Certificate::query()
                ->where('mikitchn_id', $kitchen->id)
                ->exists();

            if ($abn !== '' || $certificateNo !== '' || $existingCertificate) {
                Certificate::query()->updateOrCreate(
                    ['mikitchn_id' => $kitchen->id],
                    [
                        'abn' => $abn !== '' ? $abn : null,
                        'certificate_no' => $certificateNo,
                    ]
                );
            }

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

            if ((int) $kitchen->dine_in !== 1) {
                $this->dineInSlotService->clearKitchenSlots($kitchen);
            } elseif ($dineInSlots !== null) {
                $this->dineInSlotService->syncKitchenSlots($kitchen, $dineInSlots);
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
        $miKitchen->load('dineInSlots');
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

    private function hasOverlappingDineInSlots(array $slots): bool
    {
        $groupedByDay = [];

        foreach ($slots as $slot) {
            $groupedByDay[(int) $slot['day_of_week']][] = [
                'start_time' => Carbon::parse((string) $slot['start_time'])->format('H:i:s'),
                'end_time' => Carbon::parse((string) $slot['end_time'])->format('H:i:s'),
            ];
        }

        foreach ($groupedByDay as $daySlots) {
            usort($daySlots, function (array $left, array $right): int {
                return strcmp($left['start_time'], $right['start_time']);
            });

            $previousEndTime = null;
            foreach ($daySlots as $slot) {
                if ($previousEndTime !== null && $slot['start_time'] < $previousEndTime) {
                    return true;
                }

                $previousEndTime = $slot['end_time'];
            }
        }

        return false;
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

    public function getMyDineInSlots(Request $request)
    {
        $validator = Validator::make($request->query(), [
            'date' => 'nullable|date_format:Y-m-d',
            'persons' => 'nullable|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $kitchen = Auth::user()->restaurant;
        if (! $kitchen) {
            return $this->responser([], 'Kitchen not found for this user.', 404);
        }

        if ($request->filled('date')) {
            $slots = $this->dineInSlotService->getAvailabilityForDate(
                $kitchen,
                Carbon::parse((string) $request->query('date')),
                $request->filled('persons') ? (int) $request->query('persons') : null
            );

            return $this->responser(DineInSlotResource::collection($slots), 'Kitchen dine-in slots.');
        }

        $slots = $kitchen->dineInSlots()->orderBy('day_of_week')->orderBy('start_time')->get();

        return $this->responser(DineInSlotResource::collection($slots), 'Kitchen dine-in slots.');
    }

    public function deleteImage(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer',
            'type' => 'required|string|in:mikitchns,food',
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $result = $this->deleteImageById((int) $request->id, (string) $request->type);
        if (!($result['status'] ?? false)) {
            $message = (string) ($result['msg'] ?? 'Image Not found.');
            $status = str_contains(strtolower($message), 'unauthorized') ? 403 : 404;
            return $this->responser([], $message, $status);
        }

        return $this->responser(['id' => (int) $request->id], 'Image deleted successfully.');
    }


    private function getVendorEarnings()
    {
        $userId = (int) Auth::id();
        return (float) Cache::remember(
            'vendor_earnings_total_' . $userId,
            now()->addMinutes(30),
            function (): float {
                try {
                    $transfers = $this->paymentService->getVendorLifetimeAmount(Auth::user(), 3, 50);
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
            ->whereIn('status', [Order::STATUS_CONFIRMED, Order::STATUS_IN_PROGRESS])
            ->count();

        $data = ['total_earning'=> $earnings, 'n_bookings' => $allOrders, 'n_upcoming_bookings' => $upcoming];

        return $this->responser($data, 'kitchen dashboard data.');
    }

}
