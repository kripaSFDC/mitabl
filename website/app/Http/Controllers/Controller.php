<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;
use Carbon\Carbon;
use App\Models\Mikitchn;
/**
 * @OA\Info(
 *    title="Mitabl eComm API",
 *    version="1.0.0",
 * )
 * @OA\SecurityScheme(
 *     type="http",
 *     description="Login with email and password to get the authentication token",
 *     name="Token based Based",
 *     in="header",
 *     scheme="bearer",
 *     bearerFormat="JWT",
 *     securityScheme="Authorization",
 * )
 */
class Controller extends BaseController
{
    use AuthorizesRequests, DispatchesJobs, ValidatesRequests;

    public function responser($data,$msg)
    {

        // $num = $item->count();

        if(!empty($data)){
            return response()->json([ 
                'status' => 200,
                'isSuccess' => true,
                'message' => $msg,
                'data' => $data
            ], 200);
        } else {
            return response()->json([
                'status' => 404,
                'isSuccess' => false,
                'isError' => $msg,
                // 'data' => $data
            ], 404);
        }
    }

    public function uploadImage($mediaFile,$folderPathOrName){
        
        $allowedfileExtension=['jpg','jpeg','png','gif','svg'];
        $extension = $mediaFile->getClientOriginalExtension();
 
        $check = in_array($extension,$allowedfileExtension);
        if ($check) {
            $current = Carbon::now()->format('YmdHs');
            $name = $mediaFile->getClientOriginalName();
            $name = pathinfo($name, PATHINFO_FILENAME);
            $name = $name.'-'.$current.'.'.$extension;
            $path = $mediaFile->storeAs('/Images/'.$folderPathOrName, $name, ['disk' =>   'my_files']);
            
            return ['success'=>true,'path'=>$path];
        } else {
            return ['success'=>false,'msg'=>"Allow Image with (jpg,jpeg,png,gif,svg) These extensions."];
        }
    }
    
    public static function closest($lat, $lng, $max_distance = 50, $max_locations = 50, $units = 'kilometers')
    {
        /*
         *  Allow for changing of units of measurement
         */
        switch ( $units ) {
            default:
            case 'miles':
                $gr_circle_radius = 3959;
                break;
            case 'kilometers':
                $gr_circle_radius = 6371;
                break;
        }
        $distance_select = sprintf(
            "*, ( %d * acos( cos( radians(%s) ) " .
            " * cos( radians( latitude ) ) " .
            " * cos( radians( longitude ) - radians(%s) ) " .
            " + sin( radians(%s) ) * sin( radians( latitude ) ) " .
            ") " .
            ") " .
            "AS distance",
            $gr_circle_radius,
            $lat,
            $lng,
            $lat
        );


        return  selectraw($distance_select)
            ->having( 'distance', '<', $max_distance )
            // ->take( $max_locations )
            ->orderBy( 'distance', 'ASC' );
            // ->get();
    }
}
