<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ComplaintComment extends Model
{
    protected $fillable = ['complaint_id', 'user_id', 'comment'];

    public function author()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
