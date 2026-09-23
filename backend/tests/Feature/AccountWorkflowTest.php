<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AccountWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_disabled_or_rejected_accounts_cannot_keep_using_existing_tokens(): void
    {
        foreach ([['is_active' => false], ['account_status' => 'rejected']] as $state) {
            $user = User::factory()->create($state);
            $token = $user->createToken('existing-session')->plainTextToken;
            $this->app['auth']->forgetGuards();
            $this->withToken($token)->getJson('/api/profile')->assertForbidden();
        }
    }

    public function test_coordinator_can_list_and_approve_advisers(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'coordinator']));
        $adviser = User::factory()->create(['role' => 'adviser', 'account_status' => 'pending']);
        $this->getJson('/api/adviser-approvals')->assertOk()->assertJsonPath('data.0.id', $adviser->id);
        $this->postJson('/api/adviser-approvals/'.$adviser->id, ['action' => 'approve'])
            ->assertOk()->assertJsonPath('adviser.account_status', 'approved');
    }

    public function test_adviser_cannot_approve_another_advisers_student(): void
    {
        $adviser = User::factory()->create(['role' => 'adviser']);
        $student = User::factory()->create(['role' => 'student', 'batch_adviser_id' => $adviser->id, 'account_status' => 'pending']);
        Sanctum::actingAs(User::factory()->create(['role' => 'adviser']));
        $this->postJson('/api/student-approvals/'.$student->id, ['action' => 'approve'])->assertForbidden();
        Sanctum::actingAs($adviser);
        $this->postJson('/api/student-approvals/'.$student->id, ['action' => 'approve'])->assertOk();
        $this->assertSame('approved', $student->fresh()->account_status);
    }

    public function test_password_reset_expires_and_revokes_existing_tokens(): void
    {
        $user = User::factory()->create(['email' => 'reset-test@uetmardan.edu.pk']);
        $user->createToken('old-session');
        DB::table('password_reset_tokens')->insert([
            'email' => $user->email, 'token' => Hash::make('123456'), 'created_at' => now()->subMinutes(16),
        ]);
        $payload = ['email' => $user->email, 'code' => '123456', 'password' => 'Replacement@123', 'password_confirmation' => 'Replacement@123'];
        $this->postJson('/api/reset-password', $payload)->assertUnprocessable();
        DB::table('password_reset_tokens')->where('email', $user->email)->update(['created_at' => now()]);
        $this->postJson('/api/reset-password', $payload)->assertOk();
        $this->assertTrue(Hash::check('Replacement@123', $user->fresh()->password));
        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->assertDatabaseCount('password_reset_tokens', 0);
    }

    public function test_chairman_can_publish_notice_and_student_cannot(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'chairman']));
        $payload = ['title' => 'Test notice', 'body' => 'Notice body', 'audience' => 'student'];
        $this->postJson('/api/notices', $payload)->assertCreated();
        Sanctum::actingAs(User::factory()->create(['role' => 'student']));
        $this->getJson('/api/notices')->assertOk()->assertJsonPath('data.0.title', 'Test notice');
        $this->postJson('/api/notices', $payload)->assertForbidden();
    }
}
