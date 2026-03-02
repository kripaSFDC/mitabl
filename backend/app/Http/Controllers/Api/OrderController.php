<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Order\Order as OrderResource;
use App\Models\CompletedOrder;
use App\Models\Order;
use App\Services\OrderService;
use App\Services\PaymentService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Throwable;
use Validator, DB, Auth;

class OrderController extends Controller
{
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
        $limit = max((int) ($queryparams['limit'] ?? 10), 1);
        $currntdate = date('Y-m-d');
        $kitchen = Auth::guard('api')->user()->restaurant;

        if (! $kitchen) {
            $data['total_count'] = 0;
            $data['bookings'] = [];
            return $this->responser($data, 'No Upcoming Bookings');
        }

        $orders = Order::with($this->orderListResourceRelations())
            ->where('mikitchn_id', $kitchen->id)
            ->where('delivery_date', '>=', $currntdate)
            ->where('status', 3);

        if ($request->has('sortby')) {
            if ($request->sortby == 'take_away') {
                $orders->where('take_away', 1);
            } else {
                $orders->where('dine_in', 1);
            }
        }

        $orders = $orders->orderBy('id', 'desc')->paginate($limit);
        $data['total_count'] = $orders->total();
        $data['bookings'] = OrderResource::collection($orders);

        if ($data['total_count'] == 0) {
            return $this->responser($data, 'No Upcoming Bookings');
        }

