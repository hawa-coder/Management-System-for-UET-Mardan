<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Notice;
use Illuminate\Support\Facades\DB;

class NoticeDelivery
{
    public function dispatchDue(): void
    {
        Notice::active()->whereNull('notified_at')->select('id')->chunkById(100, function ($notices) {
            foreach ($notices as $item) {
                DB::transaction(function () use ($item) {
                    $notice = Notice::lockForUpdate()->find($item->id);
                    if (! $notice || $notice->notified_at || $notice->status !== 'Active') return;
                    $notice->recipients()->where('id', '!=', $notice->published_by)->chunkById(200, function ($users) use ($notice) {
                        foreach ($users as $user) {
                            AppNotification::firstOrCreate(['notice_id' => $notice->id, 'user_id' => $user->id], [
                                'type' => 'notice', 'title' => $notice->title,
                                'message' => 'New Notice · '.$notice->priority.' · '.$notice->category,
                            ]);
                        }
                    });
                    $notice->update(['notified_at' => now()]);
                });
            }
        });
    }
}
