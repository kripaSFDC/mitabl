<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use App\Services\SupportTicketService;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;

class SupportTicketController extends Controller
{
    public function __construct(private SupportTicketService $supportTicketService)
    {
    }

    public function store(Request $request)
    {
        $honeypotField = (string) config('support.honeypot_field', 'website');
        $honeypotValue = $request->input($honeypotField);

        if (
            (is_string($honeypotValue) && trim($honeypotValue) !== '')
            || (is_array($honeypotValue) && $honeypotValue !== [])
        ) {
            return $this->responser(['accepted' => true], 'Contact Message Sent Successfully');
        }

        $validated = $request->validate([
            'requester_name' => ['nullable', 'string', 'max:255'],
            'requester_email' => ['required', 'email', 'max:255'],
            'requester_phone' => ['nullable', 'string', 'max:40'],
            'subject' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'min:5'],
            'category' => ['nullable', Rule::in(array_merge(SupportTicket::categories(), ['order', 'kitchen', 'certificate']))],
            'priority' => ['nullable', Rule::in(SupportTicket::priorities())],
            'order_id' => ['nullable', 'integer'],
            'mikitchn_id' => ['nullable', 'integer'],
            'attachments' => ['nullable', 'array'],
            'attachments.*' => ['file', 'max:' . (int) config('support.attachments.max_size_kb', 5120)],
            'captcha_token' => ['nullable', 'string'],
            $honeypotField => ['nullable'],
        ]);

        $this->validateCaptchaToken($validated['captcha_token'] ?? null);

        try {
            $actor = $request->user();
            $result = $this->supportTicketService->createTicket([
                'user_id' => $actor?->id,
                'requester_name' => $validated['requester_name'] ?? null,
                'requester_email' => $validated['requester_email'],
                'requester_phone' => $validated['requester_phone'] ?? null,
                'subject' => $validated['subject'],
                'description' => $validated['description'],
                'category' => $validated['category'] ?? 'general',
                'priority' => $validated['priority'] ?? SupportTicket::PRIORITY_NORMAL,
                'order_id' => $validated['order_id'] ?? null,
                'mikitchn_id' => $validated['mikitchn_id'] ?? null,
                'attachments' => $request->file('attachments', []),
                'actor_type' => 'user',
                'actor_id' => $actor?->id,
            ], 'public_api');
        } catch (InvalidArgumentException $exception) {
            return response()->json([
                'status' => 422,
                'isSuccess' => false,
                'isError' => $exception->getMessage(),
            ], 422);
        }

        $ticket = $result['ticket'];

        return $this->responser([
            'id' => $ticket->id,
            'ticket_number' => $ticket->ticket_number,
            'status' => $ticket->status,
            'duplicate' => $result['duplicate'],
            'token' => $ticket->requester_token,
        ], 'Contact Message Sent Successfully');
    }


    public function deprecatedMobcontact(Request $request)
    {
        return response()->json([
            'status' => 410,
            'isSuccess' => false,
            'isError' => 'The /api/mobcontact endpoint is deprecated. Use /api/support/ticket instead.',
        ], 410);
    }

    public function show(Request $request, int $id)
    {
        $ticket = SupportTicket::query()->with(['messages' => function ($query) {
            $query->where('is_internal_note', false)->with('attachments')->latest();
        }])->findOrFail($id);

        if (! $this->canAccessTicket($request, $ticket)) {
            return response()->json([
                'status' => 403,
                'isSuccess' => false,
                'isError' => 'Unauthorized to view this ticket.',
            ], 403);
        }

        return response()->json([
            'status' => 200,
            'isSuccess' => true,
            'message' => 'Ticket details.',
            'data' => [
                'id' => $ticket->id,
                'ticket_number' => $ticket->ticket_number,
                'subject' => $ticket->subject,
                'description' => $ticket->description,
                'status' => $ticket->status,
                'priority' => $ticket->priority,
                'category' => $ticket->category,
                'messages' => $ticket->messages->map(fn ($message) => [
                    'id' => $message->id,
                    'sender_type' => $message->sender_type,
                    'message' => $message->message,
                    'attachments' => $message->attachments->map(fn ($attachment) => [
                        'id' => $attachment->id,
                        'name' => $attachment->original_name,
                        'mime_type' => $attachment->mime_type,
                        'size' => $attachment->size,
                        'scan_status' => $attachment->scan_status,
                    ])->values(),
                    'created_at' => $message->created_at,
                ])->values(),
            ],
        ]);
    }

    public function reply(Request $request, int $id)
    {
        $ticket = SupportTicket::query()->findOrFail($id);
        if (! $this->canAccessTicket($request, $ticket)) {
            return response()->json([
                'status' => 403,
                'isSuccess' => false,
                'isError' => 'Unauthorized to reply on this ticket.',
            ], 403);
        }

        $validated = $request->validate([
            'message' => ['required', 'string', 'min:2'],
            'reopen_reason' => ['nullable', 'string', 'max:300'],
            'attachments' => ['nullable', 'array'],
            'attachments.*' => ['file', 'max:' . (int) config('support.attachments.max_size_kb', 5120)],
        ]);

        $actor = $request->user();
        $senderType = 'user';
        $senderId = $actor?->id;

        try {
            $reply = $this->supportTicketService->addReply(
                $ticket,
                array_merge($validated, ['attachments' => $request->file('attachments', [])]),
                $senderType,
                $senderId
            );
        } catch (InvalidArgumentException $exception) {
            return response()->json([
                'status' => 422,
                'isSuccess' => false,
                'isError' => $exception->getMessage(),
            ], 422);
        }

        return response()->json([
            'status' => 200,
            'isSuccess' => true,
            'message' => 'Reply added.',
            'data' => [
                'reply_id' => $reply->id,
                'ticket_id' => $ticket->id,
                'ticket_number' => $ticket->ticket_number,
            ],
        ]);
    }

    private function canAccessTicket(Request $request, SupportTicket $ticket): bool
    {
        $token = (string) ($request->header('X-Ticket-Token') ?? $request->query('token', ''));

        if ($token !== '' && hash_equals((string) $ticket->requester_token, $token)) {
            return true;
        }

        $user = $request->user();
        if (! $user) {
            return false;
        }

        return (int) $ticket->user_id === (int) $user->id;
    }

    private function validateCaptchaToken(?string $captchaToken): void
    {
        $secret = (string) config('services.recaptcha.secret');
        if ($secret === '' || ! $captchaToken) {
            return;
        }

        try {
            $response = \Illuminate\Support\Facades\Http::asForm()->post(
                'https://www.google.com/recaptcha/api/siteverify',
                [
                    'secret' => $secret,
                    'response' => $captchaToken,
                ]
            )->json();
        } catch (ConnectionException|\Throwable) {
            throw ValidationException::withMessages([
                'captcha_token' => [
                    'Captcha verification is temporarily unavailable.',
                ],
            ])->status(422);
        }

        if (! is_array($response) || ! ($response['success'] ?? false)) {
            throw ValidationException::withMessages([
                'captcha_token' => [
                    'Captcha verification failed.',
                ],
            ])->status(422);
        }
    }
}
