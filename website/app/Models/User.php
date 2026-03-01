<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
// use Laravel\Sanctum\HasApiTokens;
use Tymon\JWTAuth\Contracts\JWTSubject;
use App\Notifications\MailResetPasswordNotification as ResetPassword;
use Overtrue\LaravelFavorite\Traits\Favoriter;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable, Favoriter;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    // protected $fillable = [
    //     'first_name',
    //     'email',
    //     'password',
    // ];

    // /**
    //  * The attributes that should be hidden for serialization.
    //  *
    //  * @var array<int, string>
    //  */
    // protected $hidden = [
    //     'password',
    //     'remember_token',
    // ];

    // /**
    //  * The attributes that should be cast.
    //  *
    //  * @var array<string, string>
    //  */
    // // protected $casts = [
    // //     'email_verified' => 'datetime',
    // // ];
    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'role_id','first_name', 'last_name', 'email', 'password', 'phone','address',
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $hidden = [
        'password', 'remember_token',
    ];

    public function getJWTIdentifier()
    {
        return $this->getKey();
    }
    public function getJWTCustomClaims()
    {
        return [];
    }

    /**
    * Get the products the user has added.
    */
     // public function products()
     // {
     //     return $this->hasMany('App\Product');
     // }

     /**
     * Get the reviews the user has made.
     */
     public function reviews()
     {
    return $this->hasMany('App\Models\Review');
     }

    public function orders(){
        return $this->hasMany('App\Models\Order');
    }

    // public function cart(){
    //     return $this->hasMany('App\Cart');
    // }

    public function role(){
        return $this->belongsTo('App\Models\Role');
    }

    // public function favourite(){
    //     return $this->hasMany('App\Favourites');
    // }

    // public function address(){
    //     return $this->hasMany('App\Address');
    // }

    public function restaurant(){
        return $this->hasOne('App\Models\Mikitchn');
    }

    public function is_superAdmin($id){
        $user = User::where('id' , $id)->first();
        if($user->role_id == 1 ){
            return true;
        } else {
            return false;
        }
    }

    public function is_restaurant($id){
        $user = User::where('id' , $id)->first();
        if($user->role_id == 2 ){
            return true;
        } else {
            return false;
        }
    }

    public function sendPasswordResetNotification($token)
    {
        $this->notify(new ResetPassword($token));
    }
}
