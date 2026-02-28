<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InternalNote extends Model
{
    use HasFactory;

    protected $fillable = [
        'noteable_type',
        'noteable_id',
        'author_id',
        'note',
    ];

    public function noteable()
    {
        return $this->morphTo();
    }

    public function author()
    {
        return $this->belongsTo(AdminUser::class, 'author_id');
    }
}
