<?php

namespace App\Providers;

use Illuminate\Support\Facades\Route;

class RouteServiceProvider extends \Illuminate\Foundation\Support\Providers\RouteServiceProvider
{
    public function boot(): void
    {
        $this->routes(function () {
            Route::middleware('api')->prefix('api')->group(base_path('routes/api.php'));
            Route::middleware('web')->group(base_path('routes/web.php'));
            Route::get('/up', fn () => response()->json(['status' => 'ok']));
        });
    }
}
