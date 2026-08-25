<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notices', function (Blueprint $table) {
            $table->foreignId('complaint_id')->nullable()->after('id')
                ->constrained()->nullOnDelete();
            $table->unique('complaint_id');
        });
    }

    public function down(): void
    {
        Schema::table('notices', function (Blueprint $table) {
            $table->dropUnique(['complaint_id']);
            $table->dropConstrainedForeignId('complaint_id');
        });
    }
};
