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
            'dine_in' => (int) ($this->dine_in ?? 1),
            'take_away' => (int) ($this->take_away ?? 1),
            'available_date' => $this->available_date?->toDateString(),
            'available_days' => collect($this->available_days ?? [])->map(fn ($value): int => (int) $value)->values()->all(),
            'available_from_time' => $this->available_from_time ? substr((string) $this->available_from_time, 0, 5) : null,
            'available_to_time' => $this->available_to_time ? substr((string) $this->available_to_time, 0, 5) : null,
            'description' => $this->description,
        ];
    }
}
