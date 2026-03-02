<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PreRegistrationResource\Pages;
use App\Models\PreRegistration;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Table;

class PreRegistrationResource extends Resource
{
    protected static ?string $model = PreRegistration::class;

    protected static ?string $navigationIcon = 'heroicon-o-user-plus';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 20;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Contact Information')
                ->description('Basic identity and contact details of the lead.')
                ->icon('heroicon-o-user-circle')
                ->schema([
                    Forms\Components\TextInput::make('first_name')
                        ->required()
                        ->maxLength(255),
                    Forms\Components\TextInput::make('last_name')
                        ->required()
                        ->maxLength(255),
                    Forms\Components\TextInput::make('email')
                        ->email()
                        ->maxLength(255)
                        ->helperText('Used for follow-up outreach.'),
                    Forms\Components\TextInput::make('phone')
                        ->tel()
                        ->maxLength(40),
                    Forms\Components\TextInput::make('city')
                        ->maxLength(255)
                        ->helperText('Used for launch priority geo-routing.'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Interest & Preferences')
                ->description('What role the lead is interested in and how they prefer to be contacted.')
                ->icon('heroicon-o-sparkles')
                ->schema([
                    Forms\Components\Select::make('interested_as')
                        ->required()
                        ->options([
                            'cook' => 'Cook',
                            'foodie' => 'Foodie',
                            'both' => 'Both',
                        ])
                        ->helperText('Cook = wants to list a kitchen; Foodie = wants to order.'),
                    Forms\Components\Select::make('source')
                        ->required()
                        ->default('website')
                        ->options([
                            'website' => 'Website',
                            'referral' => 'Referral',
                            'campaign' => 'Campaign',
                            'admin' => 'Admin',
                        ]),
                    Forms\Components\Select::make('communication_preference')
                        ->options([
                            'email' => 'Email',
                            'phone' => 'Phone',
                            'either' => 'Either',
                        ])
                        ->default('email'),
                    Forms\Components\Toggle::make('consent_to_contact')
                        ->label('Consented to contact')
                        ->inline(false)
                        ->default(false)
                        ->helperText('Must be true before sending any outreach.'),
                ])
                ->columns(2),

            Forms\Components\Section::make('Pipeline Status')
                ->description('Track where this lead is in the pre-launch funnel. Use row actions (Mark Contacted / Convert / Disqualify) for safe status transitions.')
                ->icon('heroicon-o-funnel')
                ->schema([
                    Forms\Components\Select::make('status')
                        ->required()
                        ->options([
                            PreRegistration::STATUS_NEW => 'New',
                            PreRegistration::STATUS_CONTACTED => 'Contacted',
                            PreRegistration::STATUS_CONVERTED => 'Converted',
                            PreRegistration::STATUS_DISQUALIFIED => 'Disqualified',
                            PreRegistration::STATUS_SPAM => 'Spam',
                        ]),
                    Forms\Components\Textarea::make('notes')
                        ->rows(4)
                        ->columnSpanFull()
                        ->helperText('Internal notes visible to CRM agents only. Never shown to the lead.'),
                ])
                ->columns(1),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        PreRegistration::STATUS_NEW => 'info',
                        PreRegistration::STATUS_CONTACTED => 'warning',
                        PreRegistration::STATUS_CONVERTED => 'success',
                        PreRegistration::STATUS_DISQUALIFIED => 'gray',
                        PreRegistration::STATUS_SPAM => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('full_name')
                    ->label('Name')
                    ->state(fn (PreRegistration $record): string => trim($record->first_name . ' ' . $record->last_name))
                    ->weight(\Filament\Support\Enums\FontWeight::SemiBold)
                    ->searchable(query: fn ($query, string $search) => $query->where(
                        fn ($q) => $q->where('first_name', 'like', "%{$search}%")->orWhere('last_name', 'like', "%{$search}%")
                    )),
                Tables\Columns\TextColumn::make('email')
                    ->searchable()
                    ->copyable(),
                Tables\Columns\TextColumn::make('phone')
                    ->searchable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('interested_as')
                    ->label('Interest')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'cook' => 'warning',
                        'foodie' => 'info',
                        'both' => 'success',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('source')
                    ->badge()
                    ->color('gray'),
                Tables\Columns\TextColumn::make('city')
                    ->placeholder('-')
                    ->toggleable(),
                Tables\Columns\IconColumn::make('consent_to_contact')
                    ->label('Consented')
                    ->boolean(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Registered')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')->options([
                    PreRegistration::STATUS_NEW => 'New',
                    PreRegistration::STATUS_CONTACTED => 'Contacted',
                    PreRegistration::STATUS_CONVERTED => 'Converted',
                    PreRegistration::STATUS_DISQUALIFIED => 'Disqualified',
                    PreRegistration::STATUS_SPAM => 'Spam',
                ]),
                Tables\Filters\SelectFilter::make('source')->options([
                    'website' => 'Website',
                    'referral' => 'Referral',
                    'campaign' => 'Campaign',
                    'admin' => 'Admin',
                ]),
                Tables\Filters\SelectFilter::make('interested_as')
                    ->label('Interest')
                    ->options([
                        'cook' => 'Cook',
                        'foodie' => 'Foodie',
                        'both' => 'Both',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Action::make('mark_contacted')
                    ->label('Mark Contacted')
                    ->icon('heroicon-o-phone')
                    ->color('warning')
                    ->visible(fn (PreRegistration $record): bool => $record->status === PreRegistration::STATUS_NEW)
                    ->requiresConfirmation()
                    ->action(fn (PreRegistration $record) => $record->update([
                        'status' => PreRegistration::STATUS_CONTACTED,
                        'followed_up_at' => now(),
                    ])),
                Action::make('convert')
                    ->label('Convert')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->visible(fn (PreRegistration $record): bool => in_array($record->status, [
                        PreRegistration::STATUS_NEW,
                        PreRegistration::STATUS_CONTACTED,
                    ], true))
                    ->requiresConfirmation()
                    ->modalDescription('Mark this lead as converted — they have successfully registered on the platform.')
                    ->action(fn (PreRegistration $record) => $record->update(['status' => PreRegistration::STATUS_CONVERTED])),
                Action::make('disqualify')
                    ->label('Disqualify')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn (PreRegistration $record): bool => ! in_array($record->status, [
                        PreRegistration::STATUS_CONVERTED,
                        PreRegistration::STATUS_DISQUALIFIED,
                        PreRegistration::STATUS_SPAM,
                    ], true))
                    ->form([
                        Forms\Components\Select::make('final_status')
                            ->label('Mark as')
                            ->options([
                                PreRegistration::STATUS_DISQUALIFIED => 'Disqualified',
                                PreRegistration::STATUS_SPAM => 'Spam',
                            ])
                            ->required(),
                    ])
                    ->action(fn (PreRegistration $record, array $data) => $record->update(['status' => $data['final_status']])),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPreRegistrations::route('/'),
            'create' => Pages\CreatePreRegistration::route('/create'),
            'edit' => Pages\EditPreRegistration::route('/{record}/edit'),
        ];
    }
}
