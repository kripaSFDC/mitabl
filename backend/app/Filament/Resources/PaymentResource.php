<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PaymentResource\Pages;
use App\Models\Payment;
use Filament\Facades\Filament;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

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
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['order.user']))
            ->defaultSort('id', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('order_id')
                    ->label('Order ID')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('order.user.email')
                    ->label('Customer')
                    ->searchable()
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
            ->actions([])
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
}
