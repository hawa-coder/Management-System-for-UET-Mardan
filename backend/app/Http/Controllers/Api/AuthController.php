<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function advisers()
    {
        return response()->json([
            'data' => User::query()
                ->where('role', 'adviser')
                ->where('is_active', true)
                ->where('account_status', 'approved')
                ->orderBy('name')
                ->get(['id', 'name', 'batch', 'semester', 'section']),
        ]);
    }

    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email:rfc', 'ends_with:@uetmardan.edu.pk', 'unique:users,email'],
            'registration_number' => ['required', 'string', 'max:50', 'unique:users,registration_number'],
            'semester' => ['required', 'integer', 'between:1,8'],
            'section' => ['required', 'in:A,B,C,D,AI,DS,CS'],
            'mobile_number' => ['required', 'regex:/^03[0-9]{9}$/'],
            'batch_adviser_id' => ['required', 'integer', 'exists:users,id'],
            'password' => ['required', 'confirmed', 'min:8', 'regex:/[a-z]/', 'regex:/[A-Z]/', 'regex:/[0-9]/', 'regex:/[^A-Za-z0-9]/'],
        ]);

        preg_match('/^(\d{4})/', $data['registration_number'], $batchMatch);
        if (! isset($batchMatch[1])) {
            throw ValidationException::withMessages([
                'registration_number' => ['Registration number must begin with the four-digit batch year.'],
            ]);
        }

        $adviser = User::query()
            ->whereKey($data['batch_adviser_id'])
            ->where('role', 'adviser')
            ->where('is_active', true)
            ->where('account_status', 'approved')
            ->first();
        if (! $adviser) {
            throw ValidationException::withMessages([
                'batch_adviser_id' => ['Please select an available batch adviser.'],
            ]);
        }

        $user = User::create([
            ...$data,
            'email' => strtolower($data['email']),
            'registration_number' => strtoupper($data['registration_number']),
            'section' => strtoupper($data['section']),
            'batch' => $batchMatch[1],
            'batch_adviser_id' => $adviser->id,
            'role' => 'student',
            'account_status' => 'pending',
        ]);

        return response()->json([
            'message' => 'Account submitted. Your batch adviser must approve it before you can sign in.',
        ], 201);
    }

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

        if ($user->account_status === 'pending' && $user->role !== 'student') {
            abort(403, 'Your account is waiting for batch adviser approval.');
        }

        if ($user->account_status === 'rejected') {
            abort(403, 'Your account request was rejected by the batch adviser.');
        }

        if ($user->role !== $credentials['role']) {
            abort(403, 'The selected portal role is not assigned to this account.');
        }

        $user->tokens()->delete();
        $token = $user->createToken('dcmcs-mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $user->load('batchAdviser:id,name'),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function profile(Request $request)
    {
        return response()->json($request->user()->load('batchAdviser:id,name'));
    }

    public function changePassword(Request $request)
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', 'min:8', 'regex:/[a-z]/', 'regex:/[A-Z]/', 'regex:/[0-9]/', 'regex:/[^A-Za-z0-9]/'],
        ]);

        if (! Hash::check($data['current_password'], $request->user()->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['The current password is incorrect.'],
            ]);
        }

        $request->user()->update(['password' => $data['password']]);
        $request->user()->tokens()->where('id', '!=', $request->user()->currentAccessToken()?->id)->delete();

        return response()->json(['message' => 'Password changed successfully.']);
    }

    public function forgotPassword(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email:rfc', 'ends_with:@uetmardan.edu.pk'],
        ]);
        $email = strtolower($data['email']);
        $user = User::where('email', $email)->first();

        if ($user) {
            $code = (string) random_int(100000, 999999);
            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $email],
                ['token' => Hash::make($code), 'created_at' => now()],
            );
            Mail::raw(
                "Your DCMCS password reset code is {$code}. It expires in 15 minutes.",
                fn ($message) => $message->to($email)->subject('DCMCS password reset code'),
            );
        }

        return response()->json([
            'message' => 'If that account exists, a six-digit reset code has been sent to its university email.',
        ]);
    }

    public function resetPassword(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email:rfc', 'ends_with:@uetmardan.edu.pk'],
            'code' => ['required', 'digits:6'],
            'password' => ['required', 'confirmed', 'min:8', 'regex:/[a-z]/', 'regex:/[A-Z]/', 'regex:/[0-9]/', 'regex:/[^A-Za-z0-9]/'],
        ]);
        $email = strtolower($data['email']);
        $reset = DB::table('password_reset_tokens')->where('email', $email)->first();

        if (! $reset || now()->diffInMinutes($reset->created_at, absolute: true) > 15
            || ! Hash::check($data['code'], $reset->token)) {
            throw ValidationException::withMessages(['code' => ['The reset code is invalid or expired.']]);
        }

        $user = User::where('email', $email)->firstOrFail();
        $user->update(['password' => $data['password']]);
        $user->tokens()->delete();
        DB::table('password_reset_tokens')->where('email', $email)->delete();

        return response()->json(['message' => 'Password reset successfully. You can now sign in.']);
    }
}
