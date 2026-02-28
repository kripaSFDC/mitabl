<?php

namespace Tests\Feature;

use Tests\TestCase;

class ModuleTwelveCollaborationContractTest extends TestCase
{
    public function test_cross_module_collaboration_models_and_relationships_exist(): void
    {
        $supportTicket = (string) file_get_contents(app_path('Models/SupportTicket.php'));
        $user = (string) file_get_contents(app_path('Models/User.php'));
        $mikitchn = (string) file_get_contents(app_path('Models/Mikitchn.php'));
        $order = (string) file_get_contents(app_path('Models/Order.php'));
        $migration = (string) file_get_contents(database_path('migrations/2026_02_28_000016_create_collaboration_tables.php'));

        $this->assertStringContainsString('function internalNotes()', $supportTicket);
        $this->assertStringContainsString('function tags()', $supportTicket);
        $this->assertStringContainsString('function watchers()', $supportTicket);
        $this->assertStringContainsString('function internalNotes()', $user);
        $this->assertStringContainsString('function internalNotes()', $mikitchn);
        $this->assertStringContainsString('function internalNotes()', $order);
        $this->assertStringContainsString("Schema::create('internal_notes'", $migration);
        $this->assertStringContainsString("Schema::create('tags'", $migration);
        $this->assertStringContainsString("Schema::create('watch_subscriptions'", $migration);
    }
}
