<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ComplaintResource;
use App\Models\AppNotification;
use App\Models\Complaint;
use App\Models\Notice;
use App\Models\User;
use App\Services\ComplaintRouting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ComplaintController extends Controller
{
    public function index(Request $request)
    {
        $query = ComplaintRouting::visibleTo($request->user())
            ->with(['student', 'history', 'comments.author:id,name,role'])->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        return ComplaintResource::collection($query->paginate(20));
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
            $adviser = User::whereKey($request->user()->batch_adviser_id)->where('role', 'adviser')
                ->where('is_active', true)->where('account_status', 'approved')->first();
            $complaint = Complaint::create($data + [
                'complaint_number' => 'CMP-'.now()->format('ymd').'-'.str_pad((string) (Complaint::max('id') + 1), 4, '0', STR_PAD_LEFT),
                'user_id' => $request->user()->id,
                'status' => 'submitted',
                'current_handler_role' => 'adviser',
                'current_handler_id' => $adviser?->id,
                'current_handler_name' => $adviser?->name,
            ]);
            ComplaintRouting::record($complaint, $request->user(), 'submitted', 'Complaint submitted', recipient: $adviser);
            AppNotification::create([
                'user_id' => $request->user()->id,
                'type' => 'complaint',
                'title' => 'Complaint submitted',
                'message' => "{$complaint->complaint_number} was submitted successfully.",
            ]);

            return $complaint;
        });

        return response()->json((new ComplaintResource($complaint))->resolve($request), 201);
    }

    public function show(Request $request, Complaint $complaint)
    {
        $this->authorizeAccess($request, $complaint);

        return response()->json((new ComplaintResource($complaint))->resolve($request));
    }

    public function recipients(Request $request, Complaint $complaint)
    {
        $this->authorizeAccess($request, $complaint);
        abort_unless(ComplaintRouting::canForward($complaint, $request->user())
            || ComplaintRouting::canSendResolution($complaint, $request->user()), 403, 'You cannot forward this complaint.');
        $query = ComplaintRouting::recipients($complaint, $request->user());
        if (ComplaintRouting::canSendResolution($complaint, $request->user())) $query->where('role', 'office');
        return response()->json(['data' => $query->orderBy('name')->get(['id', 'name', 'role'])]);
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
            'action' => ['required', 'in:accept,forward,return,forward_coordinator,forward_chairman,send_office,send_dean,send_resolved_department,resolve,reject,return_chairman'],
            'recipient_id' => ['nullable', 'integer', 'exists:users,id'],
            'remarks' => ['nullable', 'string', 'max:2000'],
        ]);
        DB::transaction(function () use ($request, $complaint, $data) {
            // Recheck ownership under a lock so two stale screens cannot both forward it.
            $locked = Complaint::whereKey($complaint->id)->lockForUpdate()->firstOrFail();
            $user = $request->user();
            $action = $data['action'];
            $sendResolution = $action === 'send_resolved_department';
            abort_unless($sendResolution ? ComplaintRouting::canSendResolution($locked, $user)
                : ComplaintRouting::canAct($locked, $user), 403, 'Only the current holder can act on this complaint.');
            $previous = $locked->status;
            $recipient = null;
            $type = 'status';
            if (in_array($action, ['accept', 'resolve', 'reject'], true)) {
                $status = ['accept' => 'review', 'resolve' => 'resolved', 'reject' => 'rejected'][$action];
                $role = $action === 'accept' ? $user->role : 'closed';
                $label = ['accept' => 'Complaint accepted for review', 'resolve' => 'Complaint resolved', 'reject' => 'Complaint rejected'][$action];
            } else {
                abort_unless($sendResolution || ComplaintRouting::canForward($locked, $user), 403, 'You do not have permission to forward complaints.');
                $targetRole = [
                    'forward_coordinator' => 'coordinator', 'forward_chairman' => 'chairman',
                    'send_office' => 'office', 'send_dean' => 'dean',
                    'return_chairman' => 'chairman', 'send_resolved_department' => 'office',
                ][$action] ?? null;
                $recipients = ComplaintRouting::recipients($locked, $user);
                if ($targetRole) $recipients->where('role', $targetRole);
                if (! empty($data['recipient_id'])) {
                    $recipient = $recipients->whereKey($data['recipient_id'])->first();
                } elseif ($targetRole) {
                    // Older clients may omit the person only when there is exactly one eligible recipient.
                    $choices = $recipients->limit(2)->get();
                    if ($choices->count() === 1) $recipient = $choices->first();
                }
                abort_unless($recipient, 422, 'Select an active, approved recipient authorized for this complaint.');
                $type = in_array($action, ['return', 'return_chairman'], true) ? 'returned' : 'forwarded';
                $status = $sendResolution ? 'resolved' : ($type === 'returned' ? 'returned' : 'forwarded');
                $role = $recipient->role;
                $label = $sendResolution ? 'Resolution sent to Department Staff'
                    : ($type === 'returned' ? 'Complaint returned' : 'Complaint forwarded');
            }
            $locked->update([
                'status' => $status, 'current_handler_role' => $role,
                'current_handler_id' => $recipient?->id ?? $user->id,
                'current_handler_name' => $recipient?->name ?? $user->name,
            ]);
            ComplaintRouting::record($locked, $user, $type, $label, $previous, $recipient, $data['remarks'] ?? null);
            AppNotification::create([
                'user_id' => $complaint->user_id,
                'type' => 'complaint',
                'title' => 'Complaint status updated',
                'message' => "{$complaint->complaint_number} is now {$status}.",
            ]);
            if ($recipient) {
                AppNotification::create([
                    'user_id' => $recipient->id, 'type' => 'complaint',
                    'title' => $label,
                    'message' => "{$complaint->complaint_number} received from {$user->name}.",
                ]);
            }
        });
        return response()->json((new ComplaintResource($complaint->fresh()))->resolve($request));
    }

    public function comment(Request $request, Complaint $complaint)
    {
        $this->authorizeAccess($request, $complaint);
        abort_unless(
            in_array($request->user()->role, ComplaintRouting::STAFF, true),
            403,
            'Only authorized staff can add complaint comments.'
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
        $this->authorizeAccess($request, $complaint);
        abort_unless($user->role === 'office', 403, 'Only Department Staff can publish resolution notices.');
        abort_unless(ComplaintRouting::isHolder($complaint, $user), 403, 'Only the current holder can publish the resolution.');
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

        ComplaintRouting::record($complaint, $user, 'status', 'Resolution published to student notice board', 'resolved');

        return response()->json($notice, 201);
    }

    private function authorizeAccess(Request $request, Complaint $complaint): void
    {
        abort_unless(ComplaintRouting::visibleTo($request->user())->whereKey($complaint->id)->exists(), 403);
    }
}
