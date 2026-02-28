<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PolicyChangeLog extends Model
{
    use HasFactory;

    protected $table = 'policy_change_log';

    protected $fillable = [
        'policy_id',
        'action',
        'changed_by',
        'from_version',
        'to_version',
        'change_summary',
        'before_payload',
        'after_payload',
        'correlation_id',
    ];

    protected $casts = [
        'before_payload' => 'array',
        'after_payload' => 'array',
    ];

    public function policy()
    {
        return $this->belongsTo(Policy::class);
    }

    public function changedBy()
    {
        return $this->belongsTo(AdminUser::class, 'changed_by');
    }
}
