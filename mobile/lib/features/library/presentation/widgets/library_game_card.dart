import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_interactive_card.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/game_hero_tag.dart';
import '../../../games/data/models/game_model.dart';
import '../../../games/presentation/screens/game_detail_screen.dart';
import '../../data/models/library_entry_model.dart';
import 'library_entry_sheet.dart';

class LibraryGameCard extends StatelessWidget {
  final LibraryEntryModel entry;
  final VoidCallback? onUpdated;
  final int index;

  const LibraryGameCard({
    super.key,
    required this.entry,
    this.onUpdated,
    this.index = 0,
  });

  GameModel _resolveGame() {
    return entry.game ??
        GameModel(
          id: entry.gameId,
          rawgId: entry.gameId,
          judul: entry.judul,
          coverUrl: entry.coverUrl,
          rating: entry.gameRating,
          genre: entry.genre,
          genres: entry.genre.isEmpty
              ? const []
              : entry.genre.split(',').map((e) => e.trim()).toList(),
          platform: entry.platform,
          platforms: entry.platform.isEmpty
              ? const []
              : entry.platform.split(',').map((e) => e.trim()).toList(),
          libraryStatus: entry.status,
          libraryEntryData: entry.toJson(),
        );
  }

  void _openDetail(BuildContext context) {
    final GameModel game = _resolveGame();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(
          game: game,
          heroTag: gameCoverHeroTag(game, 'library'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameModel game = _resolveGame();
    final bool isCompleted = entry.status == 'Tamat';

    return AppInteractiveCard(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdBorderRadius,
          border: Border.all(
            color: isCompleted
                ? AppColors.statusCompleted.withValues(alpha: 0.32)
                : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () async {
              final changed = await LibraryEntrySheet.show(
                context,
                entry: entry,
              );
              if (changed == true && onUpdated != null) {
                onUpdated!();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCover(context, game),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AppStatusChip(
                                  status: entry.status,
                                  compact: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          entry.judul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        if (entry.genre.isNotEmpty ||
                            entry.platform.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            [
                              if (entry.genre.isNotEmpty) entry.genre,
                              if (entry.platform.isNotEmpty) entry.platform,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _buildMetrics(),
                        if (isCompleted && entry.tanggalTamat != null) ...[
                          const SizedBox(height: AppSpacing.xs + 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: AppColors.statusCompleted,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Tamat pada ${entry.tanggalTamat}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.statusCompleted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (entry.catatan != null &&
                            entry.catatan!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs + 2),
                          Text(
                            '"${entry.catatan!.trim()}"',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, GameModel game) {
    return Semantics(
      button: true,
      label: 'Lihat detail ${entry.judul}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDetail(context),
        child: Hero(
          tag: gameCoverHeroTag(game, 'library'),
          child: ClipRRect(
            borderRadius: AppRadius.controlLargeBorderRadius,
            child: SizedBox(
              width: 84,
              height: 118,
              child: entry.coverUrl != null && entry.coverUrl!.isNotEmpty
                  ? Image.network(
                      entry.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildFallbackCover(),
                    )
                  : _buildFallbackCover(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _metricPill(
          icon: Icons.star_rounded,
          iconColor: entry.ratingPribadi != null
              ? AppColors.ratingStar
              : AppColors.textMuted,
          background: entry.ratingPribadi != null
              ? AppColors.ratingStar.withValues(alpha: 0.12)
              : AppColors.surfaceElevated,
          border: entry.ratingPribadi != null
              ? AppColors.ratingStar.withValues(alpha: 0.3)
              : AppColors.border,
          text: entry.ratingPribadi != null ? '${entry.ratingPribadi}/10' : '-',
          textColor: entry.ratingPribadi != null
              ? AppColors.ratingStar
              : AppColors.textMuted,
        ),
        _metricPill(
          icon: Icons.timer_outlined,
          iconColor: AppColors.textSecondary,
          background: AppColors.surfaceElevated,
          border: AppColors.border,
          text: entry.jamMain % 1 == 0
              ? '${entry.jamMain.toInt()} jam'
              : '${entry.jamMain.toStringAsFixed(1)} jam',
          textColor: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _metricPill({
    required IconData icon,
    required Color iconColor,
    required Color background,
    required Color border,
    required String text,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.fullBorderRadius,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.tabular(
              AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCover() {
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
