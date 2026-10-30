import 'package:flutter/material.dart';
import '../../features/games/data/models/game_model.dart';
import '../../features/games/presentation/screens/game_detail_screen.dart';
import '../theme/app_theme.dart';
import 'app_badge.dart';

/// Reusable Game Card sesuai referensi visual MainGa?.
class AppGameCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback? onTap;

  const AppGameCard({
    super.key,
    required this.game,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameDetailScreen(game: game),
                  ),
                );
              },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Thumbnail ──────────────────────────────
                ClipRRect(
                  borderRadius: AppRadius.mdBorderRadius,
                  child: SizedBox(
                    width: 82,
                    height: 110,
                    child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                        ? Image.network(
                            game.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildCoverFallback(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: AppColors.surfaceElevated,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildCoverFallback(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // ── Informasi Game ────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Game
                      Text(
                        game.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),

                      // Genre
                      if (game.genre.isNotEmpty)
                        Text(
                          game.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),

                      // Baris Rating & Tahun Rilis
                      Row(
                        children: [
                          // Rating Badge
                          AppBadge.rating(game.rating, compact: true),
                          const SizedBox(width: AppSpacing.sm),

                          // Tanggal / Tahun Rilis
                          if (game.tanggalRilis != null && game.tanggalRilis!.isNotEmpty)
                            Text(
                              game.tanggalRilis!.length >= 4
                                  ? game.tanggalRilis!.substring(0, 4)
                                  : game.tanggalRilis!,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),

                          const Spacer(),

                          // Chevron aksen lembut
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: AppColors.textMuted,
          size: 28,
        ),
      ),
    );
  }
}
