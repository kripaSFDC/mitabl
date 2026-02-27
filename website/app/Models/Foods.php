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
}
