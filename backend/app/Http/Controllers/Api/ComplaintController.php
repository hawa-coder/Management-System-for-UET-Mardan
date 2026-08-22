<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Complaint;
use App\Models\ComplaintHistory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ComplaintController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Complaint::with(['student:id,name,email,registration_number,batch,section', 'history.actor:id,name,role'])->latest();

        if ($user->role === 'student') {
            $query->where('user_id', $user->id);
        } elseif (! in_array($user->role, ['chairman', 'office', 'dean'], true)) {
            $query->where('current_handler_role', $user->role);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        return response()->json($query->paginate(20));
    }

    public function store(Request $request)
    {
        abort_unless($request->user()->role === 'student', 403, 'Only students can submit complaints.');

        $data = $request->validate([
            'title' => ['required', 'string', 'max:150'],
            'details' => ['required', 'string', 'max:5000'],
            'category' => ['required', 'string', 'max:80'],
            'priority' => ['required', 'in:Low,Medium,High'],
        ]);

        $complaint = DB::transaction(function () use ($request, $data) {
            $complaint = Complaint::create($data + [
                'complaint_number' => 'CMP-'.now()->format('ymd').'-'.str_pad((string) (Complaint::max('id') + 1), 4, '0', STR_PAD_LEFT),
                'user_id' => $request->user()->id,
            ]);
            ComplaintHistory::create([
                'complaint_id' => $complaint->id,
                'acted_by' => $request->user()->id,
                'action' => 'Complaint submitted',
                'to_status' => 'submitted',
            ]);
            AppNotification::create([
                'user_id' => $request->user()->id,
                'type' => 'complaint',
                'title' => 'Complaint submitted',
                'message' => "{$complaint->complaint_number} was submitted successfully.",
            ]);

            return $complaint;
        });

        return response()->json($complaint->load('history'), 201);
    }

    public function show(Request $request, Complaint $complaint)
    {
        $this->authorizeAccess($request, $complaint);

        return response()->json($complaint->load(['student', 'history.actor']));
    }

    public function transition(Request $request, Complaint $complaint)
    {
        $this->authorizeAccess($request, $complaint);
        abort_if($request->user()->role === 'student', 403, 'Students cannot change complaint status.');

        $data = $request->validate([
            'action' => ['required', 'in:forward_coordinator,forward_chairman,send_office,send_dean,resolve,reject,return_chairman'],
            'remarks' => ['nullable', 'string', 'max:2000'],
        ]);

        $allowed = [
            'adviser' => ['forward_coordinator' => ['forwarded', 'coordinator']],
            'coordinator' => ['forward_chairman' => ['forwarded', 'chairman']],
            'chairman' => [
                'send_office' => ['office', 'office'],
                'send_dean' => ['dean', 'dean'],
                'resolve' => ['resolved', 'closed'],
                'reject' => ['rejected', 'closed'],
            ],
            'office' => ['return_chairman' => ['forwarded', 'chairman']],
            'dean' => ['return_chairman' => ['forwarded', 'chairman']],
        ];

        $next = $allowed[$request->user()->role][$data['action']] ?? null;
        abort_unless($next, 403, 'This action is not permitted for your role.');
        $previous = $complaint->status;

        DB::transaction(function () use ($request, $complaint, $data, $next, $previous) {
            $complaint->update(['status' => $next[0], 'current_handler_role' => $next[1]]);
            ComplaintHistory::create([
                'complaint_id' => $complaint->id,
                'acted_by' => $request->user()->id,
                'action' => str_replace('_', ' ', ucfirst($data['action'])),
                'from_status' => $previous,
                'to_status' => $next[0],
                'remarks' => $data['remarks'] ?? null,
            ]);
            AppNotification::create([
                'user_id' => $complaint->user_id,
                'type' => 'complaint',
                'title' => 'Complaint status updated',
                'message' => "{$complaint->complaint_number} is now {$next[0]}.",
            ]);
        });

        return response()->json($complaint->fresh()->load('history.actor'));
    }

    private function authorizeAccess(Request $request, Complaint $complaint): void
    {
        $user = $request->user();
        abort_if($user->role === 'student' && $complaint->user_id !== $user->id, 403);
        abort_if(! in_array($user->role, ['student', 'chairman', 'office', 'dean'], true)
            && $complaint->current_handler_role !== $user->role, 403);
    }
}
