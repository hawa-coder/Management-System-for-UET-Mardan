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
            ['Hawa Sabir', '2023cs001@uetmardan.edu.pk', 'student', 'Student@123', '2023-CS-001', 'A'],
            ['Coordinator', 'coordinator@uetmardan.edu.pk', 'coordinator', 'Coordinator@123', null, null],
            ['Usman', 'chairman@uetmardan.edu.pk', 'chairman', 'Chairman@123', null, null],
            ['Department Staff', 'office@uetmardan.edu.pk', 'office', 'Office@123', null, null],
            ['Dean', 'dean@uetmardan.edu.pk', 'dean', 'Dean@123', null, null],
        ];

        foreach ($accounts as [$name, $email, $role, $password, $registration, $section]) {
            User::updateOrCreate(['email' => $email], [
                'name' => $name,
                'role' => $role,
                'password' => Hash::make($password),
                'registration_number' => $registration,
                'batch' => in_array($role, ['student', 'adviser'], true) ? '2023' : null,
                'section' => $section,
                'email_verified_at' => now(),
            ]);
        }

        User::whereIn('email', [
            'adviser@uetmardan.edu.pk',
            'inayat@uetmardan.edu.pk',
            'ali@uetmardan.edu.pk',
            'noor@uetmardan.edu.pk',
        ])->update(['is_active' => false]);

        $advisers = [
            ['Dr. Shams Ur Rahman', 'shams.ur.rahman@uetmardan.edu.pk', 'Batch 05', 8, 'AI'],
            ['Dr. Tariq Sadad', 'tariq.sadad@uetmardan.edu.pk', 'Batch 05', 8, 'CS'],
            ['Ms. Faiza Tila', 'faiza.tila@uetmardan.edu.pk', 'Batch 05', 8, 'DS'],
            ['Dr. Inayat Khan', 'inayat.khan@uetmardan.edu.pk', 'Batch 06', 6, 'AI'],
            ['Mr. Mian Saeed Akbar', 'mian.saeed.akbar@uetmardan.edu.pk', 'Batch 06', 6, 'CS'],
            ['Dr. Raza Ullah Khan', 'raza.ullah.khan@uetmardan.edu.pk', 'Batch 06', 6, 'DS'],
            ['Mr. Zaheen Ahmed', 'zaheen.ahmed@uetmardan.edu.pk', 'Batch 07', 4, 'A'],
            ['Mr. Bilal Khan', 'bilal.khan@uetmardan.edu.pk', 'Batch 07', 4, 'B'],
            ['Mr. Abdul Saboor', 'abdul.saboor@uetmardan.edu.pk', 'Batch 07', 4, 'C'],
            ['Mr. Asad Jan', 'asad.jan@uetmardan.edu.pk', 'Batch 07', 4, 'D'],
            ['Ms. Alishba Orakzai', 'alishba.orakzai@uetmardan.edu.pk', 'Batch 08', 2, 'A'],
            ['Ms. Hafsa Fayyaz', 'hafsa.fayyaz@uetmardan.edu.pk', 'Batch 08', 2, 'B'],
            ['Muhammad Danyal', 'muhammad.danyal@uetmardan.edu.pk', 'Batch 08', 2, 'C'],
        ];

        foreach ($advisers as [$name, $email, $batch, $semester, $section]) {
            User::updateOrCreate(['email' => $email], [
                'name' => $name,
                'role' => 'adviser',
                'password' => Hash::make('Adviser@123'),
                'batch' => $batch,
                'semester' => $semester,
                'section' => $section,
                'is_active' => true,
                'account_status' => 'approved',
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
