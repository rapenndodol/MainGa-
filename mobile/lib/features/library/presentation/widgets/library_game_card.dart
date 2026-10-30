import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../data/models/library_entry_model.dart';
import 'library_entry_sheet.dart';

class LibraryGameCard extends StatelessWidget {
  final LibraryEntryModel entry;
  final VoidCallback? onUpdated;

  const LibraryGameCard({
    super.key,
    required this.entry,
    this.onUpdated,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgBorderRadius,
          onTap: () async {
            final changed = await LibraryEntrySheet.show(context, entry: entry);
            if (changed == true && onUpdated != null) {
              onUpdated!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Image ───────────────────────────────────
                ClipRRect(
                  borderRadius: AppRadius.mdBorderRadius,
                  child: SizedBox(
                    width: 78,
                    height: 106,
                    child: entry.coverUrl != null && entry.coverUrl!.isNotEmpty
                        ? Image.network(
                            entry.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildFallbackCover(),
                          )
                        : _buildFallbackCover(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // ── Content Info ──────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & Action Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppStatusChip(status: entry.status, compact: true),
                          const Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Judul Game
                      Text(
                        entry.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Metric Row: Rating Pribadi & Jam Main
                      Row(
                        children: [
                          // Rating Pribadi
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: entry.ratingPribadi != null
                                  ? AppColors.ratingStar.withValues(alpha: 0.15)
                                  : AppColors.surfaceElevated,
                              borderRadius: AppRadius.fullBorderRadius,
                              border: Border.all(
                                color: entry.ratingPribadi != null
                                    ? AppColors.ratingStar.withValues(alpha: 0.35)
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: entry.ratingPribadi != null
                                      ? AppColors.ratingStar
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.ratingPribadi != null
                                      ? '${entry.ratingPribadi}/10'
                                      : '-',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: entry.ratingPribadi != null
                                        ? AppColors.ratingStar
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Jam Main
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppRadius.fullBorderRadius,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.jamMain % 1 == 0
                                      ? '${entry.jamMain.toInt()} jam'
                                      : '${entry.jamMain.toStringAsFixed(1)} jam',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Tanggal Tamat (jika status Tamat)
                      if (entry.status == 'Tamat' && entry.tanggalTamat != null) ...[
                        const SizedBox(height: AppSpacing.xs + 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tamat pada ${entry.tanggalTamat}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Catatan Preview jika ada
                      if (entry.catatan != null && entry.catatan!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs + 2),
                        Text(
                          '"${entry.catatan!.trim()}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
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
