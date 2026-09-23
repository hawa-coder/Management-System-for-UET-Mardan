<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * A basic test example.
     */
    public function test_the_application_returns_a_successful_response(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200);

        if (is_file(public_path('site/index.html'))) {
            $this->assertInstanceOf(\Symfony\Component\HttpFoundation\BinaryFileResponse::class, $response->baseResponse);
            $this->assertSame(realpath(public_path('site/index.html')), $response->baseResponse->getFile()->getRealPath());
            $this->assertStringContainsString('<base href="/dept_comp/public/site/">', file_get_contents(public_path('site/index.html')));
        }
    }
}
