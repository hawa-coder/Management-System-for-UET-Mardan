<?php

namespace App\Console\Commands;

use App\Services\NoticeDelivery;
use Illuminate\Console\Command;

class DispatchNotices extends Command
{
    protected $signature = 'notices:dispatch';
    protected $description = 'Deliver notifications for notices whose scheduled date has arrived';

    public function handle(NoticeDelivery $delivery): int
    {
        $delivery->dispatchDue();
        $this->info('Due notice notifications delivered.');
        return self::SUCCESS;
    }
}
