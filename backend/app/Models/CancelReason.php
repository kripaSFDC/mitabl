<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class CancelReason extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'ref_id',
        'subject',
        'comment',
        'by_user',
    ];

    public function actor()
    {
        return $this->belongsTo(User::class, 'ref_id');
    }
}
