<?php

namespace App\Filament\Pages;

use App\Services\AdminAuditLogService;
use Filament\Facades\Filament;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

class QueueOpsPage extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-server-stack';

    protected static string|\UnitEnum|null $navigationGroup = 'Platform';

    protected static ?int $navigationSort = 40;

    protected static ?string $title = 'Queue Operations';

    protected static string $view = 'filament.pages.queue-ops-page';

    public array $failedJobs = [];
    public bool $canManageQueue = false;

    public function mount(): void
    {
        $this->canManageQueue = $this->canManage();
        $this->loadFailedJobs();
    }

    public function refresh(): void
    {
        $this->canManageQueue = $this->canManage();
        $this->loadFailedJobs();

        app(AdminAuditLogService::class)->log('queue_ops.refresh', request(), [
            'visible_failed_jobs' => count($this->failedJobs),
        ]);
    }

    public function retryJob(int $id): void
    {
        if (! $this->canManage()) {
            Notification::make()->title('You do not have permission to manage queue jobs.')->danger()->send();
            return;
        }

        try {
            Artisan::call('queue:retry', ['id' => [$id]]);
            $this->loadFailedJobs();

            app(AdminAuditLogService::class)->log('queue_ops.retry', request(), ['job_id' => $id]);
            Notification::make()->title('Failed job retried.')->success()->send();
        } catch (\Throwable $throwable) {
            Notification::make()->title('Retry failed: ' . $throwable->getMessage())->danger()->send();
        }
    }

    public function requeueJob(int $id): void
    {
        if (! $this->canManage()) {
            Notification::make()->title('You do not have permission to manage queue jobs.')->danger()->send();
            return;
        }

        try {
            Artisan::call('queue:retry', ['id' => [$id]]);
            $this->loadFailedJobs();

            app(AdminAuditLogService::class)->log('queue_ops.requeue', request(), ['job_id' => $id]);
            Notification::make()->title('Failed job requeued.')->success()->send();
        } catch (\Throwable $throwable) {
            Notification::make()->title('Requeue failed: ' . $throwable->getMessage())->danger()->send();
        }
    }

    public function discardJob(int $id): void
    {
        if (! $this->canManage()) {
            Notification::make()->title('You do not have permission to manage queue jobs.')->danger()->send();
            return;
        }

        try {
            Artisan::call('queue:forget', ['id' => $id]);
            $this->loadFailedJobs();

            app(AdminAuditLogService::class)->log('queue_ops.discard', request(), ['job_id' => $id]);
            Notification::make()->title('Failed job discarded.')->success()->send();
        } catch (\Throwable $throwable) {
            Notification::make()->title('Discard failed: ' . $throwable->getMessage())->danger()->send();
        }
    }

    public function retryAll(): void
    {
        if (! $this->canManage()) {
            Notification::make()->title('You do not have permission to manage queue jobs.')->danger()->send();
            return;
        }

        try {
            Artisan::call('queue:retry', ['id' => ['all']]);
            $this->loadFailedJobs();

            app(AdminAuditLogService::class)->log('queue_ops.retry_all', request());
            Notification::make()->title('All failed jobs retried.')->success()->send();
        } catch (\Throwable $throwable) {
            Notification::make()->title('Retry all failed: ' . $throwable->getMessage())->danger()->send();
        }
    }

    private function loadFailedJobs(): void
    {
        try {
            $this->failedJobs = DB::table('failed_jobs')
                ->orderByDesc('failed_at')
                ->limit(100)
                ->get([
                    'id',
                    'connection',
                    'queue',
                    'failed_at',
                    'exception',
                ])
                ->map(function ($row): array {
                    return [
                        'id' => (int) $row->id,
                        'connection' => (string) $row->connection,
                        'queue' => (string) $row->queue,
                        'failed_at' => (string) $row->failed_at,
                        'exception' => str((string) $row->exception)->limit(240)->toString(),
                    ];
                })
                ->toArray();
        } catch (\Throwable $throwable) {
            $this->failedJobs = [];
            Notification::make()->title('Failed to load queue data: ' . $throwable->getMessage())->danger()->send();
        }
    }

    private function canManage(): bool
    {
        return (bool) Filament::auth()->user()?->can('queue_ops.manage');
    }

    public static function canAccess(): bool
    {
        return (bool) Filament::auth()->user()?->can('queue_ops.view');
    }
}
