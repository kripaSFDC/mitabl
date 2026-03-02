<?php

namespace App\Http\Resources\Order;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderData extends JsonResource
{
    /**
     * Transform the resource collection into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $food = $this->relationLoaded('food') ? $this->food : null;

        return [
            'food' => $food?->food_name,
            'quantity' => $this->quantity,
            'price' => $food?->price,
            'total_price' => $this->price,
        ];
    }
}
