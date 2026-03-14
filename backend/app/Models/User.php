<?php

namespace App\Models;

use App\Models\WatchSubscription;
use App\Models\Tag;
use App\Models\InternalNote;
use App\Models\UserRoleOnboardingChecklist;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;
use App\Notifications\MailResetPasswordNotification as ResetPassword;
use Overtrue\LaravelFavorite\Traits\Favoriter;
use Illuminate\Support\Facades\DB;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable, Favoriter, SoftDeletes;

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
        'email_verified',
        'phone',
        'address',
        'suspended',
        'suspension_reason',
        'suspended_at',
        'suspended_by',
        'avatar',
        'description',
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
        'email_verified' => 'boolean',
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

    public function notifyDisable()
    {
        return $this->hasOne(NotifyDisable::class);
    }

     /**
     * Get the reviews the user has made.
     */
    public function reviews()
    {
        return $this->hasMany(Review::class)->where('by_user', 'kitchen');
    }

    public function orders(){
        return $this->hasMany(Order::class);
    }

    public function customer(){
        return $this->hasOne(StripeAccount::class)->where('account_type', 'customer');
    }

    public function vendor()
    {
        return $this->hasOne(StripeAccount::class)->where('account_type', 'vendor');
    }

    public function card(){
        return $this->hasMany(Card::class);
    }

    public function stripeBankAccount(){
        return $this->hasMany(StripeBankAccount::class);
    }

    public function role(){
        return $this->belongsTo(Role::class);
    }

    public function roleMemberships()
    {
        return $this->hasMany(UserRole::class);
    }

    public function roleOnboardingChecklists()
    {
        return $this->hasMany(UserRoleOnboardingChecklist::class);
    }

    public function roles()
    {
        return $this->belongsToMany(Role::class, 'user_roles')
            ->withPivot('status')
            ->withTimestamps();
    }

    public function getActiveRoleIdAttribute(): int
    {
        return (int) $this->role_id;
    }

    public function roleMembershipFor(int $roleId): ?UserRole
    {
        return $this->roleMemberships->firstWhere('role_id', $roleId)
            ?? $this->roleMemberships()->where('role_id', $roleId)->first();
    }

    public function hasRoleMembership(int $roleId, bool $includeOnboarding = true): bool
    {
        $allowedStatuses = [UserRole::STATUS_ACTIVE];
        if ($includeOnboarding) {
            $allowedStatuses[] = UserRole::STATUS_ONBOARDING;
        }

        return $this->roleMemberships()
            ->where('role_id', $roleId)
            ->whereIn('status', $allowedStatuses)
            ->exists();
    }

    public function restaurant(){
        return $this->hasOne(Mikitchn::class);
    }

    public function Token(){
        return $this->hasOne(UserAuthToken::class);
    }

    public function suspendedBy()
    {
        return $this->belongsTo(AdminUser::class, 'suspended_by');
    }

    public function supportTickets()
    {
        return $this->hasMany(SupportTicket::class);
    }
    public function is_superAdmin(): bool
    {
        return (int) $this->role_id === 1;
    }

    public function is_restaurant(): bool
    {
        return (int) $this->role_id === 2;
    }

    public function is_customer(): bool
    {
        return (int) $this->role_id === 3;
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
