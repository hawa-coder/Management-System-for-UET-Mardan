<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notices', function (Blueprint $table) {
            $table->string('department')->nullable();
            $table->string('batch', 30)->nullable();
            $table->unsignedTinyInteger('semester')->nullable();
            $table->string('section', 30)->nullable();
            // Keep adviser notices restricted even when no academic filter is selected.
            $table->foreignId('target_adviser_id')->nullable()->constrained('users')->cascadeOnDelete();
        });
        $this->replaceRoles(['student', 'adviser', 'coordinator', 'chairman', 'office', 'dean', 'faculty']);
    }

    public function down(): void
    {
        if (DB::table('users')->where('role', 'faculty')->exists()) {
            throw new RuntimeException('Reassign faculty accounts before rolling back faculty support.');
        }
        $this->replaceRoles(['student', 'adviser', 'coordinator', 'chairman', 'office', 'dean']);
        Schema::table('notices', function (Blueprint $table) {
            $table->dropConstrainedForeignId('target_adviser_id');
            $table->dropColumn(['department', 'batch', 'semester', 'section']);
        });
    }

    private function replaceRoles(array $roles): void
    {
        if (DB::getDriverName() === 'mysql') {
            $allowed = implode(',', array_map(fn ($role) => "'".$role."'", $roles));
            DB::statement("ALTER TABLE users MODIFY role ENUM($allowed) NOT NULL DEFAULT 'student'");
            return;
        }
        // Copy through a new column so both MySQL enums and SQLite checks are updated.
        Schema::table('users', fn (Blueprint $table) => $table->enum('notice_role', $roles)->default('student'));
        DB::table('users')->update(['notice_role' => DB::raw('role')]);
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn('role'));
        Schema::table('users', fn (Blueprint $table) => $table->renameColumn('notice_role', 'role'));
    }
};
