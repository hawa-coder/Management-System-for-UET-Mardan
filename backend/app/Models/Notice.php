<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notice extends Model
{
    protected $fillable = ['complaint_id', 'published_by', 'title', 'body', 'audience', 'published_at'];

    protected $casts = ['published_at' => 'datetime'];

    public function publisher()
    {
        return $this->belongsTo(User::class, 'published_by');
    }
}
