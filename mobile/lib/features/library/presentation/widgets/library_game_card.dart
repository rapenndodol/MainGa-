import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/library_entry_model.dart';
import 'library_entry_sheet.dart';
import 'library_status_badge.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final changed = await LibraryEntrySheet.show(context, entry: entry);
            if (changed == true && onUpdated != null) {
              onUpdated!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Image ───────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 76,
                    height: 104,
                    child: entry.coverUrl != null && entry.coverUrl!.isNotEmpty
                        ? Image.network(
                            entry.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildFallbackCover(),
                          )
                        : _buildFallbackCover(),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Content Info ──────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & Action Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LibraryStatusBadge(status: entry.status, compact: true),
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: AppTheme.textMuted.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Judul Game
                      Text(
                        entry.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Metric Row: Rating Pribadi & Jam Main
                      Row(
                        children: [
                          // Rating Pribadi
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: entry.ratingPribadi != null
                                  ? const Color(0xFFEAB308).withValues(alpha: 0.12)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: entry.ratingPribadi != null
                                    ? const Color(0xFFEAB308).withValues(alpha: 0.25)
                                    : AppTheme.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: entry.ratingPribadi != null
                                      ? const Color(0xFFFACC15)
                                      : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.ratingPribadi != null
                                      ? '${entry.ratingPribadi}/10'
                                      : '-',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: entry.ratingPribadi != null
                                      ? const Color(0xFFFACC15)
                                      : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Jam Main
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.jamMain % 1 == 0
                                      ? '${entry.jamMain.toInt()} jam'
                                      : '${entry.jamMain.toStringAsFixed(1)} jam',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Tanggal Tamat (jika Tamat)
                      if (entry.status == 'Tamat' && entry.tanggalTamat != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tamat pada ${entry.tanggalTamat}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Catatan Preview jika ada
                      if (entry.catatan != null && entry.catatan!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '"${entry.catatan!.trim()}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textMuted,
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
      color: AppTheme.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: AppTheme.textMuted,
          size: 28,
        ),
      ),
    );
  }
}
