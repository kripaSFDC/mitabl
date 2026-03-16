<?php

namespace App\Http\Controllers\Api;

use App\Events\CancelOrderRefund;
use App\Http\Controllers\Controller;
use App\Http\Resources\Order\Order as OrderResource;
use App\Models\CancelReason;
use App\Models\CompletedOrder;
use App\Models\Order;
use App\Models\PromoCode;
use App\Services\AccountProfileService;
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
    private AccountProfileService $accountProfileService;

    public function __construct(
        PaymentService $paymentService,
        OrderService $orderService,
        AccountProfileService $accountProfileService
    )
    {
        $this->paymentService = $paymentService;
        $this->orderService = $orderService;
        $this->accountProfileService = $accountProfileService;
    }

    public function myUpcomingOrders(Request $request)
    {
        $queryparams = $request->query();
        $limit = max((int) ($queryparams['limit'] ?? 10), 1);
        $currntdate = date('Y-m-d');
        $kitchen = $this->authenticatedUser('api')->restaurant;

        if (! $kitchen) {
            $data['total_count'] = 0;
            $data['bookings'] = [];
            return $this->responser($data, 'No Upcoming Bookings');
        }

        $orders = Order::with($this->orderListResourceRelations())
            ->where('mikitchn_id', $kitchen->id)
            ->where('delivery_date', '>=', $currntdate)
            ->whereIn('status', [Order::STATUS_CONFIRMED, Order::STATUS_IN_PROGRESS]);

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

        if (! $this->authenticatedUser('api')->restaurant) {
            $data['total_count'] = 0;
            $data['bookings'] = [];
            return $this->responser($data, 'No Requested Orders');
        }

        $orders = $this->authenticatedUser('api')->restaurant->orders()->with($this->orderListResourceRelations())->where('status', 2);
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
                Order::STATUS_IN_PROGRESS,
            ])],
            'cancel_subject' => ['nullable', 'string', 'max:255'],
            'cancel_comment' => ['nullable', 'string', 'max:255'],
            'cancel_reason' => ['nullable', 'string', 'max:255'],
            'delivery_date' => ['nullable', 'date_format:Y-m-d'],
            'delivery_time_from' => ['nullable', 'date_format:H:i'],
            'delivery_time_to' => ['nullable', 'date_format:H:i'],
            'dine_in_slot_id' => ['nullable', 'integer'],
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
        $actor = $this->authenticatedUser('api');
        $actorIsFoodie = (int) $actor->id === (int) $order->user_id;
        $actorIsCook = (int) $actor->role_id === 2
            && $actor->restaurant
            && (int) $actor->restaurant->id === (int) $order->mikitchn_id;

        if ((int) $order->status === Order::STATUS_COMPLETED && $requestedStatus !== Order::STATUS_COMPLETED) {
            return $this->responser([], 'Completed orders cannot be changed.', 422);
        }

        if (in_array((int) $order->status, Order::cancelledStatuses(), true) && $requestedStatus !== Order::STATUS_CANCELLED) {
            return $this->responser([], 'Cancelled orders cannot be changed.', 422);
        }

        if ($requestedStatus === Order::STATUS_REQUESTED && (int) $order->status !== Order::STATUS_REQUESTED) {
            return $this->responser([], 'Order status cannot be moved back to requested.', 422);
        }

        if ($requestedStatus === Order::STATUS_CONFIRMED) {
            if (! $actorIsCook) {
                return $this->responser([], 'Only the owning miCook can accept this order.', 403);
            }
            if ((int) $order->status !== Order::STATUS_REQUESTED) {
                return $this->responser([], 'Only requested orders can be accepted.', 422);
            }
        }

        $hasAcceptanceWindowOverride = $request->filled('delivery_date')
            || $request->filled('delivery_time_from')
            || $request->filled('delivery_time_to');

        if ($hasAcceptanceWindowOverride && $requestedStatus !== Order::STATUS_CONFIRMED) {
            return $this->responser([], 'Delivery date/time can only be updated when miCook accepts the order.', 422);
        }

        if ($hasAcceptanceWindowOverride && (int) $order->dine_in === 1) {
            return $this->responser([], 'Dine-in orders must keep the originally selected slot and time window.', 422);
        }

        if ($hasAcceptanceWindowOverride) {
            $acceptanceWindowValidator = Validator::make($request->all(), [
                'delivery_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:today'],
                'delivery_time_from' => ['required', 'date_format:H:i'],
                'delivery_time_to' => ['required', 'date_format:H:i', 'after:delivery_time_from'],
            ]);

            if ($acceptanceWindowValidator->fails()) {
                return $this->responser([], $acceptanceWindowValidator->errors()->first(), 422);
            }
        }

        if ($requestedStatus === Order::STATUS_COMPLETED) {
            if (! $actorIsCook) {
                return $this->responser([], 'Only the owning miCook can complete this order.', 403);
            }
            if (! in_array((int) $order->status, [Order::STATUS_CONFIRMED, Order::STATUS_IN_PROGRESS], true)) {
                return $this->responser([], 'Only confirmed or in-progress orders can be completed.', 422);
            }
        }

        if ($requestedStatus === Order::STATUS_IN_PROGRESS) {
            if (! $actorIsCook) {
                return $this->responser([], 'Only the owning miCook can mark this order in progress.', 403);
            }
            if ((int) $order->status !== Order::STATUS_CONFIRMED) {
                return $this->responser([], 'Only confirmed orders can be moved to in progress.', 422);
            }
        }

        if ($requestedStatus === Order::STATUS_CANCELLED) {
            $cancelComment = trim((string) $request->input('cancel_comment', $request->input('cancel_reason', '')));
            $cancelSubject = trim((string) $request->input('cancel_subject', ''));

            if ($cancelComment === '') {
                return $this->responser([], 'cancel_comment is required when cancelling an order.', 422);
            }

            if ($actorIsFoodie && (int) $order->status !== Order::STATUS_REQUESTED) {
                return $this->responser([], 'miFoodi can only cancel an order before it is accepted by miCook.', 422);
            }

            if ($cancelSubject === '') {
                $cancelSubject = $actorIsFoodie ? 'Cancelled by mifoodi' : 'Cancelled by micook';
            }

            DB::transaction(function () use ($order, $requestedStatus, $actor, $actorIsFoodie, $cancelSubject, $cancelComment): void {
                CancelReason::query()->updateOrCreate(
                    ['order_id' => $order->id],
                    [
                        'ref_id' => $actor->id,
                        'subject' => $cancelSubject,
                        'comment' => $cancelComment,
                        'by_user' => $actorIsFoodie ? 'customer' : 'mikitchen',
                    ]
                );

                $order->status = $requestedStatus;
                $order->save();
            });

            CancelOrderRefund::dispatch(
                $order->fresh($this->orderDetailResourceRelations()),
                $actorIsFoodie ? 'customer' : 'kitchen'
            );

            return $this->responser(
                new OrderResource($order->fresh($this->orderDetailResourceRelations())),
                'Order Updated successfully.'
            );
        }

        if ($requestedStatus === Order::STATUS_CONFIRMED) {
            try {
                $payment = $this->resolvePaymentForAcceptance($order);
                $paymentAlreadyConfirmed = (bool) $payment->confirm
                    || in_array(trim((string) $payment->status), ['succeeded', 'processing', 'requires_capture'], true);
                $confirmPayment = $paymentAlreadyConfirmed
                    ? (object) ['status' => $payment->status ?: 'succeeded']
                    : $this->paymentService->confirmPaymentIntent($payment);
                DB::transaction(function () use ($order, $confirmPayment, $hasAcceptanceWindowOverride, $request): void {
                    $payment = $order->payment()->lockForUpdate()->firstOrFail();
                    $payment->confirm = 1;
                    $payment->status = (string) ($confirmPayment->status ?? 'succeeded');
                    $payment->confirm_date_time = Carbon::now()->format('Y-m-d H:i:s');
                    $payment->save();

                    if ($hasAcceptanceWindowOverride) {
                        $order->delivery_date = $request->input('delivery_date');
                        $order->delivery_time_from = Carbon::parse((string) $request->input('delivery_time_from'))->format('H:i:s');
                        $order->delivery_time_to = Carbon::parse((string) $request->input('delivery_time_to'))->format('H:i:s');
                    }

                    $order->paid = 1;
                    $order->status = Order::STATUS_CONFIRMED;
                    $order->save();
                });

                return $this->responser(
                    new OrderResource($order->fresh($this->orderDetailResourceRelations())),
                    'Order Updated successfully.'
                );
            } catch (Throwable $throwable) {
                report($throwable);
                return $this->responser([], $throwable->getMessage() ?: 'Unable to confirm payment intent for this order.', 422);
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
        $kitchen = $this->authenticatedUser('api')->restaurant;

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
            'delivery_time_from' => ['nullable', 'date_format:H:i'],
            'delivery_time_to' => ['nullable', 'date_format:H:i', 'after:delivery_time_from'],
            'item_total_price' => ['nullable', 'numeric', 'min:0'],
            'taxes' => ['nullable', 'numeric', 'min:0'],
            'total_price' => ['nullable', 'numeric', 'min:0'],
            'dine_in' => ['required', 'integer', Rule::in([0, 1])],
            'take_away' => ['required', 'integer', Rule::in([0, 1])],
            'persons' => ['nullable', 'integer', 'min:1'],
            'dine_in_slot_id' => ['nullable', 'integer', 'exists:dine_in_slots,id'],
            'item_data' => ['required', 'string'],
            'promo_code' => ['nullable', 'integer', 'exists:promo_codes,id'],
            'card_id' => ['nullable'],
            'payment_method_id' => ['nullable', 'string', 'starts_with:pm_'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        if (((int) $request->input('dine_in')) + ((int) $request->input('take_away')) !== 1) {
            return $this->responser([], 'Exactly one of dine_in or take_away must be selected.', 422);
        }

        if ((int) $request->input('dine_in') === 1 && ! $request->filled('persons')) {
            return $this->responser([], 'persons is required for dine-in orders.', 422);
        }

        if ((int) $request->input('dine_in') === 1 && ! $request->filled('dine_in_slot_id')) {
            return $this->responser([], 'dine_in_slot_id is required for dine-in orders.', 422);
        }

        if ((int) $request->input('dine_in') === 0 && $request->filled('dine_in_slot_id')) {
            return $this->responser([], 'dine_in_slot_id can only be used for dine-in orders.', 422);
        }

        if ((int) $request->input('take_away') === 1 && (! $request->filled('delivery_time_from') || ! $request->filled('delivery_time_to'))) {
            return $this->responser([], 'delivery_time_from and delivery_time_to are required for take-away orders.', 422);
        }

        if ($request->filled('promo_code')) {
            $promoCode = PromoCode::query()
                ->where('id', (int) $request->input('promo_code'))
                ->where('status', 1)
                ->first();

            $invalidWindow = false;
            if ($promoCode instanceof PromoCode) {
                $invalidWindow = ($promoCode->starts_at && now()->lt($promoCode->starts_at))
                    || ($promoCode->ends_at && now()->gt($promoCode->ends_at));
            }

            if (! ($promoCode instanceof PromoCode) || $invalidWindow) {
                return $this->responser([], 'Promo code is invalid, inactive, or expired', 422);
            }
        }

        $user = $this->authenticatedUser('api');
        try {
            $validated = $validator->validated();
            $cardReference = $validated['card_id'] ?? null;
            $paymentMethodId = $validated['payment_method_id'] ?? null;
            $shouldInitializePayment = trim((string) $cardReference) !== ''
                || trim((string) $paymentMethodId) !== '';

            if ($shouldInitializePayment) {
                $provisionError = $this->accountProfileService->ensureStripeAccountForRole($user, 3);
                if ($provisionError !== null) {
                    return $this->responser([], $provisionError, 422);
                }

                $user->unsetRelation('customer');
                $user->load('customer');
            }

            $order = DB::transaction(function () use ($user, $validated, $shouldInitializePayment, $cardReference, $paymentMethodId): Order {
                $order = $this->orderService->createOrder($user, $validated);

                if ($shouldInitializePayment) {
                    $result = $this->paymentService->initializeOrderPaymentIntent(
                        $order,
                        $user,
                        $cardReference,
                        $paymentMethodId
                    );

                    $order->paymentmethod_id = $result['selection']['payment_method_id']
                        ?? $paymentMethodId
                        ?? $cardReference;
                    $order->save();
                }

                return $order;
            });
        } catch (\InvalidArgumentException $exception) {
            return $this->responser([], $exception->getMessage(), 422);
        } catch (\RuntimeException $exception) {
            return $this->responser([], $exception->getMessage(), 422);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create order.', 422);
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
            'dineInSlot',
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
            'dineInSlot',
        ];
    }

    private function canManageOrder(Order $order): bool
    {
        $user = $this->authenticatedUser('api');
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

    private function resolvePaymentForAcceptance(Order $order)
    {
        $order->loadMissing(['payment', 'user.customer']);

        $payment = $order->payment;
        $paymentNeedsInitialization = ! $payment
            || trim((string) $payment->payment_id) === ''
            || trim((string) $payment->card_id) === ''
            || trim((string) $payment->status) === 'canceled';

        if (! $paymentNeedsInitialization) {
            return $payment;
        }

        $paymentReference = trim((string) $order->paymentmethod_id);
        if ($paymentReference === '') {
            throw new \RuntimeException('Payment intent has not been initialized for this order. miFoodi must select a payment method before miCook can accept.');
        }

        $orderUser = $order->user;
        if (! $orderUser) {
            throw new \RuntimeException('Order owner not found for payment confirmation.');
        }

        $provisionError = $this->accountProfileService->ensureStripeAccountForRole($orderUser, 3);
        if ($provisionError !== null) {
            throw new \RuntimeException($provisionError);
        }

        $orderUser->unsetRelation('customer');
        $orderUser->load('customer');

        $result = $this->paymentService->initializeOrderPaymentIntent(
            $order,
            $orderUser,
            str_starts_with($paymentReference, 'pm_') ? null : $paymentReference,
            str_starts_with($paymentReference, 'pm_') ? $paymentReference : null
        );

        return $result['payment'];
    }
}
