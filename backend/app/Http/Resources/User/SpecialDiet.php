<?php

namespace App\Http\Resources\User;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

class SpecialDiet extends JsonResource
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
                    'id' => $this->id,
                    'name' => $this->name,
                ];

        return $return;
    }
}
