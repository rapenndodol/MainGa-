import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dateTime);
      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} m lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return DateFormat('d MMM yyyy').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.sudahDibaca;
    final coverUrl = notification.game?.coverUrl;
    final storeName = notification.toko;
    final price = notification.harga;
    final relativeTime = _formatRelativeTime(notification.waktu ?? notification.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.surfaceHighlight.withValues(alpha: 0.6) : AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(
          color: isUnread ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          width: isUnread ? 1.2 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgBorderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Thumbnail / Game Icon ───────────
                ClipRRect(
                  borderRadius: AppRadius.mdBorderRadius,
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppColors.surfaceElevated,
                    child: coverUrl != null && coverUrl.isNotEmpty
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.sports_esports_rounded,
                              color: AppColors.textMuted,
                              size: 26,
                            ),
                          )
                        : const Icon(
                            Icons.sports_esports_rounded,
                            color: AppColors.textMuted,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // ── Content Info ──────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Game & Penanda Belum Dibaca
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.judulGame,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Pesan Notifikasi
                      Text(
                        notification.pesan,
                        style: AppTypography.bodySmall.copyWith(
                          color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Toko, Harga, dan Waktu Relatif
                      Row(
                        children: [
                          if (storeName != null && storeName.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: AppRadius.smBorderRadius,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                storeName,
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          if (price != null && price > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: AppRadius.smBorderRadius,
                              ),
                              child: Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          const Spacer(),
                          if (relativeTime.isNotEmpty)
                            Text(
                              relativeTime,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
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
}
