<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Notice;
use App\Services\NoticeDelivery;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        app(NoticeDelivery::class)->dispatchDue();
        return response()->json(AppNotification::visibleTo($request->user())->latest()->paginate(30));
    }

    public function read(Request $request, AppNotification $notification)
    {
        abort_unless(AppNotification::whereKey($notification->id)->visibleTo($request->user())->exists(), 403);
        $notification->update(['read_at' => now()]);
        if ($notification->notice_id) $notification->notice->markRead($request->user());

        return response()->json(['message' => 'Notification marked as read.']);
    }

    public function readAll(Request $request)
    {
        $query = AppNotification::visibleTo($request->user())->whereNull('read_at');
        Notice::whereIn('id', (clone $query)->whereNotNull('notice_id')->select('notice_id'))->get()
            ->each(fn ($notice) => $notice->markRead($request->user()));
        $query->update(['read_at' => now()]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }
}
