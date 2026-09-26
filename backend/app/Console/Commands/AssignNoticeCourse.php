<?php

namespace App\Console\Commands;

use App\Models\{Course, User};
use Illuminate\Console\Command;

class AssignNoticeCourse extends Command
{
    protected $signature = 'notices:assign-course {code} {name} {faculty_email} {--student=* : Student university emails to enroll}';
    protected $description = 'Assign a class/course to faculty and add its students for notice permissions';

    public function handle(): int
    {
        $faculty = User::where('email', $this->argument('faculty_email'))->where('role', 'faculty')->where('account_status', 'approved')->first();
        if (!$faculty) { $this->error('An approved faculty account is required.'); return self::FAILURE; }
        $emails = array_unique($this->option('student'));
        $students = User::whereIn('email', $emails)->where('role', 'student')->where('department', $faculty->department)->get();
        if ($students->count() !== count($emails)) { $this->error('Each student must exist in the faculty member’s department.'); return self::FAILURE; }
        $course = Course::updateOrCreate(['code' => $this->argument('code')], ['name' => $this->argument('name'), 'faculty_id' => $faculty->id]);
        $course->students()->syncWithoutDetaching($students->modelKeys());
        $this->info('Course assignment and enrollments saved.');
        return self::SUCCESS;
    }
}
