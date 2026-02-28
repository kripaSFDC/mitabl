<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CertificateResource\Pages;
use App\Mail\CertificateApproved;
use App\Mail\CertificateRejected;
use App\Models\Certificate;
use App\Notifications\CertificateStatusUpdatedNotification;
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
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class CertificateResource extends Resource
{
    protected static ?string $model = Certificate::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-document-check';

    protected static string|\UnitEnum|null $navigationGroup = 'Operations';

    protected static ?int $navigationSort = 10;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Certificate Details')
                    ->schema([
                        Forms\Components\Select::make('mikitchn_id')
                            ->label('Kitchen')
                            ->relationship('mikitchn', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Forms\Components\TextInput::make('first_name')->required()->maxLength(255),
                        Forms\Components\TextInput::make('last_name')->required()->maxLength(255),
                        Forms\Components\TextInput::make('abn')->maxLength(255),
                        Forms\Components\TextInput::make('certificate_no')->required()->maxLength(255),
                        Forms\Components\TextInput::make('certificate_doc')
                            ->label('Certificate Document Path')
                            ->maxLength(555)
                            ->rule('regex:/\.(pdf|jpg|jpeg|png|webp)$/i')
                            ->helperText('Stored file path for uploaded certificate document.'),
                        Forms\Components\Select::make('abn_gst')
                            ->options([
                                0 => 'No',
                                1 => 'Yes',
                            ])
                            ->required(),
                        Forms\Components\Select::make('status')
                            ->options([
                                0 => 'Pending',
                                1 => 'Approved',
                                2 => 'Rejected',
                            ])
                            ->required(),
                        Forms\Components\Textarea::make('rejection_reason')
                            ->rows(3)
                            ->visible(fn (Forms\Get $get): bool => (int) $get('status') === 2),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['mikitchn.user', 'reviewer']))
            ->columns([
                Tables\Columns\TextColumn::make('mikitchn.name')
                    ->label('Kitchen')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('full_name')
                    ->label('Cook')
                    ->state(fn (Certificate $record): string => trim($record->first_name . ' ' . $record->last_name))
                    ->searchable(query: function ($query, string $search): void {
                        $query->where(function ($innerQuery) use ($search): void {
                            $innerQuery
                                ->where('first_name', 'like', "%{$search}%")
                                ->orWhere('last_name', 'like', "%{$search}%");
                        });
                    }),
                Tables\Columns\TextColumn::make('mikitchn.phone')
                    ->label('Phone')
                    ->searchable(),
                Tables\Columns\TextColumn::make('abn')->label('ABN')->searchable(),
                Tables\Columns\TextColumn::make('certificate_no')->label('Certificate #')->searchable(),
                Tables\Columns\TextColumn::make('certificate_doc')
                    ->label('Document')
                    ->formatStateUsing(fn (?string $state): string => $state ? 'View' : 'Missing')
                    ->url(fn (Certificate $record): ?string => $record->certificate_doc ? asset($record->certificate_doc) : null)
                    ->openUrlInNewTab(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn (int $state): string => match ($state) {
                        0 => 'Pending',
                        1 => 'Approved',
                        2 => 'Rejected',
                        default => 'Unknown',
                    })
                    ->color(fn (int $state): string => match ($state) {
                        0 => 'warning',
                        1 => 'success',
                        2 => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('reviewer.name')
                    ->label('Reviewer')
                    ->placeholder('-')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('reviewed_at')
                    ->label('Reviewed')
                    ->dateTime('d M Y H:i')
                    ->placeholder('-')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Uploaded')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        0 => 'Pending',
                        1 => 'Approved',
                        2 => 'Rejected',
                    ]),
                Tables\Filters\Filter::make('submitted_between')
                    ->form([
                        Forms\Components\DatePicker::make('from')->label('From'),
                        Forms\Components\DatePicker::make('until')->label('Until'),
                    ])
                    ->query(function ($query, array $data) {
                        return $query
                            ->when($data['from'] ?? null, fn ($subQuery, $date) => $subQuery->whereDate('created_at', '>=', $date))
                            ->when($data['until'] ?? null, fn ($subQuery, $date) => $subQuery->whereDate('created_at', '<=', $date));
                    }),
            ])
            ->actions([
                Action::make('review_workspace')
                    ->label('Review Workspace')
                    ->icon('heroicon-o-eye')
                    ->color('gray')
                    ->modalHeading(fn (Certificate $record): string => 'Certificate Review: ' . (string) ($record->certificate_no ?: '#'.$record->id))
                    ->modalSubmitAction(false)
                    ->form([
                        Forms\Components\Placeholder::make('kitchen')
                            ->label('Kitchen')
                            ->content(fn (Certificate $record): string => (string) ($record->mikitchn->name ?? '-')),
                        Forms\Components\Placeholder::make('cook')
                            ->label('Cook')
                            ->content(fn (Certificate $record): string => trim($record->first_name . ' ' . $record->last_name)),
                        Forms\Components\Placeholder::make('abn')
                            ->label('ABN')
                            ->content(fn (Certificate $record): string => (string) ($record->abn ?? '-')),
                        Forms\Components\Placeholder::make('status')
                            ->label('Current status')
                            ->content(fn (Certificate $record): string => match ((int) $record->status) {
                                0 => 'Pending',
                                1 => 'Approved',
                                2 => 'Rejected',
                                default => 'Unknown',
                            }),
                        Forms\Components\Placeholder::make('document')
                            ->label('Document preview')
                            ->content(fn (Certificate $record): string => $record->certificate_doc
                                ? 'Open document: ' . asset($record->certificate_doc)
                                : 'No document uploaded'),
                    ])
                    ->columns(2),
                Action::make('approve')
                    ->label('Approve')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Hidden::make('last_known_update_at')
                            ->default(fn (Certificate $record): ?string => $record->updated_at?->toISOString()),
                    ])
                    ->visible(fn (Certificate $record): bool => (int) $record->status === 0 && static::canReview())
                    ->action(function (Certificate $record, array $data): void {
                        $approved = false;

                        DB::transaction(function () use ($record, $data, &$approved): void {
                            $certificate = Certificate::query()->lockForUpdate()->find($record->id);

                            if (! $certificate || (int) $certificate->status !== 0) {
                                Notification::make()
                                    ->title('Certificate already reviewed by another admin.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            if (! static::isReviewSnapshotCurrent($certificate, $data['last_known_update_at'] ?? null)) {
                                Notification::make()
                                    ->title('Certificate was updated while you were reviewing it. Please reopen and review the latest file.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            if (! static::hasValidCertificateDocument($certificate)) {
                                Notification::make()
                                    ->title('Certificate document is missing or invalid. Approve is blocked until a valid file is uploaded.')
                                    ->danger()
                                    ->send();

                                return;
                            }

                            $certificate->status = 1;
                            $certificate->rejection_reason = null;
                            $certificate->reviewed_by = Filament::auth()->id();
                            $certificate->reviewed_at = Carbon::now();
                            $certificate->save();

                            $recipient = optional($certificate->mikitchn)->user;
                            if ($recipient && $recipient->email) {
                                Mail::to($recipient->email)->queue((new CertificateApproved($recipient, $certificate))->afterCommit());
                                $recipient->notify((new CertificateStatusUpdatedNotification('approved', null))->afterCommit());
                            }

                            Log::info('certificate.approved', [
                                'certificate_id' => $certificate->id,
                                'mikitchn_id' => $certificate->mikitchn_id,
                                'reviewed_by' => Filament::auth()->id(),
                            ]);

                            $approved = true;
                        });

                        if (! $approved) {
                            return;
                        }

                        Notification::make()
                            ->title('Certificate approved successfully.')
                            ->success()
                            ->send();
                    }),
                Action::make('reject')
                    ->label('Reject')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn (Certificate $record): bool => (int) $record->status === 0 && static::canReview())
                    ->form([
                        Forms\Components\Hidden::make('last_known_update_at')
                            ->default(fn (Certificate $record): ?string => $record->updated_at?->toISOString()),
                        Forms\Components\Textarea::make('rejection_reason')
                            ->label('Rejection reason')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500)
                            ->rows(4),
                    ])
                    ->action(function (Certificate $record, array $data): void {
                        $rejected = false;

                        DB::transaction(function () use ($record, $data, &$rejected): void {
                            $certificate = Certificate::query()->lockForUpdate()->find($record->id);

                            if (! $certificate || (int) $certificate->status !== 0) {
                                Notification::make()
                                    ->title('Certificate already reviewed by another admin.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            if (! static::isReviewSnapshotCurrent($certificate, $data['last_known_update_at'] ?? null)) {
                                Notification::make()
                                    ->title('Certificate was updated while you were reviewing it. Please reopen and review the latest file.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $certificate->status = 2;
                            $certificate->rejection_reason = $data['rejection_reason'];
                            $certificate->reviewed_by = Filament::auth()->id();
                            $certificate->reviewed_at = Carbon::now();
                            $certificate->save();

                            $recipient = optional($certificate->mikitchn)->user;
                            if ($recipient && $recipient->email) {
                                Mail::to($recipient->email)->queue((new CertificateRejected($recipient, $certificate))->afterCommit());
                                $recipient->notify((new CertificateStatusUpdatedNotification('rejected', $data['rejection_reason']))->afterCommit());
                            }

                            Log::info('certificate.rejected', [
                                'certificate_id' => $certificate->id,
                                'mikitchn_id' => $certificate->mikitchn_id,
                                'reviewed_by' => Filament::auth()->id(),
                                'reason' => $data['rejection_reason'],
                            ]);

                            $rejected = true;
                        });

                        if (! $rejected) {
                            return;
                        }

                        Notification::make()
                            ->title('Certificate rejected successfully.')
                            ->success()
                            ->send();
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkAction::make('bulk_approve')
                    ->label('Bulk approve')
                    ->icon('heroicon-o-check-circle')
                    ->visible(fn (): bool => static::canReview())
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\TextInput::make('confirm_text')
                            ->label('Type APPROVE to confirm')
                            ->required()
                            ->rule('in:APPROVE'),
                    ])
                    ->action(function ($records, array $data): void {
                        if (($data['confirm_text'] ?? '') !== 'APPROVE') {
                            Notification::make()->title('Bulk approve confirmation mismatch.')->danger()->send();
                            return;
                        }

                        $approved = 0;
                        foreach ($records as $record) {
                            DB::transaction(function () use ($record, &$approved): void {
                                $certificate = Certificate::query()->lockForUpdate()->find($record->id);
                                if (! $certificate || (int) $certificate->status !== 0 || ! static::hasValidCertificateDocument($certificate)) {
                                    return;
                                }
                                $certificate->status = 1;
                                $certificate->rejection_reason = null;
                                $certificate->reviewed_by = Filament::auth()->id();
                                $certificate->reviewed_at = Carbon::now();
                                $certificate->save();
                                $approved++;
                            });
                        }

                        Notification::make()->title("Bulk approve complete: {$approved} approved.")->success()->send();
                    }),
                Tables\Actions\BulkAction::make('bulk_reject')
                    ->label('Bulk reject')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn (): bool => static::canReview())
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\TextInput::make('confirm_text')
                            ->label('Type REJECT to confirm')
                            ->required()
                            ->rule('in:REJECT'),
                        Forms\Components\Textarea::make('rejection_reason')
                            ->required()
                            ->rows(3),
                    ])
                    ->action(function ($records, array $data): void {
                        if (($data['confirm_text'] ?? '') !== 'REJECT') {
                            Notification::make()->title('Bulk reject confirmation mismatch.')->danger()->send();
                            return;
                        }

                        $rejected = 0;
                        foreach ($records as $record) {
                            DB::transaction(function () use ($record, $data, &$rejected): void {
                                $certificate = Certificate::query()->lockForUpdate()->find($record->id);
                                if (! $certificate || (int) $certificate->status !== 0) {
                                    return;
                                }
                                $certificate->status = 2;
                                $certificate->rejection_reason = (string) $data['rejection_reason'];
                                $certificate->reviewed_by = Filament::auth()->id();
                                $certificate->reviewed_at = Carbon::now();
                                $certificate->save();
                                $rejected++;
                            });
                        }

                        Notification::make()->title("Bulk reject complete: {$rejected} rejected.")->success()->send();
                    }),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCertificates::route('/'),
            'create' => Pages\CreateCertificate::route('/create'),
            'edit' => Pages\EditCertificate::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        return static::canView();
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

    private static function canView(): bool
    {
        return (bool) Filament::auth()->user()?->can('certificates.view');
    }

    private static function canReview(): bool
    {
        return (bool) Filament::auth()->user()?->can('certificates.review');
    }

    private static function hasValidCertificateDocument(Certificate $certificate): bool
    {
        $documentPath = trim((string) $certificate->certificate_doc);
        if ($documentPath === '') {
            return false;
        }

        $extension = Str::lower((string) pathinfo(parse_url($documentPath, PHP_URL_PATH) ?: $documentPath, PATHINFO_EXTENSION));

        return in_array($extension, ['pdf', 'jpg', 'jpeg', 'png', 'webp'], true);
    }

    private static function isReviewSnapshotCurrent(Certificate $certificate, ?string $lastKnownUpdateAt): bool
    {
        if (! $certificate->updated_at) {
            return true;
        }

        if (! $lastKnownUpdateAt) {
            return true;
        }

        return $certificate->updated_at->toISOString() === $lastKnownUpdateAt;
    }
}
