<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NoticeTargetingTest extends TestCase
{
    use RefreshDatabase;

    private function payload(array $extra = []): array
    {
        return array_merge(['title' => 'Class schedule', 'body' => 'Class starts at 9 am.', 'audience' => 'student'], $extra);
    }

    public function test_target_filters_apply_to_board_and_notifications_and_author_can_see_own_post(): void
    {
        $attributes = ['role' => 'student', 'department' => 'Computer Science', 'batch' => '2023', 'semester' => 5, 'section' => 'AI'];
        $match = User::factory()->create($attributes);
        $excluded = collect([
            ['department' => 'Electrical Engineering'], ['batch' => '2024'],
            ['semester' => 3], ['section' => 'DS'], ['role' => 'faculty'], ['batch' => null],
        ])->map(fn ($change) => User::factory()->create(array_merge($attributes, $change)));
        $author = User::factory()->create(['role' => 'chairman']);
        Sanctum::actingAs($author);
        $this->postJson('/api/notices', $this->payload(array_diff_key($attributes, ['role' => true])))
            ->assertCreated()->assertJsonPath('publisher.id', $author->id);
        $this->getJson('/api/notices')->assertJsonCount(1, 'data');
        Sanctum::actingAs($match);
        $this->getJson('/api/notices')->assertJsonCount(1, 'data');
        $this->getJson('/api/notifications')->assertJsonCount(1, 'data');
        foreach ($excluded as $user) {
            Sanctum::actingAs($user);
            $this->getJson('/api/notices')->assertJsonCount(0, 'data');
            $this->getJson('/api/notifications')->assertJsonCount(0, 'data');
        }
        $this->assertDatabaseCount('app_notifications', 1);
    }

    public function test_adviser_scope_cannot_be_overridden_or_broadcast_to_other_students(): void
    {
        $adviser = User::factory()->create(['role' => 'adviser']);
        $otherAdviser = User::factory()->create(['role' => 'adviser']);
        $assigned = User::factory()->create(['role' => 'student', 'batch_adviser_id' => $adviser->id]);
        $other = User::factory()->create(['role' => 'student', 'batch_adviser_id' => $otherAdviser->id]);
        Sanctum::actingAs($adviser);
        $this->postJson('/api/notices', $this->payload(['audience' => 'all']))->assertUnprocessable();
        $this->postJson('/api/notices', $this->payload(['target_adviser_id' => $otherAdviser->id]))
            ->assertCreated()->assertJsonPath('target_adviser_id', $adviser->id);
        $this->getJson('/api/notices')->assertJsonCount(1, 'data');
        Sanctum::actingAs($assigned);
        $this->getJson('/api/notices')->assertJsonCount(1, 'data');
        Sanctum::actingAs($other);
        $this->getJson('/api/notices')->assertJsonCount(0, 'data');
        $this->assertDatabaseHas('app_notifications', ['user_id' => $assigned->id, 'type' => 'notice']);
        $this->assertDatabaseMissing('app_notifications', ['user_id' => $other->id]);
    }

    public function test_academic_roles_can_publish_but_students_and_office_cannot(): void
    {
        foreach (['chairman', 'adviser', 'faculty', 'coordinator', 'dean'] as $role) {
            Sanctum::actingAs(User::factory()->create(['role' => $role]));
            $this->postJson('/api/notices', $this->payload())->assertCreated();
        }
        foreach (['student', 'office'] as $role) {
            Sanctum::actingAs(User::factory()->create(['role' => $role]));
            $this->postJson('/api/notices', $this->payload())->assertForbidden();
            $this->getJson('/api/notices/options')->assertForbidden();
        }
    }

    public function test_options_only_include_assigned_approved_students_for_advisers(): void
    {
        $adviser = User::factory()->create(['role' => 'adviser']);
        User::factory()->create(['role' => 'student', 'batch_adviser_id' => $adviser->id, 'batch' => '2023', 'section' => 'AI']);
        User::factory()->create(['role' => 'student', 'batch' => '2024', 'section' => 'DS']);
        User::factory()->create(['role' => 'student', 'batch_adviser_id' => $adviser->id, 'batch' => '2025', 'account_status' => 'pending']);
        Sanctum::actingAs($adviser);
        $this->getJson('/api/notices/options')->assertOk()
            ->assertJsonPath('department', ['Computer Science'])->assertJsonPath('batch', ['2023'])
            ->assertJsonPath('section', ['AI'])->assertJsonCount(1, 'students');
    }

    public function test_invalid_notice_is_rejected_without_notifications(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'faculty']));
        $this->postJson('/api/notices', $this->payload(['title' => ' ', 'body' => '', 'semester' => 9]))
            ->assertUnprocessable()->assertJsonValidationErrors(['title', 'body', 'semester']);
        $this->assertDatabaseCount('notices', 0);
        $this->assertDatabaseCount('app_notifications', 0);
    }

    public function test_unfiltered_notice_is_visible_to_all_and_existing_role_posts_still_work(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'chairman']));
        $this->postJson('/api/notices', $this->payload(['audience' => 'all']))->assertCreated();
        $this->postJson('/api/notices', $this->payload(['audience' => 'faculty']))->assertCreated();
        Sanctum::actingAs(User::factory()->create(['role' => 'faculty']));
        $this->getJson('/api/notices')->assertJsonCount(2, 'data');
        Sanctum::actingAs(User::factory()->create(['role' => 'student']));
        $this->getJson('/api/notices')->assertJsonCount(1, 'data');
    }

    public function test_faculty_can_sign_in_with_server_assigned_role(): void
    {
        User::factory()->create(['role' => 'faculty', 'email' => 'faculty@uetmardan.edu.pk']);
        $this->postJson('/api/login', ['email' => 'faculty@uetmardan.edu.pk', 'password' => 'password', 'role' => 'faculty'])
            ->assertOk()->assertJsonPath('user.role', 'faculty');
    }
}
