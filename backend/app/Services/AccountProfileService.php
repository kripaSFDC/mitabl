<?php

namespace App\Services;

use App\Models\NotifyDisable;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AccountProfileService
{
    public function updateProfile(User $user, Request $request, callable $uploadImage): array
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'phone' => 'required|string|max:30',
            'email' => 'required|email|unique:users,email,' . $user->id,
        ]);

        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        $user->first_name = (string) $request->first_name;
        $user->last_name = (string) $request->last_name;
        $user->email = (string) $request->email;
        $user->phone = (string) $request->phone;
        $user->description = $request->description;

        if ($request->hasFile('avatar')) {
            $avatar = $uploadImage($request->avatar, 'user');
            if (! ($avatar['success'] ?? false)) {
                return ['error' => (string) ($avatar['msg'] ?? 'Unable to upload avatar.'), 'status' => 422];
            }
            $user->avatar = (string) $avatar['path'];
        }

        $user->save();

        return ['user' => $user];
    }

    public function switchRole(User $user, Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'role_id' => 'required|integer|in:2,3',
        ]);

        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        $targetRoleId = (int) $request->input('role_id');
        if ((int) $user->role_id === $targetRoleId) {
            return ['user' => $user->fresh(['role', 'restaurant.certificate', 'notifyDisable'])];
        }

        if ($targetRoleId === 2) {
            $hasCookProfile = $user->restaurant()->exists();
            $hasCookOnboardingFootprint = $user->vendor()->exists();
            if (! $hasCookProfile && ! $hasCookOnboardingFootprint) {
                return [
                    'error' => 'micook profile is not available for this account.',
                    'status' => 422,
                ];
            }
        }

        $user->role_id = $targetRoleId;
        $user->save();

        return ['user' => $user->fresh(['role', 'restaurant.certificate', 'notifyDisable'])];
    }

    public function changePassword(User $user, Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'current_password' => 'required',
            'new_password' => 'required|different:current_password|min:6',
        ]);
        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        if (! Hash::check((string) $request->current_password, (string) $user->password)) {
            return ['error' => 'Current password doesn\'t match', 'status' => 422];
        }

        $user->password = bcrypt((string) $request->new_password);
        $user->save();

        return ['updated' => true];
    }

    public function updateDeviceToken(User $user, Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'device_token' => 'required|string|max:2048',
        ]);
        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        $user->device_token = (string) $request->device_token;
        $user->save();

        return ['updated' => true];
    }

    public function toggleNotifications(User $user): array
    {
        $existing = NotifyDisable::where('user_id', $user->id)->first();
        if ($existing) {
            $existing->delete();
        } else {
            $notifyDisable = new NotifyDisable();
            $notifyDisable->user_id = $user->id;
            $notifyDisable->save();
        }

        return ['updated' => true];
    }

    public function updateNotificationPreferences(User $user, Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'notifications_enabled' => 'nullable|boolean',
            'device_key' => 'nullable|string|max:2048',
            'device_token' => 'nullable|string|max:2048',
        ]);

        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        $deviceToken = $request->input('device_key', $request->input('device_token'));
        if (is_string($deviceToken) && trim($deviceToken) !== '') {
            $user->device_token = trim($deviceToken);
        }

        if ($request->has('notifications_enabled')) {
            $enabled = filter_var($request->input('notifications_enabled'), FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
            if ($enabled === null) {
                return ['error' => 'notifications_enabled must be a boolean value.', 'status' => 422];
            }

            if ($enabled) {
                NotifyDisable::where('user_id', $user->id)->delete();
            } else {
                $existing = NotifyDisable::where('user_id', $user->id)->first();
                if (! $existing) {
                    $notifyDisable = new NotifyDisable();
                    $notifyDisable->user_id = $user->id;
                    $notifyDisable->save();
                }
            }
        }

        if ($user->isDirty('device_token')) {
            $user->save();
        }

        return [
            'updated' => true,
            'notifications_enabled' => ! (bool) $user->notifyDisable,
            'has_device_token' => ! empty($user->device_token),
        ];
    }

    public function mobileContact(User $user): array
    {
        return [
            'role' => $user->role_id,
            'id' => $user->id,
            'email' => $user->email,
            'phone' => $user->phone,
        ];
    }
}
