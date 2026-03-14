<?php

namespace App\Http\Resources\User;

use App\Models\UserRole;
use Illuminate\Http\Resources\Json\JsonResource;

class User extends JsonResource
{
    public function toArray($request)
    {
        $memberships = $this->relationLoaded('roleMemberships')
            ? $this->roleMemberships
            : $this->roleMemberships()->with('role')->get();

        $availableRoles = $memberships
            ->map(function ($membership) {
                return [
                    'role_id' => (int) $membership->role_id,
                    'role' => optional($membership->role)->role,
                    'status' => $membership->status,
                    'onboarding' => $membership->status === UserRole::STATUS_ONBOARDING,
                    'disabled' => $membership->status === UserRole::STATUS_DISABLED,
                ];
            })
            ->values();

        $return = [
            'id' => $this->id,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'email' => $this->email,
            'email_verified' => $this->email_verified,
            'role_id' => $this->role_id,
            'active_role_id' => $this->active_role_id,
            'avatar' => $this->avatar,
            'description' => $this->description,
            'phone' => $this->phone,
            'address' => $this->address,
            'role' => optional($this->role)->role,
            'notification' => $this->notifyDisable ? 0 : 1,
            'available_roles' => $availableRoles,
            'role_onboarding' => $availableRoles->mapWithKeys(fn ($role) => [$role['role_id'] => $role['onboarding']]),
        ];

        if ((int) $this->active_role_id === 2) {
            $return['is_kitchen_added'] = $this->restaurant ? 1 : 0;
            $status = 0;
            if ($this->restaurant && $this->restaurant->certificate) {
                $status = $this->restaurant->certificate->status ? 1 : 0;
            }
            $return['is_certificate_approved'] = $status;
            $return['kitchen'] = $this->restaurant ? $this->restaurant->makeHidden(['reviews', 'addedimage', 'certificate']) : null;
        }

        return $return;
    }
}
