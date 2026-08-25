<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedTinyInteger('semester')->nullable()->after('batch');
            $table->string('mobile_number', 20)->nullable()->after('section');
            $table->foreignId('batch_adviser_id')->nullable()->after('mobile_number')
                ->constrained('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('batch_adviser_id');
            $table->dropColumn(['semester', 'mobile_number']);
        });
    }
};
