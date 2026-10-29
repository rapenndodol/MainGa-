import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/game_model.dart';
import '../screens/game_detail_screen.dart';

class GameCard extends StatelessWidget {
  final GameModel game;

  const GameCard({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailScreen(game: game),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover Thumbnail ──────────────────────────────
              SizedBox(
                width: 105,
                height: 125,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (game.coverUrl != null && game.coverUrl!.isNotEmpty)
                      Image.network(
                        game.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppTheme.surfaceElevated,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      _buildPlaceholder(),
                  ],
                ),
              ),

              // ── Informasi Game ────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Judul Game
                      Text(
                        game.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Genre
                      if (game.genre.isNotEmpty)
                        Text(
                          game.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Baris Rating & Tahun Rilis
                      Row(
                        children: [
                          // Rating Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFFACC15),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  game.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFACC15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Tanggal / Tahun Rilis
                          if (game.tanggalRilis != null && game.tanggalRilis!.isNotEmpty)
                            Text(
                              game.tanggalRilis!.length >= 4
                                  ? game.tanggalRilis!.substring(0, 4)
                                  : game.tanggalRilis!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),

                          const Spacer(),

                          // Panah detail
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: AppTheme.textMuted,
          size: 32,
        ),
      ),
    );
  }
}
