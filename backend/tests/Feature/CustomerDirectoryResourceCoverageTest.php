<?php

namespace Tests\Feature;

use Tests\TestCase;

class CustomerDirectoryResourceCoverageTest extends TestCase
{
    public function test_mifoodie_and_micook_resources_expose_all_user_fields_and_allow_non_system_edits(): void
    {
        $mifoodie = (string) file_get_contents(app_path('Filament/Resources/MifoodieResource.php'));
        $micook = (string) file_get_contents(app_path('Filament/Resources/MicookResource.php'));

        foreach ([$mifoodie, $micook] as $resource) {
            $this->assertStringContainsString("TextInput::make('first_name')", $resource);
            $this->assertStringContainsString("TextInput::make('last_name')", $resource);
            $this->assertStringContainsString("TextInput::make('email')", $resource);
            $this->assertStringContainsString("TextInput::make('phone')", $resource);
            $this->assertStringContainsString("TextInput::make('address')", $resource);
            $this->assertStringContainsString("TextInput::make('avatar')", $resource);
            $this->assertStringContainsString("Textarea::make('description')", $resource);
            $this->assertStringContainsString("Toggle::make('suspended')", $resource);
            $this->assertStringContainsString("Textarea::make('suspension_reason')", $resource);
            $this->assertStringContainsString("Placeholder::make('email_verified')", $resource);
            $this->assertStringContainsString("Placeholder::make('device_token')", $resource);
            $this->assertStringNotContainsString("->disabled(fn (string $operation): bool => $operation === 'edit')", $resource);
        }
    }

    public function test_mikitchn_resource_exposes_all_table_fields_and_non_system_edits(): void
    {
        $resource = (string) file_get_contents(app_path('Filament/Resources/MikitchnResource.php'));

        $this->assertStringContainsString("Select::make('user_id')", $resource);
        $this->assertStringContainsString("TextInput::make('name')", $resource);
        $this->assertStringContainsString("TextInput::make('phone')", $resource);
        $this->assertStringContainsString("TextInput::make('address')", $resource);
        $this->assertStringContainsString("TextInput::make('no_of_seats')", $resource);
        $this->assertStringContainsString("Textarea::make('timings')", $resource);
        $this->assertStringContainsString("Textarea::make('description')", $resource);
        $this->assertStringContainsString("TextInput::make('latitude')", $resource);
        $this->assertStringContainsString("TextInput::make('longitude')", $resource);
        $this->assertStringContainsString("Toggle::make('dine_in')", $resource);
        $this->assertStringContainsString("Toggle::make('take_away')", $resource);
        $this->assertStringContainsString("Toggle::make('open')", $resource);
        $this->assertStringContainsString("Select::make('status')", $resource);
        $this->assertStringContainsString("Placeholder::make('id')", $resource);
        $this->assertStringContainsString("Placeholder::make('created_at')", $resource);
        $this->assertStringContainsString("Placeholder::make('updated_at')", $resource);
    }
}
