<?php

namespace Tests\Feature;

use App\Models\{User, Notice, Course};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NoticeSystemTest extends TestCase
{
    use RefreshDatabase;

    private function publish(User $author, array $extra = []): int
    {
        Sanctum::actingAs($author);
        return $this->postJson('/api/notices', array_merge([
            'title' => 'Project meeting', 'body' => 'Meet in the project lab.', 'audience' => 'student',
            'category' => 'FYP', 'priority' => 'Important', 'notice_date' => now()->toISOString(),
        ], $extra))->assertCreated()->json('id');
    }

    public function test_multiple_values_are_or_within_groups_and_and_between_groups(): void
    {
        $author = User::factory()->create(['role' => 'chairman']);
        $base = ['role' => 'student', 'department' => 'Computer Science', 'batch' => 'FA23', 'semester' => 7, 'section' => 'A'];
        $matches = collect([$base, array_merge($base, ['batch' => 'SP24', 'semester' => 6])])->map(fn ($a) => User::factory()->create($a));
        $excluded = collect([['batch' => 'FA25'], ['semester' => 2], ['section' => 'B'], ['department' => 'Electrical Engineering']])
            ->map(fn ($a) => User::factory()->create(array_merge($base, $a)));
        $id = $this->publish($author, ['departments' => ['Computer Science'], 'batches' => ['FA23', 'SP24'], 'semesters' => [6, 7], 'sections' => ['A']]);
        foreach ($matches as $student) {
            Sanctum::actingAs($student);
            $this->getJson('/api/notices')->assertJsonPath('data.0.id', $id);
            $this->getJson('/api/notifications')->assertJsonPath('data.0.notice_id', $id);
        }
        foreach ($excluded as $student) {
            Sanctum::actingAs($student);
            $this->getJson('/api/notices')->assertJsonCount(0, 'data');
            $this->getJson('/api/notices/'.$id)->assertNotFound();
            $this->getJson('/api/notifications')->assertJsonCount(0, 'data');
        }
    }

    public function test_faculty_cannot_escape_teaching_scope_and_permission_explicitly_enables_department(): void
    {
        $faculty = User::factory()->create(['role' => 'faculty']);
        $otherFaculty = User::factory()->create(['role' => 'faculty']);
        $enrolled = User::factory()->create(['role' => 'student']);
        $outsider = User::factory()->create(['role' => 'student']);
        $course = Course::create(['code' => 'CS301-A', 'name' => 'Algorithms A', 'faculty_id' => $faculty->id]);
        $course->students()->attach($enrolled);
        $otherCourse = Course::create(['code' => 'CS301-B', 'name' => 'Algorithms B', 'faculty_id' => $otherFaculty->id]);
        $otherCourse->students()->attach($outsider);
        $id = $this->publish($faculty, ['target_faculty_id' => null, 'can_publish_department_notices' => true]);
        $this->getJson('/api/notices/options')->assertJsonPath('faculty_restricted', true)->assertJsonCount(1, 'courses')->assertJsonCount(1, 'students');
        $this->postJson('/api/notices', ['title' => 'Invalid student', 'body' => 'Text', 'student_ids' => [$outsider->id]])->assertUnprocessable();
        $this->postJson('/api/notices', ['title' => 'Invalid course', 'body' => 'Text', 'course_ids' => [$otherCourse->id]])->assertUnprocessable();
        Sanctum::actingAs($enrolled);
        $this->getJson('/api/notices/'.$id)->assertOk();
        Sanctum::actingAs($outsider);
        $this->getJson('/api/notices/'.$id)->assertNotFound();
        $this->getJson('/api/notifications')->assertJsonCount(0, 'data');
        $faculty->update(['can_publish_department_notices' => true]);
        $broadcast = $this->publish($faculty->fresh());
        Sanctum::actingAs($outsider);
        $this->getJson('/api/notices/'.$broadcast)->assertOk();
    }

    public function test_course_and_individual_student_targets_and_enrollment_changes_are_enforced(): void
    {
        $faculty = User::factory()->create(['role' => 'faculty']);
        $a = User::factory()->create(['role' => 'student']);
        $b = User::factory()->create(['role' => 'student']);
        $course = Course::create(['code' => 'CS402', 'name' => 'AI', 'faculty_id' => $faculty->id]);
        $course->students()->attach([$a->id, $b->id]);
        $id = $this->publish($faculty, ['course_ids' => [$course->id], 'student_ids' => [$a->id]]);
        Sanctum::actingAs($b);
        $this->getJson('/api/notices/'.$id)->assertNotFound();
        Sanctum::actingAs($a);
        $this->getJson('/api/notices/'.$id)->assertOk();
        $course->students()->detach($a);
        $this->getJson('/api/notices/'.$id)->assertNotFound();
        $this->getJson('/api/notifications')->assertJsonCount(0, 'data');
    }

    public function test_scheduling_expiry_delivery_and_read_tracking(): void
    {
        $this->travelTo(now()->startOfMinute());
        $author = User::factory()->create(['role' => 'chairman']);
        $student = User::factory()->create(['role' => 'student']);
        $id = $this->publish($author, ['notice_date' => now()->addHour()->toISOString(), 'expires_at' => now()->addHours(2)->toISOString()]);
        $this->getJson('/api/notices?mine=1')->assertJsonPath('data.0.status', 'Scheduled');
        Sanctum::actingAs($student);
        $this->getJson('/api/notices')->assertJsonCount(0, 'data');
        $this->getJson('/api/notices/'.$id)->assertNotFound();
        $this->assertDatabaseCount('app_notifications', 0);
        $this->travel(61)->minutes();
        $this->artisan('notices:dispatch')->assertSuccessful();
        $this->artisan('notices:dispatch')->assertSuccessful();
        $this->assertDatabaseCount('app_notifications', 1);
        $this->getJson('/api/notices?read=unread')->assertJsonCount(1, 'data')->assertJsonPath('data.0.is_read', false);
        $this->getJson('/api/notices/'.$id)->assertOk()->assertJsonPath('is_read', true);
        $this->getJson('/api/notices?read=unread')->assertJsonCount(0, 'data');
        $this->getJson('/api/notices?read=read')->assertJsonCount(1, 'data');
        $this->assertDatabaseHas('notice_reads', ['notice_id' => $id, 'user_id' => $student->id]);
        $this->assertNotNull($this->getJson('/api/notifications')->json('data.0.read_at'));
        $this->travel(60)->minutes();
        $this->getJson('/api/notices')->assertJsonCount(0, 'data');
        $this->getJson('/api/notices/'.$id)->assertNotFound();
        $this->getJson('/api/notifications')->assertJsonCount(0, 'data');
        Sanctum::actingAs($author);
        $this->getJson('/api/notices?mine=1&status=Expired')->assertJsonPath('data.0.id', $id);
    }

    public function test_owner_management_retargets_notifications_and_republish_resets_read_state(): void
    {
        $author = User::factory()->create(['role' => 'chairman']);
        $other = User::factory()->create(['role' => 'chairman']);
        $a = User::factory()->create(['role' => 'student', 'batch' => 'FA23']);
        $b = User::factory()->create(['role' => 'student', 'batch' => 'SP24']);
        $id = $this->publish($author, ['batches' => ['FA23']]);
        Sanctum::actingAs($other);
        $this->postJson('/api/notices/'.$id.'/update', ['title' => 'Hijack', 'body' => 'Bad'])->assertForbidden();
        $this->deleteJson('/api/notices/'.$id)->assertForbidden();
        $this->postJson('/api/notices/'.$id.'/republish')->assertForbidden();
        Sanctum::actingAs($author);
        $this->postJson('/api/notices/'.$id.'/update', ['title' => 'Changed', 'body' => 'Updated message', 'batches' => ['SP24']])->assertOk();
        $this->assertDatabaseMissing('app_notifications', ['notice_id' => $id, 'user_id' => $a->id]);
        $this->assertDatabaseHas('app_notifications', ['notice_id' => $id, 'user_id' => $b->id]);
        Sanctum::actingAs($a);
        $this->getJson('/api/notices/'.$id)->assertNotFound();
        Sanctum::actingAs($b);
        $this->getJson('/api/notices/'.$id)->assertOk();
        Sanctum::actingAs($author);
        $this->postJson('/api/notices/'.$id.'/republish')->assertOk();
        $this->assertDatabaseMissing('notice_reads', ['notice_id' => $id]);
        $this->assertDatabaseHas('app_notifications', ['notice_id' => $id, 'user_id' => $b->id, 'read_at' => null]);
        $this->deleteJson('/api/notices/'.$id)->assertOk();
        $this->assertDatabaseMissing('notices', ['id' => $id]);
        $this->assertDatabaseCount('app_notifications', 0);
    }

    public function test_attachment_is_private_validated_and_deleted_with_notice(): void
    {
        Storage::fake('local');
        $author = User::factory()->create(['role' => 'chairman']);
        $student = User::factory()->create(['role' => 'student', 'batch' => 'FA23']);
        $outsider = User::factory()->create(['role' => 'student', 'batch' => 'SP24']);
        Sanctum::actingAs($author);
        $id = $this->post('/api/notices', [
            'notice_data' => json_encode(['title' => 'Date sheet', 'body' => 'See PDF', 'batches' => ['FA23']]),
            'attachment' => UploadedFile::fake()->create('datesheet.pdf', 20, 'application/pdf'),
        ], ['Accept' => 'application/json'])->assertCreated()->assertJsonMissingPath('attachment_path')->json('id');
        $path = Notice::findOrFail($id)->attachment_path;
        Storage::assertExists($path);
        Sanctum::actingAs($outsider);
        $this->getJson('/api/notices/'.$id)->assertNotFound();
        $this->get('/api/notices/'.$id.'/attachment')->assertForbidden();
        Sanctum::actingAs($student);
        $url = $this->getJson('/api/notices/'.$id)->assertOk()->json('attachment_url');
        $this->get($url)->assertOk()->assertDownload('datesheet.pdf');
        $student->update(['batch' => 'SP24']);
        $this->get($url)->assertForbidden();
        Sanctum::actingAs($author);
        $this->post('/api/notices', ['title' => 'Unsafe file', 'body' => 'Text', 'attachment' => UploadedFile::fake()->create('script.exe', 20, 'application/octet-stream')], ['Accept' => 'application/json'])->assertUnprocessable();
        $this->deleteJson('/api/notices/'.$id)->assertOk();
        Storage::assertMissing($path);
    }

    public function test_priority_category_search_date_filters_and_notification_read_all(): void
    {
        $author = User::factory()->create(['role' => 'chairman']);
        $student = User::factory()->create(['role' => 'student']);
        $urgent = $this->publish($author, ['title' => 'Urgent exam', 'priority' => 'Urgent', 'category' => 'Examination']);
        $this->publish($author, ['title' => 'Normal event', 'priority' => 'Normal', 'category' => 'Events']);
        Sanctum::actingAs($student);
        $this->getJson('/api/notices')->assertJsonPath('data.0.id', $urgent);
        $this->getJson('/api/notices?category=Examination&priority=Urgent&search=exam&from='.now()->toDateString().'&to='.now()->toDateString())
            ->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $urgent);
        $this->postJson('/api/notifications/read-all')->assertOk();
        $this->getJson('/api/notices?read=unread')->assertJsonCount(0, 'data');
        $this->getJson('/api/notices?read=read')->assertJsonCount(2, 'data');
    }

    public function test_default_publication_date_and_administrator_permission_command(): void
    {
        $faculty = User::factory()->create(['role' => 'faculty']);
        $this->artisan('notices:faculty-permission', ['email' => $faculty->email])->assertSuccessful();
        $this->assertTrue($faculty->fresh()->can_publish_department_notices);
        $this->artisan('notices:faculty-permission', ['email' => $faculty->email, '--revoke' => true])->assertSuccessful();
        $this->assertFalse($faculty->fresh()->can_publish_department_notices);
        Sanctum::actingAs($faculty);
        $this->postJson('/api/notices', ['title' => 'Today', 'body' => 'Details', 'expires_at' => now()->addDay()->toISOString()])
            ->assertCreated()->assertJsonPath('status', 'Active');
        $this->postJson('/api/notices', ['title' => 'Invalid expiry', 'body' => 'Details', 'expires_at' => now()->subDay()->toISOString()])
            ->assertUnprocessable()->assertJsonValidationErrors('expires_at');
    }
}
