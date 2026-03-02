<?php

namespace App\Models;

use App\Models\WatchSubscription;
use App\Models\Tag;
use App\Models\InternalNote;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Notifications\Notifiable;
// use Laravel\Sanctum\HasApiTokens;
use Tymon\JWTAuth\Contracts\JWTSubject;
use App\Notifications\MailResetPasswordNotification as ResetPassword;
use Overtrue\LaravelFavorite\Traits\Favoriter;
use Auth;
use Illuminate\Support\Facades\DB;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable, Favoriter, SoftDeletes;

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
        'role_id',
        'first_name',
        'last_name',
        'email',
        'password',
        'phone',
        'address',
        'suspended',
        'suspension_reason',
        'suspended_at',
        'suspended_by',
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $hidden = [
        'password', 'remember_token',
    ];

    protected $casts = [
        'suspended' => 'boolean',
        'suspended_at' => 'datetime',
        'deleted_at' => 'datetime',
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
    public function notifyDisable()
    {
        return $this->hasOne('App\Models\NotifyDisable');
    }

     /**
     * Get the reviews the user has made.
     */
    public function reviews()
    {
        return $this->hasMany('App\Models\Review')->where('by_user','kitchen');
    }

    public function orders(){
        return $this->hasMany('App\Models\Order');
    }

    public function customer(){
        return $this->hasOne('App\Models\StripeAccount')->where('account_type','customer');
    }

    public function vendor()
    {
        return $this->hasOne('App\Models\StripeAccount')->where('account_type','vendor');
    }

    public function card(){
        return $this->hasMany('App\Models\Card');
    }

    public function stripeBankAccount(){
        return $this->hasMany('App\Models\StripeBankAccount');
    }

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

    public function Token(){
        return $this->hasOne('App\Models\UserAuthToken');
    }

    public function suspendedBy()
    {
        return $this->belongsTo(AdminUser::class, 'suspended_by');
    }

    public function supportTickets()
    {
        return $this->hasMany(SupportTicket::class);
    }

    

    public function is_superAdmin($id){
        $user = User::query()->find($id);
        return (bool) ($user && (int) $user->role_id === 1);
    }

    public function is_restaurant($id){
        $user = User::query()->find($id);
        return (bool) ($user && (int) $user->role_id === 2);
    }

    public function is_customer(){
        $user = Auth::guard('api')->user();
        return (bool) ($user && (int) $user->role_id === 3);
    }

    public function sendPasswordResetNotification($token)
    {
        $this->notify(new ResetPassword($token));
    }

    protected static function booted(): void
    {
        static::deleting(function (User $user): void {
            if (! $user->isForceDeleting()) {
                return;
            }

            DB::transaction(function () use ($user): void {
                $user->vendor()->delete();
                $user->customer()->delete();
                DB::table('reviews')->where('user_id', $user->id)->delete();
                $user->restaurant()->delete();
                $user->card()->delete();
                $user->stripeBankAccount()->delete();
                $user->orders()->delete();
            });
        });
    }

    public function internalNotes()
    {
        return $this->morphMany(InternalNote::class, 'noteable')->latest();
    }

    public function tags()
    {
        return $this->morphToMany(Tag::class, 'taggable');
    }

    public function watchers()
    {
        return $this->morphMany(WatchSubscription::class, 'watchable');
    }


}
