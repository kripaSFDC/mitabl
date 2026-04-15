<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\User;
use App\Mail\ResetPassword;
use Illuminate\Support\Facades\Mail;
use DB;

class ResetPasswordController extends Controller
{
    /**
    * @OA\Post(
    * path="/api/password/reset",
    * summary="password reset",
    * description="password reset",
    * operationId="reset",
    * tags={"User"},
    * @OA\RequestBody(
    *         @OA\MediaType(
    *            mediaType="multipart/form-data",
    *            @OA\Schema(
    *               type="object",
    *               required={"email"},
    *               @OA\Property(property="email", type="string")
    *            ),
    *        ),
    *       @OA\MediaType(
    *            mediaType="application/json",
    *            @OA\Schema(
    *               type="object",
    *               required={"email"},
    *               @OA\Property(property="email", type="string")
    *            ),
    *        ),
    *    ),
    *      @OA\Response(
    *          response=201,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=200,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=422,
    *          description="Unprocessable Entity",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(response=400, description="Bad request"),
    *      @OA\Response(response=404, description="Resource Not Found"),
    * )
    */

    protected function sendResetLinkResponse(Request $request)
    {
        $input = $request->only('email');

        $validator = Validator::make($input, [
            'email' => "required|email"
        ]);

        if ($validator->fails()) {
            return response(['errors'=>$validator->errors()->all()], 422);
        }

        $email = (string) ($input['email'] ?? '');
        $user = User::where('email', $email)->first();
        if (!$user) {
            return $this->responser([],"user not exist", 404);
        }
        
        $token = Str::random(60);
        $hashedToken = Hash::make($token);
        
        try {
            $rstTbl = DB::table(config('auth.passwords.users.table'))->where('email',$user->email)->first();
            if ($rstTbl) {
                DB::table(config('auth.passwords.users.table'))->where('email',$user->email)->update([ 
                    'token' => $hashedToken,
                    'created_at' => now(),
                ]);
            }else{
                DB::table(config('auth.passwords.users.table'))->insert([
                    'email' => $user->email, 
                    'token' => $hashedToken,
                    'created_at' => now(),
                ]);
            }

            Mail::to($user->email)->send(new ResetPassword(trim($user->first_name . ' ' . $user->last_name), $token));
            return $this->responser(['sendmail'=>1],'Mail send successfully');
        } catch (\Throwable $e) {
            return $this->responser([],'Email could not be sent to this email address', 422);
        }
    }
}
