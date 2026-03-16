<?php

namespace Tests\Feature;

use Tests\TestCase;

class CertificateResourceCoverageTest extends TestCase
{
    public function test_certificate_resource_shows_all_db_fields_and_keeps_non_system_fields_editable(): void
    {
        $resource = (string) file_get_contents(app_path('Filament/Resources/CertificateResource.php'));

        $this->assertStringContainsString("Select::make('mikitchn_id')", $resource);
        $this->assertStringContainsString("TextInput::make('first_name')", $resource);
        $this->assertStringContainsString("TextInput::make('last_name')", $resource);
        $this->assertStringContainsString("TextInput::make('abn')", $resource);
        $this->assertStringContainsString("Select::make('abn_gst')", $resource);
        $this->assertStringContainsString("TextInput::make('certificate_no')", $resource);
        $this->assertStringContainsString("TextInput::make('certificate_doc')", $resource);
        $this->assertStringContainsString("Select::make('status')", $resource);
        $this->assertStringContainsString("Textarea::make('rejection_reason')", $resource);

        $this->assertStringContainsString("Placeholder::make('id')", $resource);
        $this->assertStringContainsString("Placeholder::make('mikitchn_id')", $resource);
        $this->assertStringContainsString("Placeholder::make('reviewed_by')", $resource);
        $this->assertStringContainsString("Placeholder::make('reviewed_at')", $resource);
        $this->assertStringContainsString("Placeholder::make('created_at')", $resource);
        $this->assertStringContainsString("Placeholder::make('updated_at')", $resource);

        $this->assertStringContainsString("TextColumn::make('abn_gst')", $resource);
        $this->assertStringContainsString("TextColumn::make('rejection_reason')", $resource);
        $this->assertStringContainsString("TextColumn::make('mikitchn_id')", $resource);
        $this->assertStringContainsString("TextColumn::make('reviewed_by')", $resource);
        $this->assertStringContainsString("TextColumn::make('id')", $resource);
    }

    public function test_certificate_resource_supports_crud_pages_and_row_actions(): void
    {
        $resource = (string) file_get_contents(app_path('Filament/Resources/CertificateResource.php'));
        $listPage = (string) file_get_contents(app_path('Filament/Resources/CertificateResource/Pages/ListCertificates.php'));
        $editPage = (string) file_get_contents(app_path('Filament/Resources/CertificateResource/Pages/EditCertificate.php'));

        $this->assertStringContainsString("'create' => Pages\\CreateCertificate::route('/create')", $resource);
        $this->assertStringContainsString("'edit' => Pages\\EditCertificate::route('/{record}/edit')", $resource);
        $this->assertStringContainsString("CreateAction::make()", $listPage);
        $this->assertStringContainsString("DeleteAction::make()", $editPage);
        $this->assertStringContainsString("Tables\\Actions\\EditAction::make()", $resource);
        $this->assertStringContainsString("Tables\\Actions\\DeleteAction::make()", $resource);
    }
}
