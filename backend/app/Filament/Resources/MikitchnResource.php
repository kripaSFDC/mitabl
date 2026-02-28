<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MikitchnResource\Pages;
use App\Models\Mikitchn;
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

class MikitchnResource extends Resource
{
    protected static ?string $model = Mikitchn::class;

    protected static ?string $navigationIcon = 'heroicon-o-building-storefront';

    protected static ?string $navigationGroup = 'Operations';

    protected static ?int $navigationSort = 30;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Kitchen Profile')
                    ->schema([
                        Forms\Components\TextInput::make('name')->required()->maxLength(255),
                        Forms\Components\TextInput::make('phone')->tel()->required()->maxLength(255),
                        Forms\Components\TextInput::make('address')->required()->maxLength(255),
                        Forms\Components\TextInput::make('latitude')->numeric()->required(),
                        Forms\Components\TextInput::make('longitude')->numeric()->required(),
                        Forms\Components\TextInput::make('no_of_seats')->numeric()->minValue(0),
                        Forms\Components\Toggle::make('dine_in')->inline(false),
                        Forms\Components\Toggle::make('take_away')->inline(false),
                        Forms\Components\Toggle::make('open')->label('Open')->inline(false),
                        Forms\Components\Select::make('status')
                            ->options([
                                0 => 'Inactive',
                                1 => 'Active',
                            ])
                            ->required(),
                        Forms\Components\Textarea::make('description')->columnSpanFull(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('Certificate Review')
                    ->schema([
                        Forms\Components\Placeholder::make('certificate_status')
                            ->label('Current Status')
                            ->content(function (?Mikitchn $record): string {
                                if (! $record?->certificate) {
                                    return 'No certificate submitted';
                                }

                                return match ((int) $record->certificate->status) {
                                    0 => 'Pending',
                                    1 => 'Approved',
                                    2 => 'Rejected',
                                    default => 'Unknown',
                                };
                            }),
                        Forms\Components\Placeholder::make('certificate_number')
                            ->label('Certificate Number')
                            ->content(fn (?Mikitchn $record): string => (string) ($record?->certificate?->certificate_no ?? '-')),
                        Forms\Components\Placeholder::make('certificate_action')
                            ->label('Review Action')
                            ->content(function (?Mikitchn $record): string {
                                if (! $record?->certificate) {
                                    return 'No certificate available for review.';
                                }

                                return 'Open the "Review Certificate" row action to approve or reject.';
                            }),
                    ])
                    ->columns(3)
                    ->visible(fn (?Mikitchn $record): bool => (bool) $record),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['user', 'certificate'])->withCount('orders'))
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('name')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('user.first_name')
                    ->label('Cook')
                    ->formatStateUsing(fn (?string $state, Mikitchn $record): string => trim(($record->user->first_name ?? '') . ' ' . ($record->user->last_name ?? '')))
                    ->searchable(),
                Tables\Columns\TextColumn::make('address')->limit(40)->searchable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn ($state): string => (int) $state === 1 ? 'Active' : 'Inactive')
                    ->color(fn ($state): string => (int) $state === 1 ? 'success' : 'gray'),
                Tables\Columns\TextColumn::make('certificate_status')
                    ->label('Certificate')
                    ->state(function (Mikitchn $record): string {
                        $status = optional($record->certificate)->status;

                        return match ((int) $status) {
                            1 => 'Approved',
                            2 => 'Rejected',
                            0 => 'Pending',
                            default => 'Missing',
                        };
                    })
                    ->badge()
                    ->color(function (string $state): string {
                        return match ($state) {
                            'Approved' => 'success',
                            'Rejected' => 'danger',
                            'Pending' => 'warning',
                            default => 'gray',
                        };
                    }),
                Tables\Columns\IconColumn::make('dine_in')->boolean()->label('Dine-in'),
                Tables\Columns\IconColumn::make('take_away')->boolean()->label('Take-away'),
                Tables\Columns\TextColumn::make('orders_count')->label('Orders')->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        0 => 'Inactive',
                        1 => 'Active',
                    ]),
                Tables\Filters\SelectFilter::make('certificate_status')
                    ->label('Certificate Status')
                    ->options([
                        0 => 'Pending',
                        1 => 'Approved',
                        2 => 'Rejected',
                    ])
                    ->query(function ($query, array $data) {
                        if (! array_key_exists('value', $data) || $data['value'] === null || $data['value'] === '') {
                            return $query;
                        }

                        return $query->whereHas('certificate', fn ($certQuery) => $certQuery->where('status', $data['value']));
                    }),
            ])
            ->actions([
                Action::make('activate')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->visible(fn (Mikitchn $record): bool => (int) $record->status !== 1 && static::canEditKitchens())
                    ->requiresConfirmation()
                    ->action(function (Mikitchn $record): void {
                        $activated = false;

                        DB::transaction(function () use ($record, &$activated): void {
                            $kitchen = Mikitchn::query()
                                ->lockForUpdate()
                                ->with('certificate')
                                ->find($record->id);

                            if (! $kitchen) {
                                return;
                            }

                            if ((int) $kitchen->status === 1) {
                                Notification::make()
                                    ->title('Kitchen is already active.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            if ((int) optional($kitchen->certificate)->status !== 1) {
                                Notification::make()
                                    ->title('Cannot activate kitchen without an approved certificate.')
                                    ->danger()
                                    ->send();

                                return;
                            }

                            if (! static::hasValidKitchenLocation($kitchen)) {
                                Notification::make()
                                    ->title('Cannot activate kitchen with invalid address or geolocation data.')
                                    ->danger()
                                    ->send();

                                return;
                            }

                            $kitchen->status = 1;
                            $kitchen->save();

                            Log::info('kitchens.activated', [
                                'kitchen_id' => $kitchen->id,
                                'actor_admin_id' => Filament::auth()->id(),
                            ]);

                            $activated = true;
                        });

                        if (! $activated) {
                            return;
                        }

                        Notification::make()
                            ->title('Kitchen activated successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('deactivate')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn (Mikitchn $record): bool => (int) $record->status === 1 && static::canEditKitchens())
                    ->requiresConfirmation()
                    ->action(function (Mikitchn $record): void {
                        $deactivated = false;

                        DB::transaction(function () use ($record, &$deactivated): void {
                            $kitchen = Mikitchn::query()->lockForUpdate()->find($record->id);

                            if (! $kitchen) {
                                return;
                            }

                            if ((int) $kitchen->status !== 1) {
                                Notification::make()
                                    ->title('Kitchen is already inactive.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $hasOpenBookings = $kitchen->orders()
                                ->where('status', 3)
                                ->whereDate('delivery_date', '>=', Carbon::today()->toDateString())
                                ->exists();

                            if ($hasOpenBookings) {
                                Notification::make()
                                    ->title('Cannot deactivate kitchen with open upcoming bookings.')
                                    ->danger()
                                    ->send();

                                return;
                            }

                            $kitchen->status = 0;
                            $kitchen->save();

                            Log::info('kitchens.deactivated', [
                                'kitchen_id' => $kitchen->id,
                                'actor_admin_id' => Filament::auth()->id(),
                            ]);

                            $deactivated = true;
                        });

                        if (! $deactivated) {
                            return;
                        }

                        Notification::make()
                            ->title('Kitchen deactivated successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('review_certificate')
                    ->label('Review Certificate')
                    ->icon('heroicon-o-document-magnifying-glass')
                    ->url(function (Mikitchn $record): ?string {
                        if (! $record->certificate) {
                            return null;
                        }

                        return CertificateResource::getUrl('index', [
                            'tableSearch' => $record->certificate->certificate_no,
                        ]);
                    })
                    ->openUrlInNewTab(false)
                    ->visible(fn (Mikitchn $record): bool => (bool) $record->certificate && static::canViewKitchens()),
                Tables\Actions\EditAction::make()
                    ->visible(fn (): bool => static::canEditKitchens()),
            ])
            ->defaultSort('id', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListMikitchns::route('/'),
            'create' => Pages\CreateMikitchn::route('/create'),
            'edit' => Pages\EditMikitchn::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        return static::canViewKitchens();
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return static::canEditKitchens();
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    private static function canViewKitchens(): bool
    {
        return (bool) Filament::auth()->user()?->can('kitchens.view');
    }

    private static function canEditKitchens(): bool
    {
        return (bool) Filament::auth()->user()?->can('kitchens.edit');
    }

    private static function hasValidKitchenLocation(Mikitchn $record): bool
    {
        $address = trim((string) $record->address);
        $latitude = is_numeric($record->latitude) ? (float) $record->latitude : null;
        $longitude = is_numeric($record->longitude) ? (float) $record->longitude : null;

        if ($address === '' || $latitude === null || $longitude === null) {
            return false;
        }

        if ($latitude < -90 || $latitude > 90) {
            return false;
        }

        if ($longitude < -180 || $longitude > 180) {
            return false;
        }

        return true;
    }
}

