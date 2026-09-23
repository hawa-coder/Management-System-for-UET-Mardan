<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Complaint;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BackendCompatibilityTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_preflight_allows_flutter_authorization_header(): void
    {
        $this->withHeaders([
            'Origin' => 'https://client.example.test',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'authorization,content-type',
        ])->options('/api/complaints')->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', '*');
    }

    public function test_protected_api_requires_a_token(): void
    {
        $this->getJson('/api/profile')->assertUnauthorized();
    }

    public function test_bearer_token_upload_signed_download_and_notifications(): void
    {
        Storage::fake('local');
        $user = User::factory()->create(['role' => 'student', 'account_status' => 'approved']);
        $token = $user->createToken('compatibility-test')->plainTextToken;
        $this->withToken($token)->getJson('/api/profile')->assertOk();
        $response = $this->withToken($token)->postJson('/api/complaints', [
            'title' => 'Attachment test',
            'details' => 'A complaint with a PDF attachment.',
            'category' => 'Academic',
            'priority' => 'Medium',
            'attachment' => UploadedFile::fake()->create('evidence.pdf', 20, 'application/pdf'),
        ])->assertCreated();
        $complaint = Complaint::findOrFail($response->json('id'));
        Storage::disk('local')->assertExists($complaint->attachment_path);
        $this->get($response->json('attachment_url'))->assertOk();
        $this->get('/api/complaints/'.$complaint->id.'/attachment')->assertForbidden();
        $notification = AppNotification::where('user_id', $user->id)->firstOrFail();
        $this->withToken($token)->postJson('/api/notifications/'.$notification->id.'/read')->assertOk();
        $this->assertInstanceOf(\DateTimeInterface::class, $notification->fresh()->read_at);
    }
}
