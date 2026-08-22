<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notice;
use Illuminate\Http\Request;

class NoticeController extends Controller
{
    public function index(Request $request)
    {
        return response()->json(Notice::with('publisher:id,name,role')
            ->whereNotNull('published_at')
            ->where(fn ($query) => $query->where('audience', 'all')->orWhere('audience', $request->user()->role))
            ->latest('published_at')->paginate(20));
    }

    public function store(Request $request)
    {
        abort_unless($request->user()->role === 'chairman', 403, 'Only the chairman can publish notices.');
        $data = $request->validate([
            'title' => ['required', 'string', 'max:180'],
            'body' => ['required', 'string', 'max:10000'],
            'audience' => ['required', 'in:all,student,adviser,coordinator,chairman,office,dean'],
        ]);
        $notice = Notice::create($data + ['published_by' => $request->user()->id, 'published_at' => now()]);

        return response()->json($notice, 201);
    }
}
