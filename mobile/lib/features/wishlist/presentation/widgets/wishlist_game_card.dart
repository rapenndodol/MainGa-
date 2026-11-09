import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/wishlist_item_model.dart';

class WishlistGameCard extends StatelessWidget {
  final WishlistItemModel item;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  const WishlistGameCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  String _formatIdr(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final bool isReached = item.isTargetReached;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(
          color: isReached
              ? AppColors.success.withValues(alpha: 0.5)
              : (item.aktif ? AppColors.border : AppColors.border.withValues(alpha: 0.4)),
          width: isReached ? 1.5 : 1.0,
        ),
        boxShadow: isReached
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgBorderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Thumbnail Cover Game ───────────────────
                    ClipRRect(
                      borderRadius: AppRadius.mdBorderRadius,
                      child: Container(
                        width: 80,
                        height: 104,
                        color: AppColors.surfaceElevated,
                        child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                            ? Image.network(
                                item.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _buildCoverFallback(),
                              )
                            : _buildCoverFallback(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // ── Detail Informasi Game & Harga ──────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul & Tombol Hapus
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.judul,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                    color: item.aktif
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: 'Hapus dari Wishlist',
                                onPressed: onDelete,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Target Harga
                          Row(
                            children: [
                              Text(
                                'Target: ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${item.hargaTarget.toStringAsFixed(2)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                ' (estimasi ${_formatIdr(item.hargaTargetIdrEstimasi)})',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Harga Terendah Saat Ini & Toko
                          if (item.hargaTersedia && item.hargaTerendah != null) ...[
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppSpacing.xs,
                              children: [
                                Text(
                                  '${item.tokoTermurah ?? 'Termurah'}: ',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '\$${item.hargaTerendah!.toStringAsFixed(2)}',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: isReached
                                        ? AppColors.success
                                        : AppColors.primaryLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (item.hargaTerendahIdrEstimasi != null)
                                  Text(
                                    '(${_formatIdr(item.hargaTerendahIdrEstimasi!)})',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                if (item.diskonPersen != null && item.diskonPersen! > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: AppRadius.smBorderRadius,
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '-${item.diskonPersen!.toStringAsFixed(0)}%',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Harga belum tersedia',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
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
                const SizedBox(height: AppSpacing.sm + 2),

                // ── Garis Pemisah Halus ────────────────────────
                Divider(
                  color: AppColors.border.withValues(alpha: 0.5),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Baris Bawah: Status Capai Target & Saklar Pantau ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Penanda bila harga sudah mencapai / di bawah target
                    Expanded(
                      child: _buildTargetStatusIndicator(isReached),
                    ),

                    // Saklar Aktif/Nonaktif Pantauan
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.aktif ? 'Pantau aktif' : 'Nonaktif',
                          style: AppTypography.labelSmall.copyWith(
                            color: item.aktif
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: item.aktif ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: item.aktif,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primaryContainer,
                            inactiveThumbColor: AppColors.textMuted,
                            inactiveTrackColor: AppColors.surfaceElevated,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: onToggleActive,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetStatusIndicator(bool isReached) {
    if (!item.hargaTersedia || item.hargaTerendah == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Belum terpantau',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    if (isReached) {
      final double saving = (item.hargaTarget - item.hargaTerendah!).clamp(0.0, 9999.0);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: AppRadius.fullBorderRadius,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              saving > 0
                  ? 'Mencapai target! Hemat \$${saving.toStringAsFixed(2)}'
                  : 'Mencapai target!',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Belum mencapai target
    final double diff = item.selisihHargaTarget ?? (item.hargaTerendah! - item.hargaTarget);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.arrow_upward_rounded,
          size: 13,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 2),
        Text(
          '+\$${diff.toStringAsFixed(2)} dari target',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverFallback() {
    return const Center(
      child: Icon(
        Icons.sports_esports_rounded,
        color: AppColors.textMuted,
        size: 32,
      ),
    );
  }
}
