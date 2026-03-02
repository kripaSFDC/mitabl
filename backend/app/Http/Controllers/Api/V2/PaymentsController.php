<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Models\Card;
use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Http\Request;

class PaymentsController extends Controller
{
    public function __construct(private PaymentService $paymentService)
    {
    }

    public function cards(Request $request)
    {
        $response = $this->paymentService->safely(fn () => $this->paymentService->getAllCards(Auth::user()));
        if (!is_object($response) && !is_array($response)) {
            return $this->responser([], (string) $response, 422);
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

        $stripeCard = $this->paymentService->safely(
            fn () => $this->paymentService->createAndAddCard($user, $request->only('payment_method_id'))
        );
        if (!is_object($stripeCard) || !isset($stripeCard->id)) {
            return $this->responser([], is_string($stripeCard) ? $stripeCard : 'Unable to add card.', 422);
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

        $session = $this->paymentService->safely(fn () => $this->paymentService->createCheckoutSession(Auth::user()));
        if (!is_object($session)) {
            return $this->responser([], (string) $session, 422);
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

        $intent = $this->paymentService->safely(fn () => $this->paymentService->createPaymentIntent($order));
        if (!is_object($intent)) {
            return $this->responser([], (string) $intent, 422);
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

        $intent = $this->paymentService->safely(fn () => $this->paymentService->confirmPaymentIntent($payment));
        if (!is_object($intent)) {
            return $this->responser([], (string) $intent, 422);
        }

        return $this->responser($intent, 'payment intent confirmed.');
    }

    public function vendorTransfer(Request $request)
    {
        if ((int) Auth::user()->role_id !== 2) {
            return $this->responser([], 'Only cook accounts can transfer to vendor.', 403);
        }

        $validator = Validator::make($request->all(), [
            'kitchen_id' => 'required|integer',
            'amount' => 'required|numeric',
            'order_id' => 'required|integer',
            'percent' => 'required|numeric',
            'description' => 'required|string',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $kitchen = Mikitchn::find((int) $request->kitchen_id);
        if (!$kitchen) {
            return $this->responser([], 'Kitchen not found.', 404);
        }
        if ((int) $kitchen->user_id !== (int) Auth::id()) {
            return $this->responser([], 'You are not authorized for this kitchen.', 403);
        }

        $order = Order::find((int) $request->order_id);
        if (!$order || (int) $order->mikitchn_id !== (int) $kitchen->id) {
            return $this->responser([], 'Order does not belong to the provided kitchen.', 422);
        }

        $transfer = $this->paymentService->safely(
            fn () => $this->paymentService->transferToVendor(
                $kitchen,
                (float) $request->amount,
                (int) $request->order_id,
                (float) $request->percent,
                (string) $request->description
            )
        );
        if (!is_object($transfer)) {
            return $this->responser([], (string) $transfer, 422);
        }

        return $this->responser($transfer, 'amount transferred.');
    }
}
