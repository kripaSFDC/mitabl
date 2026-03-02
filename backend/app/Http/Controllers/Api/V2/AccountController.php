<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Http\Resources\User\User as UserResource;
use App\Services\AccountProfileService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class AccountController extends Controller
{
    public function __construct(private AccountProfileService $accountProfileService)
    {
    }

    public function show(Request $request)
    {
        return $this->responser(new UserResource(Auth::user()), 'User');
    }

    public function update(Request $request)
    {
        $user = Auth::guard('api')->user();
        $result = $this->accountProfileService->updateProfile($user, $request, [$this, 'uploadImage']);
        if (isset($result['error'])) {
            return $this->responser([], (string) $result['error'], (int) ($result['status'] ?? 422));
        }

        return $this->responser(new UserResource($result['user']), 'User Profile Updated');
    }

    public function changePassword(Request $request)
    {
        $user = Auth::user();
        $result = $this->accountProfileService->changePassword($user, $request);
        if (isset($result['error'])) {
            return $this->responser([], (string) $result['error'], (int) ($result['status'] ?? 422));
        }

        return $this->responser([], 'User Password Updated successfully');
    }

    public function updateDeviceToken(Request $request)
    {
        $user = Auth::guard('api')->user();
        $result = $this->accountProfileService->updateDeviceToken($user, $request);
        if (isset($result['error'])) {
            return $this->responser([], (string) $result['error'], (int) ($result['status'] ?? 422));
        }

        return $this->responser(['updated' => true], 'Device Token Updated.');
    }

    public function notificationsToggle(Request $request)
    {
        $user = Auth::user();
        $this->accountProfileService->toggleNotifications($user);
        
        return $this->responser(['updated' => true], 'User notifications updated successfully.');
    }

    public function mobileContact(Request $request)
    {
        $user = Auth::user();
        $rspn = $this->accountProfileService->mobileContact($user);
        return $this->responser($rspn,'User details.');
    }
}
