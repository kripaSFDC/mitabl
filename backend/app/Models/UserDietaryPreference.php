<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserDietaryPreference extends Model
{
    protected $fillable = ['user_id', 'special_diet_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function specialDiet()
    {
        return $this->belongsTo(SpecialDiet::class);
    }
}
