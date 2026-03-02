<?php

namespace App\Http\Resources\Restaurant;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

class Food extends JsonResource
{
    /**
     * Transform the resource collection into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $pictures = $this->relationLoaded('addedimage')
            ? $this->addedimage->pluck('path')->values()
            : [];

        return [
            'id' => $this->id,
            'restaurant_id' => $this->restaurant_id,
            'specialDiet' => $this->specialDiet,
            'cookingstyle' => $this->cookingstyle,
            'food_name' => $this->food_name,
            'pictures' => $pictures,
            'price' => $this->price,
            'status' => $this->status,
            'description' => $this->description
        ];
    }
}
