<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PaymentResource\Pages;
use App\Models\Payment;
use App\Services\AdminPaymentRefundService;
use App\Services\AdminStepUpService;
use Filament\Facades\Filament;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Throwable;

class PaymentResource extends Resource
{
    protected static ?string $model = Payment::class;

    protected static ?string $navigationIcon = 'heroicon-o-credit-card';

    protected static ?string $navigationGroup = 'Operations';

    protected static ?int $navigationSort = 60;

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['order.user', 'order.Mikitchn', 'order.refunds']))
            ->defaultSort('id', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('order_id')
                    ->label('Order ID')
                    ->sortable()
                    ->searchable()
                    ->url(fn (Payment $record): ?string => static::safeFilamentRoute('filament.admin.resources.orders.edit', ['record' => $record->order_id]))
                    ->openUrlInNewTab(),
                Tables\Columns\TextColumn::make('order.user.email')
                    ->label('Customer')
                    ->searchable()
                    ->url(fn (Payment $record): ?string => static::safeFilamentRoute('filament.admin.resources.users.edit', ['record' => $record->order?->user_id]))
                    ->openUrlInNewTab()
                    ->placeholder('-'),
                Tables\Columns\TextColumn::make('order.Mikitchn.name')
                    ->label('Kitchen')
                    ->searchable()
                    ->url(fn (Payment $record): ?string => static::safeFilamentRoute('filament.admin.resources.mikitchns.edit', ['record' => $record->order?->mikitchn_id]))
                    ->openUrlInNewTab()
                    ->placeholder('-'),
                Tables\Columns\TextColumn::make('payment_id')
                    ->label('Payment Intent')
                    ->searchable()
                    ->copyable(),
                Tables\Columns\TextColumn::make('card_id')
                    ->label('Card')
                    ->formatStateUsing(function (?string $state): string {
                        $value = (string) $state;
                        if ($value === '') {
                            return '-';
                        }

                        return '****' . substr($value, -4);
                    }),
                Tables\Columns\TextColumn::make('amount')
                    ->money('AUD')
                    ->sortable(),
                Tables\Columns\IconColumn::make('confirm')
                    ->label('Confirmed')
                    ->boolean(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->sortable(),
                Tables\Columns\TextColumn::make('refund_state')
                    ->label('Refund State')
                    ->badge()
                    ->state(function (Payment $record): string {
                        $percentage = (int) ($record->order?->refund_percentage ?? 0);

                        if ($percentage >= 100) {
                            return 'Full Refunded';
                        }

                        if ($percentage > 0) {
                            return 'Partial Refunded';
                        }

                        return 'Not Refunded';
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'Full Refunded' => 'success',
                        'Partial Refunded' => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('latest_refund')
                    ->label('Latest Refund')
                    ->state(function (Payment $record): string {
                        $latest = $record->order?->refunds?->sortByDesc('refund_date')->first();
                        if (! $latest) {
                            return '-';
                        }

                        return '$' . number_format((float) $latest->amount, 2) . ' @ ' . optional($latest->refund_date)->format('Y-m-d H:i');
                    })
                    ->toggleable(),
                Tables\Columns\TextColumn::make('confirm_date_time')
                    ->label('Confirmed At')
                    ->dateTime('d M Y H:i')
                    ->placeholder('-')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Created')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('confirm')
                    ->label('Confirmed'),
                Tables\Filters\SelectFilter::make('status')
                    ->options(function (): array {
                        return Payment::query()
                            ->select('status')
                            ->distinct()
                            ->orderBy('status')
                            ->pluck('status', 'status')
                            ->toArray();
                    }),
            ])
            ->actions([
                Action::make('open_in_stripe')
                    ->label('Open in Stripe')
                    ->icon('heroicon-o-arrow-top-right-on-square')
                    ->url(fn (Payment $record): ?string => static::stripePaymentUrl($record))
                    ->openUrlInNewTab()
                    ->visible(fn (Payment $record): bool => (string) $record->payment_id !== ''),
                Action::make('refund_full')
                    ->label('Refund Full')
                    ->icon('heroicon-o-banknotes')
                    ->color('danger')
                    ->visible(fn (Payment $record): bool => static::canRefundPayments() && static::isRefundable($record))
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
                    ->action(function (Payment $record, array $data): void {
                        if (! static::canRefundPayments()) {
                            Notification::make()->title('You are not authorized to issue refunds.')->danger()->send();
                            return;
                        }

                        if (($data['confirm_text'] ?? null) !== 'REFUND') {
                            Notification::make()->title('Refund confirmation text mismatch.')->danger()->send();
                            return;
                        }

                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to issue a manual refund.'
                        )) {
                            return;
                        }

                        try {
                            $result = app(AdminPaymentRefundService::class)->refundFull(
                                $record,
                                (string) ($data['reason'] ?? ''),
                                (int) Filament::auth()->id()
                            );

                            if (($result['status'] ?? null) === 'already_refunded') {
                                Notification::make()->title('Refund already processed for this order.')->warning()->send();
                                return;
                            }

                            Notification::make()->title('Refund submitted successfully.')->success()->send();
                        } catch (Throwable $throwable) {
                            Notification::make()->title('Refund failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
            ])
            ->bulkActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPayments::route('/'),
        ];
    }

    public static function canViewAny(): bool
    {
        return (bool) Filament::auth()->user()?->can('payments.view');
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

    private static function canRefundPayments(): bool
    {
        return (bool) Filament::auth()->user()?->can('payments.refund');
    }

    private static function isRefundable(Payment $payment): bool
    {
        if (! $payment->order || ! $payment->payment_id) {
            return false;
        }

        if ((int) ($payment->order->refund_percentage ?? 0) > 0) {
            return false;
        }

        if ($payment->order->relationLoaded('refunds') && $payment->order->refunds->isNotEmpty()) {
            return false;
        }

        return (bool) $payment->confirm || (bool) $payment->order->paid;
    }

    private static function stripePaymentUrl(Payment $payment): ?string
    {
        $intentId = trim((string) $payment->payment_id);
        if ($intentId === '') {
            return null;
        }

        $baseUrl = rtrim((string) config('services.stripe.dashboard_base_url', 'https://dashboard.stripe.com/payments'), '/');

        return $baseUrl . '/' . rawurlencode($intentId);
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
}
