<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    protected $fillable = ['user_id', 'type', 'title', 'message', 'read_at'];

    protected $casts = ['read_at' => 'datetime'];
}
