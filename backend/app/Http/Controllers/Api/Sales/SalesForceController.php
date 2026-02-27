<?php
namespace App\Http\Controllers\Api\Sales;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use Validator;
use GuzzleHttp\Client;
use Illuminate\Support\Facades\Hash;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Support\Facades\Mail;
use Carbon\Carbon;
use App\Models\CookingStyles;
use App\Models\Certificate;
use App\Models\Mikitchn;
use App\Models\User;
use JWTAuth;

class SalesForceController extends Controller
{

    public function changecertificateStatus(Request $request,$kitchen_id)
    {

        // print_r((int)$request->status);
        // die('jknkbjf');
        $certificate = Mikitchn::find($kitchen_id)->certificate;
        $certificate->status = (int) $request->status;
        $certificate->save();

        // $updatedCertificate = Certificate::find($certificate->id);

        return $this->responser($certificate,'Certificate Updated');
    }

    public function mifoodiDetails(Request $request)
    {
        $column = '';
        $value = '';

        if ($request->has('id')) {
            $column = 'id';
            $value = (int) $request->id;
        } elseif ($request->has('email')) {
            $column = 'email';
            $value = $request->email;
        } elseif ($request->has('phone')) {
            $column = 'phone';
            $value = $request->phone;
        }

        $mifoodi = User::where($column,$value)->where('role_id',3)->first();

        if ($mifoodi) {
            return $this->responser($mifoodi,'mifoodi details');
        }

        return $this->responser([],'mifoodi Not found');
        
    }

}
