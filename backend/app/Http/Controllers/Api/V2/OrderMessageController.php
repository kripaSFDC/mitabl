<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Http\Resources\Order\OrderMessage as OrderMessageResource;
use App\Models\Order;
use App\Models\OrderMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderMessageController extends Controller
{
    private const ACTIVE_STATUSES = [
        Order::STATUS_REQUESTED,
        Order::STATUS_CONFIRMED,
        Order::STATUS_IN_PROGRESS,
    ];

    public function index(Request $request, int $orderId): JsonResponse
    {
        $order = Order::with(['mikitchn'])->findOrFail($orderId);
        $user = auth('api')->user();

        if (! $this->isParticipant($user, $order)) {
            return response()->json($this->responser([], 'You are not authorized for this order.', 403), 403);
        }

        $limit = min((int) $request->input('limit', 50), 100);
        $beforeId = $request->input('before_id');

        $query = OrderMessage::query()
            ->with('sender:id,first_name,last_name')
            ->where('order_id', $orderId)
            ->orderBy('created_at', 'desc')
            ->orderBy('id', 'desc')
            ->limit($limit + 1);

        if ($beforeId !== null) {
            $query->where('id', '<', (int) $beforeId);
        }

        $messages = $query->get();
        $hasMore = $messages->count() > $limit;

        if ($hasMore) {
            $messages = $messages->slice(0, $limit);
        }

        // Mark messages from the other party as read
        OrderMessage::query()
            ->where('order_id', $orderId)
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'data' => [
                'messages' => OrderMessageResource::collection($messages->reverse()->values()),
                'has_more' => $hasMore,
            ],
            'message' => 'Order messages.',
            'status' => 200,
        ]);
    }

    public function store(Request $request, int $orderId): JsonResponse
    {
        $order = Order::with(['mikitchn', 'user'])->findOrFail($orderId);
        $user = auth('api')->user();

        if (! $this->isParticipant($user, $order)) {
            return response()->json($this->responser([], 'You are not authorized for this order.', 403), 403);
        }

        if (! in_array((int) $order->status, self::ACTIVE_STATUSES, true)) {
            return response()->json(
                $this->responser([], 'Messaging is only available for active orders.', 422),
                422
            );
        }

        $validated = $request->validate([
            'body' => 'required|string|min:1|max:1000',
        ]);

        $message = OrderMessage::create([
            'order_id' => $orderId,
            'sender_id' => $user->id,
            'body' => $validated['body'],
        ]);

        $message->load('sender:id,first_name,last_name');

        $this->notifyRecipient($user, $order);

        return response()->json([
            'data' => new OrderMessageResource($message),
            'message' => 'Message sent.',
            'status' => 201,
        ], 201);
    }

    public function markRead(Request $request, int $orderId): JsonResponse
    {
        $order = Order::findOrFail($orderId);
        $user = auth('api')->user();

        if (! $this->isParticipant($user, $order)) {
            return response()->json($this->responser([], 'You are not authorized for this order.', 403), 403);
        }

        $count = OrderMessage::query()
            ->where('order_id', $orderId)
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'data' => ['marked_count' => $count],
            'message' => 'Messages marked as read.',
            'status' => 200,
        ]);
    }

    public function unreadCounts(): JsonResponse
    {
        $user = auth('api')->user();

        // For a foodie: their orders where the cook sent unread messages.
        // For a cook: their kitchen's orders where the foodie sent unread messages.
        $unread = OrderMessage::query()
            ->selectRaw('order_id, COUNT(*) as unread_count')
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->whereHas('order', function ($q) use ($user) {
                $q->where(function ($sub) use ($user) {
                    $sub->where('user_id', $user->id)
                        ->orWhereHas('mikitchn', fn ($k) => $k->where('user_id', $user->id));
                });
            })
            ->groupBy('order_id')
            ->get();

        return response()->json([
            'data' => [
                'orders' => $unread->map(fn ($row) => [
                    'order_id' => $row->order_id,
                    'unread_count' => (int) $row->unread_count,
                ])->values(),
                'total_unread' => $unread->sum('unread_count'),
            ],
            'message' => 'Unread message counts.',
            'status' => 200,
        ]);
    }

    private function isParticipant(mixed $user, Order $order): bool
    {
        if ((int) $user->id === (int) $order->user_id) {
            return true;
        }

        // Cook role: check if the user owns the kitchen attached to this order
        if ($order->mikitchn && (int) $order->mikitchn->user_id === (int) $user->id) {
            return true;
        }

        return false;
    }

    private function notifyRecipient(mixed $user, Order $order): void
    {
        $recipient = ((int) $user->id === (int) $order->user_id)
            ? $order->mikitchn?->user
            : $order->user;

        if (! $recipient) {
            return;
        }

        $title = 'New message on order #' . $order->id;
        $body = 'You have a new message.';
        $deviceToken = $recipient->device_token ?? null;

        if ($deviceToken) {
            try {
                app(\App\Http\Controllers\FcmController::class)
                    ->sendTo($deviceToken, $title, $body, null, ['order_id' => $order->id, 'type' => 'message']);
            } catch (\Throwable) {
                // Push is best-effort; message is persisted regardless.
            }
        }

        // Persist database notification so it shows up in GET /v2/notifications.
        // Type 9 = in-app message notification (distinct from order lifecycle statuses 1-7).
        $recipient->notify(new \App\Notifications\OrderStatusNotification($order, 9, $title, $body));
    }
}
