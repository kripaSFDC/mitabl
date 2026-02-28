<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Template extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'channel',
        'subject',
        'body',
        'version',
        'active',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'body' => 'array',
        'active' => 'boolean',
    ];

    public function createdBy()
    {
        return $this->belongsTo(AdminUser::class, 'created_by');
    }

    public function updatedBy()
    {
        return $this->belongsTo(AdminUser::class, 'updated_by');
    }
}
