<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PreRegistrationResource\Pages;
use App\Models\AdminUser;
use App\Models\PreRegistration;
use App\Models\User;
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

class PreRegistrationResource extends Resource
{
    protected static ?string $model = PreRegistration::class;

    protected static ?string $navigationIcon = 'heroicon-o-user-plus';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 20;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Lead')
                ->schema([
                    Forms\Components\TextInput::make('first_name')->required()->maxLength(255),
                    Forms\Components\TextInput::make('last_name')->required()->maxLength(255),
                    Forms\Components\TextInput::make('email')->email()->maxLength(255),
                    Forms\Components\TextInput::make('phone')->maxLength(40),
                    Forms\Components\TextInput::make('city')->maxLength(120),
                    Forms\Components\Select::make('interested_as')
                        ->required()
                        ->options([
                            'cook' => 'Cook',
                            'foodie' => 'Foodie',
                            'both' => 'Both',
                        ]),
                    Forms\Components\Select::make('source')
                        ->required()
                        ->options([
                            'website' => 'Website',
                            'referral' => 'Referral',
                            'campaign' => 'Campaign',
                            'admin' => 'Admin',
                        ]),
                    Forms\Components\Select::make('status')
                        ->options([
                            PreRegistration::STATUS_NEW => 'New',
                            PreRegistration::STATUS_CONTACTED => 'Contacted',
                            PreRegistration::STATUS_CONVERTED => 'Converted',
                            PreRegistration::STATUS_DISQUALIFIED => 'Disqualified',
                            PreRegistration::STATUS_SPAM => 'Spam',
                        ])
                        ->required(),
                    Forms\Components\Toggle::make('consent_to_contact'),
                    Forms\Components\Select::make('communication_preference')
                        ->options([
                            'email' => 'Email',
                            'sms' => 'SMS',
                            'phone' => 'Phone',
                            'none' => 'Do not contact',
                        ]),
                    Forms\Components\Textarea::make('notes')->rows(4),
                ])
                ->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['assignedTo', 'convertedUser']))
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('first_name')->label('First name')->searchable(),
                Tables\Columns\TextColumn::make('last_name')->label('Last name')->searchable(),
                Tables\Columns\TextColumn::make('email')->searchable()->toggleable(),
                Tables\Columns\TextColumn::make('phone')->toggleable(),
                Tables\Columns\TextColumn::make('interested_as')->label('Interested as')->badge(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        PreRegistration::STATUS_NEW => 'info',
                        PreRegistration::STATUS_CONTACTED => 'success',
                        PreRegistration::STATUS_CONVERTED => 'success',
                        PreRegistration::STATUS_DISQUALIFIED => 'danger',
                        PreRegistration::STATUS_SPAM => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('assignedTo.name')->label('Assigned')->placeholder('Unassigned'),
                Tables\Columns\TextColumn::make('convertedUser.email')->label('Converted user')->placeholder('-')->toggleable(),
                Tables\Columns\TextColumn::make('created_at')->dateTime('d M H:i')->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        PreRegistration::STATUS_NEW => 'New',
                        PreRegistration::STATUS_CONTACTED => 'Contacted',
                        PreRegistration::STATUS_CONVERTED => 'Converted',
                        PreRegistration::STATUS_DISQUALIFIED => 'Disqualified',
                        PreRegistration::STATUS_SPAM => 'Spam',
                    ]),
                Tables\Filters\TernaryFilter::make('unassigned')
                    ->queries(
                        true: fn (Builder $query): Builder => $query->whereNull('assigned_to'),
                        false: fn (Builder $query): Builder => $query,
                        blank: fn (Builder $query): Builder => $query,
                    ),
            ])
            ->actions([
                Action::make('assign_to_me')
                    ->label('Assign to me')
                    ->icon('heroicon-o-user-plus')
                    ->visible(fn (): bool => static::canEditLeads())
                    ->action(function (PreRegistration $record): void {
                        $record->update([
                            'assigned_to' => Filament::auth()->id(),
                        ]);

                        Notification::make()->title('Lead assigned to you.')->success()->send();
                    }),
                Action::make('assign')
                    ->label('Assign')
                    ->icon('heroicon-o-user-group')
                    ->visible(fn (): bool => static::canEditLeads())
                    ->form([
                        Forms\Components\Select::make('assigned_to')
                            ->required()
                            ->options(fn (): array => AdminUser::query()->where('is_active', true)->pluck('name', 'id')->toArray()),
                        Forms\Components\Select::make('status')
                            ->required()
                            ->options([
                                PreRegistration::STATUS_CONTACTED => 'Contacted',
                            ]),
                    ])
                    ->action(function (PreRegistration $record, array $data): void {
                        $record->update([
                            'assigned_to' => (int) $data['assigned_to'],
                            'status' => (string) $data['status'],
                            'followed_up_by' => Filament::auth()->id(),
                            'followed_up_at' => now(),
                        ]);
                        Notification::make()->title('Lead updated.')->success()->send();
                    }),
                Action::make('convert')
                    ->label('Convert')
                    ->icon('heroicon-o-arrow-trending-up')
                    ->color('success')
                    ->visible(fn (): bool => static::canEditLeads())
                    ->form([
                        Forms\Components\Select::make('converted_user_id')
                            ->required()
                            ->label('Link to user')
                            ->options(fn (): array => User::query()->orderByDesc('id')->limit(500)->pluck('email', 'id')->toArray())
                            ->searchable(),
                        Forms\Components\Textarea::make('notes')
                            ->label('Conversion notes')
                            ->required(),
                    ])
                    ->action(function (PreRegistration $record, array $data): void {
                        try {
                            DB::transaction(function () use ($record, $data): void {
                                $locked = PreRegistration::query()->lockForUpdate()->findOrFail($record->id);
                                $locked->converted_user_id = (int) $data['converted_user_id'];
                                $locked->status = PreRegistration::STATUS_CONVERTED;
                                $locked->notes = trim((string) $locked->notes . "\n" . (string) $data['notes']);
                                $locked->followed_up_by = Filament::auth()->id();
                                $locked->followed_up_at = now();
                                $locked->last_contacted_at = now();
                                $locked->save();
                            });

                            Notification::make()->title('Lead converted.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Conversion failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('mark_contacted')
                    ->label('Mark contacted')
                    ->icon('heroicon-o-phone')
                    ->color('info')
                    ->visible(fn (): bool => static::canEditLeads())
                    ->form([
                        Forms\Components\Textarea::make('notes')
                            ->label('Contact note')
                            ->required(),
                    ])
                    ->action(function (PreRegistration $record, array $data): void {
                        $record->update([
                            'status' => PreRegistration::STATUS_CONTACTED,
                            'notes' => trim((string) $record->notes . "\n" . (string) $data['notes']),
                            'followed_up_by' => Filament::auth()->id(),
                            'followed_up_at' => now(),
                            'last_contacted_at' => now(),
                        ]);
                        Notification::make()->title('Lead marked contacted.')->success()->send();
                    }),
                Action::make('reject')
                    ->label('Disqualify')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn (): bool => static::canEditLeads())
                    ->form([
                        Forms\Components\Textarea::make('notes')
                            ->label('Reason')
                            ->required(),
                    ])
                    ->action(function (PreRegistration $record, array $data): void {
                        $record->update([
                            'status' => PreRegistration::STATUS_DISQUALIFIED,
                            'notes' => trim((string) $record->notes . "\n" . (string) $data['notes']),
                            'followed_up_by' => Filament::auth()->id(),
                            'followed_up_at' => now(),
                            'last_contacted_at' => now(),
                        ]);
                        Notification::make()->title('Lead disqualified.')->success()->send();
                    }),
                Action::make('mark_spam')
                    ->label('Mark spam')
                    ->icon('heroicon-o-no-symbol')
                    ->color('danger')
                    ->visible(fn (): bool => static::canEditLeads())
                    ->action(function (PreRegistration $record): void {
                        $record->update([
                            'status' => PreRegistration::STATUS_SPAM,
                            'spam_score' => max((int) $record->spam_score, 100),
                            'spam_detected_at' => now(),
                            'followed_up_by' => Filament::auth()->id(),
                            'followed_up_at' => now(),
                        ]);
                        Notification::make()->title('Lead marked as spam.')->success()->send();
                    }),
                Action::make('add_follow_up_note')
                    ->label('Follow-up note')
                    ->icon('heroicon-o-chat-bubble-left')
                    ->visible(fn (): bool => static::canEditLeads())
                    ->form([
                        Forms\Components\Textarea::make('note')
                            ->required()
                            ->rows(4),
                    ])
                    ->action(function (PreRegistration $record, array $data): void {
                        $record->update([
                            'notes' => trim((string) $record->notes . "\n" . (string) $data['note']),
                            'followed_up_by' => Filament::auth()->id(),
                            'followed_up_at' => now(),
                            'last_contacted_at' => now(),
                        ]);
                        Notification::make()->title('Follow-up note added.')->success()->send();
                    }),
            ])
            ->defaultSort('created_at', 'desc')
            ->emptyStateHeading('No pre-registrations found')
            ->emptyStateDescription('New lead submissions will appear here.')
            ->striped();
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPreRegistrations::route('/'),
            'create' => Pages\CreatePreRegistration::route('/create'),
            'edit' => Pages\EditPreRegistration::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        return (bool) Filament::auth()->user()?->can('pre_registrations.view');
    }

    public static function canCreate(): bool
    {
        return (bool) Filament::auth()->user()?->can('pre_registrations.edit');
    }

    public static function canEdit($record): bool
    {
        return static::canEditLeads();
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    private static function canEditLeads(): bool
    {
        return (bool) Filament::auth()->user()?->can('pre_registrations.edit');
    }
}

