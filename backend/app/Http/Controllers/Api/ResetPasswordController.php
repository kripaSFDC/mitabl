<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;
use Illuminate\Auth\Events\PasswordReset;
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

        $user = User::where('email',$input)->get()->first();
        if (!$user) {
            return $this->responser([],"user not exist");
        }
        
        $token = Str::random(60);
        
        // $response =  Password::sendResetLink($input);

        try {
            $rstTbl = DB::table(config('auth.passwords.users.table'))->where('email',$user->email)->get()->first();
            // print_r($rstTbl); die();
            if ($rstTbl) {
                DB::table(config('auth.passwords.users.table'))->where('email',$user->email)->update([ 
                    'token' => $token
                ]);
            }else{
                DB::table(config('auth.passwords.users.table'))->insert([
                    'email' => $user->email, 
                    'token' => $token
                ]);
            }

            Mail::to($input)->send(new ResetPassword($user->name, $token));
            // $message = "Mail send successfully";
            // $response = ['isSuccess'=>true,'message' => $message,'data'=>json_encode([])];
            return $this->responser(['sendmail'=>1],'Mail send successfully');
        } catch (Exception $e) {
            // $message = "Email could not be sent to this email address";
            // $response = ['isSuccess'=>false,'isError' => $message,'data'=>json_encode([])];
            return $this->responser([],'Email could not be sent to this email address');
        }

        // if($response == Password::RESET_LINK_SENT){
        //     
        // }else{
        //     
        // }
        //$message = $response == Password::RESET_LINK_SENT ? 'Mail send successfully' : GLOBAL_SOMETHING_WANTS_TO_WRONG;
        
    }
}
