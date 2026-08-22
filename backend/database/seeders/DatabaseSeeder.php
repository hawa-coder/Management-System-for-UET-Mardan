<?php

namespace Database\Seeders;

use App\Models\Notice;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $accounts = [
            ['Hawa Sabir', '2023cs001@uetmardan.edu.pk', 'student', 'Student@123', '2023-CS-001'],
            ['Batch Adviser', 'adviser@uetmardan.edu.pk', 'adviser', 'Adviser@123', null],
            ['Coordinator', 'coordinator@uetmardan.edu.pk', 'coordinator', 'Coordinator@123', null],
            ['Department Chairman', 'chairman@uetmardan.edu.pk', 'chairman', 'Chairman@123', null],
            ['Office Staff', 'office@uetmardan.edu.pk', 'office', 'Office@123', null],
            ['Dean', 'dean@uetmardan.edu.pk', 'dean', 'Dean@123', null],
        ];

        foreach ($accounts as [$name, $email, $role, $password, $registration]) {
            User::updateOrCreate(['email' => $email], [
                'name' => $name,
                'role' => $role,
                'password' => Hash::make($password),
                'registration_number' => $registration,
                'batch' => $role === 'student' ? '2023' : null,
                'section' => $role === 'student' ? 'A' : null,
                'email_verified_at' => now(),
            ]);
        }

        $chairman = User::where('role', 'chairman')->firstOrFail();
        Notice::firstOrCreate(['title' => 'Mid-term examination schedule'], [
            'published_by' => $chairman->id,
            'body' => 'The revised mid-term date sheet is available from the department office.',
            'audience' => 'all',
            'published_at' => now(),
        ]);
    }
}
