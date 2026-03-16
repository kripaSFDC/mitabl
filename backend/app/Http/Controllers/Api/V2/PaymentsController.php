<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Models\Card;
use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use App\Services\AccountProfileService;
use App\Services\PaymentService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\View\View;
use Throwable;

class PaymentsController extends Controller
{
    public function __construct(
        private PaymentService $paymentService,
        private AccountProfileService $accountProfileService
    )
    {
    }

    public function paymentMethodForm(Request $request): View
    {
        $validator = Validator::make($request->query(), [
            'mode' => 'required|string|in:one_time',
            'return_url' => 'required|url',
        ]);

        abort_if($validator->fails(), 422, $validator->errors()->first());
        abort_unless($this->isAllowedPaymentMethodReturnUrl((string) $request->query('return_url')), 422, 'return_url is not allowed.');

        return view('stripe-payment-method', [
            'mode' => (string) $request->query('mode'),
            'returnUrl' => (string) $request->query('return_url'),
            'publishableKey' => (string) config('stripe.api_keys.publishable_key', ''),
        ]);
    }

    private function ensureCustomerAccount(User $user): ?string
    {
        if ($user->customer && $user->customer->account_id) {
            return null;
        }

        $provisionError = $this->accountProfileService->ensureStripeAccountForRole($user, 3);
        if ($provisionError !== null) {
            return $provisionError;
        }

        $user->unsetRelation('customer');
        $user->load('customer');

        if (! $user->customer || ! $user->customer->account_id) {
            return 'Unable to create Stripe account.';
        }

        return null;
    }

    public function cards(Request $request)
    {
        $user = $this->authenticatedUser();
        $provisionError = $this->ensureCustomerAccount($user);
        if ($provisionError !== null) {
            return $this->responser([], $provisionError, 422);
        }

        try {
            $response = $this->paymentService->getAllCards($user);
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

        $user = $this->authenticatedUser();
        $provisionError = $this->ensureCustomerAccount($user);
        if ($provisionError !== null) {
            return $this->responser([], $provisionError, 422);
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
        $user = $this->authenticatedUser();
        $provisionError = $this->ensureCustomerAccount($user);
        if ($provisionError !== null) {
            return $this->responser([], $provisionError, 422);
        }

        try {
            $session = $this->paymentService->createCheckoutSession($user);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create checkout session.', 422);
        }

        return $this->responser(['url' => $session->url], 'Add card url session.');
    }

    public function createIntent(Request $request)
    {
        $user = $this->authenticatedUser();
        if ((int) $user->role_id !== 3) {
            return $this->responser([], 'Only foodie accounts can create payment intents.', 403);
        }

        $provisionError = $this->ensureCustomerAccount($user);
        if ($provisionError !== null) {
            return $this->responser([], $provisionError, 422);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'card_id' => 'nullable',
            'payment_method_id' => 'nullable|string|starts_with:pm_',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        if ($request->filled('card_id') && $request->filled('payment_method_id')) {
            return $this->responser([], 'Provide either card_id or payment_method_id, not both.', 422);
        }

        $order = Order::find((int) $request->order_id);
        if (!$order) {
            return $this->responser([], 'Order not found please check order id.', 404);
        }
        if ((int) $order->user_id !== (int) Auth::id()) {
            return $this->responser([], 'You are not authorized for this order.', 403);
        }
        if ((int) $order->paid === 1 || in_array((int) $order->status, [Order::STATUS_CONFIRMED, Order::STATUS_IN_PROGRESS, Order::STATUS_COMPLETED], true)) {
            return $this->responser([], 'This order already has a finalized payment.', 422);
        }

        try {
            $result = $this->paymentService->initializeOrderPaymentIntent(
                $order,
                $user,
                $request->input('card_id'),
                $request->input('payment_method_id')
            );
            $payment = $result['payment'];
            $selection = $result['selection'];
            $order->paymentmethod_id = $selection['payment_method_id']
                ?? $request->input('payment_method_id')
                ?? $request->input('card_id');
            $order->save();
        } catch (Throwable $throwable) {
            report($throwable);
            $message = $throwable instanceof \RuntimeException
                ? $throwable->getMessage()
                : 'Unable to create payment intent.';
            return $this->responser([], $message, 422);
        }

        return $this->responser([
            'payment_id' => $payment->id,
            'order_id' => $order->id,
            'payment_intent_id' => $payment->payment_id,
            'payment_method_id' => $payment->card_id,
            'selection_mode' => $selection['mode'],
            'status' => $payment->status,
        ], 'payment intent created.');
    }

    public function confirmIntent(Request $request)
    {
        if ((int) $this->authenticatedUser()->role_id !== 3) {
            return $this->responser([], 'Only foodie accounts can confirm payment intents.', 403);
        }

        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|integer',
            'card_id' => 'nullable',
            'payment_method_id' => 'nullable|string|starts_with:pm_',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        if ($request->filled('card_id') && $request->filled('payment_method_id')) {
            return $this->responser([], 'Provide either card_id or payment_method_id, not both.', 422);
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
            $selection = $this->paymentService->resolvePaymentMethodForIntent(
                $this->authenticatedUser(),
                $request->input('card_id'),
                $request->input('payment_method_id')
            );
            if ($selection['payment_method_id'] !== null) {
                $payment->card_id = (string) $selection['payment_method_id'];
                $payment->save();
            }
            $order->paymentmethod_id = $selection['payment_method_id']
                ?? $request->input('payment_method_id')
                ?? $request->input('card_id');
            $order->save();

            $intent = $this->paymentService->confirmPaymentIntent($payment);
        } catch (Throwable $throwable) {
            report($throwable);
            $message = $throwable instanceof \RuntimeException
                ? $throwable->getMessage()
                : 'Unable to confirm payment intent.';
            return $this->responser([], $message, 422);
        }

        return $this->responser($intent, 'payment intent confirmed.');
    }

    private function isAllowedPaymentMethodReturnUrl(string $returnUrl): bool
    {
        $parsedReturnUrl = parse_url($returnUrl);
        if (! is_array($parsedReturnUrl)) {
            return false;
        }

        $scheme = Str::lower((string) ($parsedReturnUrl['scheme'] ?? ''));
        $host = Str::lower((string) ($parsedReturnUrl['host'] ?? ''));
        $path = (string) ($parsedReturnUrl['path'] ?? '');

        if ($scheme === 'mitabl' && $host === 'payment-method-complete') {
            return true;
        }

        $appUrl = (string) config('app.url', '');
        if ($appUrl === '') {
            return false;
        }

        $parsedAppUrl = parse_url($appUrl);
        if (! is_array($parsedAppUrl)) {
            return false;
        }

        return $scheme === Str::lower((string) ($parsedAppUrl['scheme'] ?? ''))
            && $host === Str::lower((string) ($parsedAppUrl['host'] ?? ''))
            && $path !== '';
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
