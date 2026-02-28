<?php

namespace App\Http\Controllers\Api;

use App\Models\Order;
use App\Models\OrderData;
use App\Models\Mikitchn;
use App\Models\User;
use App\Models\Review;
use App\Models\Foods;
use App\Models\Timing;
use App\Models\PromoCode;
use App\Models\CancelReason;
use App\Models\Payment;
use App\Models\CompletedOrder;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Validator,DB,Auth;
use Storage, DateTime;
use Carbon\Carbon;
use App\Http\Resources\Order\Order as OrderResource;
use App\Events\MakeOrderPaymentToVendor;
use App\Events\CancelOrderRefund;
use App\Services\OrderService;
use App\Services\PaymentService;

class OrderController extends Controller
{
    public $data=[];
    private PaymentService $paymentService;
    private OrderService $orderService;

    public function __construct(PaymentService $paymentService, OrderService $orderService)
    {
        $this->paymentService = $paymentService;
        $this->orderService = $orderService;
    }

    public function myUpcomingOrderss(Request $request)
    {
        $queryparams = $request->query();
        $currntdate = date('Y-m-d');
        $kitchen = Auth::guard('api')->user()->restaurant;

        if (!$kitchen) {
            $this->data['total_count'] = 0;
            $this->data['bookings'] = [];
            return $this->responser($this->data, 'No Upcoming Bookings');
        }

        $orders = Order::where('mikitchn_id',$kitchen->id)->where('delivery_date', '>=', $currntdate)->where('status',3);

        if ($request->has('sortby')) {
            if ($request->sortby == 'take_away') {
                $orders->where('take_away',1);
            } else {
                $orders->where('dine_in',1);
            }
            
        }
        $this->data['total_count'] = $orders->count();

        $orders = $orders->orderBy('id','desc')->paginate($queryparams['limit']);
        
        $this->data['bookings'] = OrderResource::collection($orders);

        if ($this->data['total_count'] == 0) {
            return $this->responser($this->data,'No Upcoming Bookings');
        }

        return $this->responser($this->data,'Upcoming Bookings');
    }

    public function myRequestedOrders(Request $request)
    {
        $queryparams = $request->query();

        if (!Auth::guard('api')->user()->restaurant) {
            $this->data['total_count'] = 0;
            $this->data['bookings'] = [];
            return $this->responser($this->data, 'No Requested Orders');
        }


        $orders = Auth::guard('api')->user()->restaurant->orders()->where('status', 2);
        $this->data['total_count'] = $orders->count();
        $data = $orders->orderBy('id','desc')->paginate($queryparams['limit'])->makeHidden('orderdata');

        $this->data['bookings'] = OrderResource::collection($data);

        return $this->responser($this->data,'restaurant requested orders.');
    }

    public function statusUpdate(Request $request)
    {
        $order = Order::find($request->order_id);
        if (!$order) {
            return $this->responser([], 'Order not found.');
        }

        
        $requestedStatus = (int) $request->status;
        if ($requestedStatus === Order::STATUS_LEGACY_CANCELLED) {
            $requestedStatus = Order::STATUS_CANCELLED;
        }

        if ($requestedStatus === Order::STATUS_CONFIRMED) {
            if (!$order->payment) {
                return $this->responser([], 'Payment record not found for this order.');
            }
            $confirmPayment = $this->paymentService->safely(fn () => $this->paymentService->confirmPaymentIntent($order->payment));

            if (is_object($confirmPayment)) {
               
                $payment = $order->payment;
                $payment->confirm = 1;
                $payment->status = 1;
                $payment->confirm_date_time = Carbon::now()->format('Y-m-d H:i:s');
                $payment->save();

                $order->paid = 1;
            } else {
               return $this->responser([],$confirmPayment);  
            }
        } elseif ($requestedStatus === Order::STATUS_COMPLETED) {
            $completedOrder = new CompletedOrder();
            $completedOrder->order_id = $request->order_id;
            $completedOrder->completed_date_time = Carbon::now();
            $completedOrder->save();
             // $transferToVendor = $this->transferToVendor($order->Mikitchn,$order->total_price,$order->id);
            // event(new ());

            // $cOrder = CompletedOrder::where('completed_date_time','>=',Carbon::now()->subDay()->toDateTimeString())->get();
            // $cOrders = CompletedOrder::where('completed',0)->where('completed_date_time','<=',Carbon::now()->subDay())->get();

            // foreach ($cOrders as $key => $cOrder) {
            //     event(new MakeOrderPaymentToVendor($cOrder));
            // }

             // print_r($cOrder);
             // die();
        }
        

        $order->status = $requestedStatus; 
        $order->save();

        return $this->responser($order,'Order Updated successfully.'); 
    }

    public function checkDiscountedUser(Request $request)
    {
        $user = Auth::user();

        $oCount = Order::where('user_id',$user->id)->where('status',1)->count();
        $distcounted = false;
        if ($oCount <= 5) {
            $distcounted = true;
        }

        return $this->responser(['distcounted'=>$distcounted,'gstpercentage'=>10,'discount_amount'=>50],'check user in discount list');
    }

