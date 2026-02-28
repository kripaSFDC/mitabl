<?php

namespace App\Services;

use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use RuntimeException;
use Stripe\Stripe as StripeBase;
use Stripe\StripeClient;
use Throwable;

class PaymentService
{
    private ?StripeClient $stripe = null;

    private string $secretKey;

    public function __construct()
    {
        $this->secretKey = trim((string) config('stripe.api_keys.secret_key'));
    }

    public function getMerchantAccountClient(): StripeClient
    {
        return $this->stripe();
    }

    public function createCustomer(array $data)
    {
        return $this->stripe()->customers->create([
            'name' => $data['name'],
            'email' => $data['email'],
            'description' => 'mitabl customer',
        ]);
    }

    public function getAllCards(User $user)
    {
        if (! $user->customer || ! $user->customer->account_id) {
            return [];
        }

        return $this->stripe()->customers->allPaymentMethods($user->customer->account_id, ['type' => 'card']);
    }

    public function createCheckoutSession(User $user)
    {
        if (! $user->customer || ! $user->customer->account_id) {
            throw new RuntimeException('Customer Stripe account not found.');
        }

        return $this->stripe()->checkout->sessions->create([
            'success_url' => config('app.url') . '/?success=true',
            'cancel_url' => config('app.url') . '/',
            'payment_method_types' => ['card'],
            'mode' => 'setup',
            'customer' => $user->customer->account_id,
        ]);
    }

    public function createAndAddCard(User $user, array $data)
    {
        if (! $user->customer || ! $user->customer->account_id) {
            throw new RuntimeException('Customer Stripe account not found.');
        }

        $expDate = explode('/', $data['exp_date']);

        $card = $this->stripe()->paymentMethods->create([
            'type' => 'card',
            'card' => [
                'number' => $data['card_number'],
                'exp_month' => $expDate[0] ?? null,
                'exp_year' => $expDate[1] ?? null,
                'cvc' => $data['cvc'],
            ],
        ]);

        return $this->stripe()->paymentMethods->attach($card->id, ['customer' => $user->customer->account_id]);
    }

    public function createVendor(User $user)
    {
        return $this->stripe()->accounts->create([
            'type' => 'express',
            'country' => 'AU',
            'email' => $user->email,
            'capabilities' => [
                'card_payments' => ['requested' => true],
                'transfers' => ['requested' => true],
            ],
            'business_type' => 'individual',
            'business_profile' => [
                'mcc' => 5814,
                'url' => config('app.url'),
            ],
            'individual' => [
                'email' => $user->email,
                'first_name' => $user->first_name,
                'last_name' => $user->last_name,
            ],
        ]);
    }

    public function createAndAddBankToVendor(User $user, array $data)
    {
        if (! $user->vendor || ! $user->vendor->account_id) {
            throw new RuntimeException('Vendor Stripe account not found.');
        }

        return $this->stripe()->accounts->createExternalAccount(
            $user->vendor->account_id,
            [
                'external_account' => [
                    'object' => 'bank_account',
                    'country' => 'AU',
                    'currency' => 'aud',
                    'account_holder_name' => $data['holder_name'],
                    'routing_number' => $data['bsb'],
                    'account_number' => $data['number'],
                ],
            ]
        );
    }

    public function createPaymentIntent(Order $order)
    {
        $customerId = optional(optional(User::find($order->user_id))->customer)->account_id;
        if (! $customerId) {
            throw new RuntimeException('Order customer Stripe account not found.');
        }

        return $this->stripe()->paymentIntents->create([
            'amount' => (int) round(((float) $order->total_price) * 100),
            'currency' => 'aud',
            'payment_method_types' => ['card'],
            'customer' => $customerId,
            'capture_method' => 'automatic',
            'payment_method_options' => [
                'card' => [
                    'request_three_d_secure' => 'automatic',
                ],
            ],
        ]);
    }

    public function confirmPaymentIntent(Payment $payment)
    {
        return $this->stripe()->paymentIntents->confirm($payment->payment_id, ['payment_method' => $payment->card_id]);
    }

