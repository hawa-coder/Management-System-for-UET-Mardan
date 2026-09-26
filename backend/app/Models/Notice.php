<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class Notice extends Model
{
    protected $fillable = [
        'complaint_id', 'published_by', 'title', 'body', 'audience', 'published_at',
        'department', 'batch', 'semester', 'section', 'target_adviser_id',
        'category', 'priority', 'notice_date', 'expires_at', 'notified_at',
        'departments', 'batches', 'semesters', 'sections', 'course_ids', 'student_ids',
        'scope_department', 'target_faculty_id', 'attachment_path', 'attachment_name', 'attachment_mime',
    ];

    protected $hidden = ['attachment_path'];
    protected $appends = ['status'];
    protected $casts = [
        'published_at' => 'datetime', 'notice_date' => 'datetime', 'expires_at' => 'datetime',
        'notified_at' => 'datetime', 'semester' => 'integer',
        'departments' => 'array', 'batches' => 'array', 'semesters' => 'array',
        'sections' => 'array', 'course_ids' => 'array', 'student_ids' => 'array',
    ];

    public const TARGETS = ['departments' => 'department', 'batches' => 'batch', 'semesters' => 'semester', 'sections' => 'section'];

    public function getStatusAttribute(): string
    {
        if ($this->expires_at && $this->expires_at->isPast()) return 'Expired';
        if ($this->notice_date && $this->notice_date->isFuture()) return 'Scheduled';
        return 'Active';
    }

    public function scopeActive($query)
    {
        return $query->whereNotNull('published_at')
            ->where(fn ($q) => $q->whereNull('notice_date')->orWhere('notice_date', '<=', now()))
            ->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>', now()));
    }

    public function scopeForRecipient($query, User $user)
    {
        $query->where(fn ($q) => $q->where('audience', 'all')->orWhere('audience', $user->role));
        foreach (['department', 'batch', 'semester', 'section', 'scope_department'] as $field) {
            $value = $field === 'scope_department' ? $user->department : $user->$field;
            $query->where(fn ($q) => $q->whereNull($field)->orWhere($field, $value));
        }
        foreach (self::TARGETS as $field => $profile) {
            $value = $profile === 'semester' ? (int) $user->$profile : $user->$profile;
            $query->where(function ($q) use ($field, $value) {
                $q->whereNull($field)->orWhereJsonLength($field, 0);
                if ($value !== null) $q->orWhereJsonContains($field, $value);
            });
        }
        $query->where(fn ($q) => $q->whereNull('student_ids')->orWhereJsonLength('student_ids', 0)->orWhereJsonContains('student_ids', $user->id));
        $courseIds = $user->role === 'student' ? $user->courses()->pluck('courses.id')->all() : [];
        $query->where(function ($q) use ($courseIds) {
            $q->whereNull('course_ids')->orWhereJsonLength('course_ids', 0);
            foreach ($courseIds as $id) $q->orWhereJsonContains('course_ids', $id);
        });
        $query->where(function ($q) use ($user) {
            $q->whereNull('target_adviser_id');
            if ($user->role === 'student' && $user->batch_adviser_id !== null) $q->orWhere('target_adviser_id', $user->batch_adviser_id);
        });
        return $query->where(function ($q) use ($user) {
            $q->whereNull('target_faculty_id');
            if ($user->role === 'student') $q->orWhereIn('target_faculty_id', $user->courses()->select('faculty_id'));
        });
    }

    public function recipients()
    {
        $query = User::where('is_active', true)->where('account_status', 'approved');
        if ($this->audience !== 'all') $query->where('role', $this->audience);
        foreach (['department', 'batch', 'semester', 'section'] as $field) {
            if ($this->$field !== null) $query->where($field, $this->$field);
        }
        if ($this->scope_department) $query->where('department', $this->scope_department);
        foreach (self::TARGETS as $field => $profile) {
            if ($this->$field) $query->whereIn($profile, $this->$field);
        }
        if ($this->student_ids) $query->whereIn('id', $this->student_ids);
        if ($this->course_ids) $query->whereHas('courses', fn ($q) => $q->whereIn('courses.id', $this->course_ids));
        if ($this->target_adviser_id) $query->where('role', 'student')->where('batch_adviser_id', $this->target_adviser_id);
        if ($this->target_faculty_id) $query->where('role', 'student')->whereHas('courses', fn ($q) => $q->where('faculty_id', $this->target_faculty_id));
        return $query;
    }

    public function markRead(User $user): void
    {
        DB::table('notice_reads')->updateOrInsert(['notice_id' => $this->id, 'user_id' => $user->id], ['read_at' => now()]);
        AppNotification::where('notice_id', $this->id)->where('user_id', $user->id)->whereNull('read_at')->update(['read_at' => now()]);
    }

    public function publisher()
    {
        return $this->belongsTo(User::class, 'published_by');
    }
}
