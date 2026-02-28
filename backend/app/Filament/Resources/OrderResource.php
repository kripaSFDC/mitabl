<?php

namespace App\Filament\Resources;

use App\Filament\Resources\OrderResource\Pages;
use App\Models\CancelReason;
use App\Models\Order;
use App\Models\Refund;
use App\Services\PaymentService;
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
use Illuminate\Support\Facades\Mail;
use RuntimeException;
use Throwable;

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-clipboard-document-list';

    protected static string|\UnitEnum|null $navigationGroup = 'Operations';

    protected static ?int $navigationSort = 40;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Order Details')
                    ->schema([
                        Forms\Components\Select::make('mikitchn_id')
                            ->relationship('Mikitchn', 'name')
                            ->required(),
                        Forms\Components\Select::make('user_id')
                            ->relationship('user', 'email')
                            ->searchable()
                            ->required(),
                        Forms\Components\DatePicker::make('delivery_date')->required(),
                        Forms\Components\TimePicker::make('delivery_time_from')->required(),
                        Forms\Components\TimePicker::make('delivery_time_to')->required(),
                        Forms\Components\TextInput::make('item_total_price')->numeric()->required(),
                        Forms\Components\TextInput::make('total_price')->numeric()->required(),
                        Forms\Components\TextInput::make('taxes')->numeric(),
                        Forms\Components\TextInput::make('refund_percentage')->numeric(),
                        Forms\Components\Select::make('status')
                            ->options([
                                0 => 'Cancelled',
                                1 => 'Completed',
                                2 => 'Requested',
                                3 => 'Confirmed',
                                4 => 'Cancelled (legacy)',
                            ])
                            ->required(),
                        Forms\Components\Toggle::make('paid'),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['Mikitchn.user', 'user', 'payment', 'cancelreason'])->withCount('orderdata'))
            ->columns([
                Tables\Columns\TextColumn::make('id')->label('Order ID')->sortable()->searchable(),
                Tables\Columns\TextColumn::make('Mikitchn.name')->label('Kitchen')->searchable(),
                Tables\Columns\TextColumn::make('user.email')->label('Customer')->searchable(),
                Tables\Columns\TextColumn::make('delivery_date')->date()->sortable(),
                Tables\Columns\TextColumn::make('order_type')
                    ->label('Type')
                    ->state(fn (Order $record): string => (int) $record->dine_in === 1 ? 'Dine-in' : 'Take-away')
                    ->badge(),
                Tables\Columns\TextColumn::make('total_price')->money('AUD')->sortable(),
                Tables\Columns\IconColumn::make('paid')->boolean(),
                Tables\Columns\TextColumn::make('refund_percentage')
                    ->label('Refund %')
                    ->formatStateUsing(fn ($state): string => $state === null ? '-' : ((int) $state) . '%'),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn ($state): string => static::formatStatus((int) $state))
                    ->color(fn ($state): string => static::statusColor((int) $state)),
                Tables\Columns\TextColumn::make('cancelreason.subject')
                    ->label('Cancel Reason')
                    ->placeholder('-')
                    ->toggleable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        0 => 'Cancelled',
                        1 => 'Completed',
                        2 => 'Requested',
                        3 => 'Confirmed',
                        4 => 'Cancelled (legacy)',
                    ]),
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
                        Forms\Components\Placeholder::make('kitchen')
                            ->label('Kitchen')
                            ->content(fn (Order $record): string => (string) ($record->Mikitchn->name ?? '-')),
                        Forms\Components\Placeholder::make('customer')
                            ->label('Customer')
                            ->content(fn (Order $record): string => (string) ($record->user->email ?? '-')),
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
                            ->content(fn (Order $record): string => (string) ($record->payment->payment_id ?? '-')),
                        Forms\Components\Placeholder::make('payment_status')
                            ->label('Payment Status')
                            ->content(fn (Order $record): string => (string) ($record->payment->status ?? '-')),
                        Forms\Components\Placeholder::make('refund_percentage')
                            ->label('Refund %')
                            ->content(fn (Order $record): string => $record->refund_percentage === null ? '-' : ((int) $record->refund_percentage) . '%'),
                        Forms\Components\Placeholder::make('cancel_reason')
                            ->label('Cancel Reason')
                            ->content(fn (Order $record): string => (string) ($record->cancelreason->comment ?? '-')),
                    ])
                    ->columns(2),
                Action::make('override_status')
                    ->label('Override Status')
                    ->icon('heroicon-o-pencil-square')
                    ->color('warning')
                    ->visible(fn (): bool => static::canOverrideStatus())
                    ->form([
                        Forms\Components\Select::make('status')
                            ->required()
                            ->options([
                                0 => 'Cancelled',
                                1 => 'Completed',
                                2 => 'Requested',
                                3 => 'Confirmed',
                                4 => 'Cancelled (legacy)',
                            ]),
                        Forms\Components\Textarea::make('reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500),
                    ])
                    ->action(function (Order $record, array $data): void {
                        $updated = false;

                        DB::transaction(function () use ($record, $data, &$updated): void {
                            $lockedOrder = Order::query()->lockForUpdate()->find($record->id);

                            if (! $lockedOrder) {
                                return;
                            }

                            $lockedOrder->status = (int) $data['status'];
                            $lockedOrder->save();

                            if ((int) $data['status'] === 0) {
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
                                'new_status' => (int) $data['status'],
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
                    ])
                    ->action(function (Order $record, array $data): void {
                        if (($data['confirm_text'] ?? null) !== 'REFUND') {
                            Notification::make()
                                ->title('Refund confirmation text mismatch.')
                                ->danger()
                                ->send();

                            return;
                        }

                        try {
                            DB::transaction(function () use ($record, $data): void {
                                $order = Order::query()->lockForUpdate()->with('payment')->find($record->id);

                                if (! $order || ! $order->payment) {
                                    throw new RuntimeException('Order payment record is missing.');
                                }

                                if (! $order->payment->payment_id) {
                                    throw new RuntimeException('Payment intent is missing for this order.');
                                }

                                $alreadyRefunded = Refund::query()
                                    ->where('order_id', $order->id)
                                    ->exists();

                                if ($alreadyRefunded) {
                                    throw new RuntimeException('Refund already processed for this order.');
                                }

                                if ((int) $order->refund_percentage >= 100) {
                                    throw new RuntimeException('Order is already marked as fully refunded.');
                                }

                                /** @var PaymentService $paymentService */
                                $paymentService = app(PaymentService::class);
                                $refundResponse = $paymentService->refundAmount(
                                    $order->payment->payment_id,
                                    (float) $order->total_price,
                                    0,
                                    'admin_full_refund_order_' . $order->id
                                );

                                Refund::create([
                                    'order_id' => $order->id,
                                    'user_id' => $order->user_id,
                                    'percentage' => 100,
                                    'amount' => (float) $order->total_price,
                                    'balance_trans' => $refundResponse->balance_transaction ?? null,
                                    'refund_date' => Carbon::now(),
                                    'reciept_no' => Carbon::now(),
                                    'status' => 1,
                                ]);

                                $order->refund_percentage = 100;
                                $order->save();

                                CancelReason::updateOrCreate(
                                    ['order_id' => $order->id, 'subject' => 'Admin full refund'],
                                    [
                                        'ref_id' => Filament::auth()->id(),
                                        'comment' => $data['reason'],
                                        'by_user' => 'admin',
                                    ]
                                );

                                if ($order->user?->email) {
                                    Mail::to($order->user->email)->queue(
                                        (new \App\Mail\RefundInvoice($order->user, $order, 1, 100))->afterCommit()
                                    );
                                }

                                Log::info('orders.refund_full', [
                                    'order_id' => $order->id,
                                    'amount' => (float) $order->total_price,
                                    'reason' => $data['reason'],
                                    'actor_admin_id' => Filament::auth()->id(),
                                ]);
                            });

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
            0 => 'Cancelled',
            1 => 'Completed',
            2 => 'Requested',
            3 => 'Confirmed',
            4 => 'Cancelled (legacy)',
            default => 'Unknown',
        };
    }

    private static function statusColor(int $status): string
    {
        return match ($status) {
            0, 4 => 'danger',
            1 => 'success',
            2 => 'warning',
            3 => 'info',
            default => 'gray',
        };
    }
}
