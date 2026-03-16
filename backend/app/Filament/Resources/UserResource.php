<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\AdminUser;
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
use Illuminate\Support\Facades\DB;

class UserResource extends Resource
{
    protected static ?string $model = AdminUser::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';

    protected static ?string $navigationLabel = 'Platform Users';

    protected static ?string $navigationGroup = 'Operations';

    protected static ?int $navigationSort = 20;

    protected static ?string $modelLabel = 'Platform user';

    protected static ?string $pluralModelLabel = 'Platform users';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Admin Identity')
                    ->description('Platform admin account details and role assignments.')
                    ->icon('heroicon-o-user')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('email')
                            ->email()
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(255),
                        Forms\Components\Select::make('roles')
                            ->relationship('roles', 'name')
                            ->multiple()
                            ->preload()
                            ->searchable()
                            ->required()
                            ->helperText('Assign one or more admin RBAC roles.'),
                        Forms\Components\Toggle::make('is_active')
                            ->label('Active')
                            ->default(true),
                        Forms\Components\TextInput::make('password')
                            ->password()
                            ->revealable(false)
                            ->required(fn (string $operation): bool => $operation === 'create')
                            ->minLength(8)
                            ->dehydrated(fn (?string $state): bool => filled($state)),
                        Forms\Components\TextInput::make('password_confirmation')
                            ->password()
                            ->revealable(false)
                            ->same('password')
                            ->required(fn (string $operation): bool => $operation === 'create')
                            ->dehydrated(false),
                    ])
                    ->columns(['default' => 2]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with('roles'))
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('ID')
                    ->sortable(),
                Tables\Columns\TextColumn::make('name')
                    ->label('Name')
                    ->searchable()
                    ->weight(\Filament\Support\Enums\FontWeight::SemiBold),
                Tables\Columns\TextColumn::make('email')
                    ->searchable()
                    ->copyable(),
                Tables\Columns\TextColumn::make('roles.name')
                    ->label('Roles')
                    ->badge()
                    ->separator(', ')
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-badge')
                    ->falseIcon('heroicon-o-x-circle'),
                Tables\Columns\TextColumn::make('last_login_at')
                    ->label('Last Login')
                    ->dateTime('d M Y H:i')
                    ->since()
                    ->sortable()
                    ->placeholder('-')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Created')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Active'),
                Tables\Filters\SelectFilter::make('roles')
                    ->relationship('roles', 'name')
                    ->label('Role'),
            ])
            ->actions([
                Action::make('suspend')
                    ->icon('heroicon-o-no-symbol')
                    ->color('danger')
                    ->visible(fn (AdminUser $record): bool => (bool) $record->is_active && static::canEditUsers())
                    ->form([
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
                    ->action(function (AdminUser $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to suspend this account.'
                        )) {
                            return;
                        }

                        $suspended = false;

                        DB::transaction(function () use ($record, &$suspended): void {
                            $user = AdminUser::query()->lockForUpdate()->find($record->id);
                            if (! $user || ! $user->is_active) {
                                return;
                            }

                            if ($user->hasRole('super_admin')) {
                                Notification::make()
                                    ->title('Super admin accounts cannot be suspended.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $user->is_active = false;
                            $user->save();
                            $suspended = true;
                        });

                        if (! $suspended) {
                            return;
                        }

                        Notification::make()
                            ->title('Platform user suspended successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('unsuspend')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->visible(fn (AdminUser $record): bool => ! (bool) $record->is_active && static::canEditUsers())
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Unsuspension reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500),
                        Forms\Components\TextInput::make('current_password')
                            ->label('Confirm admin password')
                            ->password()
                            ->revealable(false)
                            ->required(),
                    ])
                    ->action(function (AdminUser $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to unsuspend this account.'
                        )) {
                            return;
                        }

                        $unsuspended = false;

                        DB::transaction(function () use ($record, &$unsuspended): void {
                            $user = AdminUser::query()->lockForUpdate()->find($record->id);
                            if (! $user || $user->is_active) {
                                return;
                            }

                            $user->is_active = true;
                            $user->suspended_by = null;
                            unset($user->suspended_by);
                            $user->save();
                            $unsuspended = true;
                        });

                        if (! $unsuspended) {
                            return;
                        }

                        Notification::make()
                            ->title('Platform user unsuspended successfully.')
                            ->success()
                            ->send();
                    }),
                Tables\Actions\EditAction::make()
                    ->visible(fn (): bool => static::canEditUsers()),
                Tables\Actions\DeleteAction::make()
                    ->visible(fn (AdminUser $record): bool => static::canDeleteUsers($record)),
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
        return static::canCreateUsers();
    }

    public static function canEdit($record): bool
    {
        return static::canEditUsers();
    }

    public static function canDelete($record): bool
    {
        if (! $record instanceof AdminUser) {
            return false;
        }

        return static::canDeleteUsers($record);
    }

    private static function canViewUsers(): bool
    {
        $user = Filament::auth()->user();

        return (bool) (
            $user
            && static::hasAdminRole($user, ['super_admin', 'platform_admin', 'super admin', 'platform admin'])
        );
    }

    private static function canEditUsers(): bool
    {
        $user = Filament::auth()->user();

        return (bool) (
            $user
            && (
                $user->can('users.edit')
                || $user->can('iam.manage')
                || static::hasAdminRole($user, ['super_admin', 'platform_admin', 'super admin', 'platform admin'])
            )
        );
    }

    private static function canCreateUsers(): bool
    {
        $user = Filament::auth()->user();

        return (bool) (
            $user
            && (
                $user->can('users.create')
                || $user->can('iam.manage')
                || static::hasAdminRole($user, ['super_admin', 'platform_admin', 'super admin', 'platform admin'])
            )
        );
    }

    private static function canDeleteUsers(AdminUser $record): bool
    {
        $user = Filament::auth()->user();

        if (! $user || ! static::hasAdminRole($user, ['super_admin', 'platform_admin', 'super admin', 'platform admin'])) {
            return false;
        }

        if ((int) $record->id === (int) $user->id) {
            return false;
        }

        if ($record->hasRole('super_admin') && static::superAdminCount() <= 1) {
            return false;
        }

        return true;
    }

    private static function superAdminCount(): int
    {
        return AdminUser::query()
            ->whereHas('roles', fn (Builder $query) => $query->whereIn('name', ['super_admin', 'super admin']))
            ->count();
    }

    private static function hasAdminRole($user, array $roles): bool
    {
        if (! $user || ! method_exists($user, 'hasRole')) {
            return false;
        }

        foreach ($roles as $role) {
            if ($user->hasRole($role)) {
                return true;
            }
        }

        return false;
    }
}