    public function allOrders(Request $request)
    {
        $queryparams = $request->query();
        $kitchen = Auth::guard('api')->user()->restaurant;

        if (!$kitchen) {
            $this->data['total_count'] = 0;
            $this->data['bookings'] = [];
            return $this->responser($this->data, 'No Bookings');
        }

        $statusArry = [
            Order::STATUS_LEGACY_CANCELLED,
            Order::STATUS_COMPLETED,
            Order::STATUS_CANCELLED,
        ];
        $orders = Order::where('mikitchn_id',$kitchen->id);
        if ($request->has('sortby')) {
            if ($request->sortby == 'take_away') {
                $orders->where('take_away',1);
            } else {
                $orders->where('dine_in',1);
            }
            
        }

        if ($request->has('status')) {
            $orders->where('status',$request->status);
        } else {
            $orders->whereIn('status',$statusArry);
        }
        // echo $orders->toSql();
        $this->data['total_count'] = $orders->count();

        $orders = $orders->orderBy('id','desc')->paginate($queryparams['limit']);
        // $this->data['total_count'] = $kitchen->orders->whereIn('status',$statusArry)->count();
        $this->data['bookings'] = OrderResource::collection($orders);

        if ($this->data['total_count'] == 0) {
            return $this->responser($this->data,'No Bookings');
        }
        return $this->responser($this->data,'All Bookings');

    }

    public function checkPromoCode(Request $request)
    {
        $now = Carbon::now();
        $promocode = PromoCode::query()
            ->whereRaw('LOWER(code) = ?', [strtolower((string) $request->code)])
            ->where('status', 1)
            ->where(function ($query) use ($now) {
                $query->whereNull('starts_at')->orWhere('starts_at', '<=', $now);
            })
            ->where(function ($query) use ($now) {
                $query->whereNull('ends_at')->orWhere('ends_at', '>=', $now);
            })
            ->first();

        if (!$promocode) {
            return $this->responser($this->data,'Promo code is invalid, inactive, or expired.');
        }

        // $this->data = new OrderResource($promocode);

        return $this->responser($promocode,'Promo code founded.');
    }

    public function myorderlist(Request $request)
    {
        $queryparams = $request->query();
        $orders = Auth::guard('api')->user()->orders()->whereNotIn('status', Order::cancelledStatuses());

        $this->data['total_count'] = $orders->count();
        $orders = $orders->orderBy('id','desc')->paginate($queryparams['limit']);
        $this->data['bookings'] = OrderResource::collection($orders);

        return $this->responser($this->data,'Order List.');
    }

    public function getBookedDates(Request $request,$restaurantId)
    {
        
        $restaurant = Mikitchn::find($restaurantId);
        if (!$restaurant) {
            return $this->responser([], 'restaurant not found.');
        }

        $statusArry = [Order::STATUS_CONFIRMED];

        $timings = $restaurant->weektimings->makeHidden(['created_at','updated_at','id','mikitchn_id'])->toArray();
        $TotalSeats = $restaurant->no_of_seats;

        // print_r($timings); 
        // die;
        $orders = Order::join('mikitchns', 'mikitchns.id', '=', 'orders.mikitchn_id')
            ->where('orders.mikitchn_id', $restaurantId)->where('orders.dine_in',1)->where('orders.delivery_date', '>=', date('Y-m-d'))->whereIn('orders.status',$statusArry)
                    ->selectRaw('DATE_FORMAT(orders.delivery_date, "%d-%m-%Y") as bookedDate, DAYNAME(orders.delivery_date) as dayN, SUM(TIMESTAMPDIFF(minute, orders.delivery_time_from, orders.delivery_time_to)) as bookedmins, SUM(orders.persons) as bookedseats')
                    ->groupBy('orders.delivery_date')
                    // ->having('bookedseats','=', $TotalSeats)
                    // ->toSql();
                    ->get()
                    ->makeHidden(['items','orderId'])->toArray();

        $data['weekOff'] = array();
        $data['bookedDates'] = array();
        // print_r($orders); 
        // die;  

        foreach ($timings as $key => $timing){
            
            if (!$timing['status']) {
                array_push($data['weekOff'],$timing['day']);
                 
            } 
            
        }

        foreach ($orders as $key11 => $order) {

            $findKey = array_search($order['dayN'], array_column($timings, 'day'));
            if ($findKey >= 0 && $order['bookedmins'] >= $timings[$findKey]['avail_minutes']) {
                array_push($data['bookedDates'],$order['bookedDate']);
                
            }
        }

        $this->data = $data;
        return $this->responser($this->data,'booked dates list.');
    }

