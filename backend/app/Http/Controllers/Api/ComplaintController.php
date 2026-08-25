<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Complaint;
use App\Models\ComplaintHistory;
use App\Models\Notice;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ComplaintController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Complaint::with(['student:id,name,email,registration_number,batch,section,batch_adviser_id', 'history.actor:id,name,role'])->latest();

        if (in_array($user->role, ['adviser', 'coordinator', 'chairman'], true)) {
            $query->with('comments.author:id,name,role');
        }

        if ($user->role === 'student') {
            $query->where('user_id', $user->id);
        } elseif ($user->role === 'adviser') {
            $query->where('current_handler_role', 'adviser')
                ->whereHas('student', fn ($student) => $student->where('batch_adviser_id', $user->id));
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
        abort_unless(
            $request->user()->account_status === 'approved',
            403,
            'You cannot submit complaints until your batch adviser approves your account.'
        );

        $data = $request->validate([
            'title' => ['required', 'string', 'max:150'],
            'details' => ['required', 'string', 'max:5000'],
            'category' => ['required', 'string', 'max:80'],
            'priority' => ['required', 'in:Low,Medium,High'],
            'attachment' => ['nullable', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:10240'],
        ]);

        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $data['attachment_path'] = $file->store('complaint-attachments');
            $data['attachment_name'] = $file->getClientOriginalName();
            $data['attachment_mime'] = $file->getMimeType();
        }

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

    public function attachment(Request $request, Complaint $complaint)
    {
        abort_unless($request->hasValidSignature(false), 403, 'This attachment link has expired.');
        abort_unless($complaint->attachment_path && Storage::exists($complaint->attachment_path), 404);

        return Storage::download(
            $complaint->attachment_path,
            $complaint->attachment_name,
            ['Content-Type' => $complaint->attachment_mime],
        );
    }

    public function transition(Request $request, Complaint $complaint)
    {
        $this->authorizeAccess($request, $complaint);
        abort_if($request->user()->role === 'student', 403, 'Students cannot change complaint status.');

        $data = $request->validate([
            'action' => ['required', 'in:accept,forward_coordinator,forward_chairman,send_office,send_dean,send_resolved_department,resolve,reject,return_chairman'],
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
                'send_resolved_department' => ['resolved', 'office'],
            ],
            'office' => ['return_chairman' => ['forwarded', 'chairman']],
            'dean' => ['return_chairman' => ['forwarded', 'chairman']],
        ];

        $commonActions = [
            'accept' => ['review', $request->user()->role],
            'resolve' => ['resolved', 'closed'],
            'reject' => ['rejected', 'closed'],
        ];
        $next = $commonActions[$data['action']]
            ?? $allowed[$request->user()->role][$data['action']]
            ?? null;
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

        $fresh = $complaint->fresh()->load('history.actor');
        if (in_array($request->user()->role, ['adviser', 'coordinator', 'chairman'], true)) {
            $fresh->load('comments.author:id,name,role');
        }

        return response()->json($fresh);
    }

    public function comment(Request $request, Complaint $complaint)
    {
        $this->authorizeAccess($request, $complaint);
        abort_unless(
            in_array($request->user()->role, ['adviser', 'coordinator', 'chairman'], true),
            403,
            'Only batch advisers, the coordinator, and the chairman can add complaint comments.'
        );

        $data = $request->validate([
            'comment' => ['required', 'string', 'max:2000'],
        ]);

        $comment = $complaint->comments()->create([
            'user_id' => $request->user()->id,
            'comment' => $data['comment'],
        ]);

        return response()->json($comment->load('author:id,name,role'), 201);
    }

    public function publishResolution(Request $request, Complaint $complaint)
    {
        $user = $request->user();
        abort_unless($user->role === 'office', 403, 'Only Department Staff can publish resolution notices.');
        abort_unless(
            $complaint->status === 'resolved' && $complaint->current_handler_role === 'office',
            422,
            'This resolved complaint has not been sent to Department Staff.'
        );

        $data = $request->validate([
            'title' => ['required', 'string', 'max:180'],
            'body' => ['required', 'string', 'max:10000'],
        ]);

        $notice = Notice::updateOrCreate(
            ['complaint_id' => $complaint->id],
            $data + [
                'published_by' => $user->id,
                'audience' => 'student',
                'published_at' => now(),
            ],
        );

        ComplaintHistory::create([
            'complaint_id' => $complaint->id,
            'acted_by' => $user->id,
            'action' => 'Resolution published to student notice board',
            'from_status' => 'resolved',
            'to_status' => 'resolved',
        ]);

        return response()->json($notice, 201);
    }

    private function authorizeAccess(Request $request, Complaint $complaint): void
    {
        $user = $request->user();
        abort_if($user->role === 'student' && $complaint->user_id !== $user->id, 403);
        if ($user->role === 'adviser') {
            $complaint->loadMissing('student:id,batch_adviser_id');
            abort_if($complaint->current_handler_role !== 'adviser'
                || $complaint->student?->batch_adviser_id !== $user->id, 403);
            return;
        }
        abort_if(! in_array($user->role, ['student', 'chairman', 'office', 'dean'], true)
            && $complaint->current_handler_role !== $user->role, 403);
    }
}
