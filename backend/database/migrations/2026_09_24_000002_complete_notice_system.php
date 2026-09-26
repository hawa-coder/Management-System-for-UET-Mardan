<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', fn (Blueprint $table) => $table->boolean('can_publish_department_notices')->default(false));
        Schema::create('courses', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->foreignId('faculty_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });
        Schema::create('course_student', function (Blueprint $table) {
            $table->foreignId('course_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->primary(['course_id', 'user_id']);
        });
        Schema::table('notices', function (Blueprint $table) {
            $table->string('category')->default('Department');
            $table->string('priority')->default('Normal');
            $table->timestamp('notice_date')->nullable()->index();
            $table->timestamp('expires_at')->nullable()->index();
            $table->timestamp('notified_at')->nullable();
            foreach (['departments', 'batches', 'semesters', 'sections', 'course_ids', 'student_ids'] as $field) {
                $table->json($field)->nullable();
            }
            $table->string('scope_department')->nullable();
            $table->foreignId('target_faculty_id')->nullable()->constrained('users')->cascadeOnDelete();
            $table->string('attachment_path')->nullable();
            $table->string('attachment_name')->nullable();
            $table->string('attachment_mime')->nullable();
        });
        DB::table('notices')->update(['notice_date' => DB::raw('published_at'), 'notified_at' => DB::raw('published_at')]);
        Schema::create('notice_reads', function (Blueprint $table) {
            $table->foreignId('notice_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('read_at');
            $table->primary(['notice_id', 'user_id']);
        });
        Schema::table('app_notifications', function (Blueprint $table) {
            $table->foreignId('notice_id')->nullable()->constrained()->cascadeOnDelete();
            $table->unique(['notice_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::table('app_notifications', function (Blueprint $table) {
            $table->dropUnique(['notice_id', 'user_id']);
            $table->dropConstrainedForeignId('notice_id');
        });
        Schema::dropIfExists('notice_reads');
        Schema::table('notices', function (Blueprint $table) {
            $table->dropConstrainedForeignId('target_faculty_id');
            $table->dropColumn(['category', 'priority', 'notice_date', 'expires_at', 'notified_at', 'departments', 'batches', 'semesters', 'sections', 'course_ids', 'student_ids', 'scope_department', 'attachment_path', 'attachment_name', 'attachment_mime']);
        });
        Schema::dropIfExists('course_student');
        Schema::dropIfExists('courses');
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn('can_publish_department_notices'));
    }
};
