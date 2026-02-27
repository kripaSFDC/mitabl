<?php

namespace App\Http\Resources\Reviews;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

class Reviews extends JsonResource
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

        $return = [
            'id'=> $this->id,
            'rating'=> $this->rating,
            'review'=> $this->review,
            'review_tag'=> $this->review_tag
        ];

        if ($this->user) {
            $return['user'] = [
               'id' => $this->user->id,
               'name' => $this->user->first_name,
               'avatar' => $this->user->avatar,
            ];
        }

        return $return;
    }
}
