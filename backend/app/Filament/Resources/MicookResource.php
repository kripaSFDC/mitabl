<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MicookResource\Pages;
use App\Models\User;
use App\Services\AdminStepUpService;
use Filament\Facades\Filament;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class MicookResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-user-group';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 10;

    protected static ?string $navigationLabel = 'Micooks';

    protected static ?string $modelLabel = 'Micook';

    protected static ?string $pluralModelLabel = 'Micooks';

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->where('role_id', 2)
            ->withTrashed();
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Hidden::make('role_id')
                ->default(2)
                ->dehydrated(),
            Forms\Components\TextInput::make('first_name')
                ->required()
                ->maxLength(255),
            Forms\Components\TextInput::make('last_name')
                ->required()
                ->maxLength(255),
            Forms\Components\TextInput::make('email')
                ->required()
                ->email()
                ->unique(ignoreRecord: true)
                ->maxLength(255)
                ->disabled(fn (string $operation): bool => $operation === 'edit'),
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
            Forms\Components\TextInput::make('phone')
                ->required()
                ->rule('regex:/^[0-9]{7,15}$/')
                ->helperText('Digits only, 7-15 characters.')
                ->maxLength(255),
            Forms\Components\TextInput::make('address')
                ->maxLength(1001),
        ])->columns(2);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->sortable(),
                Tables\Columns\TextColumn::make('first_name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('last_name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('email')
                    ->searchable()
                    ->copyable(),
                Tables\Columns\TextColumn::make('phone')
                    ->searchable(),
                Tables\Columns\IconColumn::make('suspended')
                    ->boolean(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('deleted_at')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TrashedFilter::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make()
                    ->visible(fn (User $record): bool => ! $record->trashed() && static::canEditUsers()),
                Tables\Actions\Action::make('soft_delete')
                    ->label('Soft Delete')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->visible(fn (User $record): bool => ! $record->trashed() && static::canDeleteUsers())
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
                    ->action(function (User $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to soft delete this account.'
                        )) {
                            return;
                        }

                        $deleted = false;

                        DB::transaction(function () use ($record, &$deleted): void {
                            $user = User::query()->withTrashed()->lockForUpdate()->find($record->id);
                            if (! $user || $user->trashed()) {
                                return;
                            }

                            $deleted = (bool) $user->delete();
                        });

                        Notification::make()
                            ->title($deleted ? 'Micook soft deleted successfully.' : 'Micook could not be deleted.')
                            ->{$deleted ? 'success' : 'warning'}()
                            ->send();
                    }),
                Tables\Actions\Action::make('restore')
                    ->label('Restore')
                    ->icon('heroicon-o-arrow-uturn-left')
                    ->color('success')
                    ->visible(fn (User $record): bool => $record->trashed() && static::canDeleteUsers())
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
                    ->action(function (User $record, array $data): void {
                        if (! app(AdminStepUpService::class)->validateCurrentPassword(
                            $data['current_password'] ?? null,
                            'Step-up authentication failed. Enter your admin password to restore this account.'
                        )) {
                            return;
                        }

                        $restored = false;

                        DB::transaction(function () use ($record, &$restored): void {
                            $user = User::query()->withTrashed()->lockForUpdate()->find($record->id);
                            if (! $user || ! $user->trashed()) {
                                return;
                            }

                            $restored = (bool) $user->restore();
                        });

                        Notification::make()
                            ->title($restored ? 'Micook restored successfully.' : 'Micook could not be restored.')
                            ->{$restored ? 'success' : 'warning'}()
                            ->send();
                    }),
            ])
            ->defaultSort('id', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListMicooks::route('/'),
            'create' => Pages\CreateMicook::route('/create'),
            'edit' => Pages\EditMicook::route('/{record}/edit'),
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
        if ($record instanceof User && $record->trashed()) {
            return false;
        }

        return static::canEditUsers();
    }

    public static function canDelete($record): bool
    {
        return ! ($record instanceof User && $record->trashed()) && static::canDeleteUsers();
    }

    private static function canViewUsers(): bool
    {
        return (bool) Filament::auth()->user()?->can('users.view');
    }

    private static function canCreateUsers(): bool
    {
        return (bool) Filament::auth()->user()?->can('users.create');
    }

    private static function canEditUsers(): bool
    {
        return (bool) Filament::auth()->user()?->can('users.edit');
    }

    private static function canDeleteUsers(): bool
    {
        return (bool) Filament::auth()->user()?->can('users.delete');
    }
}
