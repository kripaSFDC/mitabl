<?php

namespace Tests\Feature;

use Tests\TestCase;

class ModuleEightNineTenContractTest extends TestCase
{
    public function test_module_eight_promo_code_management_includes_usage_history_and_overlap_guardrails(): void
    {
        $resource = (string) file_get_contents(app_path('Filament/Resources/PromoCodeResource.php'));
        $createPage = (string) file_get_contents(app_path('Filament/Resources/PromoCodeResource/Pages/CreatePromoCode.php'));
        $editPage = (string) file_get_contents(app_path('Filament/Resources/PromoCodeResource/Pages/EditPromoCode.php'));
        $orderController = (string) file_get_contents(app_path('Http/Controllers/Api/OrderController.php'));

        $this->assertStringContainsString("Action::make('usage_history')", $resource);
        $this->assertStringContainsString('starts_at', $resource);
        $this->assertStringContainsString('ends_at', $resource);
        $this->assertStringContainsString('validatePromoCodeWindow', $resource);
        $this->assertStringContainsString('windowsOverlap', $resource);
        $this->assertStringContainsString('validatePromoCodeWindow', $createPage);
        $this->assertStringContainsString('validatePromoCodeWindow', $editPage);
        $this->assertStringContainsString("where('status', 1)", $orderController);
        $this->assertStringContainsString('Promo code is invalid, inactive, or expired', $orderController);
    }

    public function test_module_nine_financial_overview_includes_links_stripe_and_controlled_refund_path(): void
    {
        $paymentResource = (string) file_get_contents(app_path('Filament/Resources/PaymentResource.php'));
        $refundService = (string) file_get_contents(app_path('Services/AdminPaymentRefundService.php'));
        $registry = (string) file_get_contents(app_path('Services/PlatformSettingRegistry.php'));

        $this->assertStringContainsString("Action::make('open_in_stripe')", $paymentResource);
        $this->assertStringContainsString("Action::make('refund_full')", $paymentResource);
        $this->assertStringContainsString("can('payments.refund')", $paymentResource);
        $this->assertStringContainsString('safeFilamentRoute', $paymentResource);
        $this->assertStringContainsString('stripePaymentUrl', $paymentResource);
        $this->assertStringContainsString('admin_full_refund_order_', $refundService);
        $this->assertStringContainsString('payments.refund_full', $refundService);
        $this->assertStringContainsString("'stripe.dashboard_base_url'", $registry);
    }

    public function test_module_ten_platform_admin_includes_template_governance_and_policy_activation_validation(): void
    {
        $policyResource = (string) file_get_contents(app_path('Filament/Resources/PolicyResource.php'));
        $createPolicyPage = (string) file_get_contents(app_path('Filament/Resources/PolicyResource/Pages/CreatePolicy.php'));
        $editPolicyPage = (string) file_get_contents(app_path('Filament/Resources/PolicyResource/Pages/EditPolicy.php'));
        $policyValidator = (string) file_get_contents(app_path('Services/PolicyDefinitionValidator.php'));
        $templateResource = (string) file_get_contents(app_path('Filament/Resources/TemplateResource.php'));
        $templateModel = (string) file_get_contents(app_path('Models/Template.php'));
        $permissionSeeder = (string) file_get_contents(database_path('seeders/AdminRolePermissionSeeder.php'));

        $this->assertStringContainsString('PolicyDefinitionValidator::class', $policyResource);
        $this->assertStringContainsString("Select::make('name')", $policyResource);
        $this->assertStringContainsString('blast-radius', $policyResource);
        $this->assertStringContainsString('impact_acknowledged', $policyResource);
        $this->assertStringContainsString('validateOrFail', $createPolicyPage);
        $this->assertStringContainsString('validateOrFail', $editPolicyPage);
        $this->assertStringContainsString('SUPPORTED_POLICY_NAMES', $policyValidator);
        $this->assertStringContainsString('validateRefundPolicy', $policyValidator);
        $this->assertStringContainsString('validateEscalationPolicy', $policyValidator);
        $this->assertStringContainsString('class TemplateResource', $templateResource);
        $this->assertStringContainsString('class Template extends Model', $templateModel);
        $this->assertStringContainsString("'templates.view'", $permissionSeeder);
        $this->assertStringContainsString("'templates.edit'", $permissionSeeder);
        $this->assertFileExists(database_path('migrations/2026_02_28_000016_create_templates_table.php'));
    }
}
