<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('complaint_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('complaint_id')->constrained()->cascadeOnDelete();
            $table->foreignId('acted_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action');
            $table->string('from_status')->nullable();
            $table->string('to_status');
            $table->text('remarks')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('complaint_histories');
    }
};
