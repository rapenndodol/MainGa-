<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('library_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('game_id')->constrained('games')->cascadeOnDelete();
            $table->enum('status', ['Wishlist', 'Backlog', 'Sedang Dimainkan', 'Tamat', 'Dropped'])->default('Backlog');
            $table->unsignedTinyInteger('rating_pribadi')->nullable();
            $table->decimal('jam_main', 8, 2)->default(0);
            $table->text('catatan')->nullable();
            $table->date('tanggal_tamat')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'game_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('library_entries');
    }
};
