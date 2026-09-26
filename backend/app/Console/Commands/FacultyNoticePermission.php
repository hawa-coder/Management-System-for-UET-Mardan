<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class FacultyNoticePermission extends Command
{
    protected $signature = 'notices:faculty-permission {email} {--revoke : Restrict new notices to taught classes again}';
    protected $description = 'Grant or revoke department-wide notice permission for an approved faculty account';

    public function handle(): int
    {
        $faculty = User::where('email', $this->argument('email'))->where('role', 'faculty')->where('account_status', 'approved')->first();
        if (!$faculty) { $this->error('An approved faculty account is required.'); return self::FAILURE; }
        $faculty->update(['can_publish_department_notices' => !$this->option('revoke')]);
        $this->info($this->option('revoke') ? 'Department-wide permission revoked for future notices.' : 'Department-wide notice permission granted.');
        return self::SUCCESS;
    }
}
