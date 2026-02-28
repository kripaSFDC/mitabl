<?php

namespace Tests\Unit;

use App\Services\PaymentService;
use RuntimeException;
use Tests\TestCase;

class PaymentServiceConfigurationTest extends TestCase
{
    public function test_service_boots_without_stripe_key_until_stripe_operation_is_invoked(): void
    {
        config(['stripe.api_keys.secret_key' => '']);

        $service = new PaymentService();

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Stripe secret key is not configured.');

        $service->getMerchantAccountClient();
    }
}
