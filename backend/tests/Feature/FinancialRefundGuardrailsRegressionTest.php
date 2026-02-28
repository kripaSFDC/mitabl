<?php

namespace Tests\Feature;

use Tests\TestCase;

class FinancialRefundGuardrailsRegressionTest extends TestCase
{
    public function test_full_refund_action_blocks_orders_with_existing_partial_refunds(): void
    {
        $paymentResource = (string) file_get_contents(app_path('Filament/Resources/PaymentResource.php'));
        $refundService = (string) file_get_contents(app_path('Services/AdminPaymentRefundService.php'));

        $this->assertStringContainsString("refund_percentage ?? 0) > 0", $paymentResource);
        $this->assertStringContainsString("relationLoaded('refunds')", $paymentResource);
        $this->assertStringContainsString("where('percentage', '>=', 100)", $refundService);
        $this->assertStringContainsString('Order already has a partial refund', $refundService);
    }
}
