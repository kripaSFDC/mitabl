<?php

namespace Tests\Feature;

use Tests\TestCase;

class PhaseTwoResourceScaffoldTest extends TestCase
{
    public function test_phase_two_resource_files_exist(): void
    {
        $requiredFiles = [
            'app/Filament/Resources/CertificateResource.php',
            'app/Filament/Resources/UserResource.php',
            'app/Filament/Resources/MikitchnResource.php',
            'app/Filament/Resources/OrderResource.php',
            'app/Filament/Resources/PromoCodeResource.php',

            'app/Filament/Resources/CertificateResource/Pages/ListCertificates.php',
            'app/Filament/Resources/CertificateResource/Pages/EditCertificate.php',
            'app/Filament/Resources/UserResource/Pages/ListUsers.php',
            'app/Filament/Resources/UserResource/Pages/EditUser.php',
            'app/Filament/Resources/MikitchnResource/Pages/ListMikitchns.php',
            'app/Filament/Resources/MikitchnResource/Pages/EditMikitchn.php',
            'app/Filament/Resources/OrderResource/Pages/ListOrders.php',
            'app/Filament/Resources/OrderResource/Pages/EditOrder.php',
            'app/Filament/Resources/PromoCodeResource/Pages/ListPromoCodes.php',
            'app/Filament/Resources/PromoCodeResource/Pages/EditPromoCode.php',

            'app/Mail/CertificateApproved.php',
            'app/Mail/CertificateRejected.php',
            'app/Notifications/CertificateStatusUpdatedNotification.php',
            'resources/views/Mail/certificateApproved.blade.php',
            'resources/views/Mail/certificateRejected.blade.php',
        ];

        foreach ($requiredFiles as $path) {
            $this->assertFileExists(base_path($path), 'Missing required Phase 2 scaffold file: '.$path);
        }
    }

    public function test_phase_two_resources_are_auto_discovered_by_admin_panel(): void
    {
        $provider = (string) file_get_contents(app_path('Providers/Filament/AdminPanelProvider.php'));

        $this->assertStringContainsString("->discoverResources(in: app_path('Filament/Resources')", $provider);
        $this->assertStringContainsString("->authGuard('admin')", $provider);
    }
}
