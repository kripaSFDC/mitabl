<?php

namespace App\Http\Resources\Order;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Http\Resources\Order\OrderData as OrderDataResource;

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
        // return parent::toArray($request);

        return [

            'mikitchn' => [
                    'id' => $this->Mikitchn->id,
                    'name' => $this->Mikitchn->name,
                    'address' => $this->Mikitchn->address,
                    'rating' => $this->Mikitchn->reviews->avg('rating'),
                ],
            'customer' => [
                    'id' => $this->user_id, 
                    'name' => $this->user->first_name.' '.$this->user->last_name, 
                    'phone' => $this->user->phone, 
                ],
            'date' => $this->delivery_date,
            'time_from' => $this->delivery_time_from,
            'time_to' => $this->delivery_time_to,
            'persons' => $this->persons,
            'dine_in' => $this->dine_in,
            'take_away' => $this->take_away,
            'item_total_price' => $this->item_total_price,
            'promo_code' => $this->promo_code,
            'taxes' => $this->taxes,
            'status' => $this->status,
            'paid' => $this->paid,
            'items' => OrderDataResource::collection($this->items)
        ];
    }
}
