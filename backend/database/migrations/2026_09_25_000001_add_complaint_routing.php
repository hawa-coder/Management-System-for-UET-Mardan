<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', fn (Blueprint $table) => $table->boolean('can_forward_complaints')->default(false));
        Schema::table('complaints', function (Blueprint $table) {
            $table->foreignId('current_handler_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('current_handler_name')->nullable();
        });
        Schema::table('complaint_histories', function (Blueprint $table) {
            $table->string('event_type')->default('legacy');
            $table->string('actor_name')->nullable();
            $table->string('actor_role')->nullable();
            $table->foreignId('recipient_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('recipient_name')->nullable();
            $table->string('recipient_role')->nullable();
        });
        $this->statuses(['submitted', 'review', 'forwarded', 'returned', 'office', 'dean', 'resolved', 'rejected']);

        // Preserve existing events. Recover only identities that were actually saved.
        DB::table('complaint_histories')->orderBy('id')->chunkById(200, function ($rows) {
            foreach ($rows as $row) {
                $actor = DB::table('users')->find($row->acted_by);
                $action = strtolower($row->action);
                $type = str_contains($action, 'submitted') ? 'submitted'
                    : (str_starts_with($action, 'return ') ? 'returned'
                        : ((str_starts_with($action, 'forward ') || str_starts_with($action, 'send ')) ? 'forwarded' : 'status'));
                $recipientRole = match ($action) {
                    'forward coordinator' => 'coordinator',
                    'forward chairman', 'return chairman' => 'chairman',
                    'send office', 'send resolved department' => 'office',
                    'send dean' => 'dean',
                    default => null,
                };
                DB::table('complaint_histories')->where('id', $row->id)->update([
                    'event_type' => $type,
                    'actor_name' => $actor ? ($actor->role === 'student' ? $actor->registration_number : $actor->name) : null,
                    'actor_role' => $actor?->role,
                    'recipient_role' => $recipientRole,
                ]);
            }
        });
        DB::table('complaints')->where('current_handler_role', 'adviser')->orderBy('id')->chunkById(200, function ($rows) {
            foreach ($rows as $row) {
                $student = DB::table('users')->find($row->user_id);
                $adviser = $student?->batch_adviser_id ? DB::table('users')->find($student->batch_adviser_id) : null;
                if ($adviser && $adviser->role === 'adviser') {
                    DB::table('complaints')->where('id', $row->id)->update([
                        'current_handler_id' => $adviser->id,
                        'current_handler_name' => $adviser->name,
                    ]);
                }
            }
        });
    }

    public function down(): void
    {
        if (DB::table('complaint_histories')->whereIn('event_type', ['forwarded', 'returned'])->whereNotNull('recipient_id')->exists()) {
            throw new RuntimeException('Routing history must be retained; export it before removing routing support.');
        }
        DB::table('complaints')->where('status', 'returned')->update(['status' => 'forwarded']);
        $this->statuses(['submitted', 'review', 'forwarded', 'office', 'dean', 'resolved', 'rejected']);
        Schema::table('complaint_histories', function (Blueprint $table) {
            $table->dropConstrainedForeignId('recipient_id');
            $table->dropColumn(['event_type', 'actor_name', 'actor_role', 'recipient_name', 'recipient_role']);
        });
        Schema::table('complaints', function (Blueprint $table) {
            $table->dropConstrainedForeignId('current_handler_id');
            $table->dropColumn('current_handler_name');
        });
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn('can_forward_complaints'));
    }

    private function statuses(array $statuses): void
    {
        if (DB::getDriverName() === 'mysql') {
            $values = implode(',', array_map(fn ($status) => "'$status'", $statuses));
            DB::statement("ALTER TABLE complaints MODIFY status ENUM($values) NOT NULL DEFAULT 'submitted'");
            return;
        }
        Schema::table('complaints', function (Blueprint $table) use ($statuses) {
            $table->dropIndex(['status', 'current_handler_role']);
            $table->enum('routing_status', $statuses)->default('submitted');
        });
        DB::table('complaints')->update(['routing_status' => DB::raw('status')]);
        Schema::table('complaints', fn (Blueprint $table) => $table->dropColumn('status'));
        Schema::table('complaints', fn (Blueprint $table) => $table->renameColumn('routing_status', 'status'));
        Schema::table('complaints', fn (Blueprint $table) => $table->index(['status', 'current_handler_role']));
    }
};
