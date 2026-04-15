<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;
use DB;
use App\Models\User;

class ForgotPasswordController extends Controller
{
    public function resetPassword($token) {
        return view('forgetPasswordLink', ['token' => $token]);
    }

    protected function sendResetResponse(Request $request){
        $input = $request->only('email','token', 'password', 'password_confirmation');

        $validator = Validator::make($input, [
        'token' => 'required',
        'email' => 'required|email',
        'password' => 'required|confirmed|min:8',
        ]);

        if ($validator->fails()) {
            return redirect()->back()->with('error', $validator->errors()->first());
        }
        $rstTbl = DB::table(config('auth.passwords.users.table'))
            ->where('email', $request->email)
            ->first();
        
        if ($rstTbl && Hash::check((string) $request->token, (string) $rstTbl->token)) {
            $expiresAt = now()->subMinutes((int) config('auth.passwords.users.expire', 60));
            $createdAt = isset($rstTbl->created_at) ? \Carbon\Carbon::parse((string) $rstTbl->created_at) : null;
            if ($createdAt && $createdAt->lt($expiresAt)) {
                return redirect()->back()->with('message', 'Token expired');
            }

            $user = User::where('email',$request->email)->first();
            if ($user) {
                $user->forceFill([
                'password' => Hash::make($request->password)
                ])->save();
                DB::table(config('auth.passwords.users.table'))
                    ->where('email', $request->email)
                    ->delete();
                $message = "Password reset successfully";
            } else {
                $message = "User not exist";
            }

        }else{
            $message = "Token not authenticated for this request";
        }
        return redirect()->back()->with('message', $message);
        
    }
}
