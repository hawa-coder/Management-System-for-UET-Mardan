<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\{Notice, AppNotification, User, Course};
use App\Services\{NoticeAudience, NoticeDelivery};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{DB, Storage, URL};
use Illuminate\Validation\ValidationException;

class NoticeController extends Controller
{
    public function index(Request $request, NoticeDelivery $delivery)
    {
        $delivery->dispatchDue();
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:180'],
            'category' => ['nullable', 'string'], 'priority' => ['nullable', 'in:Normal,Important,Urgent'],
            'from' => ['nullable', 'date'], 'to' => ['nullable', 'date', 'after_or_equal:from'],
            'read' => ['nullable', 'in:read,unread'], 'status' => ['nullable', 'in:Active,Expired,Scheduled'],
        ]);
        $user = $request->user();
        $query = Notice::with('publisher:id,name,role');
        if ($request->boolean('mine')) {
            $this->authorizePublisher($request);
            $query->where('published_by', $user->id);
        } else {
            $query->active()->where(fn ($q) => $q->where(fn ($r) => $r->forRecipient($user))->orWhere('published_by', $user->id));
        }
        if ($search = $filters['search'] ?? null) $query->where(fn ($q) => $q->where('title', 'like', '%'.$search.'%')->orWhere('body', 'like', '%'.$search.'%'));
        foreach (['category', 'priority'] as $field) if (!empty($filters[$field])) $query->where($field, $filters[$field]);
        if (!empty($filters['from'])) $query->whereDate('notice_date', '>=', $filters['from']);
        if (!empty($filters['to'])) $query->whereDate('notice_date', '<=', $filters['to']);
        if (!empty($filters['read'])) {
            $method = $filters['read'] === 'read' ? 'whereIn' : 'whereNotIn';
            $query->$method('id', DB::table('notice_reads')->where('user_id', $user->id)->select('notice_id'));
        }
        if (($filters['status'] ?? null) === 'Active') $query->active();
        if (($filters['status'] ?? null) === 'Expired') $query->where('expires_at', '<=', now());
        if (($filters['status'] ?? null) === 'Scheduled') $query->where('notice_date', '>', now())->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>', now()));
        $page = $query->orderByRaw("CASE priority WHEN 'Urgent' THEN 0 WHEN 'Important' THEN 1 ELSE 2 END")
            ->orderByDesc('notice_date')->orderByDesc('id')->paginate(20);
        $readIds = DB::table('notice_reads')->where('user_id', $user->id)->whereIn('notice_id', $page->pluck('id'))->pluck('notice_id')->all();
        $page->getCollection()->each(fn ($notice) => $notice->setAttribute('is_read', in_array($notice->id, $readIds)));
        return response()->json($page);
    }

    private function authorizePublisher(Request $request): void
    {
        abort_unless(in_array($request->user()->role, ['chairman', 'adviser', 'faculty', 'coordinator', 'dean'], true)
            && $request->user()->account_status === 'approved', 403, 'Only approved academic staff can publish notices.');
    }

    private function authorizeOwner(Request $request, Notice $notice): void
    {
        $this->authorizePublisher($request);
        abort_unless($notice->published_by === $request->user()->id, 403, 'You can manage only your own notices.');
    }

    private function canView(User $user, Notice $notice): bool
    {
        return $notice->published_by === $user->id || Notice::whereKey($notice->id)->active()->forRecipient($user)->exists();
    }

    public function options(Request $request)
    {
        $this->authorizePublisher($request);
        $user = $request->user();
        $students = NoticeAudience::studentsFor($user);
        $options = [];
        foreach (['department', 'batch', 'section'] as $field) {
            $options[$field] = (clone $students)->whereNotNull($field)->where($field, '!=', '')->distinct()->orderBy($field)->pluck($field);
        }
        $options['students'] = (clone $students)->orderBy('name')->get(['id', 'name', 'registration_number', 'department', 'batch', 'semester', 'section']);
        $options['courses'] = Course::whereHas('students', fn ($q) => $q->whereIn('users.id', (clone $students)->select('id')))
            ->when($user->role === 'faculty', fn ($q) => $q->where('faculty_id', $user->id))
            ->orderBy('code')->get(['id', 'code', 'name']);
        $options['faculty_restricted'] = $user->role === 'faculty' && !$user->can_publish_department_notices;
        $options['scope_description'] = match ($user->role) {
            'adviser' => 'Only students assigned to you.',
            'faculty' => $user->can_publish_department_notices ? 'Students in your department.' : 'Only students enrolled in classes you teach.',
            'chairman', 'coordinator' => 'Students in your department.',
            default => 'All university students.',
        };
        return response()->json($options);
    }

    private function validated(Request $request): array
    {
        if ($request->has('notice_data')) {
            $request->validate(['notice_data' => ['required', 'json']]);
            $payload = json_decode($request->input('notice_data'), true);
            if (!is_array($payload)) throw ValidationException::withMessages(['notice_data' => 'Invalid notice data.']);
            $request->merge($payload);
        }
        if (!$request->filled('notice_date')) $request->merge(['notice_date' => now()->toISOString()]);
        $rules = [
            'title' => ['required', 'string', 'max:180'], 'body' => ['required', 'string', 'max:10000'],
            'audience' => ['sometimes', $request->user()->role === 'adviser' || $request->user()->role === 'faculty' ? 'in:student' : 'in:all,student,adviser,coordinator,chairman,office,dean,faculty'],
            'category' => ['sometimes', 'in:Academic,Examination,Events,Timetable,FYP,Department'],
            'priority' => ['sometimes', 'in:Normal,Important,Urgent'],
            'notice_date' => ['nullable', 'date'], 'expires_at' => ['nullable', 'date', 'after:notice_date'],
            'department' => ['nullable', 'string', 'max:255'], 'batch' => ['nullable', 'string', 'max:30'],
            'semester' => ['nullable', 'integer', 'between:1,8'], 'section' => ['nullable', 'string', 'max:30'],
            'attachment' => ['nullable', 'file', 'mimes:pdf,jpg,jpeg,png,doc,docx,txt,odt', 'max:10240'],
            'remove_attachment' => ['sometimes', 'boolean'],
        ];
        foreach (['departments', 'batches', 'semesters', 'sections', 'course_ids', 'student_ids'] as $field) {
            $rules[$field] = ['sometimes', 'array', 'max:500'];
            $rules[$field.'.*'] = match ($field) {
                'semesters' => ['integer', 'between:1,8', 'distinct'],
                'course_ids', 'student_ids' => ['integer', 'distinct'],
                default => ['string', 'max:255', 'distinct'],
            };
        }
        $data = $request->validate($rules);
        unset($data['attachment'], $data['remove_attachment']);
        foreach (['semesters', 'course_ids', 'student_ids'] as $field) {
            if (isset($data[$field])) $data[$field] = array_map('intval', $data[$field]);
        }
        $user = $request->user();
        $data['audience'] ??= 'student';
        $data['notice_date'] = isset($data['notice_date']) ? \Carbon\Carbon::parse($data['notice_date'])->utc() : now();
        if (!empty($data['expires_at'])) {
            $data['expires_at'] = \Carbon\Carbon::parse($data['expires_at'])->utc();
            if ($data['expires_at']->lte($data['notice_date'])) throw ValidationException::withMessages(['expires_at' => 'Expiry must be after the notice date.']);
        }
        $students = NoticeAudience::studentsFor($user);
        if (!empty($data['student_ids']) && (clone $students)->whereIn('id', $data['student_ids'])->count() !== count($data['student_ids'])) {
            throw ValidationException::withMessages(['student_ids' => 'Select only students within your permitted audience.']);
        }
        if (!empty($data['course_ids'])) {
            $courses = Course::whereIn('id', $data['course_ids'])
                ->whereHas('students', fn ($q) => $q->whereIn('users.id', (clone $students)->select('id')))
                ->when($user->role === 'faculty', fn ($q) => $q->where('faculty_id', $user->id));
            if ($courses->count() !== count($data['course_ids'])) throw ValidationException::withMessages(['course_ids' => 'Select only courses within your permitted audience.']);
        }
        $data['target_adviser_id'] = $user->role === 'adviser' ? $user->id : null;
        $data['scope_department'] = in_array($user->role, ['chairman', 'faculty', 'coordinator'], true) ? $user->department : null;
        $data['target_faculty_id'] = $user->role === 'faculty' && !$user->can_publish_department_notices ? $user->id : null;
        return $data;
    }

    public function store(Request $request, NoticeDelivery $delivery)
    {
        $this->authorizePublisher($request);
        return $this->save($request, new Notice(['published_by' => $request->user()->id]), $delivery, 201);
    }

    public function update(Request $request, Notice $notice, NoticeDelivery $delivery)
    {
        $this->authorizeOwner($request, $notice);
        return $this->save($request, $notice, $delivery);
    }

    private function save(Request $request, Notice $notice, NoticeDelivery $delivery, int $status = 200)
    {
        $data = $this->validated($request);
        $oldPath = $notice->attachment_path;
        $newPath = null;
        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $newPath = $data['attachment_path'] = $file->store('notice-attachments');
            $data['attachment_name'] = $file->getClientOriginalName();
            $data['attachment_mime'] = $file->getMimeType();
        } elseif ($request->boolean('remove_attachment')) {
            $data += ['attachment_path' => null, 'attachment_name' => null, 'attachment_mime' => null];
        }
        try {
            DB::transaction(function () use ($notice, $data) {
                $notice->fill($data + ['published_at' => now(), 'notified_at' => null])->save();
                AppNotification::where('notice_id', $notice->id)->delete();
                DB::table('notice_reads')->where('notice_id', $notice->id)->delete();
            });
        } catch (\Throwable $e) {
            if ($newPath) Storage::delete($newPath);
            throw $e;
        }
        if ($oldPath && $oldPath !== $notice->attachment_path) Storage::delete($oldPath);
        $delivery->dispatchDue();
        return response()->json($notice->fresh()->load('publisher:id,name,role'), $status);
    }

    public function show(Request $request, Notice $notice)
    {
        abort_unless($this->canView($request->user(), $notice), 404);
        $notice->markRead($request->user());
        $notice->load('publisher:id,name,role')->setAttribute('is_read', true);
        if ($notice->attachment_path) {
            $notice->setAttribute('attachment_url', URL::temporarySignedRoute('notices.attachment', now()->addMinutes(10), ['notice' => $notice->id, 'user' => $request->user()->id], absolute: false));
        }
        return response()->json($notice);
    }

    public function destroy(Request $request, Notice $notice)
    {
        $this->authorizeOwner($request, $notice);
        $path = $notice->attachment_path;
        DB::transaction(function () use ($notice) {
            AppNotification::where('notice_id', $notice->id)->delete();
            DB::table('notice_reads')->where('notice_id', $notice->id)->delete();
            $notice->delete();
        });
        if ($path) Storage::delete($path);
        return response()->json(['message' => 'Notice deleted.']);
    }

    public function republish(Request $request, Notice $notice, NoticeDelivery $delivery)
    {
        $this->authorizeOwner($request, $notice);
        $data = $request->validate(['expires_at' => ['nullable', 'date', 'after:now']]);
        // Reapply current permissions if the author's scope has changed.
        $user = $request->user();
        DB::transaction(function () use ($notice, $data, $user) {
            $notice->update([
                'notice_date' => now(), 'published_at' => now(), 'notified_at' => null,
                'expires_at' => isset($data['expires_at']) ? \Carbon\Carbon::parse($data['expires_at'])->utc() : null,
                'target_adviser_id' => $user->role === 'adviser' ? $user->id : null,
                'scope_department' => in_array($user->role, ['chairman', 'faculty', 'coordinator'], true) ? $user->department : null,
                'target_faculty_id' => $user->role === 'faculty' && !$user->can_publish_department_notices ? $user->id : null,
            ]);
            AppNotification::where('notice_id', $notice->id)->delete();
            DB::table('notice_reads')->where('notice_id', $notice->id)->delete();
        });
        $delivery->dispatchDue();
        return response()->json($notice->fresh()->load('publisher:id,name,role'));
    }

    public function attachment(Request $request, Notice $notice)
    {
        abort_unless($request->hasValidSignature(false), 403, 'This attachment link has expired.');
        $user = User::find($request->query('user'));
        abort_unless($user && $user->is_active && $user->account_status === 'approved' && $this->canView($user, $notice), 403);
        abort_unless($notice->attachment_path && Storage::exists($notice->attachment_path), 404);
        return Storage::download($notice->attachment_path, $notice->attachment_name, ['Content-Type' => $notice->attachment_mime, 'X-Content-Type-Options' => 'nosniff']);
    }
}
