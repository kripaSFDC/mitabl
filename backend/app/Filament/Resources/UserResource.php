<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\AdminActionLog;
use App\Models\Order;
use App\Models\SupportTicket;
use App\Models\User;
use App\Services\AdminAuditLogService;
use App\Services\AdminStepUpService;
use Carbon\Carbon;
use Filament\Facades\Filament;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\HtmlString;
use Throwable;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 20;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('User Profile')
                    ->schema([
                        Forms\Components\TextInput::make('first_name')->required()->maxLength(255),
                        Forms\Components\TextInput::make('last_name')->required()->maxLength(255),
                        Forms\Components\TextInput::make('email')->email()->required()->maxLength(255)->disabled(),
                        Forms\Components\TextInput::make('phone')->tel()->maxLength(255),
                        Forms\Components\TextInput::make('address')->maxLength(255),
                        Forms\Components\Select::make('role_id')
                            ->relationship('role', 'role')
                            ->required()
                            ->disabled(),
                        Forms\Components\Toggle::make('email_verified')
                            ->label('Email verified')
                            ->disabled(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('Account Status')
                    ->schema([
                        Forms\Components\Toggle::make('suspended')
                            ->disabled(),
                        Forms\Components\Textarea::make('suspension_reason')->disabled(),
                        Forms\Components\DateTimePicker::make('suspended_at')->disabled(),
                        Forms\Components\DateTimePicker::make('deleted_at')
                            ->label('Deleted at')
                            ->disabled(),
                    ])
                    ->columns(1),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query
                ->withTrashed()
                ->with(['role', 'restaurant'])
                ->withCount(['orders', 'supportTickets']))
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('full_name')
                    ->label('Name')
                    ->state(fn (User $record): string => trim($record->first_name . ' ' . $record->last_name))
                    ->searchable(query: function ($query, string $search): void {
                        $query->where(function ($innerQuery) use ($search): void {
                            $innerQuery
                                ->where('first_name', 'like', "%{$search}%")
                                ->orWhere('last_name', 'like', "%{$search}%");
                        });
                    }),
                Tables\Columns\TextColumn::make('email')->searchable(),
                Tables\Columns\TextColumn::make('phone')->searchable(),
                Tables\Columns\TextColumn::make('role.role')
                    ->label('Role(s)')
                    ->badge()
                    ->sortable(),
                Tables\Columns\IconColumn::make('email_verified')
                    ->label('Verified')
                    ->boolean(),
                Tables\Columns\IconColumn::make('suspended')
                    ->boolean()
                    ->label('Suspended'),
                Tables\Columns\TextColumn::make('account_status')
                    ->label('Account Status')
                    ->badge()
                    ->state(fn (User $record): string => $record->trashed()
                        ? 'deleted'
                        : ((bool) $record->suspended ? 'suspended' : 'active'))
                    ->color(fn (string $state): string => match ($state) {
                        'active' => 'success',
                        'suspended' => 'warning',
                        'deleted' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('orders_count')
                    ->label('Orders')
                    ->sortable(),
                Tables\Columns\TextColumn::make('support_tickets_count')
                    ->label('Tickets')
                    ->sortable(),
                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Last Activity')
                    ->since(),
                Tables\Columns\TextColumn::make('restaurant.name')
                    ->label('Kitchen')
                    ->placeholder('-')
                    ->url(fn (User $record): ?string => static::safeFilamentRoute(
                        'filament.admin.resources.mikitchns.edit',
                        ['record' => $record->restaurant?->id]
                    ))
                    ->openUrlInNewTab()
                    ->toggleable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('suspended')
                    ->label('Suspended'),
                Tables\Filters\SelectFilter::make('account_status')
                    ->label('Account status')
                    ->options([
                        'active' => 'Active',
                        'suspended' => 'Suspended',
                        'deleted' => 'Deleted',
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        $state = $data['value'] ?? null;

                        return match ($state) {
                            'active' => $query->whereNull('deleted_at')->where('suspended', false),
                            'suspended' => $query->whereNull('deleted_at')->where('suspended', true),
                            'deleted' => $query->onlyTrashed(),
                            default => $query,
                        };
                    }),
                Tables\Filters\SelectFilter::make('role_id')
                    ->relationship('role', 'role')
                    ->label('Role'),
                Tables\Filters\TrashedFilter::make(),
            ])
            ->actions([
                Action::make('timeline')
                    ->label('Timeline')
                    ->icon('heroicon-o-clock')
                    ->color('gray')
                    ->modalSubmitAction(false)
                    ->form([
                        Forms\Components\Placeholder::make('recent_orders')
                            ->label('Recent orders')
                            ->content(fn (User $record): HtmlString => static::buildRecentOrdersHtml($record)),
                        Forms\Components\Placeholder::make('recent_tickets')
                            ->label('Recent tickets')
                            ->content(fn (User $record): HtmlString => static::buildRecentTicketsHtml($record)),
                        Forms\Components\Placeholder::make('flags_notes')
                            ->label('Flags / notes')
                            ->content(fn (User $record): HtmlString => static::buildRecentAuditHtml($record)),
                    ])
                    ->modalWidth('4xl'),
                Action::make('suspend')
                    ->icon('heroicon-o-lock-closed')
                    ->color('danger')
                    ->visible(fn (User $record): bool => ! $record->trashed() && ! $record->suspended && static::canSuspend())
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Suspension reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500)
                            ->rows(4),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (User $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to suspend this account.'
                        )) {
                            return;
                        }

                        $suspended = false;

                        DB::transaction(function () use ($record, $data, &$suspended): void {
                            $user = User::query()->lockForUpdate()->find($record->id);

                            if (! $user) {
                                return;
                            }

                            if ((int) $user->role_id === 1) {
                                if (static::activeSuperAdminCount() <= 1) {
                                    Notification::make()
                                        ->title('Final super admin account cannot be suspended.')
                                        ->danger()
                                        ->send();

                                    return;
                                }

                                Notification::make()
                                    ->title('Super admin accounts cannot be suspended.')
                                    ->danger()
                                    ->send();

                                return;
                            }

                            if ((bool) $user->suspended) {
                                Notification::make()
                                    ->title('User is already suspended.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $user->suspended = true;
                            $user->suspension_reason = $data['reason'];
                            $user->suspended_at = Carbon::now();
                            $user->suspended_by = Filament::auth()->id();
                            $user->save();

                            $suspended = true;
                        });

                        if (! $suspended) {
                            return;
                        }

                        Log::info('users.suspended', [
                            'user_id' => $record->id,
                            'reason' => $data['reason'],
                            'actor_admin_id' => Filament::auth()->id(),
                        ]);
                        app(AdminAuditLogService::class)->log(
                            'users.suspended',
                            request(),
                            [
                                'target_user_id' => $record->id,
                                'reason' => (string) $data['reason'],
                                'new_state' => 'suspended',
                            ]
                        );

                        Notification::make()
                            ->title('User suspended successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('unsuspend')
                    ->icon('heroicon-o-lock-open')
                    ->color('success')
                    ->visible(fn (User $record): bool => ! $record->trashed() && (bool) $record->suspended && static::canSuspend())
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Unsuspension reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500)
                            ->rows(4),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (User $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to unsuspend this account.'
                        )) {
                            return;
                        }

                        $unsuspended = false;

                        DB::transaction(function () use ($record, &$unsuspended): void {
                            $user = User::query()->lockForUpdate()->find($record->id);

                            if (! $user) {
                                return;
                            }

                            if (! (bool) $user->suspended) {
                                Notification::make()
                                    ->title('User is already active.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $user->suspended = false;
                            $user->suspension_reason = null;
                            $user->suspended_at = null;
                            $user->suspended_by = null;
                            $user->save();

                            $unsuspended = true;
                        });

                        if (! $unsuspended) {
                            return;
                        }

                        Log::info('users.unsuspended', [
                            'user_id' => $record->id,
                            'reason' => $data['reason'],
                            'actor_admin_id' => Filament::auth()->id(),
                        ]);
                        app(AdminAuditLogService::class)->log(
                            'users.unsuspended',
                            request(),
                            [
                                'target_user_id' => $record->id,
                                'reason' => (string) $data['reason'],
                                'new_state' => 'active',
                            ]
                        );

                        Notification::make()
                            ->title('User unsuspended successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('soft_delete')
                    ->label('Soft Delete')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->visible(fn (User $record): bool => ! $record->trashed() && static::canEditUsers())
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Deletion reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500)
                            ->rows(4),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (User $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to soft delete this account.'
                        )) {
                            return;
                        }

                        $deleted = false;

                        DB::transaction(function () use ($record, &$deleted): void {
                            $user = User::query()->withTrashed()->lockForUpdate()->find($record->id);

                            if (! $user || $user->trashed()) {
                                return;
                            }

                            if ((int) $user->role_id === 1) {
                                if (static::activeSuperAdminCount() <= 1) {
                                    Notification::make()
                                        ->title('Final super admin account cannot be deleted.')
                                        ->danger()
                                        ->send();

                                    return;
                                }

                                Notification::make()
                                    ->title('Super admin accounts cannot be deleted.')
                                    ->danger()
                                    ->send();

                                return;
                            }

                            $deleted = (bool) $user->delete();
                        });

                        if (! $deleted) {
                            Notification::make()
                                ->title('User could not be deleted.')
                                ->warning()
                                ->send();

                            return;
                        }

                        app(AdminAuditLogService::class)->log(
                            'users.soft_deleted',
                            request(),
                            [
                                'target_user_id' => $record->id,
                                'reason' => (string) $data['reason'],
                                'new_state' => 'deleted',
                            ]
                        );

                        Notification::make()
                            ->title('User soft deleted successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('restore')
                    ->label('Restore')
                    ->icon('heroicon-o-arrow-uturn-left')
                    ->color('success')
                    ->visible(fn (User $record): bool => $record->trashed() && static::canEditUsers())
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Restore reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500)
                            ->rows(4),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (User $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to restore this account.'
                        )) {
                            return;
                        }

                        $restored = false;

                        DB::transaction(function () use ($record, &$restored): void {
                            $user = User::query()->withTrashed()->lockForUpdate()->find($record->id);

                            if (! $user || ! $user->trashed()) {
                                return;
                            }

                            $restored = (bool) $user->restore();
                        });

                        if (! $restored) {
                            Notification::make()
                                ->title('User could not be restored.')
                                ->warning()
                                ->send();

                            return;
                        }

                        app(AdminAuditLogService::class)->log(
                            'users.restored',
                            request(),
                            [
                                'target_user_id' => $record->id,
                                'reason' => (string) $data['reason'],
                                'new_state' => 'active',
                            ]
                        );

                        Notification::make()
                            ->title('User restored successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('view_orders')
                    ->label('Orders')
                    ->icon('heroicon-o-clipboard-document-list')
                    ->color('gray')
                    ->url(fn (User $record): ?string => static::safeFilamentRoute(
                        'filament.admin.resources.orders.index',
                        ['tableSearch' => $record->email]
                    ))
                    ->openUrlInNewTab(),
                Action::make('view_tickets')
                    ->label('Tickets')
                    ->icon('heroicon-o-inbox-stack')
                    ->color('gray')
                    ->url(fn (User $record): ?string => static::safeFilamentRoute(
                        'filament.admin.resources.support-tickets.index',
                        ['tableSearch' => $record->email]
                    ))
                    ->openUrlInNewTab(),
                Tables\Actions\EditAction::make()
                    ->visible(fn (User $record): bool => ! $record->trashed() && static::canEditUsers()),
            ])
            ->defaultSort('id', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        return static::canViewUsers();
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        if ($record instanceof User && $record->trashed()) {
            return false;
        }

        return static::canEditUsers();
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    private static function canViewUsers(): bool
    {
        return (bool) Filament::auth()->user()?->can('users.view');
    }

    private static function canEditUsers(): bool
    {
        return (bool) Filament::auth()->user()?->can('users.edit');
    }

    private static function canSuspend(): bool
    {
        return (bool) Filament::auth()->user()?->can('users.suspend');
    }

    private static function activeSuperAdminCount(): int
    {
        return User::query()
            ->where('role_id', 1)
            ->where('suspended', false)
            ->whereNull('deleted_at')
            ->count();
    }

    private static function safeFilamentRoute(string $name, array $parameters = []): ?string
    {
        try {
            if (! app('router')->has($name)) {
                return null;
            }

            return route($name, array_filter($parameters, fn ($value) => $value !== null));
        } catch (Throwable) {
            return null;
        }
    }

    private static function buildRecentOrdersHtml(User $record): HtmlString
    {
        $orders = Order::query()
            ->where('user_id', $record->id)
            ->orderByDesc('created_at')
            ->limit(5)
            ->get(['id', 'status', 'total_price', 'created_at']);

        if ($orders->isEmpty()) {
            return new HtmlString('No orders found.');
        }

        $items = $orders->map(function (Order $order): string {
            return sprintf(
                '<li>#%d | status=%d | $%0.2f | %s</li>',
                $order->id,
                (int) $order->status,
                (float) $order->total_price,
                e(optional($order->created_at)->toDateTimeString())
            );
        })->implode('');

        return new HtmlString("<ul>{$items}</ul>");
    }

    private static function buildRecentTicketsHtml(User $record): HtmlString
    {
        $tickets = SupportTicket::query()
            ->where('user_id', $record->id)
            ->orderByDesc('created_at')
            ->limit(5)
            ->get(['ticket_number', 'status', 'subject', 'created_at']);

        if ($tickets->isEmpty()) {
            return new HtmlString('No support tickets found.');
        }

        $items = $tickets->map(function (SupportTicket $ticket): string {
            return sprintf(
                '<li>%s | %s | %s | %s</li>',
                e((string) $ticket->ticket_number),
                e((string) $ticket->status),
                e((string) $ticket->subject),
                e(optional($ticket->created_at)->toDateTimeString())
            );
        })->implode('');

        return new HtmlString("<ul>{$items}</ul>");
    }

    private static function buildRecentAuditHtml(User $record): HtmlString
    {
        $entries = AdminActionLog::query()
            ->whereIn('action', ['users.suspended', 'users.unsuspended', 'users.soft_deleted', 'users.restored'])
            ->orderByDesc('created_at')
            ->limit(100)
            ->get(['action', 'metadata', 'created_at'])
            ->filter(fn (AdminActionLog $entry): bool => (int) data_get($entry->metadata, 'target_user_id') === (int) $record->id)
            ->take(10)
            ->values();

        if ($entries->isEmpty()) {
            return new HtmlString('No flags/notes found.');
        }

        $items = $entries->map(function (AdminActionLog $entry): string {
            $reason = (string) data_get($entry->metadata, 'reason', '-');

            return sprintf(
                '<li>%s | %s | %s</li>',
                e((string) $entry->action),
                e($reason),
                e(optional($entry->created_at)->toDateTimeString())
            );
        })->implode('');

        return new HtmlString("<ul>{$items}</ul>");
    }
}

