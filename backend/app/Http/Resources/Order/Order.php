<?php

namespace App\Http\Resources\Order;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Http\Resources\Order\OrderData as OrderDataResource;
use App\Http\Resources\Order\CancelReason as CancelReasonResource;
use Carbon\Carbon;
use App\Models\Review;

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
        
        return [
            'order_id' => $this->id,
            'order_type_id' => $this->orderId,
            'mikitchn' => [
                    'id' => $this->Mikitchn->id,
                    'name' => $this->Mikitchn->name,
                    'address' => $this->Mikitchn->address,
                    'rating' => $this->Mikitchn->reviews->avg('rating'),
                    'images' => $this->Mikitchn->images,
                ],
            'customer' => [
                    'id' => $this->user_id, 
                    'name' => $this->user->first_name.' '.$this->user->last_name, 
                    'phone' => $this->user->phone, 
                    'avatar' => $this->user->avatar, 
                    'description' => $this->user->description, 
                    'rating' => $this->user->reviews->avg('rating'), 
                ],
            'date' => $this->delivery_date->format('d M Y'),
            'time_from' => $this->delivery_time_from->format('H:i a'),
            'time_to' => $this->delivery_time_to->format('H:i a'),
            'created_at' => $this->created_at->format('d M Y'),
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
            'items' => OrderDataResource::collection($this->items)
        ];
    }
}
