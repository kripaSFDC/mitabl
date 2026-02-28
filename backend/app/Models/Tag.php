<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tag extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
    ];

    public function users()
    {
        return $this->morphedByMany(User::class, 'taggable');
    }

    public function mikitchns()
    {
        return $this->morphedByMany(Mikitchn::class, 'taggable');
    }

    public function orders()
    {
        return $this->morphedByMany(Order::class, 'taggable');
    }

    public function supportTickets()
    {
        return $this->morphedByMany(SupportTicket::class, 'taggable');
    }
}
