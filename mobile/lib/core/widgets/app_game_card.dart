import 'package:flutter/material.dart';
import '../../features/games/data/models/game_model.dart';
import '../../features/games/presentation/screens/game_detail_screen.dart';
import '../theme/app_theme.dart';
import 'app_badge.dart';

/// Kartu game reusable dengan cover rasio poster 3:4 dan permukaan
/// tanpa border—pemisahan bidang memakai tone step.
class AppGameCard extends StatefulWidget {
  final GameModel game;
  final VoidCallback? onTap;

  const AppGameCard({
    super.key,
    required this.game,
    this.onTap,
  });

  @override
  State<AppGameCard> createState() => _AppGameCardState();
}

class _AppGameCardState extends State<AppGameCard> {
  bool _pressed = false;

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(game: widget.game),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: _pressed ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onTap: widget.onTap ?? _openDetail,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Thumbnail (3:4) ────────────────────────
                ClipRRect(
                  borderRadius: AppRadius.mdBorderRadius,
                  child: SizedBox(
                    width: 84,
                    height: 112,
                    child: widget.game.coverUrl != null &&
                            widget.game.coverUrl!.isNotEmpty
                        ? Image.network(
                            widget.game.coverUrl!,
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
                                          AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
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
                      Text(
                        widget.game.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),

                      if (widget.game.genre.isNotEmpty)
                        Text(
                          widget.game.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),

                      Row(
                        children: [
                          AppBadge.rating(widget.game.rating, compact: true),
                          const SizedBox(width: AppSpacing.sm),

                          if (widget.game.tanggalRilis != null &&
                              widget.game.tanggalRilis!.isNotEmpty)
                            Text(
                              widget.game.tanggalRilis!.length >= 4
                                  ? widget.game.tanggalRilis!.substring(0, 4)
                                  : widget.game.tanggalRilis!,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),

                          const Spacer(),

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
