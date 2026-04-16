<?php

namespace App\Models;

use App\Models\WatchSubscription;
use App\Models\Tag;
use App\Models\DineInSlot;
use App\Models\InternalNote;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Notifications\Notifiable;

class Order extends Model
{
    use HasFactory, Notifiable;

    public const STATUS_LEGACY_CANCELLED = 0;
    public const STATUS_COMPLETED = 1;
    public const STATUS_REQUESTED = 2;
    public const STATUS_CONFIRMED = 3;
    public const STATUS_CANCELLED = 4;
    public const STATUS_IN_PROGRESS = 5;
    public const STATUS_READY = 6;

    protected $fillable = [
        'mikitchn_id',
        'user_id',
        'dine_in',
        'take_away',
        'persons',
        'dine_in_slot_id',
        'delivery_date',
        'delivery_time_from',
        'delivery_time_to',
        'message',
        'item_total_price',
        'promo_code',
        'taxes',
        'total_price',
        'discounted_amount',
        'paymentmethod_id',
        'ready_at',
        'no_show',
        'no_show_at',
    ];

    protected $casts = [
        'item_total_price' => 'decimal:2',
        'taxes' => 'decimal:2',
        'total_price' => 'decimal:2',
        'discounted_amount' => 'decimal:2',
        'refund_percentage' => 'integer',
        'dine_in_slot_id' => 'integer',
        'no_show' => 'boolean',
        'ready_at' => 'datetime',
        'no_show_at' => 'datetime',
    ];

    /**
     * The attributes that should be mutated to dates.
     *
     * @var array
     */
    protected $dates = ['delivery_time_from','delivery_time_to','delivery_date'];

    /**
     * Get the reviews of the product.
     */
    public function orderdata()
    {
        return $this->hasMany(OrderData::class);
    }

    public function Mikitchn()
    {
        return $this->belongsTo(Mikitchn::class);
    }

    public function getItemsAttribute()
    {
        return $this->orderdata;
    }

    public function getOrderIdAttribute()
    {
        $orderPrefix = 'T';
        if ($this->dine_in) {
            $orderPrefix = 'D';
        }
        return $orderPrefix.'-'.$this->id;
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function dineInSlot()
    {
        return $this->belongsTo(DineInSlot::class, 'dine_in_slot_id');
    }

    public function promocode()
    {
        return $this->belongsTo(PromoCode::class, 'promo_code');
    }


    public function review()
    {
        return $this->hasOne(Review::class);
    }

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }

    public function cancelreason()
    {
        return $this->hasOne(CancelReason::class);
    }

    public function completedorder()
    {
        return $this->hasOne(CompletedOrder::class);
    }

    public function refunds()
    {
        return $this->hasMany(Refund::class);
    }

    public static function cancelledStatuses(): array
    {
        return [self::STATUS_LEGACY_CANCELLED, self::STATUS_CANCELLED];
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
