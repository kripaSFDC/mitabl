<?php

namespace Tests\Feature\Api;

use Tests\TestCase;

class RequirementsRegressionCoverageTest extends TestCase
{
    public function test_routes_keep_public_order_discovery_menu_and_payments_endpoints_registered(): void
    {
        $routes = (string) file_get_contents(base_path('routes/api.php'));

        $this->assertStringContainsString("Route::post('orders', [OrderController::class, 'store'])", $routes);
        $this->assertStringContainsString("Route::get('restaurants/{id}/menu', [V2DiscoveryController::class, 'menu'])", $routes);
        $this->assertStringContainsString("Route::get('restaurants/{id}/dine-in-slots', [V2DiscoveryController::class, 'dineInSlots'])", $routes);
        $this->assertStringContainsString("Route::get('search', [V2DiscoveryController::class, 'search'])", $routes);
        $this->assertStringContainsString("Route::post('intent', [V2PaymentsController::class, 'createIntent'])", $routes);
    }

    public function test_order_controller_uses_correct_upcoming_orders_method_name_without_typo(): void
    {
        $controller = (string) file_get_contents(base_path('app/Http/Controllers/Api/OrderController.php'));

        $this->assertStringContainsString('public function myUpcomingOrders(Request $request)', $controller);
        $this->assertStringNotContainsString('myUpcomingOrderss', $controller);
    }

    public function test_discovery_show_loads_food_menu_for_kitchen_detail(): void
    {
        $controller = (string) file_get_contents(base_path('app/Http/Controllers/Api/V2/DiscoveryController.php'));

        $this->assertStringContainsString("'foods' => function", $controller);
        $this->assertStringContainsString('->availableForOrderType(', $controller);
    }

    public function test_status_update_enforces_foodie_cancel_only_before_acceptance_and_records_reason(): void
    {
        $controller = (string) file_get_contents(base_path('app/Http/Controllers/Api/OrderController.php'));

        $this->assertStringContainsString('cancel_comment is required when cancelling an order.', $controller);
        $this->assertStringContainsString('miFoodi can only cancel an order before it is accepted by miCook.', $controller);
        $this->assertStringContainsString('CancelReason::query()->updateOrCreate(', $controller);
    }

    public function test_payment_intent_allows_saved_card_or_one_time_payment_method_selection(): void
    {
        $controller = (string) file_get_contents(base_path('app/Http/Controllers/Api/V2/PaymentsController.php'));

        $this->assertStringContainsString("'card_id' => 'nullable'", $controller);
        $this->assertStringContainsString("'payment_method_id' => 'nullable|string|starts_with:pm_'", $controller);
        $this->assertStringContainsString('resolvePaymentMethodSelection(', $controller);
    }
}
