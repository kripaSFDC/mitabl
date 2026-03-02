<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Foods extends Model
{
    use HasFactory;
    protected $fillable = [
        'restaurant_id','food_name', 'cookingstyle', 'specialDiet', 'price', 'description','pictures'
    ];

    protected $casts = [
        'price' => 'decimal:2',
    ];

    public function addedimage()
    {
        return $this->hasMany(Image::class, 'ref_id')->where('model_name', 'food');
    }

    public function getAddedImagesAttribute()
    {
        return $this->addedimage;
    }
}
