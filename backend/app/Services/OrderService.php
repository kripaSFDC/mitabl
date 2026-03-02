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
    public function completedOrderCountForUser(int $userId, bool $lock = false): int
    {
        $query = Order::query()
            ->where('user_id', $userId)
            ->where('status', 1);

        if ($lock) {
            $query->lockForUpdate();
        }

        return $query->count();
    }

    public function createOrder(User $user, array $payload): Order
    {
        $items = json_decode((string) ($payload['item_data'] ?? ''), true);
        if (! is_array($items) || $items === []) {
            throw new InvalidArgumentException('item_data must be a non-empty JSON array.');
        }

        return DB::transaction(function () use ($user, $payload, $items): Order {
            // Serialize discount eligibility checks for concurrent order creation by the same user.
            User::query()->whereKey($user->id)->lockForUpdate()->firstOrFail();

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

            $itemTotalCents = 0;
            $lineItems = [];
            foreach ($normalizedItems as $item) {
                $food = $foods->get($item['food_id']);
                if (! $food) {
                    throw new InvalidArgumentException('One or more items do not belong to the selected kitchen.');
                }

                $unitPriceCents = $this->moneyToCents($food->price, 'food price');
                $lineTotalCents = $unitPriceCents * (int) $item['quantity'];
                $itemTotalCents += $lineTotalCents;
                $lineItems[] = [
                    'food_id' => (int) $item['food_id'],
                    'quantity' => (int) $item['quantity'],
                    'line_total_cents' => $lineTotalCents,
                ];
            }

            $taxesCents = $this->moneyToCents($payload['taxes'] ?? 0, 'taxes');
            if ($taxesCents < 0) {
                throw new InvalidArgumentException('taxes must be greater than or equal to 0.');
            }

            $order = new Order();
            $order->mikitchn_id = $kitchenId;
            $order->user_id = $user->id;
            $order->delivery_date = $payload['delivery_date'];
            $order->delivery_time_from = $fromTime;
            $order->delivery_time_to = $toTime;
            $order->message = $payload['message'] ?? null;
            $order->item_total_price = $this->centsToMoney($itemTotalCents);
            $order->promo_code = $payload['promo_code'] ?? null;
            $order->taxes = $this->centsToMoney($taxesCents);
            $order->dine_in = $payload['dine_in'];
            $order->take_away = $payload['take_away'];

            $discountAmountCents = 0;
            if ($this->completedOrderCountForUser($user->id, true) < 5) {
                $discountAmountCents = 5000;
                $order->discounted_amount = $this->centsToMoney($discountAmountCents);
            }
            $order->total_price = $this->centsToMoney(max($itemTotalCents + $taxesCents - $discountAmountCents, 0));

            if (!empty($payload['dine_in']) && (int) $payload['dine_in'] === 1) {
                $order->persons = (int) ($payload['persons'] ?? 0);
            }

            // If clients still send totals, enforce consistency rather than trusting request values.
            if (array_key_exists('item_total_price', $payload)) {
                $providedItemTotalCents = $this->moneyToCents($payload['item_total_price'], 'item_total_price');
                if ($providedItemTotalCents !== $itemTotalCents) {
                    throw new InvalidArgumentException('item_total_price does not match server-calculated amount.');
                }
            }
            if (array_key_exists('total_price', $payload)) {
                $providedTotalCents = $this->moneyToCents($payload['total_price'], 'total_price');
                $computedTotalCents = $this->moneyToCents($order->total_price, 'total_price');
                if ($providedTotalCents !== $computedTotalCents) {
                    throw new InvalidArgumentException('total_price does not match server-calculated amount.');
                }
            }

            $order->save();

            foreach ($lineItems as $item) {
                $orderData = new OrderData();
                $orderData->order_id = $order->id;
                $orderData->food_id = $item['food_id'];
                $orderData->quantity = $item['quantity'];
                $orderData->price = $this->centsToMoney($item['line_total_cents']);
                $orderData->save();
            }

            return $order;
        });
    }

    private function moneyToCents(mixed $amount, string $field): int
    {
        if (is_float($amount)) {
            $amount = number_format($amount, 2, '.', '');
        }

        $normalized = trim((string) $amount);
        if ($normalized === '') {
            throw new InvalidArgumentException($field . ' must be a valid monetary amount.');
        }
        if (! preg_match('/^-?\d+(?:\.\d{1,2})?$/', $normalized)) {
            throw new InvalidArgumentException($field . ' must have at most 2 decimal places.');
        }

        $negative = str_starts_with($normalized, '-');
        if ($negative) {
            $normalized = substr($normalized, 1);
        }

        [$units, $fraction] = array_pad(explode('.', $normalized, 2), 2, '0');
        $fraction = str_pad($fraction, 2, '0');
        $cents = ((int) $units * 100) + (int) $fraction;

        return $negative ? -$cents : $cents;
    }

    private function centsToMoney(int $cents): string
    {
        $absCents = abs($cents);
        $sign = $cents < 0 ? '-' : '';

        return sprintf('%s%d.%02d', $sign, intdiv($absCents, 100), $absCents % 100);
    }
}
