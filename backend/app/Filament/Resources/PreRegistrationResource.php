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
            Forms\Components\TextInput::make('first_name')->required()->maxLength(255),
            Forms\Components\TextInput::make('last_name')->required()->maxLength(255),
            Forms\Components\TextInput::make('email')->email()->maxLength(255),
            Forms\Components\TextInput::make('phone')->maxLength(40),
            Forms\Components\TextInput::make('city')->maxLength(255),
            Forms\Components\Select::make('interested_as')->required()->options([
                'cook' => 'Cook',
                'foodie' => 'Foodie',
                'both' => 'Both',
            ]),
            Forms\Components\Select::make('source')->required()->default('website')->options([
                'website' => 'Website',
                'referral' => 'Referral',
                'campaign' => 'Campaign',
                'admin' => 'Admin',
            ]),
            Forms\Components\Select::make('status')->required()->options([
                PreRegistration::STATUS_NEW => 'New',
                PreRegistration::STATUS_CONTACTED => 'Contacted',
                PreRegistration::STATUS_CONVERTED => 'Converted',
                PreRegistration::STATUS_DISQUALIFIED => 'Disqualified',
                PreRegistration::STATUS_SPAM => 'Spam',
            ]),
            Forms\Components\Toggle::make('consent_to_contact')->default(false),
            Forms\Components\Select::make('communication_preference')->options([
                'email' => 'Email',
                'phone' => 'Phone',
                'either' => 'Either',
            ])->default('email'),
            Forms\Components\Textarea::make('notes')->columnSpanFull(),
        ])->columns(2);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('first_name')->searchable(),
                Tables\Columns\TextColumn::make('last_name')->searchable(),
                Tables\Columns\TextColumn::make('email')->searchable(),
                Tables\Columns\TextColumn::make('phone')->searchable(),
                Tables\Columns\TextColumn::make('source')->badge(),
                Tables\Columns\TextColumn::make('interested_as')->badge(),
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
                Tables\Columns\TextColumn::make('created_at')->dateTime('d M Y H:i')->sortable(),
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
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Action::make('mark_contacted')
                    ->label('Mark Contacted')
                    ->visible(fn (PreRegistration $record): bool => $record->status === PreRegistration::STATUS_NEW)
                    ->action(fn (PreRegistration $record) => $record->update([
                        'status' => PreRegistration::STATUS_CONTACTED,
                        'followed_up_at' => now(),
                    ])),
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
