<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderData;
use App\Models\Foods;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class OrderService
{
    public function completedOrderCountForUser(int $userId): int
    {
        return Order::where('user_id', $userId)->where('status', 1)->count();
    }

    public function createOrder(User $user, array $payload): Order
    {
        $items = json_decode((string) ($payload['item_data'] ?? ''), true);
        if (! is_array($items) || $items === []) {
            throw new InvalidArgumentException('item_data must be a non-empty JSON array.');
        }

        return DB::transaction(function () use ($user, $payload, $items): Order {
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
            $order->taxes = $payload['taxes'] ?? null;
            $order->total_price = $payload['total_price'];
            $order->dine_in = $payload['dine_in'];
            $order->take_away = $payload['take_away'];

            if ($this->completedOrderCountForUser($user->id) <= 5) {
                $order->discounted_amount = 50;
            }

            if (!empty($payload['dine_in']) && (int) $payload['dine_in'] === 1) {
                $order->persons = (int) ($payload['persons'] ?? 0);
            }

            $order->save();

            foreach ($items as $item) {
                $foodId = (int) ($item['id'] ?? 0);
                $quantity = (int) ($item['quantity'] ?? 0);
                $price = (float) ($item['price'] ?? 0);
                if ($foodId <= 0 || $quantity <= 0 || $price < 0) {
                    throw new InvalidArgumentException('Each item must include valid id, quantity, and price.');
                }

                $foodExists = Foods::query()
                    ->where('id', $foodId)
                    ->where('restaurant_id', (int) $payload['kitchen_id'])
                    ->exists();
                if (! $foodExists) {
                    throw new InvalidArgumentException('One or more items do not belong to the selected kitchen.');
                }

                $orderData = new OrderData();
                $orderData->order_id = $order->id;
                $orderData->food_id = $foodId;
                $orderData->quantity = $quantity;
                $orderData->price = $price;
                $orderData->save();
            }

            return $order;
        });
    }
}
