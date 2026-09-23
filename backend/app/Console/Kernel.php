<?php

namespace App\Console;

class Kernel extends \Illuminate\Foundation\Console\Kernel
{
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');
        require base_path('routes/console.php');
    }
}
