<?php

namespace Tests\Feature;

use App\Models\Complaint;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ComplaintApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_can_submit_and_read_own_complaint(): void
    {
        $student = User::factory()->create([
            'role' => 'student',
            'account_status' => 'approved',
        ]);
        Sanctum::actingAs($student);

        $response = $this->postJson('/api/complaints', [
            'title' => 'Laboratory issue',
            'details' => 'Several computers are not starting.',
            'category' => 'Lab',
            'priority' => 'High',
        ])->assertCreated();

        $this->getJson('/api/complaints/'.$response->json('id'))->assertOk();
        $this->assertDatabaseCount('complaint_histories', 1);
    }

    public function test_student_cannot_read_another_students_complaint(): void
    {
        $owner = User::factory()->create(['role' => 'student']);
        $otherStudent = User::factory()->create(['role' => 'student']);
        $complaint = Complaint::create([
            'complaint_number' => 'CMP-TEST-0001',
            'user_id' => $owner->id,
            'title' => 'Private complaint',
            'details' => 'Private complaint details.',
            'category' => 'Academic',
            'priority' => 'Medium',
        ]);
        Sanctum::actingAs($otherStudent);

        $this->getJson('/api/complaints/'.$complaint->id)->assertForbidden();
    }

    public function test_adviser_can_forward_an_assigned_complaint(): void
    {
        $adviser = User::factory()->create(['role' => 'adviser']);
        $student = User::factory()->create([
            'role' => 'student',
            'batch_adviser_id' => $adviser->id,
        ]);
        $complaint = Complaint::create([
            'complaint_number' => 'CMP-TEST-0002',
            'user_id' => $student->id,
            'title' => 'Academic issue',
            'details' => 'An academic complaint.',
            'category' => 'Academic',
            'priority' => 'Medium',
            'current_handler_role' => 'adviser',
        ]);
        Sanctum::actingAs($adviser);

        $this->postJson('/api/complaints/'.$complaint->id.'/transition', [
            'action' => 'forward_coordinator',
        ])->assertOk()->assertJsonPath('current_handler_role', 'coordinator');
    }

    public function test_adviser_can_accept_resolve_and_reject_assigned_complaints(): void
    {
        $adviser = User::factory()->create(['role' => 'adviser']);
        $student = User::factory()->create([
            'role' => 'student',
            'batch_adviser_id' => $adviser->id,
        ]);
        Sanctum::actingAs($adviser);

        foreach (['accept' => 'review', 'resolve' => 'resolved', 'reject' => 'rejected'] as $action => $status) {
            $complaint = Complaint::create([
                'complaint_number' => 'CMP-'.$action,
                'user_id' => $student->id,
                'title' => 'Academic issue',
                'details' => 'An academic complaint.',
                'category' => 'Academic',
                'priority' => 'Medium',
                'current_handler_role' => 'adviser',
            ]);

            $this->postJson('/api/complaints/'.$complaint->id.'/transition', [
                'action' => $action,
            ])->assertOk()->assertJsonPath('status', $status);
        }
    }

    public function test_student_cannot_change_complaint_status(): void
    {
        $student = User::factory()->create(['role' => 'student']);
        $complaint = Complaint::create([
            'complaint_number' => 'CMP-STUDENT-ACTION',
            'user_id' => $student->id,
            'title' => 'Academic issue',
            'details' => 'An academic complaint.',
            'category' => 'Academic',
            'priority' => 'Medium',
        ]);
        Sanctum::actingAs($student);

        foreach (['accept', 'resolve', 'reject'] as $action) {
            $this->postJson('/api/complaints/'.$complaint->id.'/transition', [
                'action' => $action,
            ])->assertForbidden();
        }
    }
}
