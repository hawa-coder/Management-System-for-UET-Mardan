<?php

namespace Tests\Feature;

use App\Models\Complaint;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ComplaintRoutingTest extends TestCase
{
    use RefreshDatabase;

    private function staff(string $role, string $name): User
    {
        return User::factory()->create(['role' => $role, 'name' => $name]);
    }

    private function submit(User $adviser): array
    {
        $student = User::factory()->create([
            'name' => 'Private student name', 'registration_number' => 'FA23-BCS-123',
            'batch_adviser_id' => $adviser->id, 'mobile_number' => '03001234567',
        ]);
        Sanctum::actingAs($student);
        $response = $this->postJson('/api/complaints', [
            'title' => 'Attendance Issue', 'details' => 'Please correct my attendance.',
            'category' => 'Academic', 'priority' => 'Medium',
        ])->assertCreated()->assertJsonPath('routing.currently_with.name', $adviser->name);
        return [$student, $response->json('id')];
    }

    public function test_named_routing_survives_forward_return_review_and_profile_changes(): void
    {
        $adviser = $this->staff('adviser', 'Dr. Ahmed Khan');
        $chairman = $this->staff('chairman', 'Dr. Usman Khan');
        $faculty = $this->staff('faculty', 'Dr. Hassan Ali');
        $faculty->forceFill(['can_forward_complaints' => true])->save();
        [$student, $id] = $this->submit($adviser);

        Sanctum::actingAs($adviser);
        $this->postJson("/api/complaints/$id/transition", [
            'action' => 'forward', 'recipient_id' => $chairman->id, 'remarks' => 'Please review this complaint.',
        ])->assertOk()->assertJsonPath('routing.originally_forwarded_by.name', 'Dr. Ahmed Khan')
            ->assertJsonPath('routing.forwarded_to.name', 'Dr. Usman Khan');

        Sanctum::actingAs($chairman);
        $this->postJson("/api/complaints/$id/transition", [
            'action' => 'forward', 'recipient_id' => $faculty->id,
        ])->assertOk()->assertJsonPath('routing.received_from.name', 'Dr. Usman Khan')
            ->assertJsonPath('routing.currently_with.name', 'Dr. Hassan Ali')
            ->assertJsonPath('routing.next_forwarded_to.name', 'Dr. Hassan Ali');

        // An already-open screen from the former holder cannot overwrite the new assignment.
        $this->postJson("/api/complaints/$id/transition", ['action' => 'resolve'])->assertForbidden();
        $adviser->update(['name' => 'Renamed Adviser', 'role' => 'coordinator']);
        Sanctum::actingAs($faculty);
        $this->postJson("/api/complaints/$id/transition", ['action' => 'accept'])->assertOk();
        $this->getJson("/api/complaints/$id")->assertOk()
            ->assertJsonPath('routing.originally_forwarded_by.name', 'Dr. Ahmed Khan')
            ->assertJsonPath('routing.originally_forwarded_by.role', 'adviser')
            ->assertJsonPath('routing.received_from.name', 'Dr. Usman Khan')
            ->assertJsonPath('history.1.remarks', 'Please review this complaint.')
            ->assertJsonPath('permissions.can_forward', true);

        $this->postJson("/api/complaints/$id/transition", [
            'action' => 'return', 'recipient_id' => $chairman->id, 'remarks' => 'Please provide additional information.',
        ])->assertOk()->assertJsonPath('status', 'returned')
            ->assertJsonPath('routing.received_from.name', 'Dr. Hassan Ali')
            ->assertJsonPath('routing.currently_with.name', 'Dr. Usman Khan')
            ->assertJsonPath('history.4.event_type', 'returned');

        foreach ([$adviser, $chairman, $faculty, $student] as $viewer) {
            Sanctum::actingAs($viewer);
            $response = $this->getJson("/api/complaints/$id")->assertOk()->assertJsonCount(5, 'history')
                ->assertJsonPath('student_registration_number', 'FA23-BCS-123')
                ->assertJsonPath('history.0.actor.name', 'FA23-BCS-123')
                ->assertJsonMissingPath('student');
            $this->assertStringNotContainsString('Private student name', $response->getContent());
            $this->assertStringNotContainsString($student->email, $response->getContent());
            $this->assertStringNotContainsString('03001234567', $response->getContent());
            $this->getJson('/api/complaints')->assertOk()->assertJsonPath('data.0.id', $id);
        }
        $this->assertDatabaseCount('complaint_histories', 5);
    }

    public function test_faculty_forwarding_requires_permission_and_an_authorized_recipient(): void
    {
        $adviser = $this->staff('adviser', 'Adviser');
        $faculty = $this->staff('faculty', 'Faculty');
        $otherFaculty = $this->staff('faculty', 'Other Faculty');
        [$student, $id] = $this->submit($adviser);
        Sanctum::actingAs($adviser);
        $this->postJson("/api/complaints/$id/transition", ['action' => 'forward', 'recipient_id' => $faculty->id])->assertOk();
        Sanctum::actingAs($faculty);
        $this->getJson("/api/complaints/$id")->assertOk()->assertJsonPath('permissions.can_forward', false);
        $this->getJson("/api/complaints/$id/recipients")->assertForbidden();
        $this->postJson("/api/complaints/$id/transition", ['action' => 'forward', 'recipient_id' => $adviser->id])->assertForbidden();
        $this->artisan('complaints:forward-permission', ['email' => $faculty->email])->assertSuccessful();
        Sanctum::actingAs($faculty->fresh());
        $this->getJson("/api/complaints/$id/recipients")->assertOk()->assertJsonFragment(['id' => $otherFaculty->id, 'name' => 'Other Faculty', 'role' => 'faculty']);

        $disabled = $this->staff('chairman', 'Disabled');
        $disabled->update(['is_active' => false]);
        $pending = $this->staff('faculty', 'Pending');
        $pending->update(['account_status' => 'pending']);
        $foreign = $this->staff('faculty', 'Other Department');
        $foreign->update(['department' => 'Electrical Engineering']);
        foreach ([$student, $faculty, $disabled, $pending, $foreign] as $invalid) {
            $this->postJson("/api/complaints/$id/transition", ['action' => 'forward', 'recipient_id' => $invalid->id])->assertStatus(422);
        }
        $this->postJson("/api/complaints/$id/transition", ['action' => 'forward'])->assertStatus(422);
        $this->assertDatabaseCount('complaint_histories', 2);
        $this->postJson("/api/complaints/$id/transition", ['action' => 'forward', 'recipient_id' => $otherFaculty->id])->assertOk();
        $this->assertDatabaseCount('complaint_histories', 3);
    }

    public function test_unrelated_staff_cannot_read_or_act_and_previous_holders_cannot_act(): void
    {
        $adviser = $this->staff('adviser', 'Adviser');
        $faculty = $this->staff('faculty', 'Faculty');
        [, $id] = $this->submit($adviser);
        foreach (['adviser', 'faculty', 'coordinator', 'chairman'] as $role) {
            $outsider = $this->staff($role, 'Outsider');
            $outsider->update(['department' => 'Other Department']);
            Sanctum::actingAs($outsider);
            $this->getJson("/api/complaints/$id")->assertForbidden();
            $this->getJson('/api/complaints')->assertOk()->assertJsonCount(0, 'data');
            $this->postJson("/api/complaints/$id/transition", ['action' => 'accept'])->assertForbidden();
        }
        Sanctum::actingAs($adviser);
        $this->postJson("/api/complaints/$id/transition", ['action' => 'forward', 'recipient_id' => $faculty->id])->assertOk();
        $this->getJson("/api/complaints/$id")->assertOk()->assertJsonPath('permissions.can_act', false);
        $this->postJson("/api/complaints/$id/transition", ['action' => 'reject'])->assertForbidden();
        $this->getJson("/api/complaints/$id/recipients")->assertForbidden();
        $this->assertDatabaseCount('complaint_histories', 2);
    }

    public function test_routing_records_cannot_be_rewritten(): void
    {
        $adviser = $this->staff('adviser', 'Adviser');
        [, $id] = $this->submit($adviser);
        $event = Complaint::findOrFail($id)->history()->first();
        $this->expectException(\LogicException::class);
        $event->update(['actor_name' => 'Replacement']);
    }

    public function test_resolution_can_still_be_sent_to_a_named_department_staff_member(): void
    {
        $chairman = $this->staff('chairman', 'Chairman');
        $office = $this->staff('office', 'Department Staff');
        $adviser = $this->staff('adviser', 'Adviser');
        [, $id] = $this->submit($adviser);
        Sanctum::actingAs($adviser);
        $this->postJson("/api/complaints/$id/transition", ['action' => 'forward', 'recipient_id' => $chairman->id])->assertOk();
        Sanctum::actingAs($chairman);
        $this->postJson("/api/complaints/$id/transition", ['action' => 'resolve'])->assertOk()->assertJsonPath('permissions.can_send_resolution', true);
        $this->getJson("/api/complaints/$id/recipients")->assertOk()->assertJsonCount(1, 'data');
        $this->postJson("/api/complaints/$id/transition", ['action' => 'send_resolved_department', 'recipient_id' => $office->id])->assertOk();
        Sanctum::actingAs($office);
        $this->getJson("/api/complaints/$id")->assertOk()->assertJsonPath('permissions.can_publish_resolution', true);
        $this->postJson("/api/complaints/$id/publish-resolution", ['title' => 'Resolved', 'body' => 'The attendance was corrected.'])->assertCreated();
        $this->assertDatabaseCount('complaint_histories', 5);
    }
}
