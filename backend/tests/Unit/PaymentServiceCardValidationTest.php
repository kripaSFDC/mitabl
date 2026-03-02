<?php

namespace Tests\Unit;

use App\Models\User;
use App\Services\PaymentService;
use RuntimeException;
use Tests\TestCase;

class PaymentServiceCardValidationTest extends TestCase
{
    public function test_create_and_add_card_requires_payment_method_id_format(): void
    {
        $service = new PaymentService();

        $user = new User();
        $user->setRelation('customer', (object) ['account_id' => 'cus_test_123']);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('A valid Stripe payment_method_id (pm_...) is required.');

        $service->createAndAddCard($user, ['payment_method_id' => 'tok_legacy']);
    }
}
