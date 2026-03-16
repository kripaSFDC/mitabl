<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PromoCodeResource\Pages;
use App\Models\Order;
use App\Models\PromoCode;
use App\Services\AdminAuditLogService;
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
use Illuminate\Support\HtmlString;
use Illuminate\Validation\ValidationException;

class PromoCodeResource extends Resource
{
    protected static ?string $model = PromoCode::class;

    protected static ?string $navigationIcon = 'heroicon-o-ticket';

    protected static ?string $navigationGroup = 'Operations';

    protected static ?int $navigationSort = 50;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Promo Code')
                    ->description('Define the discount code, its discount percentage, and its validity window. Active codes can be used at checkout immediately.')
                    ->icon('heroicon-o-ticket')
                    ->schema([
                        Forms\Components\TextInput::make('code')
                            ->required()
                            ->maxLength(255)
                            ->unique(ignoreRecord: true)
                            ->helperText('Uppercase codes recommended. Must be globally unique.')
                            ->extraInputAttributes(['style' => 'font-family: monospace; letter-spacing: 0.05em;']),
                        Forms\Components\TextInput::make('percentage_value')
                            ->label('Discount (%)')
                            ->required()
                            ->numeric()
                            ->minValue(1)
                            ->maxValue(100)
                            ->suffix('%')
                            ->helperText('Enter a value between 1 and 100.'),
                        Forms\Components\Toggle::make('status')
                            ->label('Active')
                            ->inline(false)
                            ->default(true)
                            ->helperText('Use the Activate / Deactivate row actions for safe status transitions with audit log.'),
                    ])
                    ->columns(['default' => 3]),

