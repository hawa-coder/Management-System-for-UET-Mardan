<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    $website = public_path('site/index.html');
    if (is_file($website)) {
        return response()->file($website, ['Cache-Control' => 'no-cache']);
    }

    return view('welcome');
});
