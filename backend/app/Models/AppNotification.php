<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    protected $fillable = ['user_id', 'notice_id', 'type', 'title', 'message', 'read_at'];

    public function notice()
    {
        return $this->belongsTo(Notice::class);
    }

    public function scopeVisibleTo($query, User $user)
    {
        return $query->where('user_id', $user->id)->where(fn ($q) => $q
            ->whereNull('notice_id')
            ->orWhereHas('notice', fn ($n) => $n->active()->forRecipient($user)));
    }

    protected $casts = ['read_at' => 'datetime'];
}