    public function updateConnectedAccount(string $accountId)
    {
        return $this->stripe()->accounts->update($accountId, [
            'business_profile' => ['mcc' => 5814],
        ]);
    }

    public function refundAmount(string $intentId, float $amount, float $percent, ?string $idempotencyKey = null)
    {
        $percentInDecimal = $percent / 100;
        $transferAmount = $amount - ($percentInDecimal * $amount);
        $amountInCents = (int) round(max($transferAmount, 0) * 100);

        $params = [
            'payment_intent' => $intentId,
            'amount' => $amountInCents,
        ];

        if ($idempotencyKey) {
            return $this->stripe()->refunds->create($params, ['idempotency_key' => $idempotencyKey]);
        }

        return $this->stripe()->refunds->create($params);
    }

    public function getVendorLifetimeAmount(User $user)
    {
        if (! $user->vendor || ! $user->vendor->account_id) {
            throw new RuntimeException('Vendor Stripe account not found.');
        }

        return $this->stripe()->transfers->all(['destination' => $user->vendor->account_id]);
    }

    public function retrieveAccount(User $user)
    {
        if (! $user->vendor || ! $user->vendor->account_id) {
            throw new RuntimeException('Vendor Stripe account not found.');
        }

        return $this->stripe()->accounts->retrieve($user->vendor->account_id, []);
    }

    public function getVendorBankAccount(User $user)
    {
        $account = $this->retrieveAccount($user);

        return $this->stripe()->accounts->retrieveExternalAccount(
            $account->id,
            $account->external_accounts->data[0]->id,
            []
        );
    }

    public function getBankAccFromConnect(User $user): ?string
    {
        $account = $this->retrieveAccount($user);

        return $account->external_accounts->data[0]->id ?? null;
    }

    public function isAccountCompleted(User $user): bool
    {
        $account = $this->retrieveAccount($user);

        return (bool) ($account->payouts_enabled && $account->charges_enabled);
    }

    public function createAccLoginLink(User $user)
    {
        $account = $this->retrieveAccount($user);

        return $this->stripe()->accounts->createLoginLink($account->id, []);
    }

    public function transferToVendor(Mikitchn $vendor, float $totalAmount, int $orderId, float $percentToGet, string $description)
    {
        $accountId = optional(optional($vendor->user)->vendor)->account_id;
        if (! $accountId) {
            throw new RuntimeException('Vendor Stripe account not found.');
        }
        $percentInDecimal = $percentToGet / 100;
        $transferAmount = $totalAmount - ($percentInDecimal * $totalAmount);
        $amountInCents = (int) round(max($transferAmount, 0) * 100);

        return $this->stripe()->transfers->create([
            'amount' => $amountInCents,
            'currency' => 'aud',
            'destination' => $accountId,
            'transfer_group' => 'ORDER_' . $orderId,
            'description' => $description,
        ]);
    }

    public function topups()
    {
        return $this->stripe()->topups->create([
            'amount' => 2000,
            'currency' => 'aud',
            'description' => 'Top-up for operations',
            'statement_descriptor' => 'Weekly top-up',
        ]);
    }

    public function onboardingLink(User $user)
    {
        return $this->stripe()->accountLinks->create([
            'account' => $user->vendor->account_id,
            'refresh_url' => config('app.url') . '/',
            'return_url' => config('app.url') . '/?success=true',
            'type' => 'account_onboarding',
        ]);
    }

    public function safely(callable $callback)
    {
        try {
            return $callback();
        } catch (Throwable $exception) {
            return $exception->getMessage();
        }
    }

    private function stripe(): StripeClient
    {
        if ($this->stripe instanceof StripeClient) {
            return $this->stripe;
        }

        if ($this->secretKey === '') {
            throw new RuntimeException('Stripe secret key is not configured.');
        }

        $this->stripe = new StripeClient($this->secretKey);
        StripeBase::setApiKey($this->secretKey);

        return $this->stripe;
    }
}
