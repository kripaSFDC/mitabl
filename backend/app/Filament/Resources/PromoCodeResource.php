<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PromoCodeResource\Pages;
use App\Models\PromoCode;
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
                    ->schema([
                        Forms\Components\TextInput::make('code')
                            ->required()
                            ->maxLength(255)
                            ->unique(ignoreRecord: true),
                        Forms\Components\TextInput::make('percentage_value')
                            ->label('Discount (%)')
                            ->required()
                            ->numeric()
                            ->minValue(1)
                            ->maxValue(100),
                        Forms\Components\Toggle::make('status')
                            ->label('Active')
                            ->inline(false)
                            ->default(true),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->withCount('orders'))
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('code')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('percentage_value')
                    ->label('Discount')
                    ->formatStateUsing(fn ($state): string => (string) $state . '%')
                    ->sortable(),
                Tables\Columns\TextColumn::make('orders_count')
                    ->label('Usage Count')
                    ->sortable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn ($state): string => (int) $state === 1 ? 'Active' : 'Inactive')
                    ->color(fn ($state): string => (int) $state === 1 ? 'success' : 'gray'),
                Tables\Columns\TextColumn::make('updated_at')->since(),
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

                            $promoCode->status = 1;
                            $promoCode->save();

                            Log::info('promo_codes.activated', [
                                'promo_code_id' => $promoCode->id,
                                'code' => $promoCode->code,
                                'actor_admin_id' => Filament::auth()->id(),
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
}

