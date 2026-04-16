<?php

namespace App\Http\Resources\Order;

use Illuminate\Http\Resources\Json\JsonResource;

class CancelReason extends JsonResource
{
    /**
     * Transform the resource collection into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $user = $this->relationLoaded('actor') ? $this->actor : null;
        $username = $user ? ($user->first_name.' '.$user->last_name) : null;

        if ($this->by_user == 'mikitchen' && $user && $user->relationLoaded('restaurant') && $user->restaurant) {
            $username = $user->restaurant->name;
        }

        return [
            'subject' => $this->subject,
            'comment' => $this->comment,
            'by_user' => $this->by_user,
            'user' => $username
        ];
    }
}
