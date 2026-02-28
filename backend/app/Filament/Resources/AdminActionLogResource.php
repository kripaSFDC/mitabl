<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AdminActionLogResource\Pages;
use App\Models\AdminActionLog;
use Filament\Facades\Filament;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class AdminActionLogResource extends Resource
{
    protected static ?string $model = AdminActionLog::class;

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-list';

    protected static ?string $navigationGroup = 'Platform';

    protected static ?int $navigationSort = 50;

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with('adminUser'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('created_at')->dateTime('d M Y H:i:s')->sortable(),
                Tables\Columns\TextColumn::make('adminUser.name')->label('Admin')->placeholder('Unknown')->searchable(),
                Tables\Columns\TextColumn::make('action')->searchable()->sortable()->copyable(),
                Tables\Columns\TextColumn::make('method')->badge()->sortable(),
                Tables\Columns\TextColumn::make('status_code')->sortable()->toggleable(),
                Tables\Columns\TextColumn::make('path')->searchable()->toggleable(),
                Tables\Columns\TextColumn::make('ip_address')->toggleable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('method')
                    ->options([
                        'POST' => 'POST',
                        'PUT' => 'PUT',
                        'PATCH' => 'PATCH',
                        'DELETE' => 'DELETE',
                    ]),
            ])
            ->actions([])
            ->bulkActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAdminActionLogs::route('/'),
        ];
    }

    public static function canViewAny(): bool
    {
        return (bool) Filament::auth()->user()?->can('audit_logs.view');
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

