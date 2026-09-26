<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class RegistrationValidationTest extends TestCase
{
    use RefreshDatabase;

    private function registration(array $overrides = []): array
    {
        $adviser = User::factory()->create(['role' => 'adviser', 'account_status' => 'approved']);

        return array_replace([
            'name' => 'Registration Test',
            'email' => '0425@uetmardan.edu.pk',
            'registration_number' => '23MDBCS425',
            'semester' => 5,
            'section' => 'AI',
            'mobile_number' => '03001234567',
            'batch_adviser_id' => $adviser->id,
            'password' => 'TestOnly@123',
            'password_confirmation' => 'TestOnly@123',
        ], $overrides);
    }

    public function test_spaces_and_letter_case_are_normalized_before_registration(): void
    {
        $this->postJson('/api/register', $this->registration([
            'registration_number' => ' 23mdbcs425 ',
            'email' => ' Student.Name@UETMARDAN.EDU.PK ',
        ]))->assertCreated();

        $this->assertDatabaseHas('users', [
            'registration_number' => '23MDBCS425',
            'email' => 'student.name@uetmardan.edu.pk',
            'batch' => '23',
        ]);
    }

    public static function duplicateFields(): array
    {
        return [
            'registration letter case' => ['registration_number', '23mdbcs425'],
            'email letter case' => ['email', 'STUDENT@uetmardan.edu.pk'],
        ];
    }

    #[\PHPUnit\Framework\Attributes\DataProvider('duplicateFields')]
    public function test_duplicate_checks_use_normalized_values(string $field, string $value): void
    {
        User::factory()->create([
            'email' => 'student@uetmardan.edu.pk',
            'registration_number' => '23MDBCS425',
        ]);
        $payload = $this->registration([
            'email' => 'another@uetmardan.edu.pk',
            'registration_number' => '23MDBCS426',
            $field => $value,
        ]);
        $count = User::count();

        $this->postJson('/api/register', $payload)->assertUnprocessable()
            ->assertJsonValidationErrors($field);
        $this->assertDatabaseCount('users', $count);
    }

    public static function invalidRegistrationNumbers(): array
    {
        return [
            [''], ['MDBCS425'], ['2MDBCS425'], ['12345MDBCS425'],
            [str_repeat('2', 51)], [123], [['23MDBCS425']],
        ];
    }

    #[\PHPUnit\Framework\Attributes\DataProvider('invalidRegistrationNumbers')]
    public function test_invalid_registration_numbers_return_validation_errors(mixed $registration): void
    {
        $payload = $this->registration(['registration_number' => $registration]);
        $count = User::count();
        $this->postJson('/api/register', $payload)->assertUnprocessable()
            ->assertJsonValidationErrors('registration_number');
        $this->assertDatabaseCount('users', $count);
    }

    public static function unavailableAdvisers(): array
    {
        return [
            [['role' => 'student']],
            [['is_active' => false]],
            [['account_status' => 'pending']],
            [['account_status' => 'rejected']],
        ];
    }

    #[\PHPUnit\Framework\Attributes\DataProvider('unavailableAdvisers')]
    public function test_short_prefix_does_not_bypass_adviser_checks(array $state): void
    {
        $payload = $this->registration();
        User::findOrFail($payload['batch_adviser_id'])->update($state);
        $this->postJson('/api/register', $payload)->assertUnprocessable()
            ->assertJsonValidationErrors('batch_adviser_id');
        $this->assertDatabaseMissing('users', ['registration_number' => '23MDBCS425']);
    }

    public function test_short_registration_completes_approval_login_and_complaint_workflow(): void
    {
        $payload = $this->registration();
        $this->postJson('/api/register', $payload)->assertCreated();
        $student = User::where('registration_number', '23MDBCS425')->firstOrFail();
        $this->assertSame('pending', $student->account_status);
        $this->assertTrue(Hash::check($payload['password'], $student->password));

        $credentials = ['email' => $payload['email'], 'password' => $payload['password'], 'role' => 'student'];
        $login = $this->postJson('/api/login', $credentials)->assertOk();
        $studentToken = $login->json('token');
        $complaint = ['title' => 'Registration workflow check', 'details' => 'Test complaint details.', 'category' => 'Academic', 'priority' => 'Medium'];
        $this->withToken($studentToken)->getJson('/api/profile')->assertOk()
            ->assertJsonPath('registration_number', '23MDBCS425');
        $this->withToken($studentToken)->postJson('/api/complaints', $complaint)->assertForbidden();

        $this->app['auth']->forgetGuards();
        $adviserToken = User::findOrFail($payload['batch_adviser_id'])->createToken('test-adviser')->plainTextToken;
        $this->withToken($adviserToken)->getJson('/api/student-approvals')->assertOk()
            ->assertJsonPath('data.0.registration_number', '23MDBCS425');
        $this->withToken($adviserToken)->postJson('/api/student-approvals/'.$student->id, ['action' => 'approve'])->assertOk();

        $this->app['auth']->forgetGuards();
        $this->withToken($studentToken)->getJson('/api/profile')->assertOk()
            ->assertJsonPath('account_status', 'approved');
        $this->withToken($studentToken)->postJson('/api/complaints', $complaint)->assertCreated();
        $this->postJson('/api/login', array_replace($credentials, ['role' => 'coordinator']))->assertForbidden();
    }
}
