<?php

namespace App\Providers\Filament;

use App\Filament\Pages\Auth\AdminLogin;
use App\Filament\Widgets\CrmAgingBucketsChart;
use App\Filament\Widgets\CrmQueueStatsWidget;
use App\Filament\Widgets\DashboardLiveOperationsWidget;
use App\Filament\Widgets\DashboardOperationalSnapshotWidget;
use App\Filament\Widgets\IntegrationHealthWidget;
use App\Filament\Widgets\OrdersPerDayChartWidget;
use App\Filament\Widgets\RegistrationsPerDayChartWidget;
use App\Filament\Widgets\SlaHealthWidget;
use App\Filament\Widgets\SystemHealthSummaryWidget;
use App\Http\Middleware\RecordAdminAction;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Navigation\NavigationGroup;
use Filament\Pages;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Support\Enums\MaxWidth;
use Filament\Widgets;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->id('admin')
            ->path('admin')
            ->authGuard('admin')
            ->authPasswordBroker('admin_users')
            ->login(AdminLogin::class)
            ->maxContentWidth(MaxWidth::Full)
            ->simplePageMaxContentWidth(MaxWidth::SevenExtraLarge)
            ->passwordReset()
            ->colors([
                'primary' => Color::Amber,
                'gray' => Color::Slate,
            ])
            ->brandName(config('app.name').' Admin')
            ->navigationGroups([
                NavigationGroup::make()->label('Customer Support'),
                NavigationGroup::make()->label('Operations'),
                NavigationGroup::make()->label('Platform'),
            ])
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([
                Pages\Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->widgets([
                Widgets\AccountWidget::class,
                Widgets\FilamentInfoWidget::class,
                DashboardOperationalSnapshotWidget::class,
                DashboardLiveOperationsWidget::class,
                IntegrationHealthWidget::class,
                CrmQueueStatsWidget::class,
                CrmAgingBucketsChart::class,
                SlaHealthWidget::class,
                SystemHealthSummaryWidget::class,
                OrdersPerDayChartWidget::class,
                RegistrationsPerDayChartWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
                RecordAdminAction::class,
            ]);
    }
}
