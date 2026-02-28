<?php

namespace Tests\Feature;

use Tests\TestCase;

class PhaseTwoActionContractTest extends TestCase
{
    public function test_certificate_review_actions_have_concurrency_and_rejection_guardrails(): void
    {
        $certificateResource = (string) file_get_contents(app_path('Filament/Resources/CertificateResource.php'));

        $this->assertStringContainsString("Action::make('approve')", $certificateResource);
        $this->assertStringContainsString("Action::make('reject')", $certificateResource);
        $this->assertStringContainsString('lockForUpdate()', $certificateResource);
        $this->assertStringContainsString("Forms\\Components\\Textarea::make('rejection_reason')", $certificateResource);
        $this->assertStringContainsString("->required()", $certificateResource);
        $this->assertStringContainsString("SendCertificateReviewOutcomeJob::dispatch", $certificateResource);
        $this->assertStringContainsString('hasValidCertificateDocument', $certificateResource);
        $this->assertStringContainsString('isReviewSnapshotCurrent', $certificateResource);
        $this->assertStringContainsString('afterCommit()', $certificateResource);
    }

    public function test_order_admin_actions_are_idempotent_and_permission_gated(): void
    {
        $orderResource = (string) file_get_contents(app_path('Filament/Resources/OrderResource.php'));

        $this->assertStringContainsString("Action::make('override_status')", $orderResource);
        $this->assertStringContainsString("Action::make('refund_full')", $orderResource);
        $this->assertStringContainsString('AdminPaymentRefundService::class', $orderResource);
        $this->assertStringContainsString('canOverrideStatus()', $orderResource);
        $this->assertStringContainsString('canRefundOrder()', $orderResource);
        $this->assertStringContainsString('isFullyRefunded', $orderResource);
        $this->assertStringContainsString('Refund::query()', $orderResource);
        $this->assertStringContainsString('Order payment record is missing.', $orderResource);
        $this->assertStringContainsString("Order::STATUS_CANCELLED => 'Cancelled'", $orderResource);
        $this->assertStringContainsString("Order::STATUS_LEGACY_CANCELLED => 'Cancelled (legacy: 0)'", $orderResource);
        $this->assertStringContainsString('renderTimeline', $orderResource);
    }

    public function test_user_and_kitchen_admin_actions_have_required_safety_checks(): void
    {
        $userResource = (string) file_get_contents(app_path('Filament/Resources/UserResource.php'));
        $kitchenResource = (string) file_get_contents(app_path('Filament/Resources/MikitchnResource.php'));

        $this->assertStringContainsString("Action::make('suspend')", $userResource);
        $this->assertStringContainsString("Action::make('unsuspend')", $userResource);
        $this->assertStringContainsString('Super admin accounts cannot be suspended.', $userResource);
        $this->assertStringContainsString("Unsuspension reason", $userResource);
        $this->assertStringContainsString('lockForUpdate()', $userResource);
        $this->assertStringContainsString('$user->suspended_by = null;', $userResource);

        $this->assertStringContainsString("Action::make('activate')", $kitchenResource);
        $this->assertStringContainsString("Action::make('deactivate')", $kitchenResource);
        $this->assertStringContainsString("Action::make('view_profile')", $kitchenResource);
        $this->assertStringContainsString('approved certificate', $kitchenResource);
        $this->assertStringContainsString('open upcoming bookings', $kitchenResource);
        $this->assertStringContainsString('hasValidKitchenLocation', $kitchenResource);
        $this->assertStringContainsString('lockForUpdate()', $kitchenResource);
        $this->assertStringContainsString('Order::STATUS_REQUESTED', $kitchenResource);
        $this->assertStringContainsString('Order::STATUS_CONFIRMED', $kitchenResource);
    }

    public function test_promo_code_actions_are_stateful_and_delete_is_disabled(): void
    {
        $promoResource = (string) file_get_contents(app_path('Filament/Resources/PromoCodeResource.php'));

        $this->assertStringContainsString("Action::make('deactivate')", $promoResource);
        $this->assertStringContainsString("Action::make('activate')", $promoResource);
        $this->assertStringContainsString('public static function canDelete($record): bool', $promoResource);
        $this->assertStringContainsString('return false;', $promoResource);
        $this->assertStringContainsString('lockForUpdate()', $promoResource);
    }
}
