<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Timing extends Model
{
    use HasFactory;

    public function user()
    {
        return $this->belongsTo('App\Models\Mikitchn');
    }

    public function getAvailMinutesAttribute($value='')
    {
        if (! $this->start_time || ! $this->end_time) {
            return 0;
        }

        $start = strtotime((string) $this->start_time);
        $end = strtotime((string) $this->end_time);

        if ($start === false || $end === false) {
            return 0;
        }

        return (int) abs(($end - $start) / 60);
    }

}
