<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiAuthenticationTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_can_create_an_account(): void
    {
        $adviser = User::factory()->create([
            'name' => 'Dr. Ahmad',
            'role' => 'adviser',
            'batch' => '2023',
            'section' => 'A',
            'account_status' => 'approved',
        ]);

        $response = $this->postJson('/api/register', [
            'name' => 'Hawa Sabir',
            'email' => '2023cs009@uetmardan.edu.pk',
            'registration_number' => '2023-CS-009',
            'semester' => 5,
            'section' => 'A',
            'mobile_number' => '03001234567',
            'batch_adviser_id' => $adviser->id,
            'password' => 'Student@123',
            'password_confirmation' => 'Student@123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('message', 'Account submitted. Your batch adviser must approve it before you can sign in.');
        $this->assertDatabaseHas('users', [
            'email' => '2023cs009@uetmardan.edu.pk',
            'role' => 'student',
            'registration_number' => '2023-CS-009',
            'batch' => '2023',
            'batch_adviser_id' => $adviser->id,
            'account_status' => 'pending',
        ]);
    }

    public function test_registration_rejects_a_duplicate_student(): void
    {
        User::factory()->create([
            'role' => 'adviser',
            'batch' => '2023',
            'section' => 'A',
        ]);
        User::factory()->create([
            'email' => '2023cs009@uetmardan.edu.pk',
            'registration_number' => '2023-CS-009',
        ]);

        $this->postJson('/api/register', [
            'name' => 'Hawa Sabir',
            'email' => '2023cs009@uetmardan.edu.pk',
            'registration_number' => '2023-CS-009',
            'semester' => 5,
            'section' => 'A',
            'mobile_number' => '03001234567',
            'password' => 'Student@123',
            'password_confirmation' => 'Student@123',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'registration_number']);
    }

    public function test_registration_requires_an_available_approved_adviser(): void
    {
        $adviser = User::factory()->create([
            'role' => 'adviser',
            'account_status' => 'pending',
        ]);

        $this->postJson('/api/register', [
            'name' => 'Hawa Sabir',
            'email' => '2023cs009@uetmardan.edu.pk',
            'registration_number' => '2023-CS-009',
            'semester' => 5,
            'section' => 'A',
            'mobile_number' => '03001234567',
            'batch_adviser_id' => $adviser->id,
            'password' => 'Student@123',
            'password_confirmation' => 'Student@123',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('batch_adviser_id');
    }

    public function test_user_can_login_with_the_assigned_role(): void
    {
        $user = User::factory()->create([
            'email' => 'chairman@uetmardan.edu.pk',
            'password' => 'Chairman@123',
            'role' => 'chairman',
        ]);

        $response = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'Chairman@123',
            'role' => 'chairman',
        ]);

        $response->assertOk()->assertJsonPath('user.role', 'chairman')->assertJsonStructure(['token', 'user']);
    }

    public function test_login_rejects_an_unassigned_role(): void
    {
        User::factory()->create([
            'email' => 'adviser@uetmardan.edu.pk',
            'password' => 'Adviser@123',
            'role' => 'adviser',
        ]);

        $this->postJson('/api/login', [
            'email' => 'adviser@uetmardan.edu.pk',
            'password' => 'Adviser@123',
            'role' => 'chairman',
        ])->assertForbidden();
    }

    public function test_login_rejects_an_incorrect_password(): void
    {
        User::factory()->create([
            'email' => '2023cs001@uetmardan.edu.pk',
            'password' => 'Student@123',
            'role' => 'student',
        ]);

        $this->postJson('/api/login', [
            'email' => '2023cs001@uetmardan.edu.pk',
            'password' => 'WrongPassword@1',
            'role' => 'student',
        ])->assertUnprocessable();
    }
}
