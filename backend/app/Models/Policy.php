<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Policy extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'version',
        'schema_version',
        'definition',
        'effective_at',
        'active',
        'created_by',
        'published_by',
        'published_at',
    ];

    protected $casts = [
        'definition' => 'array',
        'effective_at' => 'datetime',
        'published_at' => 'datetime',
        'active' => 'boolean',
    ];

    public function createdBy()
    {
        return $this->belongsTo(AdminUser::class, 'created_by');
    }

    public function publishedBy()
    {
        return $this->belongsTo(AdminUser::class, 'published_by');
    }

    public function changeLogs()
    {
        return $this->hasMany(PolicyChangeLog::class);
    }
}