                Forms\Components\Section::make('Validity Window')
                    ->description('Optionally restrict the code to a specific date range. Outside this window the code will be rejected at checkout even if Active.')
                    ->icon('heroicon-o-calendar-days')
                    ->schema([
                        Forms\Components\DateTimePicker::make('starts_at')
                            ->label('Valid from')
                            ->seconds(false)
                            ->helperText('Leave empty for immediate validity.'),
                        Forms\Components\DateTimePicker::make('ends_at')
                            ->label('Valid until')
                            ->seconds(false)
                            ->after('starts_at')
                            ->helperText('Leave empty for no expiry.'),
                    ])
                    ->columns(['default' => 2])
                    ->collapsible(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->withCount('orders'))
            ->columns([
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn ($state): string => (int) $state === 1 ? 'Active' : 'Inactive')
                    ->colors([
                        'success' => 1,
                        'gray' => 0,
                    ]),
                Tables\Columns\TextColumn::make('code')
                    ->searchable()
                    ->sortable()
                    ->copyable()
                    ->weight(\Filament\Support\Enums\FontWeight::SemiBold),
                Tables\Columns\TextColumn::make('percentage_value')
                    ->label('Discount')
                    ->formatStateUsing(fn ($state): string => (string) $state . '%')
                    ->badge()
                    ->color('info')
                    ->sortable(),
                Tables\Columns\TextColumn::make('validity')
                    ->label('Validity window')
                    ->state(function (PromoCode $record): string {
                        $from = $record->starts_at ? \Carbon\Carbon::parse($record->starts_at)->format('d M Y') : 'Now';
                        $until = $record->ends_at ? \Carbon\Carbon::parse($record->ends_at)->format('d M Y') : 'No expiry';
                        return $from . ' → ' . $until;
                    }),
                Tables\Columns\TextColumn::make('orders_count')
                    ->label('Usage')
                    ->badge()
                    ->color('success')
                    ->sortable(),
                Tables\Columns\TextColumn::make('starts_at')
                    ->label('Valid from')
                    ->dateTime('d M Y H:i')
                    ->placeholder('Immediate')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('ends_at')
                    ->label('Valid until')
                    ->dateTime('d M Y H:i')
                    ->placeholder('No expiry')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Last updated')
                    ->since()
                    ->sortable(),
                Tables\Columns\TextColumn::make('id')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('status')
                    ->label('Active'),
            ])
            ->actions([
                Action::make('deactivate')
                    ->label('Deactivate')
                    ->icon('heroicon-o-no-symbol')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn (PromoCode $record): bool => (int) $record->status === 1 && static::canEditPromoCodes())
                    ->action(function (PromoCode $record): void {
                        $deactivated = false;

                        DB::transaction(function () use ($record, &$deactivated): void {
                            $promoCode = PromoCode::query()->lockForUpdate()->find($record->id);

                            if (! $promoCode) {
                                return;
                            }

                            if ((int) $promoCode->status !== 1) {
                                Notification::make()
                                    ->title('Promo code is already inactive.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $promoCode->status = 0;
                            $promoCode->save();

                            Log::info('promo_codes.deactivated', [
                                'promo_code_id' => $promoCode->id,
                                'code' => $promoCode->code,
                                'actor_admin_id' => Filament::auth()->id(),
                            ]);
                            app(AdminAuditLogService::class)->log('promo_codes.deactivated', request(), [
                                'promo_code_id' => $promoCode->id,
                                'code' => $promoCode->code,
                            ]);

                            $deactivated = true;
                        });

                        if (! $deactivated) {
                            return;
                        }

                        Notification::make()
                            ->title('Promo code deactivated.')
                            ->success()
                            ->send();
                    }),
                Action::make('activate')
                    ->label('Activate')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->visible(fn (PromoCode $record): bool => (int) $record->status === 0 && static::canEditPromoCodes())
                    ->action(function (PromoCode $record): void {
                        $activated = false;

                        DB::transaction(function () use ($record, &$activated): void {
                            $promoCode = PromoCode::query()->lockForUpdate()->find($record->id);

                            if (! $promoCode) {
                                return;
                            }

                            if ((int) $promoCode->status === 1) {
                                Notification::make()
                                    ->title('Promo code is already active.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            static::assertNoOverlappingActiveRule($promoCode);

                            $promoCode->status = 1;
                            $promoCode->save();

                            Log::info('promo_codes.activated', [
                                'promo_code_id' => $promoCode->id,
                                'code' => $promoCode->code,
                                'actor_admin_id' => Filament::auth()->id(),
                            ]);
                            app(AdminAuditLogService::class)->log('promo_codes.activated', request(), [
                                'promo_code_id' => $promoCode->id,
                                'code' => $promoCode->code,
                            ]);

                            $activated = true;
                        });

                        if (! $activated) {
                            return;
                        }

                        Notification::make()
                            ->title('Promo code activated.')
                            ->success()
                            ->send();
                    }),
                Action::make('usage_history')
                    ->label('Usage History')
                    ->icon('heroicon-o-clock')
                    ->color('gray')
                    ->modalHeading(fn (PromoCode $record): string => 'Usage History: ' . $record->code)
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('Close')
                    ->modalContent(function (PromoCode $record): HtmlString {
                        $orders = Order::query()
                            ->with(['user', 'Mikitchn'])
                            ->where('promo_code', $record->id)
                            ->orderByDesc('created_at')
                            ->limit(25)
                            ->get();

                        if ($orders->isEmpty()) {
                            return new HtmlString('<p>No usage found for this promo code.</p>');
                        }

                        $rows = $orders->map(function (Order $order): string {
                            return sprintf(
                                '<tr><td class="px-2 py-1">#%d</td><td class="px-2 py-1">%s</td><td class="px-2 py-1">%s</td><td class="px-2 py-1">$%0.2f</td><td class="px-2 py-1">%s</td></tr>',
                                $order->id,
                                e((string) optional($order->user)->email ?: '-'),
                                e((string) optional($order->Mikitchn)->name ?: '-'),
                                (float) $order->total_price,
                                e(optional($order->created_at)->format('Y-m-d H:i') ?? '-')
                            );
                        })->implode('');

                        return new HtmlString('<div class="overflow-x-auto"><table class="w-full text-xs border-collapse"><thead><tr><th class="px-2 py-1 text-left">Order</th><th class="px-2 py-1 text-left">Customer</th><th class="px-2 py-1 text-left">Kitchen</th><th class="px-2 py-1 text-left">Amount</th><th class="px-2 py-1 text-left">Used At</th></tr></thead><tbody>' . $rows . '</tbody></table></div>');
                    }),
                Tables\Actions\EditAction::make()
                    ->visible(fn (): bool => static::canEditPromoCodes()),
            ])
            ->defaultSort('id', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPromoCodes::route('/'),
            'create' => Pages\CreatePromoCode::route('/create'),
            'edit' => Pages\EditPromoCode::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        return static::canViewPromoCodes();
    }

    public static function canCreate(): bool
    {
        return static::canEditPromoCodes();
    }

    public static function canEdit($record): bool
    {
        return static::canEditPromoCodes();
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    private static function canViewPromoCodes(): bool
    {
        return (bool) Filament::auth()->user()?->can('promo_codes.view');
    }

    private static function canEditPromoCodes(): bool
    {
        return (bool) Filament::auth()->user()?->can('promo_codes.edit');
    }

    public static function validatePromoCodeWindow(array $data, ?PromoCode $record = null): void
    {
        $startsAt = isset($data['starts_at']) && $data['starts_at'] !== null ? Carbon::parse((string) $data['starts_at']) : null;
        $endsAt = isset($data['ends_at']) && $data['ends_at'] !== null ? Carbon::parse((string) $data['ends_at']) : null;

        if ($startsAt && $endsAt && $startsAt->gt($endsAt)) {
            throw ValidationException::withMessages([
                'starts_at' => 'Valid From must be before or equal to Valid Until.',
            ]);
        }

        $isActive = (int) ($data['status'] ?? ($record?->status ? 1 : 0)) === 1;
        if (! $isActive) {
            return;
        }

        $code = trim((string) ($data['code'] ?? $record?->code ?? ''));
        if ($code === '') {
            return;
        }

        $query = PromoCode::query()
            ->whereRaw('LOWER(code) = ?', [strtolower($code)])
            ->where('status', 1);

        if ($record) {
            $query->where('id', '!=', $record->id);
        }

        $conflicts = $query->get(['id', 'starts_at', 'ends_at']);
        foreach ($conflicts as $conflict) {
            if (static::windowsOverlap($startsAt, $endsAt, $conflict->starts_at, $conflict->ends_at)) {
                throw ValidationException::withMessages([
                    'code' => 'Active promo rules overlap with another active promo code using the same code.',
                ]);
            }
        }
    }

    private static function assertNoOverlappingActiveRule(PromoCode $record): void
    {
        static::validatePromoCodeWindow([
            'code' => $record->code,
            'status' => 1,
            'starts_at' => $record->starts_at,
            'ends_at' => $record->ends_at,
        ], $record);
    }

    private static function windowsOverlap(
        Carbon|string|null $leftStart,
        Carbon|string|null $leftEnd,
        Carbon|string|null $rightStart,
        Carbon|string|null $rightEnd
    ): bool {
        $leftStartTs = $leftStart ? Carbon::parse((string) $leftStart)->getTimestamp() : PHP_INT_MIN;
        $leftEndTs = $leftEnd ? Carbon::parse((string) $leftEnd)->getTimestamp() : PHP_INT_MAX;
        $rightStartTs = $rightStart ? Carbon::parse((string) $rightStart)->getTimestamp() : PHP_INT_MIN;
        $rightEndTs = $rightEnd ? Carbon::parse((string) $rightEnd)->getTimestamp() : PHP_INT_MAX;

        return $leftStartTs <= $rightEndTs && $rightStartTs <= $leftEndTs;
    }
}

