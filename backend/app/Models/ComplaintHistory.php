<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ComplaintHistory extends Model
{
    protected $fillable = [
        'complaint_id', 'acted_by', 'action', 'from_status', 'to_status', 'remarks',
        'event_type', 'actor_name', 'actor_role', 'recipient_id', 'recipient_name', 'recipient_role',
    ];

    protected static function booted(): void
    {
        static::updating(fn () => throw new \LogicException('Routing history cannot be overwritten.'));
        static::deleting(fn () => throw new \LogicException('Routing history cannot be deleted.'));
    }

    public function actor()
    {
        return $this->belongsTo(User::class, 'acted_by');
    }
}
