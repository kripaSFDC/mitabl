<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use DB;

class Timing extends Model
{
    use HasFactory;

    protected $appends = ['avail_minutes'];

    public function user()
    {
        return $this->belongsTo('App\Models\Mikitchn');
    }

    public function getAvailMinutesAttribute($value='')
    {
        $diff = Timing::select(
                DB::raw('SUM(TIMESTAMPDIFF(minute, start_time, end_time)) AS diff'))
                ->where('id',$this->id)
                ->get()->first();
        return abs($diff->diff);
        // return 195;
    }

}
