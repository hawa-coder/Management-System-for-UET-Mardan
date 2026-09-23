<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureAccountCanAccessApi
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        abort_unless($user && $user->is_active, 403, 'This account has been disabled.');
        abort_if($user->account_status === 'rejected', 403, 'Your account request was rejected.');
        // Pending students can view their approval status, but cannot submit complaints.
        abort_if($user->account_status === 'pending' && $user->role !== 'student',
            403, 'Your account is waiting for approval.');

        return $next($request);
    }
}