        return $this->responser($data, 'Upcoming Bookings');
    }

    public function myRequestedOrders(Request $request)
    {
        $queryparams = $request->query();
        $limit = max((int) ($queryparams['limit'] ?? 10), 1);

        if (! Auth::guard('api')->user()->restaurant) {
            $data['total_count'] = 0;
            $data['bookings'] = [];
            return $this->responser($data, 'No Requested Orders');
        }

        $orders = Auth::guard('api')->user()->restaurant->orders()->with($this->orderListResourceRelations())->where('status', 2);
        $ordersPage = $orders->orderBy('id', 'desc')->paginate($limit);
        $ordersPage->getCollection()->makeHidden('orderdata');
        $data = [
            'total_count' => $ordersPage->total(),
            'bookings' => OrderResource::collection($ordersPage),
        ];

        return $this->responser($data, 'restaurant requested orders.');
    }

    public function statusUpdate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => ['required', 'integer'],
            'status' => ['required', 'integer', Rule::in([
                Order::STATUS_LEGACY_CANCELLED,
                Order::STATUS_COMPLETED,
                Order::STATUS_REQUESTED,
                Order::STATUS_CONFIRMED,
                Order::STATUS_CANCELLED,
            ])],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $order = Order::find($request->order_id);
        if (! $order) {
            return $this->responser([], 'Order not found.', 404);
        }
        if (! $this->canManageOrder($order)) {
            return $this->responser([], 'You are not authorized for this order.', 403);
        }

        $requestedStatus = (int) $request->status;
        if ($requestedStatus === Order::STATUS_LEGACY_CANCELLED) {
            $requestedStatus = Order::STATUS_CANCELLED;
        }

        if ($requestedStatus === Order::STATUS_CONFIRMED) {
            if (! $order->payment) {
                return $this->responser([], 'Payment record not found for this order.', 404);
            }
            try {
                $confirmPayment = $this->paymentService->confirmPaymentIntent($order->payment);
                DB::transaction(function () use ($order, $confirmPayment): void {
                    $payment = $order->payment()->lockForUpdate()->firstOrFail();
                    $payment->confirm = 1;
                    $payment->status = (string) ($confirmPayment->status ?? 'succeeded');
                    $payment->confirm_date_time = Carbon::now()->format('Y-m-d H:i:s');
                    $payment->save();

                    $order->paid = 1;
                    $order->status = Order::STATUS_CONFIRMED;
                    $order->save();
                });

                return $this->responser($order->fresh(), 'Order Updated successfully.');
            } catch (Throwable $throwable) {
                report($throwable);
                return $this->responser([], 'Unable to confirm payment intent for this order.', 422);
            }
        } elseif ($requestedStatus === Order::STATUS_COMPLETED) {
            CompletedOrder::query()->updateOrCreate(
                ['order_id' => (int) $request->order_id],
                ['completed_date_time' => Carbon::now()]
            );
        }

        $order->status = $requestedStatus;
        $order->save();

        return $this->responser($order, 'Order Updated successfully.');
    }

    public function allOrders(Request $request)
    {
        $queryparams = $request->query();
        $limit = max((int) ($queryparams['limit'] ?? 10), 1);
        $kitchen = Auth::guard('api')->user()->restaurant;

        if (! $kitchen) {
            $data['total_count'] = 0;
            $data['bookings'] = [];
            return $this->responser($data, 'No Bookings');
        }

        $statusArry = [
            Order::STATUS_LEGACY_CANCELLED,
            Order::STATUS_COMPLETED,
            Order::STATUS_CANCELLED,
        ];
        $orders = Order::with($this->orderListResourceRelations())->where('mikitchn_id', $kitchen->id);
        if ($request->has('sortby')) {
            if ($request->sortby == 'take_away') {
                $orders->where('take_away', 1);
            } else {
                $orders->where('dine_in', 1);
            }
        }

        if ($request->has('status')) {
            $orders->where('status', $request->status);
        } else {
            $orders->whereIn('status', $statusArry);
        }
        $orders = $orders->orderBy('id', 'desc')->paginate($limit);
        $data['total_count'] = $orders->total();
        $data['bookings'] = OrderResource::collection($orders);

        if ($data['total_count'] == 0) {
            return $this->responser($data, 'No Bookings');
        }
        return $this->responser($data, 'All Bookings');
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'kitchen_id' => ['required', 'integer', 'exists:mikitchns,id'],
            'delivery_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:today'],
            'delivery_time_from' => ['required', 'date_format:H:i'],
            'delivery_time_to' => ['required', 'date_format:H:i', 'after:delivery_time_from'],
            'item_total_price' => ['required', 'numeric', 'min:0'],
            'taxes' => ['nullable', 'numeric', 'min:0'],
            'total_price' => ['required', 'numeric', 'min:0'],
            'dine_in' => ['required', 'integer', Rule::in([0, 1])],
            'take_away' => ['required', 'integer', Rule::in([0, 1])],
            'persons' => ['nullable', 'integer', 'min:1'],
            'item_data' => ['required', 'string'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        if ((int) $request->input('dine_in') === 1 && ! $request->filled('persons')) {
            return $this->responser([], 'persons is required for dine-in orders.', 422);
        }

        $user = Auth::guard('api')->user();
        try {
            $order = $this->orderService->createOrder($user, $validator->validated());
        } catch (\InvalidArgumentException $exception) {
            return $this->responser([], $exception->getMessage(), 422);
        }
        $createdOrder = new OrderResource(Order::with($this->orderDetailResourceRelations())->find($order->id));
        return $this->responser($createdOrder, 'Food Ordered Created.');
    }

    private function orderListResourceRelations(): array
    {
        return [
            'orderdata.food',
            'Mikitchn.addedimage',
            'user',
            'promocode',
            'cancelreason.actor.restaurant',
            'review',
            'payment',
        ];
    }

    private function orderDetailResourceRelations(): array
    {
        return [
            'orderdata.food',
            'Mikitchn.addedimage',
            'Mikitchn.reviews',
            'user.reviews',
            'promocode',
            'cancelreason.actor.restaurant',
            'review',
            'payment',
        ];
    }

    private function canManageOrder(Order $order): bool
    {
        $user = Auth::guard('api')->user();
        if (! $user) {
            return false;
        }

        if ((int) $user->id === (int) $order->user_id) {
            return true;
        }

        if ((int) $user->role_id === 2 && $user->restaurant) {
            return (int) $user->restaurant->id === (int) $order->mikitchn_id;
        }

        return false;
    }
}
