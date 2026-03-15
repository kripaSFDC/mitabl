<?php

namespace App\Http\Controllers\Api\User\Concerns;

use App\Models\Card;
use App\Models\Order;
use App\Models\Payment;
use App\Models\StripeBankAccount;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Throwable;

trait HandlesUserPayments
{
    private function ensureCustomerAccountOrError($user): ?array
    {
        if ($user->customer && $user->customer->account_id) {
            return null;
        }

        $provisionError = $this->accountProfileService->ensureStripeAccountForRole($user, 3);
        if ($provisionError !== null) {
            return ['message' => $provisionError, 'status' => 422];
        }

        $user->unsetRelation('customer');
        $user->load('customer');

        if (! $user->customer || ! $user->customer->account_id) {
            return ['message' => 'Unable to create Stripe account.', 'status' => 422];
        }

        return null;
    }

    public function addCardToCustomer(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_method_id' => 'required|string|starts_with:pm_',
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $user = Auth::user();
        $provisionError = $this->ensureCustomerAccountOrError($user);
        if ($provisionError !== null) {
            return $this->responser([], $provisionError['message'], $provisionError['status']);
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

        return $this->responser($card, 'Card Added successfully.');
    }

    public function completedOnBoarding(Request $request)
    {
        if ((int) Auth::id() <= 0 || (int) Auth::user()->role_id !== 2) {
            return $this->responser([], 'Only cook accounts can complete onboarding.', 403);
        }

        $kitchen = Auth::user()->restaurant;
        if (empty($kitchen)) {
            return $this->responser([], 'This user has not Kitchen', 404);
        }

        $isCompleted = $this->checkaccountComplted();
        if ($isCompleted) {
            $kitchen->status = 1;
            $kitchen->save();
        }

        return $this->responser($kitchen, 'Kitchen stripe on boarding process completed');
    }

    public function addBankAccToVendor(Request $request)
    {
        $validator = \Validator::make($request->all(), [
            'holder_name' => 'required|string|max:100',
            'bsb' => ['required', 'regex:/^[0-9]{6}$/'],
            'number' => ['required', 'regex:/^[0-9]{6,10}$/'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        if (! Auth::user()->vendor) {
            return $this->responser([], "you don't have stripe vendor connected account.", 403);
        }

        try {
            $stripeExternalBank = $this->paymentService->createAndAddBankToVendor(Auth::user(), $request->all());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to add vendor bank account.', 422);
        }

        $userId = Auth::user()->id;
        $bankAccount = new StripeBankAccount();
        $bankAccount->user_id = $userId;
        $bankAccount->stripe_bank_id = $stripeExternalBank->id;

        if ($bankAccount->save()) {
            $kitchen = Auth::user()->restaurant;
            if ($kitchen) {
                $kitchen->status = 1;
                $kitchen->save();
            }
        }

        return $this->responser($bankAccount, 'Bank Account Added successfully.');
    }

    public function getMerchantacc()
    {
        return $this->responser(['client' => get_class($this->paymentService->getMerchantAccountClient())], 'stripe client loaded.');
    }

    public function getAllCards()
    {
        $user = Auth::user();
        $provisionError = $this->ensureCustomerAccountOrError($user);
        if ($provisionError !== null) {
            return $this->responser([], $provisionError['message'], $provisionError['status']);
        }

        try {
            $response = $this->paymentService->getAllCards($user);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to fetch cards.', 422);
        }

        return $this->responser($response, 'customer cards.');
    }

    public function createCheckoutsession()
    {
        $user = Auth::user();
        $provisionError = $this->ensureCustomerAccountOrError($user);
        if ($provisionError !== null) {
            return $this->responser([], $provisionError['message'], $provisionError['status']);
        }

        try {
            $session = $this->paymentService->createCheckoutSession($user);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create checkout session.', 422);
        }

        return $this->responser(['url' => $session->url], 'Add card url session.');
    }

    public function createPaymentIntent(Request $request)
    {
        $user = Auth::user();
        if ((int) $user->role_id !== 3) {
            return $this->responser([], 'Only foodie accounts can create payment intents.', 403);
        }

        $provisionError = $this->ensureCustomerAccountOrError($user);
        if ($provisionError !== null) {
            return $this->responser([], $provisionError['message'], $provisionError['status']);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'card_id' => 'nullable',
            'payment_method_id' => 'nullable|string|starts_with:pm_',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $order = Order::find((int) $request->order_id);
        if (! $order) {
            return $this->responser([], 'Order not found please check order id.', 404);
        }
        if ((int) $order->user_id !== (int) Auth::id()) {
            return $this->responser([], 'You are not authorized for this order.', 403);
        }
        if ((int) $order->paid === 1 || in_array((int) $order->status, [Order::STATUS_CONFIRMED, Order::STATUS_COMPLETED], true)) {
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
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], $throwable->getMessage() ?: 'Unable to create payment intent.', 422);
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

    public function confirmPaymentIntent(Request $request)
    {
        if ((int) Auth::user()->role_id !== 3) {
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

        $payment = Payment::find((int) $request->payment_id);
        if (! $payment) {
            return $this->responser([], 'Payment not found.', 404);
        }
        $order = Order::find($payment->order_id);
        if (! $order || (int) $order->user_id !== (int) Auth::id()) {
            return $this->responser([], 'You are not authorized for this payment.', 403);
        }

        try {
            $selection = $this->paymentService->resolvePaymentMethodForIntent(
                Auth::user(),
                $request->input('card_id'),
                $request->input('payment_method_id')
            );
            if ($selection['payment_method_id'] !== null) {
                $payment->card_id = (string) $selection['payment_method_id'];
                $payment->save();
            }

            $intent = $this->paymentService->confirmPaymentIntent($payment);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], $throwable->getMessage() ?: 'Unable to confirm payment intent.', 422);
        }

        return $this->responser($intent, 'payment intent confirmed.');
    }

    public function transferToVendor(Request $request)
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => 'Forbidden. Manual vendor-transfer operations are restricted to admin automation.',
            'data' => [],
        ], 403);
    }

    public function refundFullAmount(Request $request)
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => 'Forbidden. Manual refunds are restricted to admin identities in the web admin panel.',
            'data' => [],
        ], 403);
    }

    public function retrieveAccount()
    {
        if (! Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $account = $this->paymentService->retrieveAccount(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to retrieve Stripe account details.', 422);
        }

        return $this->responser($account, 'stripe account details.');
    }

    public function getVendorBankAcc()
    {
        if (! Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $account = $this->paymentService->getVendorBankAccount(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to retrieve vendor bank account.', 422);
        }

        return $this->responser($account, 'vendor bank account.');
    }

    public function getBankAccFromConect()
    {
        if (! Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $bankId = $this->paymentService->getBankAccFromConnect(Auth::user());
        } catch (Throwable $th) {
            return $this->responser([], $th->getMessage(), 422);
        }

        if (! $bankId) {
            return $this->responser([], 'vendor bank account not found.', 404);
        }

        return $this->responser(['bank_id' => $bankId], 'vendor bank account.');
    }

    public function checkaccountComplted()
    {
        if (! Auth::user()->vendor) {
            return false;
        }

        try {
            $result = $this->paymentService->isAccountCompleted(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return false;
        }

        return $result;
    }

    public function accountCompletionStatus()
    {
        return $this->responser([
            'completed' => (bool) $this->checkaccountComplted(),
        ], 'vendor account completion status.');
    }

    public function createAccLoginLink()
    {
        if (! Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $link = $this->paymentService->createAccLoginLink(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create account login link.', 422);
        }

        return $this->responser(['url' => $link->url], 'express account login link');
    }

    public function onboardingLink()
    {
        if (! Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $link = $this->paymentService->onboardingLink(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create onboarding link.', 422);
        }

        return $this->responser(['url' => $link->url], 'On boarding Url');
    }

    public function updateConnectedAccount(Request $request)
    {
        if (! Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        $accountId = (string) optional(Auth::user()->vendor)->account_id;
        if ($accountId === '') {
            return $this->responser([], 'account_id is required.', 422);
        }

        $requestedAccountId = trim((string) $request->input('account_id', ''));
        if ($requestedAccountId !== '' && $requestedAccountId !== $accountId) {
            return $this->responser([], 'You are not authorized to update this connected account.', 403);
        }

        try {
            $updated = $this->paymentService->updateConnectedAccount($accountId);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to update connected account.', 422);
        }

        return $this->responser($updated, 'connected account updated.');
    }

    public function topups()
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => 'Forbidden. Top-up operations are restricted to admin identities in the web admin panel.',
            'data' => [],
        ], 403);
    }
}
