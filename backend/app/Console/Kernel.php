<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        'App\Console\Commands\OrderPaymentCron',
        'App\Console\Commands\SupportTicketSlaScanCommand',
        'App\Console\Commands\PlatformSyntheticHealthCheckCommand',
        'App\Console\Commands\ReconcileIntakeDataCommand',
        'App\Console\Commands\ActivateDuePoliciesCommand',
        'App\Console\Commands\RepairUserRoleStateCommand',
    ];

    /**
     * Define the application's command schedule.
     *
     * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        $schedule->command('orderpayment:cron')->hourly()->withoutOverlapping();
        $schedule->command('support:sla:scan')->everyFiveMinutes()->withoutOverlapping();
        $schedule->command('platform:health:synthetic')->everyFiveMinutes()->withoutOverlapping();
        $schedule->command('platform:policies:activate-due')->everyMinute()->withoutOverlapping();
        $schedule->command('roles:repair-state')->hourly()->withoutOverlapping();
    }

    /**
     * Register the commands for the application.
     *
     * @return void
     */
    protected function commands()
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
