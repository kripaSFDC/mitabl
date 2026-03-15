<?php

namespace App\Filament\Resources;

use App\Filament\Resources\OrderResource\Pages;
use App\Models\CancelReason;
use App\Models\Order;
use App\Models\Refund;
use App\Services\AdminPaymentRefundService;
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
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-list';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 70;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Order Summary')
                    ->description('Core order identifiers and fulfillment type.')
                    ->icon('heroicon-o-clipboard-document-list')
                    ->schema([
                        Forms\Components\Select::make('mikitchn_id')
                            ->label('Kitchen')
                            ->relationship('Mikitchn', 'name')
                            ->required()
                            ->searchable()
                            ->preload(),
                        Forms\Components\Select::make('user_id')
                            ->label('Customer')
                            ->relationship('user', 'email')
                            ->searchable()
                            ->required(),
                        Forms\Components\Select::make('status')
                            ->options(static::statusOptions(includeLegacy: true))
                            ->required(),
                        Forms\Components\Toggle::make('paid')
                            ->label('Payment Confirmed')
                            ->inline(false),
                        Forms\Components\Toggle::make('dine_in')
                            ->label('Dine-in')
                            ->inline(false),
                        Forms\Components\Toggle::make('take_away')
                            ->label('Take-away')
                            ->inline(false),
                    ])
                    ->columns(3),

                Forms\Components\Section::make('Delivery Window')
                    ->description('Scheduled delivery date and arrival window.')
                    ->icon('heroicon-o-calendar-days')
                    ->schema([
                        Forms\Components\DatePicker::make('delivery_date')
                            ->required(),
                        Forms\Components\TimePicker::make('delivery_time_from')
                            ->label('Window Start')
                            ->required(),
                        Forms\Components\TimePicker::make('delivery_time_to')
                            ->label('Window End')
                            ->required(),
                    ])
                    ->columns(3),

                Forms\Components\Section::make('Pricing & Refund')
                    ->description('Financial breakdown. Use the Refund action on the order row to issue refunds.')
                    ->icon('heroicon-o-banknotes')
                    ->schema([
                        Forms\Components\TextInput::make('item_total_price')
                            ->label('Item Subtotal (AUD)')
                            ->numeric()
                            ->required()
                            ->prefix('$'),
                        Forms\Components\TextInput::make('taxes')
                            ->label('Taxes (AUD)')
                            ->numeric()
                            ->prefix('$'),
                        Forms\Components\TextInput::make('total_price')
                            ->label('Total (AUD)')
                            ->numeric()
                            ->required()
                            ->prefix('$'),
                        Forms\Components\TextInput::make('refund_percentage')
                            ->label('Refund Applied (%)')
                            ->numeric()
                            ->suffix('%')
                            ->helperText('Set via Refund action — manual edits here are for corrections only.'),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query
                ->with(['Mikitchn.user', 'user', 'payment', 'cancelreason', 'completedorder'])
                ->withCount(['orderdata', 'refunds'])
                ->withMax('refunds', 'percentage'))
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('Order #')
                    ->sortable()
                    ->searchable()
                    ->copyable()
                    ->weight(\Filament\Support\Enums\FontWeight::SemiBold),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn ($state): string => static::formatStatus((int) $state))
                    ->color(fn ($state): string => static::statusColor((int) $state)),
                Tables\Columns\TextColumn::make('Mikitchn.name')
                    ->label('Kitchen')
                    ->searchable()
                    ->url(fn (Order $record): ?string => $record->mikitchn_id
                        ? '/admin/mikitchns/' . $record->mikitchn_id . '/edit'
                        : null)
                    ->openUrlInNewTab(),
                Tables\Columns\TextColumn::make('user.email')
                    ->label('Customer')
                    ->searchable()
                    ->url(fn (Order $record): ?string => $record->user_id
                        ? '/admin/users/' . $record->user_id . '/edit'
                        : null)
                    ->openUrlInNewTab(),
                Tables\Columns\TextColumn::make('total_price')
                    ->label('Total')
                    ->money('AUD')
                    ->sortable()
                    ->weight(\Filament\Support\Enums\FontWeight::SemiBold),
                Tables\Columns\IconColumn::make('paid')
                    ->label('Paid')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-badge')
                    ->falseIcon('heroicon-o-clock'),
                Tables\Columns\TextColumn::make('refund_state')
                    ->label('Refund')
                    ->badge()
                    ->state(fn (Order $record): string => static::refundStateLabel($record))
                    ->color(fn (Order $record): string => static::refundStateColor($record)),
                Tables\Columns\TextColumn::make('refund_percentage')
                    ->label('Refund %')
                    ->formatStateUsing(fn ($state): string => $state === null ? '—' : ((int) $state) . '%')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('order_type')
                    ->label('Type')
                    ->state(function (Order $record): string {
                        $isDineIn = (int) $record->dine_in === 1;
                        $isTakeAway = (int) $record->take_away === 1;

                        return match (true) {
                            $isDineIn && $isTakeAway => 'Dine-in / Take-away',
                            $isDineIn => 'Dine-in',
                            $isTakeAway => 'Take-away',
                            default => '—',
                        };
                    })
                    ->badge()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('delivery_date')
                    ->label('Delivery')
                    ->date()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Ordered')
                    ->dateTime('d M Y')
                    ->sortable(),
                Tables\Columns\TextColumn::make('cancelreason.subject')
                    ->label('Cancel Reason')
                    ->placeholder('—')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options(static::statusOptions(includeLegacy: true)),
                Tables\Filters\Filter::make('delivery_date')
                    ->form([
                        Forms\Components\DatePicker::make('from'),
                        Forms\Components\DatePicker::make('until'),
                    ])
                    ->query(function ($query, array $data) {
                        return $query
                            ->when($data['from'] ?? null, fn ($subQuery, $date) => $subQuery->whereDate('delivery_date', '>=', $date))
                            ->when($data['until'] ?? null, fn ($subQuery, $date) => $subQuery->whereDate('delivery_date', '<=', $date));
                    }),
            ])
            ->actions([
                Action::make('view_detail')
                    ->label('View')
                    ->icon('heroicon-o-eye')
                    ->color('gray')
                    ->visible(fn (): bool => static::canViewOrders())
                    ->modalHeading(fn (Order $record): string => 'Order #' . $record->id)
                    ->modalSubmitAction(false)
                    ->form([
                        Forms\Components\Grid::make(2)->schema([
                            Forms\Components\Placeholder::make('kitchen')
                                ->label('Kitchen')
                                ->content(fn (Order $record): string => (string) (optional($record->Mikitchn)->name ?? '-')),
                            Forms\Components\Placeholder::make('customer')
                                ->label('Customer')
                                ->content(fn (Order $record): string => (string) (optional($record->user)->email ?? '-')),
                            Forms\Components\Placeholder::make('status')
                                ->label('Status')
                                ->content(fn (Order $record): string => static::formatStatus((int) $record->status)),
                            Forms\Components\Placeholder::make('delivery_window')
                                ->label('Delivery Window')
                                ->content(fn (Order $record): string => (string) $record->delivery_date . ' ' . (string) $record->delivery_time_from . ' - ' . (string) $record->delivery_time_to),
                            Forms\Components\Placeholder::make('amount')
                                ->label('Total Amount')
                                ->content(fn (Order $record): string => '$' . number_format((float) $record->total_price, 2)),
                            Forms\Components\Placeholder::make('payment_id')
                                ->label('Payment Intent')
                                ->content(fn (Order $record): string => (string) (optional($record->payment)->payment_id ?? '-')),
                            Forms\Components\Placeholder::make('payment_status')
                                ->label('Payment Status')
                                ->content(fn (Order $record): string => (string) (optional($record->payment)->status ?? '-')),
                            Forms\Components\Placeholder::make('refund_percentage')
                                ->label('Refund %')
                                ->content(fn (Order $record): string => $record->refund_percentage === null ? '-' : ((int) $record->refund_percentage) . '%'),
                            Forms\Components\Placeholder::make('cancel_reason')
                                ->label('Cancel Reason')
                                ->content(fn (Order $record): string => (string) ($record->cancelreason->comment ?? '-')),
                            Forms\Components\Placeholder::make('timeline')
                                ->label('Timeline')
                                ->content(fn (Order $record): string => static::renderTimeline($record)),
                        ]),
                    ])
                    ->modalWidth('5xl'),
                Action::make('override_status')
                    ->label('Override Status')
                    ->icon('heroicon-o-pencil-square')
                    ->color('warning')
                    ->visible(fn (): bool => static::canOverrideStatus())
                    ->form([
                        Forms\Components\Select::make('status')
                            ->required()
                            ->options(static::statusOptions(includeLegacy: false)),
                        Forms\Components\Textarea::make('reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (Order $record, array $data): void {
                        if (! static::canOverrideStatus()) {
                            Notification::make()->title('You are not authorized to override order status.')->danger()->send();
                            return;
                        }

                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to force a status transition.'
                        )) {
                            return;
                        }

                        $updated = false;

                        DB::transaction(function () use ($record, $data, &$updated): void {
                            $lockedOrder = Order::query()->lockForUpdate()->find($record->id);

                            if (! $lockedOrder) {
                                return;
                            }

                            $targetStatus = (int) $data['status'];
                            if ((int) $lockedOrder->status === $targetStatus) {
                                Notification::make()
                                    ->title('Order is already in the selected status. No changes applied.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $lockedOrder->status = $targetStatus;
                            $lockedOrder->save();

                            if ($targetStatus === Order::STATUS_CANCELLED) {
                                CancelReason::updateOrCreate(
                                    ['order_id' => $lockedOrder->id],
                                    [
                                        'ref_id' => Filament::auth()->id(),
                                        'subject' => 'Admin status override',
                                        'comment' => $data['reason'],
                                        'by_user' => 'admin',
                                    ]
                                );
                            }

                            Log::info('orders.override_status', [
                                'order_id' => $lockedOrder->id,
                                'new_status' => $targetStatus,
                                'reason' => $data['reason'],
                                'actor_admin_id' => Filament::auth()->id(),
                            ]);

                            $updated = true;
                        });

                        if (! $updated) {
                            Notification::make()
                                ->title('Order not found for status override.')
                                ->danger()
                                ->send();

                            return;
                        }

                        Notification::make()
                            ->title('Order status overridden successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('refund_full')
                    ->label('Refund Full Amount')
                    ->icon('heroicon-o-banknotes')
                    ->color('danger')
                    ->visible(fn (Order $record): bool => static::canRefundOrder() && (bool) $record->paid && ! static::isFullyRefunded($record))
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\TextInput::make('confirm_text')
                            ->label('Type REFUND to confirm')
                            ->required()
                            ->rule('in:REFUND'),
                        Forms\Components\Textarea::make('reason')
                            ->label('Refund reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (Order $record, array $data): void {
                        if (! static::canRefundOrder()) {
                            Notification::make()->title('You are not authorized to refund orders.')->danger()->send();
                            return;
                        }

                        if (($data['confirm_text'] ?? null) !== 'REFUND') {
                            Notification::make()
                                ->title('Refund confirmation text mismatch.')
                                ->danger()
                                ->send();

                            return;
                        }

                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to issue a manual refund.'
                        )) {
                            return;
                        }

                        try {
                            $order = Order::query()->with('payment')->find($record->id);
                            if (! $order || ! $order->payment) {
                                Notification::make()->title('Refund failed: Order payment record is missing.')->danger()->send();
                                return;
                            }

                            $result = app(AdminPaymentRefundService::class)->refundFull(
                                $order->payment,
                                (string) ($data['reason'] ?? ''),
                                (int) Filament::auth()->id()
                            );

                            if (($result['status'] ?? null) === 'already_refunded') {
                                Notification::make()->title('Refund already processed for this order.')->warning()->send();
                                return;
                            }

                            Notification::make()
                                ->title('Refund submitted successfully.')
                                ->success()
                                ->send();
                        } catch (Throwable $throwable) {
                            Notification::make()
                                ->title('Refund failed: ' . $throwable->getMessage())
                                ->danger()
                                ->send();
                        }
                    }),
            ])
            ->defaultSort('id', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListOrders::route('/'),
            'create' => Pages\CreateOrder::route('/create'),
            'edit' => Pages\EditOrder::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        return static::canViewOrders();
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return false;
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    private static function canViewOrders(): bool
    {
        return (bool) Filament::auth()->user()?->can('orders.view');
    }

    private static function canOverrideStatus(): bool
    {
        return (bool) Filament::auth()->user()?->can('orders.override_status');
    }

    private static function canRefundOrder(): bool
    {
        return (bool) Filament::auth()->user()?->can('orders.refund');
    }

    private static function isFullyRefunded(Order $record): bool
    {
        if ((int) $record->refund_percentage >= 100) {
            return true;
        }

        return Refund::query()->where('order_id', $record->id)->exists();
    }

    private static function formatStatus(int $status): string
    {
        return match ($status) {
            Order::STATUS_COMPLETED => 'Completed',
            Order::STATUS_REQUESTED => 'Requested',
            Order::STATUS_CONFIRMED => 'Confirmed',
            Order::STATUS_IN_PROGRESS => 'In Progress',
            Order::STATUS_CANCELLED => 'Cancelled',
            Order::STATUS_LEGACY_CANCELLED => 'Cancelled (legacy: 0)',
            default => 'Unknown',
        };
    }

    private static function statusColor(int $status): string
    {
        return match ($status) {
            Order::STATUS_LEGACY_CANCELLED, Order::STATUS_CANCELLED => 'danger',
            Order::STATUS_COMPLETED => 'success',
            Order::STATUS_REQUESTED => 'warning',
            Order::STATUS_CONFIRMED => 'info',
            Order::STATUS_IN_PROGRESS => 'primary',
            default => 'gray',
        };
    }

    private static function statusOptions(bool $includeLegacy): array
    {
        $options = [
            Order::STATUS_COMPLETED => 'Completed',
            Order::STATUS_REQUESTED => 'Requested',
            Order::STATUS_CONFIRMED => 'Confirmed',
            Order::STATUS_IN_PROGRESS => 'In Progress',
            Order::STATUS_CANCELLED => 'Cancelled',
        ];

        if ($includeLegacy) {
            $options[Order::STATUS_LEGACY_CANCELLED] = 'Cancelled (legacy: 0)';
        }

        return $options;
    }

    private static function refundStateLabel(Order $record): string
    {
        $percentage = (int) ($record->refund_percentage ?? 0);
        $hasRefund = (int) ($record->refunds_count ?? 0) > 0;
        $maxRecordedRefundPercentage = (int) ($record->refunds_max_percentage ?? 0);

        if ($percentage >= 100 || $maxRecordedRefundPercentage >= 100) {
            return 'Full Refunded';
        }

        if ($percentage > 0 || $hasRefund) {
            return 'Partial Refunded';
        }

        return 'Not Refunded';
    }

    private static function refundStateColor(Order $record): string
    {
        return match (static::refundStateLabel($record)) {
            'Full Refunded' => 'success',
            'Partial Refunded' => 'warning',
            default => 'gray',
        };
    }

    private static function renderTimeline(Order $record): string
    {
        $entries = [
            'Created: ' . ($record->created_at ? $record->created_at->format('Y-m-d H:i') : '-'),
        ];

        if ($record->payment?->confirm_date_time) {
            $entries[] = 'Payment confirmed: ' . Carbon::parse($record->payment->confirm_date_time)->format('Y-m-d H:i');
        }

        if ($record->completedorder?->completed_date_time) {
            $entries[] = 'Completed: ' . Carbon::parse($record->completedorder->completed_date_time)->format('Y-m-d H:i');
        }

        if ($record->cancelreason?->created_at) {
            $entries[] = 'Cancelled: ' . Carbon::parse($record->cancelreason->created_at)->format('Y-m-d H:i');
        }

        $entries[] = 'Current status: ' . static::formatStatus((int) $record->status);

        return implode(PHP_EOL, $entries);
    }
}
