<?php

namespace App\Services;

use App\Models\User;

class NoticeAudience
{
    public static function studentsFor(User $user)
    {
        $query = User::where('role', 'student')->where('is_active', true)->where('account_status', 'approved');
        if ($user->role === 'adviser') $query->where('batch_adviser_id', $user->id);
        if (in_array($user->role, ['chairman', 'faculty', 'coordinator'], true)) $query->where('department', $user->department);
        if ($user->role === 'faculty' && ! $user->can_publish_department_notices) {
            $query->whereHas('courses', fn ($q) => $q->where('faculty_id', $user->id));
        }
        return $query;
    }
}
