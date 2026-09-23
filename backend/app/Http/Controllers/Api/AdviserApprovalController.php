<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AdviserApprovalController extends Controller
{
    public function store(Request $request)
    {
        abort_unless($request->user()->role === 'coordinator', 403);

        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email:rfc', 'ends_with:@uetmardan.edu.pk', 'unique:users,email'],
            'batch' => ['required', 'string', 'max:30'],
            'semester' => ['required', 'integer', 'between:1,8'],
            'section' => ['required', 'in:A,B,C,D,AI,DS,CS'],
        ]);
        $email = strtolower($data['email']);
        $code = (string) random_int(100000, 999999);

        $adviser = User::create([
            ...$data,
            'email' => $email,
            'password' => Str::password(32),
            'role' => 'adviser',
            'account_status' => 'pending',
            'is_active' => true,
        ]);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $email],
            ['token' => Hash::make($code), 'created_at' => now()],
        );
        Mail::raw(
            "Your DCMCS adviser setup code is {$code}. It expires in 15 minutes. After coordinator approval, use Forgot Password to create your password.",
            fn ($message) => $message->to($email)->subject('Batch adviser account setup'),
        );

        return response()->json([
            'message' => 'Batch adviser added as pending. A password setup code was sent by email.',
            'adviser' => $adviser->only(['id', 'name', 'email', 'batch', 'semester', 'section', 'account_status']),
        ], 201);
    }

    public function index(Request $request)
    {
        abort_unless($request->user()->role === 'coordinator', 403);

        return response()->json([
            'data' => User::query()
                ->where('role', 'adviser')
                ->where('is_active', true)
                ->orderByRaw("CASE account_status WHEN 'pending' THEN 0 WHEN 'approved' THEN 1 WHEN 'rejected' THEN 2 ELSE 3 END")
                ->orderBy('name')
                ->get(['id', 'name', 'email', 'batch', 'semester', 'section', 'account_status']),
        ]);
    }

    public function update(Request $request, User $adviser)
    {
        abort_unless($request->user()->role === 'coordinator', 403);
        abort_unless($adviser->role === 'adviser', 422, 'This user is not a batch adviser.');

        $data = $request->validate([
            'action' => ['required', 'in:approve,reject'],
        ]);

        $adviser->update([
            'account_status' => $data['action'] === 'approve' ? 'approved' : 'rejected',
        ]);

        return response()->json([
            'message' => "Batch adviser {$data['action']}d successfully.",
            'adviser' => $adviser->only(['id', 'name', 'email', 'batch', 'semester', 'section', 'account_status']),
        ]);
    }
}
