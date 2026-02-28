<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderData;
use App\Models\User;
use Carbon\Carbon;

class OrderService
{
    public function completedOrderCountForUser(int $userId): int
    {
        return Order::where('user_id', $userId)->where('status', 1)->count();
    }

    public function createOrder(User $user, array $payload): Order
    {
        $fromTime = Carbon::parse($payload['delivery_time_from'])->format('H:i:s');
        $toTime = Carbon::parse($payload['delivery_time_to'])->format('H:i:s');

        $order = new Order();
        $order->mikitchn_id = $payload['kitchen_id'];
        $order->user_id = $user->id;
        $order->delivery_date = $payload['delivery_date'];
        $order->delivery_time_from = $fromTime;
        $order->delivery_time_to = $toTime;
        $order->message = $payload['message'] ?? null;
        $order->item_total_price = $payload['item_total_price'];
        $order->promo_code = $payload['promo_code'] ?? null;
        $order->taxes = $payload['taxes'];
        $order->total_price = $payload['total_price'];
        $order->dine_in = $payload['dine_in'];
        $order->take_away = $payload['take_away'];

        if ($this->completedOrderCountForUser($user->id) <= 5) {
            $order->discounted_amount = 50;
        }

        if (!empty($payload['dine_in']) && (int) $payload['dine_in'] === 1) {
            $order->persons = $payload['persons'];
        }

        $order->save();

        $items = json_decode($payload['item_data'], true) ?? [];
        foreach ($items as $item) {
            $orderData = new OrderData();
            $orderData->order_id = $order->id;
            $orderData->food_id = $item['id'];
            $orderData->quantity = $item['quantity'];
            $orderData->price = $item['price'];
            $orderData->save();
        }

        return $order;
    }
}
