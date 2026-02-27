<?php

namespace App\Http\Resources\Order;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Models\User;

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
        // return parent::toArray($request);
        $user = User::find($this->ref_id);
        $username = $user->first_name.' '.$user->last_name;
        if ($this->by_user == 'mikitchen') {
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
