<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CertificateResource\Pages;
use App\Jobs\SendCertificateReviewOutcomeJob;
use App\Models\Certificate;
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

class CertificateResource extends Resource
{
    protected static ?string $model = Certificate::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-check';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 40;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Holder & Kitchen')
                    ->description('The individual (cook) who owns this certificate and the kitchen they operate. ABN is required for GST-registered cooks.')
                    ->icon('heroicon-o-user-circle')
                    ->schema([
                        Forms\Components\Select::make('mikitchn_id')
                            ->label('Kitchen')
                            ->relationship('mikitchn', 'name')
                            ->searchable()
                            ->preload()
                            ->required()
                            ->columnSpanFull(),
                        Forms\Components\TextInput::make('first_name')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('last_name')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('abn')
                            ->label('ABN')
                            ->maxLength(255)
                            ->helperText('Australian Business Number — 11 digits.'),
                        Forms\Components\Select::make('abn_gst')
                            ->label('GST Registered?')
                            ->options([
                                0 => 'No',
                                1 => 'Yes',
                            ])
                            ->required(),
                    ])
                    ->columns(['default' => 2]),

                Forms\Components\Section::make('Certificate & Review')
                    ->description('Document reference and the current review outcome. Use the Approve / Reject row actions for safe status transitions with audit trail.')
                    ->icon('heroicon-o-document-check')
                    ->schema([
                        Forms\Components\TextInput::make('certificate_no')
                            ->label('Certificate number')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('certificate_doc')
                            ->label('Document path')
                            ->maxLength(555)
                            ->rule('regex:/\.(pdf|jpg|jpeg|png|webp)$/i')
                            ->helperText('Stored file path — accepted: pdf, jpg, jpeg, png, webp.'),
                        Forms\Components\Select::make('status')
                            ->options([
                                0 => 'Pending',
                                1 => 'Approved',
                                2 => 'Rejected',
                            ])
                            ->required()
                            ->helperText('Editable status for certificate lifecycle management.'),
                        Forms\Components\Textarea::make('rejection_reason')
                            ->label('Rejection reason')
                            ->rows(3)
                            ->columnSpanFull()
                            ->helperText('Provide reason when status is Rejected. Emailed to the cook.')
                            ->visible(fn (Forms\Get $get): bool => (int) $get('status') === 2),
                    ])
                    ->columns(['default' => 2]),

                Forms\Components\Section::make('System Fields')
                    ->schema([
                        Forms\Components\Placeholder::make('id')
                            ->content(fn (?Certificate $record): string => (string) ($record?->id ?? '-')),
                        Forms\Components\Placeholder::make('mikitchn_id')
                            ->label('Kitchen ID')
                            ->content(fn (?Certificate $record): string => (string) ($record?->mikitchn_id ?? '-')),
                        Forms\Components\Placeholder::make('reviewed_by')
                            ->label('Reviewed by admin ID')
                            ->content(fn (?Certificate $record): string => (string) ($record?->reviewed_by ?? '-')),
                        Forms\Components\Placeholder::make('reviewed_at')
                            ->content(fn (?Certificate $record): string => (string) ($record?->reviewed_at?->toDateTimeString() ?? '-')),
                        Forms\Components\Placeholder::make('created_at')
                            ->content(fn (?Certificate $record): string => (string) ($record?->created_at?->toDateTimeString() ?? '-')),
                        Forms\Components\Placeholder::make('updated_at')
                            ->content(fn (?Certificate $record): string => (string) ($record?->updated_at?->toDateTimeString() ?? '-')),
                    ])
                    ->columns(['default' => 3])
                    ->collapsible()
                    ->visible(fn (?Certificate $record): bool => (bool) $record),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['mikitchn.user', 'reviewer']))
            ->columns([
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn (int $state): string => match ($state) {
                        0 => 'Pending',
                        1 => 'Approved',
                        2 => 'Rejected',
                        default => 'Unknown',
                    })
                    ->colors([
                        'warning' => 0,
                        'success' => 1,
                        'danger' => 2,
                    ])
                    ->sortable(),
                Tables\Columns\TextColumn::make('certificate_no')
                    ->label('Certificate #')
                    ->searchable()
                    ->copyable()
                    ->weight(\Filament\Support\Enums\FontWeight::SemiBold),
                Tables\Columns\TextColumn::make('mikitchn.name')
                    ->label('Kitchen')
                    ->searchable()
                    ->sortable()
                    ->url(fn (Certificate $record): ?string => $record->mikitchn_id ? '/admin/mikitchns/' . $record->mikitchn_id . '/edit' : null)
                    ->openUrlInNewTab(),
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
                    ->searchable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('abn')
                    ->label('ABN')
                    ->searchable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('abn_gst')
                    ->label('GST')
                    ->formatStateUsing(fn (?int $state): string => (int) $state === 1 ? 'Yes' : 'No')
                    ->badge()
                    ->colors([
                        'success' => 1,
                        'gray' => 0,
                    ])
                    ->toggleable(),
                Tables\Columns\TextColumn::make('rejection_reason')
                    ->limit(45)
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('certificate_doc')
                    ->label('Document')
                    ->formatStateUsing(fn (?string $state): string => $state ? 'View' : 'Missing')
                    ->url(fn (Certificate $record): ?string => static::resolveDocumentUrl($record->certificate_doc))
                    ->openUrlInNewTab(),
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
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('mikitchn_id')
                    ->label('Kitchen ID')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('reviewed_by')
                    ->label('Reviewer ID')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('id')
                    ->label('ID')
                    ->toggleable(isToggledHiddenByDefault: true),
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
                        Forms\Components\Grid::make(2)->schema([
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
                                    ? 'Open document: ' . (static::resolveDocumentUrl($record->certificate_doc) ?? '-')
                                    : 'No document uploaded'),
                        ]),
                    ])
                    ->modalWidth('4xl'),
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
                                SendCertificateReviewOutcomeJob::dispatch($certificate->id)->afterCommit();
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
                                SendCertificateReviewOutcomeJob::dispatch($certificate->id)->afterCommit();
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
                Action::make('request_resubmission')
                    ->label('Request Re-Submission')
                    ->icon('heroicon-o-arrow-path-rounded-square')
                    ->color('warning')
                    ->visible(fn (Certificate $record): bool => in_array((int) $record->status, [1, 2], true) && static::canReview())
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Textarea::make('resubmission_reason')
                            ->label('Reason for re-submission')
                            ->required()
                            ->minLength(5)
                            ->maxLength(500)
                            ->rows(4),
                    ])
                    ->action(function (Certificate $record, array $data): void {
                        $requested = false;

                        DB::transaction(function () use ($record, $data, &$requested): void {
                            $certificate = Certificate::query()->lockForUpdate()->find($record->id);

                            if (! $certificate) {
                                return;
                            }

                            if ((int) $certificate->status === 0) {
                                Notification::make()
                                    ->title('Certificate is already pending review.')
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $certificate->status = 0;
                            $certificate->rejection_reason = (string) $data['resubmission_reason'];
                            $certificate->reviewed_by = Filament::auth()->id();
                            $certificate->reviewed_at = Carbon::now();
                            $certificate->save();

                            Log::info('certificate.resubmission_requested', [
                                'certificate_id' => $certificate->id,
                                'mikitchn_id' => $certificate->mikitchn_id,
                                'reviewed_by' => Filament::auth()->id(),
                                'reason' => $data['resubmission_reason'],
                            ]);

                            $requested = true;
                        });

                        if (! $requested) {
                            return;
                        }

                        Notification::make()
                            ->title('Re-submission requested. Certificate moved to pending review.')
                            ->success()
                            ->send();
                    }),
                Tables\Actions\EditAction::make()
                    ->visible(fn (): bool => static::canEditCertificates()),
                Tables\Actions\DeleteAction::make()
                    ->requiresConfirmation()
                    ->visible(fn (): bool => static::canDeleteCertificates()),
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
                                SendCertificateReviewOutcomeJob::dispatch($certificate->id)->afterCommit();
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
                                SendCertificateReviewOutcomeJob::dispatch($certificate->id)->afterCommit();
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
        return static::canViewCertificates();
    }

    public static function canCreate(): bool
    {
        return static::canCreateCertificates();
    }

    public static function canEdit($record): bool
    {
        return static::canEditCertificates();
    }

    public static function canDelete($record): bool
    {
        return static::canDeleteCertificates();
    }

    private static function canViewCertificates(): bool
    {
        return (bool) Filament::auth()->user()?->can('certificates.view');
    }

    private static function canReview(): bool
    {
        return (bool) Filament::auth()->user()?->can('certificates.review');
    }

    private static function canCreateCertificates(): bool
    {
        return (bool) Filament::auth()->user()?->can('certificates.create');
    }

    private static function canEditCertificates(): bool
    {
        return (bool) Filament::auth()->user()?->can('certificates.edit');
    }

    private static function canDeleteCertificates(): bool
    {
        return (bool) Filament::auth()->user()?->can('certificates.delete');
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

    private static function resolveDocumentUrl(?string $documentPath): ?string
    {
        $documentPath = trim((string) $documentPath);
        if ($documentPath === '') {
            return null;
        }

        if (Str::startsWith($documentPath, ['http://', 'https://'])) {
            return $documentPath;
        }

        return asset($documentPath);
    }
}

