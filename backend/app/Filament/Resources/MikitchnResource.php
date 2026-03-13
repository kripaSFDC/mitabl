<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MikitchnResource\Pages;
use App\Models\Mikitchn;
use App\Models\Order;
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
use Illuminate\Support\Str;

class MikitchnResource extends Resource
{
    protected static ?string $model = Mikitchn::class;

    protected static ?string $navigationIcon = 'heroicon-o-building-storefront';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 20;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Kitchen Identity')
                    ->description('Core display information shown to customers in search results and on the kitchen profile page.')
                    ->icon('heroicon-o-building-storefront')
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->label('Micook account')
                            ->relationship('user', 'email', fn ($query) => $query->where('role_id', 2))
                            ->searchable()
                            ->preload()
                            ->required(),
                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('phone')
                            ->tel()
                            ->required()
                            ->maxLength(255)
                            ->helperText('Contact number visible to ops team only.'),
                        Forms\Components\TextInput::make('address')
                            ->required()
                            ->minLength(8)
                            ->maxLength(255)
                            ->columnSpanFull()
                            ->helperText('Full street address. Used for delivery radius calculations and customer-facing display.'),
                        Forms\Components\Textarea::make('description')
                            ->rows(3)
                            ->columnSpanFull()
                            ->helperText('Short description shown on the kitchen profile card.'),
                    ])
                    ->columns(2),

                Forms\Components\Section::make('Geo & Capacity')
                    ->description('GPS coordinates are required for proximity search. Seats are the max dine-in capacity.')
                    ->icon('heroicon-o-map-pin')
                    ->schema([
                        Forms\Components\TextInput::make('latitude')
                            ->numeric()
                            ->minValue(-90)
                            ->maxValue(90)
                            ->required()
                            ->helperText('-90 to 90'),
                        Forms\Components\TextInput::make('longitude')
                            ->numeric()
                            ->minValue(-180)
                            ->maxValue(180)
                            ->required()
                            ->helperText('-180 to 180'),
                        Forms\Components\TextInput::make('no_of_seats')
                            ->label('Seats')
                            ->numeric()
                            ->minValue(0)
                            ->helperText('Max dine-in capacity. Leave 0 if not applicable.'),
                        Forms\Components\Textarea::make('timings')
                            ->label('Operating timings')
                            ->rows(3)
                            ->columnSpanFull()
                            ->helperText('Store schedule payload exactly as provided by operations/mobile.'),
                    ])
                    ->columns(3),

                Forms\Components\Section::make('Service & Status')
                    ->description('Control which service modes are offered and whether the kitchen is active on the platform. Activation requires an approved certificate.')
                    ->icon('heroicon-o-adjustments-horizontal')
                    ->schema([
                        Forms\Components\Toggle::make('dine_in')
                            ->label('Dine-in available')
                            ->inline(false),
                        Forms\Components\Toggle::make('take_away')
                            ->label('Take-away available')
                            ->inline(false),
                        Forms\Components\Toggle::make('open')
                            ->label('Currently open')
                            ->inline(false)
                            ->helperText('Toggle off to pause all incoming orders.'),
                        Forms\Components\Select::make('status')
                            ->options([
                                0 => 'Inactive',
                                1 => 'Active',
                            ])
                            ->required()
                            ->helperText('Use the Activate/Deactivate row actions on the list for safe status transitions.'),
                    ])
                    ->columns(4),

                Forms\Components\Section::make('Certificate Review')
                    ->description('Read-only summary of the current certificate attached to this kitchen. Use the Review Certificate row action on the Certificates resource for approve/reject.')
                    ->icon('heroicon-o-document-check')
                    ->schema([
                        Forms\Components\Placeholder::make('certificate_status')
                            ->label('Certificate status')
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
                            ->label('Certificate number')
                            ->content(fn (?Mikitchn $record): string => (string) ($record?->certificate?->certificate_no ?? '-')),
                        Forms\Components\Placeholder::make('certificate_action')
                            ->label('Next step')
                            ->content(function (?Mikitchn $record): string {
                                if (! $record?->certificate) {
                                    return 'No certificate available for review.';
                                }

                                return 'Go to the Certificates resource → find this kitchen → use the Review Workspace action.';
                            }),
                    ])
                    ->columns(3)
                    ->collapsible()
                    ->visible(fn (?Mikitchn $record): bool => (bool) $record),

                Forms\Components\Section::make('System Fields')
                    ->schema([
                        Forms\Components\Placeholder::make('id')
                            ->content(fn (?Mikitchn $record): string => (string) ($record?->id ?? '-')),
                        Forms\Components\Placeholder::make('created_at')
                            ->content(fn (?Mikitchn $record): string => (string) ($record?->created_at?->toDateTimeString() ?? '-')),
                        Forms\Components\Placeholder::make('updated_at')
                            ->content(fn (?Mikitchn $record): string => (string) ($record?->updated_at?->toDateTimeString() ?? '-')),
                    ])
                    ->columns(3)
                    ->collapsible()
                    ->visible(fn (?Mikitchn $record): bool => (bool) $record),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query
                ->with(['user', 'certificate'])
                ->withAvg('reviews', 'rating')
                ->withCount(['orders', 'reviews']))
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable()
                    ->weight(\Filament\Support\Enums\FontWeight::SemiBold),
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
                Tables\Columns\TextColumn::make('user.first_name')
                    ->label('Cook')
                    ->formatStateUsing(fn (?string $state, Mikitchn $record): string => trim((optional($record->user)->first_name ?? '') . ' ' . (optional($record->user)->last_name ?? '')))
                    ->searchable(),
                Tables\Columns\TextColumn::make('location')
                    ->label('Address')
                    ->state(fn (Mikitchn $record): string => trim((string) $record->address))
                    ->description(fn (Mikitchn $record): ?string => is_numeric($record->latitude) && is_numeric($record->longitude)
                        ? number_format((float) $record->latitude, 5) . ', ' . number_format((float) $record->longitude, 5)
                        : null)
                    ->limit(40)
                    ->searchable(query: function ($query, string $search): void {
                        $query->where('address', 'like', "%{$search}%");
                    }),
                Tables\Columns\TextColumn::make('phone')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('no_of_seats')
                    ->label('Seats')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('timings')
                    ->limit(40)
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('open')
                    ->boolean()
                    ->label('Open now'),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('dine_in')
                    ->boolean()
                    ->label('Dine-in'),
                Tables\Columns\IconColumn::make('take_away')
                    ->boolean()
                    ->label('Take-away'),
                Tables\Columns\TextColumn::make('rating_summary')
                    ->label('Rating')
                    ->state(function (Mikitchn $record): string {
                        $average = $record->reviews_avg_rating;
                        $count = (int) ($record->reviews_count ?? 0);

                        if ($count === 0 || $average === null) {
                            return '-';
                        }

                        return number_format((float) $average, 1) . ' / 5 (' . $count . ')';
                    }),
                Tables\Columns\TextColumn::make('orders_count')
                    ->label('Orders')
                    ->badge()
                    ->color('info')
                    ->sortable(),
                Tables\Columns\TextColumn::make('id')
                    ->label('ID')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
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
                        if (! static::canEditKitchens()) {
                            Notification::make()->title('You are not authorized to activate kitchens.')->danger()->send();
                            return;
                        }

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
                        if (! static::canEditKitchens()) {
                            Notification::make()->title('You are not authorized to deactivate kitchens.')->danger()->send();
                            return;
                        }

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
                                ->whereIn('status', [Order::STATUS_REQUESTED, Order::STATUS_CONFIRMED])
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
                Action::make('view_profile')
                    ->label('View Profile')
                    ->icon('heroicon-o-eye')
                    ->color('gray')
                    ->visible(fn (): bool => static::canViewKitchens())
                    ->modalHeading(fn (Mikitchn $record): string => 'Kitchen: ' . $record->name)
                    ->modalSubmitAction(false)
                    ->form([
                        Forms\Components\Placeholder::make('profile')
                            ->label('Kitchen profile')
                            ->content(fn (Mikitchn $record): string => trim(implode(' | ', [
                                'Cook: ' . trim((optional($record->user)->first_name ?? '') . ' ' . (optional($record->user)->last_name ?? '')),
                                'Phone: ' . (string) ($record->phone ?? '-'),
                                'Address: ' . (string) ($record->address ?? '-'),
                            ]))),
                        Forms\Components\Placeholder::make('gallery')
                            ->label('Media gallery')
                            ->content(function (Mikitchn $record): string {
                                $media = $record->addedimage()->orderByDesc('id')->limit(5)->pluck('path')->all();
                                if ($media === []) {
                                    return 'No media uploaded';
                                }

                                return implode(PHP_EOL, array_map(fn (string $path): string => Str::limit($path, 80), $media));
                            }),
                        Forms\Components\Placeholder::make('menu')
                            ->label('Menu')
                            ->content(function (Mikitchn $record): string {
                                $foods = $record->foods()->orderByDesc('id')->limit(5)->get(['name', 'price']);
                                if ($foods->isEmpty()) {
                                    return 'No menu items';
                                }

                                return $foods
                                    ->map(fn ($food): string => (string) $food->name . ' - $' . number_format((float) $food->price, 2))
                                    ->implode(PHP_EOL);
                            }),
                        Forms\Components\Placeholder::make('reviews')
                            ->label('Recent reviews')
                            ->content(function (Mikitchn $record): string {
                                $reviews = $record->reviews()->latest('id')->limit(3)->get(['rating', 'review']);
                                if ($reviews->isEmpty()) {
                                    return 'No reviews yet';
                                }

                                return $reviews
                                    ->map(fn ($review): string => (string) $review->rating . '/5 - ' . Str::limit((string) $review->review, 80))
                                    ->implode(PHP_EOL);
                            }),
                    ])
                    ->modalWidth('4xl'),
                Tables\Actions\EditAction::make()
                    ->visible(fn (): bool => static::canEditKitchens()),
                Tables\Actions\DeleteAction::make()
                    ->requiresConfirmation()
                    ->visible(fn (): bool => static::canDeleteKitchens()),
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
        return static::canCreateKitchens();
    }

    public static function canEdit($record): bool
    {
        return static::canEditKitchens();
    }

    public static function canDelete($record): bool
    {
        return static::canDeleteKitchens();
    }

    private static function canViewKitchens(): bool
    {
        return (bool) Filament::auth()->user()?->can('kitchens.view');
    }

    private static function canEditKitchens(): bool
    {
        return (bool) Filament::auth()->user()?->can('kitchens.edit');
    }

    private static function canCreateKitchens(): bool
    {
        return (bool) Filament::auth()->user()?->can('kitchens.create');
    }

    private static function canDeleteKitchens(): bool
    {
        return (bool) Filament::auth()->user()?->can('kitchens.delete');
    }

    private static function hasValidKitchenLocation(Mikitchn $record): bool
    {
        $address = trim((string) $record->address);
        $latitude = is_numeric($record->latitude) ? (float) $record->latitude : null;
        $longitude = is_numeric($record->longitude) ? (float) $record->longitude : null;

        if ($address === '' || strlen($address) < 8 || $latitude === null || $longitude === null) {
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
