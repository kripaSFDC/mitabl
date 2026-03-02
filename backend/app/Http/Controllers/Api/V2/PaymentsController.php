<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Models\Card;
use App\Models\Order;
use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Http\Request;
use Throwable;

class PaymentsController extends Controller
{
    public function __construct(private PaymentService $paymentService)
    {
    }

    public function cards(Request $request)
    {
        try {
            $response = $this->paymentService->getAllCards(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to fetch cards.', 422);
        }

        return $this->responser($response, 'customer cards.');
    }

    public function addCard(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_method_id' => 'required|string|starts_with:pm_',
        ]);

        if($validator->fails()){    
            return $this->responser([],$validator->errors()->first(), 422);
        }

        $user = Auth::user();
        if (! $user->customer) {
            return $this->responser([],"you don't have stripe customer account.", 403);
        }

        try {
            $stripeCard = $this->paymentService->createAndAddCard($user, $request->only('payment_method_id'));
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to add card.', 422);
        }

        $card = Card::query()->firstOrCreate([
            'user_id' => $user->id,
            'stripe_card_id' => $stripeCard->id,
        ]);

        return $this->responser($card,'Card Added successfully.');
    }

    public function checkoutSession(Request $request)
    {
        if (!Auth::user()->customer) {
            return $this->responser([], 'This user has not stripe customer account.', 403);
        }

        try {
            $session = $this->paymentService->createCheckoutSession(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create checkout session.', 422);
        }

        return $this->responser(['url' => $session->url], 'Add card url session.');
    }

    public function createIntent(Request $request)
    {
        if ((int) Auth::user()->role_id !== 3) {
            return $this->responser([], 'Only foodie accounts can create payment intents.', 403);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $order = Order::find((int) $request->order_id);
        if (!$order) {
            return $this->responser([], 'Order not found please check order id.', 404);
        }
        if ((int) $order->user_id !== (int) Auth::id()) {
            return $this->responser([], 'You are not authorized for this order.', 403);
        }

        try {
            $intent = $this->paymentService->createPaymentIntent($order);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create payment intent.', 422);
        }

        return $this->responser($intent, 'payment intent created.');
    }

    public function confirmIntent(Request $request)
    {
        if ((int) Auth::user()->role_id !== 3) {
            return $this->responser([], 'Only foodie accounts can confirm payment intents.', 403);
        }

        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|integer',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $payment = Payment::find((int) $request->payment_id);
        if (!$payment) {
            return $this->responser([], 'Payment not found.', 404);
        }
        $order = Order::find($payment->order_id);
        if (!$order || (int) $order->user_id !== (int) Auth::id()) {
            return $this->responser([], 'You are not authorized for this payment.', 403);
        }

        try {
            $intent = $this->paymentService->confirmPaymentIntent($payment);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to confirm payment intent.', 422);
        }

        return $this->responser($intent, 'payment intent confirmed.');
    }

    public function vendorTransfer(Request $request)
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => 'Forbidden. Manual vendor-transfer operations are restricted to admin automation.',
            'data' => [],
        ], 403);
    }
}
