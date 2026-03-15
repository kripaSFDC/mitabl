<?php

namespace App\Http\Resources\Order;

use Illuminate\Http\Resources\Json\JsonResource;
use App\Http\Resources\Order\OrderData as OrderDataResource;
use App\Http\Resources\Order\CancelReason as CancelReasonResource;
use Carbon\Carbon;

class Order extends JsonResource
{
    /**
     * Transform the resource collection into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $orderTypeId = ($this->dine_in ? 'D' : 'T') . '-' . $this->id;

        $kitchen = $this->relationLoaded('Mikitchn') ? $this->Mikitchn : null;
        $customer = $this->relationLoaded('user') ? $this->user : null;
        $items = $this->relationLoaded('orderdata') ? $this->orderdata : collect();
        $dineInSlot = $this->relationLoaded('dineInSlot') ? $this->dineInSlot : null;

        $kitchenImages = [];
        if ($kitchen && $kitchen->relationLoaded('addedimage')) {
            $kitchenImages = $kitchen->addedimage->pluck('path')->values();
        }

        $kitchenRating = null;
        if ($kitchen) {
            if (isset($kitchen->reviews_avg_rating)) {
                $kitchenRating = $kitchen->reviews_avg_rating;
            } elseif ($kitchen->relationLoaded('reviews')) {
                $kitchenRating = $kitchen->reviews->avg('rating');
            }
        }

        $customerRating = null;
        if ($customer && $customer->relationLoaded('reviews')) {
            $customerRating = $customer->reviews->avg('rating');
        }

        return [
            'order_id' => $this->id,
            'order_type_id' => $orderTypeId,
            'mikitchn' => [
                    'id' => $kitchen?->id,
                    'name' => $kitchen?->name,
                    'address' => $kitchen?->address,
                    'rating' => $kitchenRating,
                    'images' => $kitchenImages,
                ],
            'customer' => [
                    'id' => $this->user_id, 
                    'name' => $customer ? ($customer->first_name.' '.$customer->last_name) : null,
                    'phone' => $customer?->phone,
                    'avatar' => $customer?->avatar,
                    'description' => $customer?->description,
                    'rating' => $customerRating,
                ],
            'date' => $this->formatValue($this->delivery_date, 'd M Y'),
            'time_from' => $this->formatValue($this->delivery_time_from, 'H:i a'),
            'time_to' => $this->formatValue($this->delivery_time_to, 'H:i a'),
            'dine_in_slot' => $this->when($dineInSlot !== null, [
                'id' => $dineInSlot?->id,
                'day_of_week' => $dineInSlot?->day_of_week,
                'day_name' => $dineInSlot?->day_name,
                'start_time' => $dineInSlot?->start_time ? substr((string) $dineInSlot->start_time, 0, 5) : null,
                'end_time' => $dineInSlot?->end_time ? substr((string) $dineInSlot->end_time, 0, 5) : null,
            ]),
            'created_at' => $this->formatValue($this->created_at, 'd M Y'),
            'persons' => $this->persons,
            'message' => $this->message,
            'dine_in' => $this->dine_in,
            'take_away' => $this->take_away,
            'item_total_price' => $this->item_total_price,
            'discounted_amount' => $this->discounted_amount,
            'promo_code' => $this->promo_code,
            'promocode' => $this->promocode,
            'taxes' => $this->taxes,
            'total_price' => $this->total_price,
            'status' => $this->status,
            'cancel_reason' => $this->cancelreason ? new CancelReasonResource($this->cancelreason) : null,
            'refund_percentage' => $this->refund_percentage,
            'paid' => $this->paid,
            'rating_by_customer' => ($this->review) ? $this->review->rating : null,
            'items' => OrderDataResource::collection($items)
        ];
    }

    private function formatValue(mixed $value, string $format): ?string
    {
        if ($value === null) {
            return null;
        }

        if ($value instanceof Carbon) {
            return $value->format($format);
        }

        return Carbon::parse((string) $value)->format($format);
    }
}
