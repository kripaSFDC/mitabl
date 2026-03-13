<?php

namespace Tests\Feature;

use Tests\TestCase;

class AdminPlatformCrudRegressionTest extends TestCase
{
    public function test_platform_user_email_field_is_editable(): void
    {
        $resource = (string) file_get_contents(app_path('Filament/Resources/UserResource.php'));

        $this->assertStringContainsString("TextInput::make('email')", $resource);
        $this->assertStringNotContainsString('->disabled(fn (string $operation): bool => $operation === \'edit\')', $resource);
    }
}
