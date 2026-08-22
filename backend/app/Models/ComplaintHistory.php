<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ComplaintHistory extends Model
{
    protected $fillable = [
        'complaint_id', 'acted_by', 'action', 'from_status', 'to_status', 'remarks',
    ];

    public function actor()
    {
        return $this->belongsTo(User::class, 'acted_by');
    }
}
