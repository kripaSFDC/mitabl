<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
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

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-users';

    protected static string|\UnitEnum|null $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 20;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('User Profile')
                    ->schema([
                        Forms\Components\TextInput::make('first_name')->required()->maxLength(255),
                        Forms\Components\TextInput::make('last_name')->required()->maxLength(255),
                        Forms\Components\TextInput::make('email')->email()->required()->maxLength(255),
                        Forms\Components\TextInput::make('phone')->tel()->maxLength(255),
                        Forms\Components\TextInput::make('address')->maxLength(255),
                        Forms\Components\Select::make('role_id')
                            ->relationship('role', 'role')
                            ->required(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('Account Status')
                    ->schema([
                        Forms\Components\Toggle::make('suspended')
                            ->disabled(),
                        Forms\Components\Textarea::make('suspension_reason')->disabled(),
                        Forms\Components\DateTimePicker::make('suspended_at')->disabled(),
                    ])
                    ->columns(1),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['role', 'restaurant', 'orders']))
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
                    ->label('Role')
                    ->badge()
                    ->sortable(),
                Tables\Columns\IconColumn::make('suspended')
                    ->boolean()
                    ->label('Suspended'),
                Tables\Columns\TextColumn::make('orders_count')
                    ->label('Orders')
                    ->counts('orders')
                    ->sortable(),
                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Last Activity')
                    ->since(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('suspended')
                    ->label('Suspended'),
                Tables\Filters\SelectFilter::make('role_id')
                    ->relationship('role', 'role')
                    ->label('Role'),
            ])
            ->actions([
                Action::make('suspend')
                    ->icon('heroicon-o-lock-closed')
                    ->color('danger')
                    ->visible(fn (User $record): bool => ! $record->suspended && static::canSuspend())
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Suspension reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500)
                            ->rows(4),
                    ])
                    ->action(function (User $record, array $data): void {
                        $suspended = false;

                        DB::transaction(function () use ($record, $data, &$suspended): void {
                            $user = User::query()->lockForUpdate()->find($record->id);

                            if (! $user) {
                                return;
                            }

                            if ((int) $user->role_id === 1) {
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

                        Notification::make()
                            ->title('User suspended successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('unsuspend')
                    ->icon('heroicon-o-lock-open')
                    ->color('success')
                    ->visible(fn (User $record): bool => (bool) $record->suspended && static::canSuspend())
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Unsuspension reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500)
                            ->rows(4),
                    ])
                    ->action(function (User $record, array $data): void {
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

                        Notification::make()
                            ->title('User unsuspended successfully.')
                            ->success()
                            ->send();
                    }),
                Tables\Actions\EditAction::make()
                    ->visible(fn (): bool => static::canEditUsers()),
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
}
