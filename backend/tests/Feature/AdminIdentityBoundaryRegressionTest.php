<?php

namespace Tests\Feature;

use Tests\TestCase;

class AdminIdentityBoundaryRegressionTest extends TestCase
{
    public function test_api_routes_apply_user_activity_guard_middleware(): void
    {
        $routes = (string) file_get_contents(base_path('routes/api.php'));
        $kernel = (string) file_get_contents(app_path('Http/Kernel.php'));
        $middleware = (string) file_get_contents(app_path('Http/Middleware/EnsureApiUserIsActive.php'));

        $this->assertStringContainsString("'api.user.active' => \\App\\Http\\Middleware\\EnsureApiUserIsActive::class", $kernel);
        $this->assertStringContainsString("['auth:api', 'api.user.active']", $routes);
        $this->assertStringContainsString('Admin identities must authenticate via the web admin panel', $middleware);
        $this->assertStringContainsString('Your account is suspended. Please contact support.', $middleware);
    }

    public function test_mobile_auth_flows_block_admin_and_suspended_users(): void
    {
        $controller = (string) file_get_contents(app_path('Http/Controllers/Api/User/UserController.php'));

        $this->assertStringContainsString("if (\$this->isAdminIdentityRole((int) \$user->role_id))", $controller);
        $this->assertStringContainsString("if ((bool) \$user->suspended)", $controller);
        $this->assertStringContainsString("'role_id' => 'nullable|integer|in:2,3'", $controller);
        $this->assertStringContainsString("'first_name' => (string) \$request->input('first_name')", $controller);
        $this->assertStringNotContainsString("\$input = \$request->all();", $controller);
        $this->assertStringContainsString('Unsupported account role for mobile authentication.', $controller);
        $this->assertStringContainsString('forbiddenAdminIdentityResponse', $controller);
        $this->assertStringContainsString('suspendedAccountResponse', $controller);
    }

    public function test_role_middlewares_use_explicit_api_guard(): void
    {
        $customer = (string) file_get_contents(app_path('Http/Middleware/Customer.php'));
        $restaurant = (string) file_get_contents(app_path('Http/Middleware/Restaurant.php'));
        $settingsPage = (string) file_get_contents(app_path('Filament/Pages/PlatformSettingsPage.php'));

        $this->assertStringContainsString("Auth::guard('api')->user()", $customer);
        $this->assertStringContainsString("Auth::guard('api')->user()", $restaurant);
        $this->assertStringNotContainsString('Auth::check()', $customer);
        $this->assertStringNotContainsString('Auth::check()', $restaurant);
        $this->assertStringContainsString("'feature'", $settingsPage);
        $this->assertStringContainsString("'integration'", $settingsPage);
    }
}
