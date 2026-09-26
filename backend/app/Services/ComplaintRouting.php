<?php

namespace App\Services;

use App\Models\Complaint;
use App\Models\ComplaintHistory;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;

class ComplaintRouting
{
    public const STAFF = ['adviser', 'coordinator', 'chairman', 'office', 'dean', 'faculty'];

    public static function visibleTo(User $user): Builder
    {
        $query = Complaint::query();
        if ($user->role === 'student') {
            return $query->where('user_id', $user->id);
        }
        if (! in_array($user->role, self::STAFF, true)) {
            return $query->whereRaw('1 = 0');
        }
        return $query->where(function ($q) use ($user) {
            $q->where('current_handler_id', $user->id)
                ->orWhereHas('history', fn ($h) => $h->where('acted_by', $user->id)->orWhere('recipient_id', $user->id))
                ->orWhere(function ($legacy) use ($user) {
                    $legacy->whereNull('current_handler_id')->whereNull('current_handler_name')
                        ->where('current_handler_role', $user->role)
                        ->whereHas('student', function ($student) use ($user) {
                            if ($user->role === 'adviser') {
                                $student->where('batch_adviser_id', $user->id);
                            } else {
                                $student->where('department', $user->department);
                            }
                        });
                });
            if (in_array($user->role, ['chairman', 'office'], true) && $user->department) {
                $q->orWhereHas('student', fn ($s) => $s->where('department', $user->department));
            }
            if ($user->role === 'dean') {
                $q->orWhereRaw('1 = 1');
            }
        });
    }

    public static function isHolder(Complaint $complaint, User $user): bool
    {
        if (! in_array($user->role, self::STAFF, true)) return false;
        if ($complaint->current_handler_id !== null) return $complaint->current_handler_id === $user->id;
        if ($complaint->current_handler_name || $complaint->current_handler_role !== $user->role) return false;
        $complaint->loadMissing('student');
        return $user->role === 'adviser'
            ? $complaint->student?->batch_adviser_id === $user->id
            : ($user->department && $complaint->student?->department === $user->department);
    }

    public static function canAct(Complaint $complaint, User $user): bool
    {
        return self::isHolder($complaint, $user) && ! in_array($complaint->status, ['resolved', 'rejected'], true);
    }

    public static function canForward(Complaint $complaint, User $user): bool
    {
        return self::canAct($complaint, $user) && ($user->role !== 'faculty' || $user->can_forward_complaints);
    }

    public static function canSendResolution(Complaint $complaint, User $user): bool
    {
        return self::isHolder($complaint, $user) && $user->role === 'chairman'
            && $complaint->status === 'resolved' && $complaint->current_handler_role === 'closed';
    }

    public static function recipients(Complaint $complaint, User $sender): Builder
    {
        $complaint->loadMissing('student');
        return User::whereIn('role', self::STAFF)->where('is_active', true)->where('account_status', 'approved')
            ->where('id', '!=', $sender->id)
            ->where(function ($q) use ($complaint) {
                $q->where('role', 'dean');
                if ($complaint->student?->department) {
                    $q->orWhere('department', $complaint->student->department);
                }
                if ($complaint->student?->batch_adviser_id) {
                    $q->orWhere('id', $complaint->student->batch_adviser_id);
                }
            });
    }

    public static function record(Complaint $complaint, User $actor, string $type, string $action, ?string $previous = null, ?User $recipient = null, ?string $remarks = null): void
    {
        ComplaintHistory::create([
            'complaint_id' => $complaint->id,
            'acted_by' => $actor->id,
            'actor_name' => $actor->role === 'student' ? $actor->registration_number : $actor->name,
            'actor_role' => $actor->role,
            'recipient_id' => $recipient?->id,
            'recipient_name' => $recipient?->name,
            'recipient_role' => $recipient?->role,
            'event_type' => $type,
            'action' => $action,
            'from_status' => $previous,
            'to_status' => $complaint->status,
            'remarks' => $remarks,
        ]);
    }
}
