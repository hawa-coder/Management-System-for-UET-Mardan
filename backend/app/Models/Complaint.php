<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Complaint extends Model
{
    use HasFactory;

    protected $fillable = [
        'complaint_number', 'user_id', 'title', 'details', 'category',
        'priority', 'status', 'current_handler_role',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function history()
    {
        return $this->hasMany(ComplaintHistory::class)->oldest();
    }
}
