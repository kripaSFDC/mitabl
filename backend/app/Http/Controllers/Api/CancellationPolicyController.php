<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\OrderNotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CancellationPolicyController extends Controller
{
    public function __construct(private OrderNotificationService $notificationService)
    {
    }

    public function show(Request $request)
    {
        $kitchen = $this->authenticatedUser('api')->restaurant;

        if (! $kitchen) {
            return $this->responser([], 'No kitchen found for this cook.', 404);
        }

        return $this->responser([
            'cancellation_window_hours' => $kitchen->cancellation_window_hours ?? 12,
            'no_show_penalty_pct' => $kitchen->no_show_penalty_pct ?? 100,
        ], 'Cancellation policy.');
    }

    public function update(Request $request)
    {
        $kitchen = $this->authenticatedUser('api')->restaurant;

        if (! $kitchen) {
            return $this->responser([], 'No kitchen found for this cook.', 404);
        }

        $validator = Validator::make($request->all(), [
            'cancellation_window_hours' => ['nullable', 'integer', 'min:0', 'max:168'],
            'no_show_penalty_pct' => ['nullable', 'integer', 'min:0', 'max:100'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $data = array_filter($validator->validated(), fn ($v) => $v !== null);
        $kitchen->fill($data)->save();

        return $this->responser([
            'cancellation_window_hours' => $kitchen->cancellation_window_hours ?? 12,
            'no_show_penalty_pct' => $kitchen->no_show_penalty_pct ?? 100,
        ], 'Cancellation policy updated.');
    }

    public function noShow(Request $request, int $id)
    {
        $actor = $this->authenticatedUser('api');
        $kitchen = $actor->restaurant;

        if (! $kitchen) {
            return $this->responser([], 'No kitchen found for this cook.', 404);
        }

        $order = Order::with(['mikitchn', 'user', 'payment'])
            ->where('mikitchn_id', $kitchen->id)
            ->find($id);

        if (! $order) {
            return $this->responser([], 'Order not found.', 404);
        }

        // Idempotent — already marked
        if ($order->no_show) {
            return $this->responser([
                'order_id' => $order->id,
                'no_show' => true,
                'penalty_amount' => number_format((float) $order->total_price * (($kitchen->no_show_penalty_pct ?? 100) / 100), 2),
                'refund_amount' => '0.00',
            ], 'Order marked as no-show.');
        }

        if (! in_array((int) $order->status, [Order::STATUS_CONFIRMED, Order::STATUS_IN_PROGRESS, Order::STATUS_READY], true)) {
            return $this->responser([], 'Only confirmed, in-progress, or ready orders can be marked as no-show.', 422);
        }

        // Delivery time must have passed
        if ($order->delivery_date && $order->delivery_time_to) {
            $deliveryEnd = Carbon::parse(
                Carbon::parse($order->delivery_date)->toDateString() . ' ' . Carbon::parse($order->delivery_time_to)->format('H:i:s')
            );
            if ($deliveryEnd->isFuture()) {
                return $this->responser([], 'Cannot mark no-show before the delivery window has ended.', 422);
            }
        }

        $penaltyPct = $kitchen->no_show_penalty_pct ?? 100;
        $penaltyAmount = round((float) $order->total_price * ($penaltyPct / 100), 2);

        $order->no_show = true;
        $order->no_show_at = Carbon::now();
        $order->status = Order::STATUS_COMPLETED;
        $order->save();

        $this->notificationService->notifyTransition($order->fresh(['mikitchn', 'user']), Order::STATUS_COMPLETED, 'No-show');

        return $this->responser([
            'order_id' => $order->id,
            'no_show' => true,
            'penalty_amount' => number_format($penaltyAmount, 2),
            'refund_amount' => '0.00',
        ], 'Order marked as no-show.');
    }
}
