<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class AdviserApprovalController extends Controller
{
    public function index(Request $request)
    {
        abort_unless($request->user()->role === 'coordinator', 403);

        return response()->json([
            'data' => User::query()
                ->where('role', 'adviser')
                ->where('is_active', true)
                ->orderByRaw("FIELD(account_status, 'pending', 'approved', 'rejected')")
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
