<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Http\Resources\User\User as UserResource;
use App\Models\NotifyDisable;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Http\Request;

class AccountController extends Controller
{
    public function show(Request $request)
    {
        return $this->responser(new UserResource(Auth::user()), 'User');
    }

    public function update(Request $request)
    {
        $user = Auth::guard('api')->user();

        $validator = Validator::make($request->all(), [
            'first_name' => 'required',
            'last_name' => 'required',
            'phone' => 'required',
            'email' => 'required|email|unique:users,email,'.$user->id,
        ]);

        if($validator->fails()){
            return $this->responser([],$validator->errors()->first(), 422);
        }

        $user->first_name = $request->first_name;
        $user->last_name = $request->last_name;
        $user->email = $request->email;
        $user->phone = $request->phone;
        $user->description = $request->description;
        if ($request->hasFile('avatar')) {
            $avatar = $this->uploadImage($request->avatar,'user');
            if ($avatar['success']) {
                $user->avatar = $avatar['path'];
            } else {
                return $this->responser([], $avatar['msg'], 422);
            }
        }
        $user->save();

        return $this->responser(new UserResource($user), 'User Profile Updated');
    }

    public function changePassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'current_password' => 'required',
            'new_password' => 'required|different:current_password|min:8',
        ]);
        if($validator->fails()){
            return $this->responser([],$validator->errors()->first(), 422);
        }

        $user = Auth::user();
        if (! Hash::check((string) $request->current_password, (string) $user->password)) {
            return $this->responser([],'Current password doesn\'t match', 422);
        }

        $user->password = bcrypt((string) $request->new_password);
        $user->save();
        return $this->responser([], 'User Password Updated successfully');
    }

    public function updateDeviceToken(Request $request)
    {
        $user = Auth::guard('api')->user();
        if ($request->has('device_token')) {
            $user->device_token = $request->device_token;
            $user->save();
        }

        return $this->responser($user,'Device Token Updated.');
    }

    public function notificationsToggle(Request $request)
    {
        $user = Auth::user();

        $existing = NotifyDisable::where('user_id',$user->id)->first();
        if ($existing) {
            $existing->delete();
        } else {
            $notifyDisable = new NotifyDisable();
            $notifyDisable->user_id = $user->id;
            $notifyDisable->save();
        }
        
        return $this->responser($user,'User notifications updated successfully.');
    }

    public function mobileContact(Request $request)
    {
        $user = Auth::user();
        $rspn = ['role' => $user->role_id,'id' => $user->id,'email' => $user->email,'phone' => $user->phone ];
        return $this->responser($rspn,'User details.');
    }
}
