import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_interactive_card.dart';
import '../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final int index;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.index = 0,
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
    final String? coverUrl = notification.game?.coverUrl;
    final String? storeName = notification.toko;
    final double? price = notification.harga;
    final String relativeTime = _formatRelativeTime(
      notification.waktu ?? notification.createdAt,
    );

    return AppInteractiveCard(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: AppRadius.lgBorderRadius,
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.border,
            width: isUnread ? 1.2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                if (isUnread)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 3, color: AppColors.primary),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md + (isUnread ? 3 : 0),
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildThumbnail(coverUrl),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isUnread) ...[
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(top: 5),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs + 2),
                                ],
                                Expanded(
                                  child: Text(
                                    notification.judulGame,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: isUnread
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isUnread
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs + 1),
                            Text(
                              notification.pesan,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: isUnread
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                            if ((storeName != null && storeName.isNotEmpty) ||
                                (price != null && price > 0) ||
                                relativeTime.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (storeName != null && storeName.isNotEmpty)
                                    _metaChip(
                                      text: storeName,
                                      background: isUnread
                                          ? AppColors.surface
                                          : AppColors.surfaceElevated,
                                      foreground: AppColors.textSecondary,
                                      borderColor: AppColors.border,
                                    ),
                                  if (price != null && price > 0)
                                    _metaChip(
                                      text: '\$${price.toStringAsFixed(2)}',
                                      background: AppColors.primaryContainer,
                                      foreground: AppColors.primaryLight,
                                      borderColor: AppColors.primary.withValues(
                                        alpha: 0.28,
                                      ),
                                      bold: true,
                                    ),
                                  if (relativeTime.isNotEmpty)
                                    Text(
                                      relativeTime,
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
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

  Widget _buildThumbnail(String? coverUrl) {
    return ClipRRect(
      borderRadius: AppRadius.controlLargeBorderRadius,
      child: Container(
        width: 54,
        height: 54,
        color: AppColors.surfaceHighlight,
        child: coverUrl != null && coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallbackIcon(),
              )
            : _buildFallbackIcon(),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return const Center(
      child: Icon(
        Icons.sports_esports_rounded,
        color: AppColors.textMuted,
        size: 24,
      ),
    );
  }

  Widget _metaChip({
    required String text,
    required Color background,
    required Color foreground,
    required Color borderColor,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smBorderRadius,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: AppTypography.tabular(
          AppTypography.labelSmall.copyWith(
            fontSize: 10,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
