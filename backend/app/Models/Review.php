<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    use HasFactory;

    /**
     * Get the product that owns the review.
     */
    public function mikitchn()
    {
        return $this->belongsTo(Mikitchn::class);
    }

    /**
     * Get the user that made the review.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function images()
    {
        return $this->hasMany(\App\Models\Image::class, 'ref_id')->where('model_name', 'review');
    }

}
