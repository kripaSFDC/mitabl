<?php

namespace Tests\Unit;

use Tests\TestCase;

class CrmWorkspaceAccessibilityMarkupTest extends TestCase
{
    public function test_workspace_template_contains_accessibility_landmarks_and_keyboard_shortcuts(): void
    {
        $template = file_get_contents(resource_path('views/filament/pages/crm-agent-workspace-page.blade.php'));

        $this->assertStringContainsString('role="main"', $template);
        $this->assertStringContainsString('aria-label="Ticket queue"', $template);
        $this->assertStringContainsString('aria-label="Conversation timeline"', $template);
        $this->assertStringContainsString('accesskey="r"', $template);
        $this->assertStringContainsString('accesskey="m"', $template);
        $this->assertStringContainsString('accesskey="s"', $template);
    }
}
