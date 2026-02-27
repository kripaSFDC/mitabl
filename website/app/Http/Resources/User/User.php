<?php

namespace App\Http\Resources\User;

use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

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
                ];
        if ($this->role_id == 2) {

            $return['kitchen'] = $this->restaurant;
        }

        return $return;
    }
}
