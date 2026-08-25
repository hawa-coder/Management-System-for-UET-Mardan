<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\URL;

class Complaint extends Model
{
    use HasFactory;

    protected $fillable = [
        'complaint_number', 'user_id', 'title', 'details', 'category',
        'priority', 'status', 'current_handler_role', 'attachment_path',
        'attachment_name', 'attachment_mime',
    ];

    protected $hidden = ['attachment_path'];

    protected $appends = ['attachment_url'];

    public function getAttachmentUrlAttribute(): ?string
    {
        if (! $this->attachment_path) {
            return null;
        }

        return URL::temporarySignedRoute(
            'complaints.attachment',
            now()->addMinutes(10),
            ['complaint' => $this->id],
            absolute: false,
        );
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function history()
    {
        return $this->hasMany(ComplaintHistory::class)->oldest();
    }
}
