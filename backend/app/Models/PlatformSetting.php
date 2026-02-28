<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PlatformSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'value',
        'value_type',
        'description',
        'version',
        'updated_by',
    ];

    protected $casts = [
        'value' => 'array',
    ];

    public function updatedBy()
    {
        return $this->belongsTo(AdminUser::class, 'updated_by');
    }
}
