<?php

namespace App\Http\Resources\User;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Http\Resources\Reviews\Reviews as ReviewsResource;

class User extends JsonResource
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
                    'first_name' => $this->first_name,
                    'last_name' => $this->last_name,
                    'email' => $this->email,
                    'email_verified' => $this->email_verified,
                    'role_id' => $this->role_id,
                    'avatar' => $this->avatar,
                    'description' => $this->description,
                    'phone' => $this->phone,
                    'address' => $this->address,
                    'role' => $this->role->role,
                    'notification' => $this->notifyDisable ? 0 : 1,
                ];
        if ($this->role_id == 2) {
            $return['is_kitchen_added'] = $this->restaurant ? 1 : 0;
            $status = 0;
            if ($this->restaurant && $this->restaurant->certificate) {
                $status = $this->restaurant->certificate->status ? 1 : 0;
            }
            $return['is_certificate_approved'] = $status;
            $return['kitchen'] = $this->restaurant ? $this->restaurant->makeHidden(['reviews','addedimage','certificate']) : null;
        }

        return $return;
    }
}
