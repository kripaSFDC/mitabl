<?php

namespace App\Http\Controllers\Api\User\Concerns;

use App\Models\StripeBankAccount;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Throwable;

trait HandlesUserPayments
{
    public function addCardToCustomer(Request $request)
    {
        return $this->v2PaymentsController->addCard($request);
    }

    public function completedOnBoarding(Request $request)
    {
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
            'holder_name' => 'required',
            'bsb' => 'required',
            'number' => 'required',
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
        return $this->v2PaymentsController->cards(request());
    }

    public function createCheckoutsession()
    {
        return $this->v2PaymentsController->checkoutSession(request());
    }

    public function createPaymentIntent(Request $request)
    {
        return $this->v2PaymentsController->createIntent($request);
    }

    public function confirmPaymentIntent(Request $request)
    {
        return $this->v2PaymentsController->confirmIntent($request);
    }

    public function transferToVendor(Request $request)
    {
        return $this->v2PaymentsController->vendorTransfer($request);
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
