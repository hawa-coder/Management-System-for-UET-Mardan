<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class ComplaintForwardPermission extends Command
{
    protected $signature = 'complaints:forward-permission {email} {--revoke}';
    protected $description = 'Grant or revoke permission for a faculty member to forward complaints they hold';

    public function handle(): int
    {
        $user = User::where('email', $this->argument('email'))->where('role', 'faculty')->first();
        if (! $user) {
            $this->error('Faculty account not found.');
            return self::FAILURE;
        }
        $user->can_forward_complaints = ! $this->option('revoke');
        $user->save();
        $this->info($user->can_forward_complaints ? 'Complaint forwarding enabled.' : 'Complaint forwarding disabled.');
        return self::SUCCESS;
    }
}
