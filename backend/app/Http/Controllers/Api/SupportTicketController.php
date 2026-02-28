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
        $validated = $request->validate([
            'requester_name' => ['nullable', 'string', 'max:255'],
            'requester_email' => ['required', 'email', 'max:255'],
            'requester_phone' => ['nullable', 'string', 'max:40'],
            'subject' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'min:5'],
            'category' => ['nullable', 'string', 'max:120'],
            'priority' => ['nullable', Rule::in(SupportTicket::priorities())],
            'order_id' => ['nullable', 'integer'],
            'mikitchn_id' => ['nullable', 'integer'],
            'captcha_token' => ['nullable', 'string'],
            'g-recaptcha-response' => ['nullable', 'string'],
            $honeypotField => ['nullable', 'string', 'max:255'],
        ]);

        if (! empty($validated[$honeypotField] ?? null)) {
            return $this->responser(['accepted' => true], 'Contact Message Sent Successfully');
        }

        $this->validateCaptchaToken($validated['captcha_token'] ?? $validated['g-recaptcha-response'] ?? null);

        $result = $this->supportTicketService->createTicket([
            'requester_name' => $validated['requester_name'] ?? null,
            'requester_email' => $validated['requester_email'],
            'requester_phone' => $validated['requester_phone'] ?? null,
            'subject' => $validated['subject'],
            'description' => $validated['description'],
            'category' => $validated['category'] ?? 'general',
            'priority' => $validated['priority'] ?? SupportTicket::PRIORITY_NORMAL,
            'order_id' => $validated['order_id'] ?? null,
            'mikitchn_id' => $validated['mikitchn_id'] ?? null,
            'actor_type' => 'guest',
            'actor_id' => null,
        ], 'public_api');

        $ticket = $result['ticket'];

        return $this->responser([
            'id' => $ticket->id,
            'ticket_number' => $ticket->ticket_number,
            'status' => $ticket->status,
            'duplicate' => $result['duplicate'],
            'token' => $ticket->requester_token,
        ], 'Contact Message Sent Successfully');
    }

    public function show(Request $request, int $id)
    {
        $ticket = SupportTicket::query()->with(['messages' => function ($query) {
            $query->where('is_internal_note', false)->latest();
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
        ]);

        $actor = $request->user();
        $senderType = $actor ? 'user' : 'guest';
        $senderId = $actor?->id;

        try {
            $reply = $this->supportTicketService->addReply($ticket, $validated, $senderType, $senderId);
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
