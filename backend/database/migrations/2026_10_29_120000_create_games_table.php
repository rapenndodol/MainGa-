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
        Schema::create('games', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('rawg_id')->unique();
            $table->string('judul');
            $table->text('cover_url')->nullable();
            $table->decimal('rating', 3, 2)->nullable();
            $table->text('deskripsi')->nullable();
            $table->date('tanggal_rilis')->nullable();
            $table->timestamp('cached_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('games');
    }
};
