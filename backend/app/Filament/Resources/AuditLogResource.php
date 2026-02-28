<?php

namespace App\Filament\Resources;

class AuditLogResource extends AdminActionLogResource
{
    protected static bool $shouldRegisterNavigation = false;

    protected static ?string $slug = 'audit-logs';
}
