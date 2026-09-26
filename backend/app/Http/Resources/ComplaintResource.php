<?php

namespace App\Http\Resources;

use App\Services\ComplaintRouting;
use Illuminate\Http\Resources\Json\JsonResource;

class ComplaintResource extends JsonResource
{
    public function toArray($request): array
    {
        $this->resource->loadMissing(['student', 'history', 'comments.author:id,name,role']);
        $person = fn ($id, $name, $role) => $role ? ['id' => $id, 'name' => $name, 'role' => $role] : null;
        $events = $this->history->map(fn ($h) => [
            'id' => $h->id, 'event_type' => $h->event_type, 'action' => $h->action,
            'actor' => $person($h->acted_by, $h->actor_name, $h->actor_role),
            'recipient' => $person($h->recipient_id, $h->recipient_name, $h->recipient_role),
            'from_status' => $h->from_status, 'to_status' => $h->to_status,
            'remarks' => $h->remarks, 'created_at' => $h->created_at?->toISOString(),
        ]);
        $handoffs = $events->whereIn('event_type', ['forwarded', 'returned'])->values();
        $latest = $handoffs->last();
        $original = $handoffs->first(fn ($h) => ($h['actor']['role'] ?? null) === 'adviser');
        $submission = $events->firstWhere('event_type', 'submitted');
        $user = $request->user();
        return [
            'id' => $this->id, 'complaint_number' => $this->complaint_number,
            'student_registration_number' => $this->student?->registration_number,
            'title' => $this->title, 'details' => $this->details, 'category' => $this->category,
            'priority' => $this->priority, 'status' => $this->status,
            'current_handler_role' => $this->current_handler_role,
            'created_at' => $this->created_at?->toISOString(), 'updated_at' => $this->updated_at?->toISOString(),
            'attachment_name' => $this->attachment_name, 'attachment_url' => $this->attachment_url,
            'routing' => [
                'received_from' => $latest['actor'] ?? $submission['actor'] ?? $person(null, $this->student?->registration_number, 'student'),
                'originally_forwarded_by' => $original['actor'] ?? null,
                'batch_adviser' => $original['actor'] ?? (($submission['recipient']['role'] ?? null) === 'adviser' ? $submission['recipient'] : null),
                'forwarded_by' => $latest['actor'] ?? null,
                'forwarded_to' => $latest['recipient'] ?? null,
                'next_forwarded_to' => $handoffs->count() > 1 ? $latest['recipient'] : null,
                'currently_with' => $this->current_handler_role === 'closed' ? null
                    : $person($this->current_handler_id, $this->current_handler_name, $this->current_handler_role),
            ],
            'permissions' => [
                'can_act' => ComplaintRouting::canAct($this->resource, $user),
                'can_forward' => ComplaintRouting::canForward($this->resource, $user),
                'can_send_resolution' => ComplaintRouting::canSendResolution($this->resource, $user),
                'can_comment' => $user->role !== 'student',
                'can_publish_resolution' => $user->role === 'office' && ComplaintRouting::isHolder($this->resource, $user)
                    && $this->status === 'resolved' && $this->current_handler_role === 'office',
            ],
            'history' => $events->all(),
            'comments' => $user->role === 'student' ? [] : $this->comments->map(fn ($c) => [
                'id' => $c->id, 'comment' => $c->comment, 'created_at' => $c->created_at?->toISOString(),
                'author' => $person($c->user_id, $c->author?->name, $c->author?->role),
            ])->all(),
        ];
    }
}
