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
                Tables\Columns\TextColumn::make('metadata.before')
                    ->label('Before')
                    ->formatStateUsing(fn ($state): string => str(json_encode($state, JSON_UNESCAPED_SLASHES))->limit(80)->toString())
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('metadata.after')
                    ->label('After')
                    ->formatStateUsing(fn ($state): string => str(json_encode($state, JSON_UNESCAPED_SLASHES))->limit(80)->toString())
                    ->toggleable(isToggledHiddenByDefault: true),
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
            ->actions([
                Tables\Actions\ViewAction::make()
                    ->modalHeading('Audit log entry')
                    ->infolist([
                        \Filament\Infolists\Components\TextEntry::make('adminUser.name')->label('Admin'),
                        \Filament\Infolists\Components\TextEntry::make('action'),
                        \Filament\Infolists\Components\TextEntry::make('method'),
                        \Filament\Infolists\Components\TextEntry::make('path'),
                        \Filament\Infolists\Components\TextEntry::make('metadata')->formatStateUsing(fn ($state): string => json_encode($state, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}'),
                        \Filament\Infolists\Components\TextEntry::make('request_payload')->label('Request payload')->formatStateUsing(fn ($state): string => json_encode($state, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}'),
                    ]),
            ])
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

