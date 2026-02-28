<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SupportTicketResource\Pages;
use App\Models\AdminUser;
use App\Models\SupportTicket;
use App\Services\SupportTicketService;
use Filament\Facades\Filament;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class SupportTicketResource extends Resource
{
    protected static ?string $model = SupportTicket::class;

    protected static ?string $navigationIcon = 'heroicon-o-inbox-stack';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 10;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Requester')
                ->schema([
                    Forms\Components\TextInput::make('requester_name')->maxLength(255),
                    Forms\Components\TextInput::make('requester_email')->email()->required()->maxLength(255),
                    Forms\Components\TextInput::make('requester_phone')->maxLength(40),
                ])
                ->columns(3),
            Forms\Components\Section::make('Ticket')
                ->schema([
                    Forms\Components\TextInput::make('subject')->required()->maxLength(255),
                    Forms\Components\Textarea::make('description')->rows(4)->required(),
                    Forms\Components\Select::make('category')
                        ->options([
                            'general' => 'General',
                            'account' => 'Account',
                            'order' => 'Order',
                            'payment' => 'Payment',
                            'kitchen' => 'Kitchen',
                            'certificate' => 'Certificate',
                        ])
                        ->default('general')
                        ->required(),
                    Forms\Components\Select::make('priority')
                        ->options([
                            'low' => 'Low',
                            'normal' => 'Normal',
                            'high' => 'High',
                            'urgent' => 'Urgent',
                        ])
                        ->default('normal')
                        ->required(),
                    Forms\Components\Select::make('status')
                        ->options([
                            SupportTicket::STATUS_OPEN => 'Open',
                            SupportTicket::STATUS_IN_PROGRESS => 'In progress',
                            SupportTicket::STATUS_PENDING_USER => 'Pending user',
                            SupportTicket::STATUS_RESOLVED => 'Resolved',
                            SupportTicket::STATUS_CLOSED => 'Closed',
                            SupportTicket::STATUS_SPAM => 'Spam',
                        ])
                        ->default(SupportTicket::STATUS_OPEN)
                        ->required(),
                    Forms\Components\Select::make('assigned_to')
                        ->label('Assigned to')
                        ->relationship('assignee', 'name')
                        ->searchable()
                        ->preload(),
                    Forms\Components\TextInput::make('order_id')->numeric(),
                    Forms\Components\TextInput::make('mikitchn_id')->numeric(),
                ])
                ->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(function (Builder $query): Builder {
                return $query->with(['assignee', 'user', 'mikitchn', 'order'])->whereNull('merged_into_ticket_id');
            })
            ->columns([
                Tables\Columns\TextColumn::make('ticket_number')
                    ->label('Ticket')
                    ->searchable()
                    ->sortable()
                    ->copyable(),
                Tables\Columns\TextColumn::make('requester_name')
                    ->label('Requester')
                    ->placeholder('Guest')
                    ->searchable(),
                Tables\Columns\TextColumn::make('requester_email')
                    ->searchable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('subject')
                    ->searchable()
                    ->limit(40),
                Tables\Columns\TextColumn::make('priority')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'low' => 'gray',
                        'normal' => 'info',
                        'high' => 'warning',
                        'urgent' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => str($state)->replace('_', ' ')->title())
                    ->color(fn (string $state): string => match ($state) {
                        SupportTicket::STATUS_OPEN => 'info',
                        SupportTicket::STATUS_IN_PROGRESS => 'warning',
                        SupportTicket::STATUS_PENDING_USER => 'gray',
                        SupportTicket::STATUS_RESOLVED => 'success',
                        SupportTicket::STATUS_CLOSED => 'gray',
                        SupportTicket::STATUS_SPAM => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('first_response_sla')
                    ->label('First response SLA')
                    ->state(fn (SupportTicket $record): string => str($record->firstResponseSlaState())->replace('_', ' ')->title())
                    ->badge()
                    ->color(fn (SupportTicket $record): string => match ($record->firstResponseSlaState()) {
                        'breached' => 'danger',
                        'at_risk' => 'warning',
                        'met' => 'success',
                        default => 'info',
                    }),
                Tables\Columns\TextColumn::make('resolution_sla')
                    ->label('Resolution SLA')
                    ->state(fn (SupportTicket $record): string => str($record->resolutionSlaState())->replace('_', ' ')->title())
                    ->badge()
                    ->color(fn (SupportTicket $record): string => match ($record->resolutionSlaState()) {
                        'breached' => 'danger',
                        'at_risk' => 'warning',
                        'met' => 'success',
                        default => 'info',
                    }),
                Tables\Columns\TextColumn::make('assignee.name')
                    ->label('Assignee')
                    ->placeholder('Unassigned'),
                Tables\Columns\TextColumn::make('created_at')->dateTime('d M H:i')->sortable()->toggleable(),
                Tables\Columns\TextColumn::make('last_message_at')->dateTime('d M H:i')->sortable()->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('my_queue')
                    ->label('My Queue')
                    ->queries(
                        true: fn (Builder $query): Builder => $query->where('assigned_to', Filament::auth()->id()),
                        false: fn (Builder $query): Builder => $query,
                        blank: fn (Builder $query): Builder => $query,
                    ),
                Tables\Filters\TernaryFilter::make('unassigned')
                    ->label('Unassigned')
                    ->queries(
                        true: fn (Builder $query): Builder => $query->whereNull('assigned_to'),
                        false: fn (Builder $query): Builder => $query,
                        blank: fn (Builder $query): Builder => $query,
                    ),
                Tables\Filters\TernaryFilter::make('sla_risk')
                    ->label('SLA Risk')
                    ->queries(
                        true: fn (Builder $query): Builder => $query->where(function (Builder $risk): void {
                            $risk->where(function (Builder $first): void {
                                $first->whereNull('first_responded_at')->whereNotNull('first_response_due_at')->where('first_response_due_at', '<=', now()->addMinutes(30));
                            })->orWhere(function (Builder $resolution): void {
                                $resolution->whereNull('resolved_at')->whereNotNull('resolution_due_at')->where('resolution_due_at', '<=', now()->addHour());
                            });
                        }),
                        false: fn (Builder $query): Builder => $query,
                        blank: fn (Builder $query): Builder => $query,
                    ),
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        SupportTicket::STATUS_OPEN => 'Open',
                        SupportTicket::STATUS_IN_PROGRESS => 'In progress',
                        SupportTicket::STATUS_PENDING_USER => 'Pending user',
                        SupportTicket::STATUS_RESOLVED => 'Resolved',
                        SupportTicket::STATUS_CLOSED => 'Closed',
                        SupportTicket::STATUS_SPAM => 'Spam',
                    ]),
                Tables\Filters\SelectFilter::make('priority')
                    ->options([
                        'low' => 'Low',
                        'normal' => 'Normal',
                        'high' => 'High',
                        'urgent' => 'Urgent',
                    ]),
            ])
            ->actions([
                Action::make('assign_to_me')
                    ->label('Assign to me')
                    ->icon('heroicon-o-user-plus')
                    ->color('info')
                    ->visible(fn (SupportTicket $record): bool => static::canAssign() && ! $record->isTerminal())
                    ->action(function (SupportTicket $record): void {
                        try {
                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            $service->assignTicket($record, Filament::auth()->id(), 'Self assignment from triage queue', Filament::auth()->id());
                            Notification::make()->title('Ticket assigned.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Assignment failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('assign')
                    ->label('Assign')
                    ->icon('heroicon-o-user-group')
                    ->color('warning')
                    ->visible(fn (SupportTicket $record): bool => static::canAssign() && ! $record->isTerminal())
                    ->form([
                        Forms\Components\Select::make('assignee_id')
                            ->label('Assign to')
                            ->required()
                            ->options(fn (): array => AdminUser::query()->where('is_active', true)->pluck('name', 'id')->toArray()),
                        Forms\Components\Textarea::make('reason')
                            ->required()
                            ->maxLength(300),
                    ])
                    ->action(function (SupportTicket $record, array $data): void {
                        try {
                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            $service->assignTicket($record, (int) $data['assignee_id'], (string) $data['reason'], Filament::auth()->id());
                            Notification::make()->title('Ticket reassigned.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Reassignment failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('reply')
                    ->label('Reply')
                    ->icon('heroicon-o-chat-bubble-left-right')
                    ->color('success')
                    ->visible(fn (SupportTicket $record): bool => static::canRespond() && ! $record->isTerminal())
                    ->form([
                        Forms\Components\Textarea::make('message')
                            ->required()
                            ->rows(5)
                            ->maxLength(4000),
                    ])
                    ->action(function (SupportTicket $record, array $data): void {
                        try {
                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            $service->addReply($record, ['message' => $data['message'], 'is_internal_note' => false], 'admin', Filament::auth()->id());
                            Notification::make()->title('Reply sent.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Reply failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('internal_note')
                    ->label('Internal note')
                    ->icon('heroicon-o-pencil-square')
                    ->color('gray')
                    ->visible(fn (SupportTicket $record): bool => static::canRespond() && ! $record->isTerminal())
                    ->form([
                        Forms\Components\Textarea::make('message')
                            ->required()
                            ->rows(4)
                            ->maxLength(4000),
                    ])
                    ->action(function (SupportTicket $record, array $data): void {
                        try {
                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            $service->addReply($record, ['message' => $data['message'], 'is_internal_note' => true], 'admin', Filament::auth()->id());
                            Notification::make()->title('Internal note saved.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Save failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('resolve')
                    ->label('Resolve')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->visible(fn (SupportTicket $record): bool => static::canResolve() && in_array($record->status, [
                        SupportTicket::STATUS_OPEN,
                        SupportTicket::STATUS_IN_PROGRESS,
                        SupportTicket::STATUS_PENDING_USER,
                    ], true))
                    ->form([
                        Forms\Components\Textarea::make('summary')
                            ->required()
                            ->label('Resolution summary')
                            ->rows(4)
                            ->maxLength(2000),
                    ])
                    ->action(function (SupportTicket $record, array $data): void {
                        try {
                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            $service->resolveTicket($record, (string) $data['summary'], Filament::auth()->id());
                            Notification::make()->title('Ticket resolved.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Resolve failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('transition')
                    ->label('Change status')
                    ->icon('heroicon-o-arrow-path')
                    ->color('warning')
                    ->visible(fn (SupportTicket $record): bool => static::canResolve() && ! $record->isTerminal())
                    ->form([
                        Forms\Components\Select::make('status')
                            ->required()
                            ->options([
                                SupportTicket::STATUS_OPEN => 'Open',
                                SupportTicket::STATUS_IN_PROGRESS => 'In progress',
                                SupportTicket::STATUS_PENDING_USER => 'Pending user',
                                SupportTicket::STATUS_RESOLVED => 'Resolved',
                                SupportTicket::STATUS_CLOSED => 'Closed',
                                SupportTicket::STATUS_SPAM => 'Spam',
                            ]),
                        Forms\Components\Textarea::make('reason')
                            ->required()
                            ->label('Status change reason')
                            ->maxLength(300),
                    ])
                    ->action(function (SupportTicket $record, array $data): void {
                        try {
                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            $service->transitionStatus($record, (string) $data['status'], (string) $data['reason'], Filament::auth()->id());
                            Notification::make()->title('Ticket status updated.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Status change failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('merge')
                    ->label('Merge')
                    ->icon('heroicon-o-link')
                    ->color('danger')
                    ->visible(fn (SupportTicket $record): bool => static::canResolve() && ! $record->isTerminal() && $record->merged_into_ticket_id === null)
                    ->form([
                        Forms\Components\TextInput::make('target_ticket_number')
                            ->required()
                            ->label('Target ticket number'),
                        Forms\Components\TextInput::make('confirm_text')
                            ->required()
                            ->label('Type MERGE to confirm')
                            ->rule('in:MERGE'),
                        Forms\Components\Textarea::make('reason')
                            ->required(),
                    ])
                    ->action(function (SupportTicket $record, array $data): void {
                        try {
                            if (($data['confirm_text'] ?? '') !== 'MERGE') {
                                Notification::make()->title('Typed confirmation did not match MERGE.')->danger()->send();
                                return;
                            }

                            $target = SupportTicket::query()
                                ->where('ticket_number', $data['target_ticket_number'])
                                ->first();

                            if (! $target) {
                                Notification::make()->title('Target ticket not found.')->danger()->send();
                                return;
                            }

                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            $service->mergeInto($record, $target, (string) $data['reason'], Filament::auth()->id());
                            Notification::make()->title('Ticket merged.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Merge failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
                Action::make('split')
                    ->label('Split')
                    ->icon('heroicon-o-arrows-right-left')
                    ->color('warning')
                    ->visible(fn (SupportTicket $record): bool => static::canResolve() && ! $record->isTerminal() && $record->merged_into_ticket_id === null)
                    ->form([
                        Forms\Components\TextInput::make('subject')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('description')
                            ->required()
                            ->rows(4),
                    ])
                    ->action(function (SupportTicket $record, array $data): void {
                        try {
                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            $split = $service->splitTicket($record, (string) $data['subject'], (string) $data['description'], Filament::auth()->id());
                            Notification::make()->title('New split ticket created: ' . $split->ticket_number)->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Split failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkAction::make('assign_to_me_bulk')
                    ->label('Assign selected to me')
                    ->icon('heroicon-o-user-plus')
                    ->visible(fn (): bool => static::canAssign())
                    ->action(function ($records): void {
                        try {
                            /** @var SupportTicketService $service */
                            $service = app(SupportTicketService::class);
                            foreach ($records as $record) {
                                $service->assignTicket($record, Filament::auth()->id(), 'Bulk assignment', Filament::auth()->id());
                            }
                            Notification::make()->title('Selected tickets assigned.')->success()->send();
                        } catch (\Throwable $throwable) {
                            Notification::make()->title('Bulk assignment failed: ' . $throwable->getMessage())->danger()->send();
                        }
                    }),
            ])
            ->defaultSort('created_at', 'desc')
            ->recordAction(null)
            ->emptyStateHeading('No support tickets found')
            ->emptyStateDescription('Try adjusting filters or create a ticket from API intake.')
            ->striped();
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSupportTickets::route('/'),
            'create' => Pages\CreateSupportTicket::route('/create'),
            'edit' => Pages\EditSupportTicket::route('/{record}/edit'),
        ];
    }

    public static function canViewAny(): bool
    {
        return static::canViewTickets();
    }

    public static function canCreate(): bool
    {
        return (bool) Filament::auth()->user()?->can('support_tickets.create');
    }

    public static function canEdit($record): bool
    {
        return false;
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    private static function canViewTickets(): bool
    {
        return (bool) Filament::auth()->user()?->can('support_tickets.view');
    }

    private static function canAssign(): bool
    {
        return (bool) Filament::auth()->user()?->can('support_tickets.assign');
    }

    private static function canRespond(): bool
    {
        return (bool) Filament::auth()->user()?->can('support_tickets.respond');
    }

    private static function canResolve(): bool
    {
        return (bool) Filament::auth()->user()?->can('support_tickets.resolve');
    }
}

