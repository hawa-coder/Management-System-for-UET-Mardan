<?php

namespace App\Http\Middleware;

class TrimStrings extends \Illuminate\Foundation\Http\Middleware\TrimStrings
{
    protected $except = ['current_password', 'password', 'password_confirmation'];
}
