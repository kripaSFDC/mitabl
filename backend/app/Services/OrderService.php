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
            $kitchenId = (int) $payload['kitchen_id'];

            $normalizedItems = [];
            $foodIds = [];
            foreach ($items as $item) {
                $foodId = (int) ($item['id'] ?? 0);
                $quantity = (int) ($item['quantity'] ?? 0);
                if ($foodId <= 0 || $quantity <= 0) {
                    throw new InvalidArgumentException('Each item must include valid id and quantity.');
                }
                $normalizedItems[] = ['food_id' => $foodId, 'quantity' => $quantity];
                $foodIds[] = $foodId;
            }

            $foods = Foods::query()
                ->select(['id', 'price'])
                ->where('restaurant_id', $kitchenId)
                ->whereIn('id', $foodIds)
                ->get()
                ->keyBy('id');

            if (count($foodIds) !== $foods->count()) {
                throw new InvalidArgumentException('One or more items do not belong to the selected kitchen.');
            }

            $itemTotalPrice = 0.0;
            $lineItems = [];
            foreach ($normalizedItems as $item) {
                $food = $foods->get($item['food_id']);
                if (! $food) {
                    throw new InvalidArgumentException('One or more items do not belong to the selected kitchen.');
                }

                $unitPrice = round((float) $food->price, 2);
                $lineTotal = round($unitPrice * (int) $item['quantity'], 2);
                $itemTotalPrice = round($itemTotalPrice + $lineTotal, 2);
                $lineItems[] = [
                    'food_id' => (int) $item['food_id'],
                    'quantity' => (int) $item['quantity'],
                    'line_total' => $lineTotal,
                ];
            }

            $taxes = round((float) ($payload['taxes'] ?? 0), 2);
            if ($taxes < 0) {
                throw new InvalidArgumentException('taxes must be greater than or equal to 0.');
            }

            $order = new Order();
            $order->mikitchn_id = $kitchenId;
            $order->user_id = $user->id;
            $order->delivery_date = $payload['delivery_date'];
            $order->delivery_time_from = $fromTime;
            $order->delivery_time_to = $toTime;
            $order->message = $payload['message'] ?? null;
            $order->item_total_price = $itemTotalPrice;
            $order->promo_code = $payload['promo_code'] ?? null;
            $order->taxes = $taxes;
            $order->dine_in = $payload['dine_in'];
            $order->take_away = $payload['take_away'];

            $discountAmount = 0.0;
            if ($this->completedOrderCountForUser($user->id) < 5) {
                $order->discounted_amount = 50;
                $discountAmount = 50.0;
            }
            $order->total_price = max(round($itemTotalPrice + $taxes - $discountAmount, 2), 0);

            if (!empty($payload['dine_in']) && (int) $payload['dine_in'] === 1) {
                $order->persons = (int) ($payload['persons'] ?? 0);
            }

            // If clients still send totals, enforce consistency rather than trusting request values.
            if (array_key_exists('item_total_price', $payload)) {
                $providedItemTotal = round((float) $payload['item_total_price'], 2);
                if (abs($providedItemTotal - $itemTotalPrice) > 0.01) {
                    throw new InvalidArgumentException('item_total_price does not match server-calculated amount.');
                }
            }
            if (array_key_exists('total_price', $payload)) {
                $providedTotal = round((float) $payload['total_price'], 2);
                if (abs($providedTotal - (float) $order->total_price) > 0.01) {
                    throw new InvalidArgumentException('total_price does not match server-calculated amount.');
                }
            }

            $order->save();

            foreach ($lineItems as $item) {
                $orderData = new OrderData();
                $orderData->order_id = $order->id;
                $orderData->food_id = $item['food_id'];
                $orderData->quantity = $item['quantity'];
                $orderData->price = $item['line_total'];
                $orderData->save();
            }

            return $order;
        });
    }
}
