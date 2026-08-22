<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email:rfc', 'ends_with:@uetmardan.edu.pk'],
            'password' => ['required', 'string'],
            'role' => ['required', 'in:student,adviser,coordinator,chairman,office,dean'],
        ]);

        $user = User::where('email', strtolower($credentials['email']))->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages(['email' => ['Invalid email or password.']]);
        }

        if (! $user->is_active) {
            abort(403, 'This account has been disabled.');
        }

        if ($user->role !== $credentials['role']) {
            abort(403, 'The selected portal role is not assigned to this account.');
        }

        $user->tokens()->delete();
        $token = $user->createToken('dcmcs-mobile')->plainTextToken;

        return response()->json(['token' => $token, 'user' => $user]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function profile(Request $request)
    {
        return response()->json($request->user());
    }
}
