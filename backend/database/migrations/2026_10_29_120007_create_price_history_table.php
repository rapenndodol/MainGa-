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
        Schema::create('price_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('game_id')->constrained('games')->cascadeOnDelete();
            $table->string('toko');
            $table->decimal('harga', 10, 2);
            $table->decimal('diskon_persen', 5, 2)->default(0);
            $table->timestamp('dicek_pada')->useCurrent();
            $table->timestamps();

            $table->index('game_id');
            $table->index('dicek_pada');
            $table->index(['game_id', 'dicek_pada']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('price_history');
    }
};
