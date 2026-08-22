<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiAuthenticationTest extends TestCase
{
    use RefreshDatabase;

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
