<?php

namespace App\Http\Resources\Restaurant;

use Illuminate\Http\Resources\Json\JsonResource;

class Restaurant extends JsonResource
{
    /**
     * Transform the resource collection into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $images = $this->relationLoaded('addedimage')
            ? $this->addedimage->pluck('path')->values()
            : [];

        $rating = null;
        if (isset($this->rating_count)) {
            $rating = $this->rating_count;
        } elseif (isset($this->reviews_avg_rating)) {
            $rating = $this->reviews_avg_rating;
        }

        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'name' => $this->name,
            'address' => $this->address,
            'phone' => $this->phone,
            'no_of_seats' => $this->no_of_seats,
            'description' => $this->description,
            'dine_in' => (int) ($this->dine_in ?? 0),
            'take_away' => (int) ($this->take_away ?? 0),
            'status' => $this->status,
            'open' => (int) ($this->open ?? 0),
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'distance' => isset($this->distance) ? (float) $this->distance : null,
            'rating_count' => $rating,
            'orders_count' => isset($this->orders_count) ? (int) $this->orders_count : null,
            'images' => $images,
            'foods' => Food::collection($this->whenLoaded('foods')),
            'weektimings' => $this->whenLoaded('weektimings'),
            'certificate' => $this->whenLoaded('certificate', function () {
                return [
                    'id' => $this->certificate?->id,
                    'status' => $this->certificate?->status,
                    'abn' => $this->certificate?->abn,
                    'abn_gst' => $this->certificate?->abn_gst,
                ];
            }),
            'cock' => $this->when(isset($this->cock), $this->cock),
            'gst' => $this->when(isset($this->gst), $this->gst),
            'is_favourited' => (bool) ($this->is_favourited ?? false),
        ];
    }
}
