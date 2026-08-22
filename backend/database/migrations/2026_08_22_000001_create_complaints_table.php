<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('complaints', function (Blueprint $table) {
            $table->id();
            $table->string('complaint_number')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('details');
            $table->string('category');
            $table->enum('priority', ['Low', 'Medium', 'High'])->default('Medium');
            $table->enum('status', ['submitted', 'review', 'forwarded', 'office', 'dean', 'resolved', 'rejected'])->default('submitted');
            $table->string('current_handler_role')->default('adviser');
            $table->timestamps();
            $table->index(['status', 'current_handler_role']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('complaints');
    }
};
