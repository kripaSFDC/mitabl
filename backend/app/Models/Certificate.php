<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Certificate extends Model
{
    use HasFactory;

    protected $fillable = [
        'mikitchn_id',
        'abn',
        'first_name',
        'last_name',
        'certificate_no',
        'certificate_doc',
        'abn_gst',
        'status',
        'rejection_reason',
        'reviewed_at',
        'reviewed_by',
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
    ];

    public function reviewer()
    {
        return $this->belongsTo(AdminUser::class, 'reviewed_by');
    }

    public function mikitchn()
    {
        return $this->belongsTo(Mikitchn::class);
    }
}
