<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;
use Carbon\Carbon;
use App\Models\Image;
use File,DateTime;
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

    public static function responser($data, $msg, int $status = 200)
    {
        $isSuccess = $status >= 200 && $status < 300;

        $response = [
            'status' => $status,
            'isSuccess' => $isSuccess,
            'data' => $data ?? [],
        ];

        if ($isSuccess) {
            $response['message'] = $msg;
        } else {
            $response['isError'] = $msg;
        }

        return response()->json($response, $status);
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

    public function uploadImageOrDoc($mediaFile,$folderPathOrName){
        
        $allowedfileExtension=['jpg','jpeg','png','pdf','webp'];
        $extension = strtolower((string) $mediaFile->getClientOriginalExtension());
 
        $check = in_array($extension,$allowedfileExtension);
        if ($check) {
            $current = Carbon::now()->format('YmdHs');
            $name = $mediaFile->getClientOriginalName();
            $name = pathinfo($name, PATHINFO_FILENAME);
            $name = $name.'-'.$current.'.'.$extension;
            $path = $mediaFile->storeAs('/Images/'.$folderPathOrName, $name, ['disk' =>   'my_files']);
            
            return ['success'=>true,'path'=>$path];
        } else {
            return ['success'=>false,'msg'=>"Allow Image with (jpg,jpeg,png,pdf,webp) These extensions."];
        }
    }

    public function addImages($mediaFiles,$folderPathOrName,$model,$refId){
        // $add = 0;
        foreach ($mediaFiles as $key => $mediaFile) {

            $return = $this->uploadImage($mediaFile,$folderPathOrName);

            if ($return['success']) {
                $image = new Image();
                $image->ref_id = $refId;
                $image->model_name = $model;
                $image->path = $return['path'];
                $image->save();
            }

        }

        return true;
        
    }

    public function deleteImageById($id,$type)
    {
        $image = Image::where('id',$id)->where('model_name',$type)->get()->first();
        if (!$image) {
            return ['status'=>false,'id'=>$id,'msg'=>'Image Not found.'];
        }
        if(File::exists($image->path)) {
            File::delete($image->path);
        }
        $image->delete();
        return ['status'=>true,'id'=>$id,'msg'=>'Image Deleted.'];
    }
    
    public function getPendingHoursInOrderD($order)
    {
        $todayCurrnt = Carbon::now()->format('Y-m-d H:i:s');
        $merge = new DateTime($order->delivery_date->format('Y-m-d') .' ' .$order->delivery_time_from->format('H:i:s'));
        $orderTime = $merge->format('Y-m-d H:i:s');

        // echo $todayCurrnt;
        // echo '------';
        // echo $orderTime; die();

        $to = Carbon::createFromFormat('Y-m-d H:i:s', $todayCurrnt);
        $from = Carbon::createFromFormat('Y-m-d H:i:s', $orderTime);

        return $to->diffInHours($from);

    }
}
