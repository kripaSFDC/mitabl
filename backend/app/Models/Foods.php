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

    protected $appends = ['added_images'];

    public function addedimage()
    {
        return $this->hasMany('App\Models\Image','ref_id')->where('model_name','food');
    }

    public function getAddedImagesAttribute()
    {
        return $this->addedimage;
    }
}
