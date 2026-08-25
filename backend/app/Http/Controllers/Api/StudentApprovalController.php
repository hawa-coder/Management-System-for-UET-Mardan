<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class StudentApprovalController extends Controller
{
    public function index(Request $request)
    {
        abort_unless($request->user()->role === 'adviser', 403);

        return response()->json([
            'data' => $request->user()->advisedStudents()
                ->where('role', 'student')
                ->where('account_status', 'pending')
                ->latest()
                ->get(['id', 'name', 'email', 'registration_number', 'batch', 'semester', 'section', 'mobile_number']),
        ]);
    }

    public function update(Request $request, User $student)
    {
        $adviser = $request->user();
        abort_unless($adviser->role === 'adviser', 403);
        abort_unless($student->role === 'student' && $student->batch_adviser_id === $adviser->id, 403);

        $data = $request->validate([
            'action' => ['required', 'in:approve,reject'],
        ]);

        $student->update([
            'account_status' => $data['action'] === 'approve' ? 'approved' : 'rejected',
        ]);

        return response()->json(['message' => "Student account {$data['action']}d successfully."]);
    }
}