    public function checkBookedTimeByDate(Request $request)
    {
        $statusArry = [Order::STATUS_CONFIRMED];
        $date = $request->date;
        $time_from = Carbon::parse($request->time_from)->format('H:i:s');
        $time_to = Carbon::parse($request->time_to)->format('H:i:s');

        $restaurant = Mikitchn::find($request->kitchen);
        if (!$restaurant) {
            return $this->responser([], 'restaurant not found.');
        }
        $TotalSeats = $restaurant->no_of_seats;

        $orders = Order::where('dine_in',1)->whereIn('status',$statusArry)
                    ->where(function($query) use ($date,$time_from,$time_to){
                            $query->where('delivery_date','=',$date)
                            ->whereRaw('(TIME(delivery_time_from) <= "'.$time_from.'" OR TIME(delivery_time_to) <= "'.$time_to.'")');
                    })
                    ->selectRaw('persons as bookedseats')
                    // ->exists();
                    // ->toSql();
                    ->get();
                    // ->first();
        // print_r($orders); 
        // die();
        $bookdSeats = 0;
        foreach ($orders as $key => $order) {
            $bookdSeats = $bookdSeats + $order->bookedseats;
        }
        if ($bookdSeats) {
            $data['total_seats'] = $TotalSeats;
            $data['available_seats'] = $TotalSeats - $bookdSeats;

        }else{
            $data['total_seats'] = $TotalSeats;
            $data['available_seats'] = $TotalSeats;
        }
        
        $this->data = $data;
        return $this->responser($this->data,'checked time slot exist.');
    }


    public function orderCancelWithReason(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'subject' => 'required',
            'comment' => 'required',
            'order_id' => 'required|integer',
        ]);

        if($validator->fails()){
            return $this->responser([],$validator->errors()->first());
        }

        $by_user = 'customer';
        $user = Auth::user();
        if ($user->role_id == 2) {
            $by_user = 'mikitchen';
            // $user = $user->restaurant;
        }
        // print_r($user); die();
        $order = Order::find($request->order_id);
        if ((int) $order->status === Order::STATUS_CONFIRMED) {
            event(new CancelOrderRefund($order,$by_user));
        }

        $orderPendingHrs = $this->getPendingHoursInOrderD($order);
        if ($order->payment) {
	        if ($by_user == 'customer' && $orderPendingHrs >= 12) {
	        	$order->refund_percentage = 50;
	        }else{
	        	$order->refund_percentage = 100;
	        }
	    }
        

        $order->status = Order::STATUS_CANCELLED;

        if ($order->save()) {
            $cancelReason = new CancelReason();
            $cancelReason->order_id = (int) $request->order_id;
            $cancelReason->ref_id = $user->id;
            $cancelReason->subject = $request->subject;
            $cancelReason->comment = $request->comment;
            $cancelReason->by_user = $by_user;
            $cancelReason->save();

            // event(new CancelOrderRefund($order));
            
        }

        return $this->responser($order,'Order canceled.');
    }

    public function getOrderDetails(Request $request,$id)
    {
        $order = Order::find($id);

        if (empty($order)) {
            return $this->responser([], 'order not found.');
        }

        $ordr = new OrderResource($order);

        return $this->responser($ordr, 'order details.');
    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
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

    public function makePayment(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer ',
            'card_id' => 'required|string'
        ]);

        if($validator->fails()){    
            return $this->responser([],$validator->errors()->first());
        }

        $order = Order::find($request->order_id);

        if (empty($order)) {
            return $this->responser([],'Order not found please check order id.');
        }

        // $diffInHrs = $this->getPendingHoursInOrderD($order);

        $paymentIntent = $this->paymentService->safely(fn () => $this->paymentService->createPaymentIntent($order));

        if (is_object($paymentIntent)) {
            // print_r($paymentIntent); die();
            $payment = new Payment();
            $payment->order_id = $request->order_id;
            $payment->payment_id = $paymentIntent->id;
            $payment->card_id = $request->card_id;
            $payment->amount = $order->total_price;
            $payment->save();
            // $payment->order_id = ;
            // $payment->order_id = ;
            // $payment->order_id = ;
            
        }else{
            return $this->responser([],$paymentIntent);
        }

        // print_r($order); die();
        $order->status = Order::STATUS_REQUESTED;
        $order->paymentmethod_id = $request->card_id;
        $order->save();

        // event(new MakeOrderPayment($order));

        return $this->responser($order,"payment successfully.");


    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {

        $user = Auth::guard('api')->user();
        $order = $this->orderService->createOrder($user, $request->all());
        $createdOrder = new OrderResource(Order::find($order->id));
        return $this->responser($createdOrder, 'Food Ordered Created.');
    }

    public function addOrderData($orderId,$itemsData)
    {

        foreach ($itemsData as $key => $itemData) {
            $orderData = new OrderData;
            $orderData->order_id = $orderId;
            $orderData->food_id = $itemData['id'];
            $orderData->quantity = $itemData['quantity'];
            $orderData->price = $itemData['price'];
            $orderData->save();
        }
        return true;
        // echo $orderId;
        // print_r($itemsData);
        // die();
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Order  $order
     * @return \Illuminate\Http\Response
     */
    public function show(Order $order)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \App\Models\Order  $order
     * @return \Illuminate\Http\Response
     */
    public function edit(Order $order)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Order  $order
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Order $order)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Order  $order
     * @return \Illuminate\Http\Response
     */
    public function destroy(Order $order)
    {
        //
    }
}
