import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_interactive_card.dart';
import '../../../../core/widgets/game_hero_tag.dart';
import '../../../games/data/models/game_model.dart';
import '../../data/models/wishlist_item_model.dart';

class WishlistGameCard extends StatelessWidget {
  final WishlistItemModel item;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;
  final int index;

  const WishlistGameCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
    this.index = 0,
  });

  String _formatIdr(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  GameModel _heroGame() {
    return item.game ??
        GameModel(
          id: item.gameId,
          rawgId: item.gameId,
          judul: item.judul,
          coverUrl: item.coverUrl,
          rating: item.rating,
          genre: '',
          genres: const [],
          platform: '',
          platforms: const [],
        );
  }

  @override
  Widget build(BuildContext context) {
    final bool isReached = item.isTargetReached;
    final bool isInactive = !item.aktif;

    return AppInteractiveCard(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBorderRadius,
          border: Border.all(
            color: isReached
                ? AppColors.primary.withValues(alpha: 0.85)
                : AppColors.border,
            width: isReached ? 1.3 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCover(),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.judul,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                      color: isInactive
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  tooltip: 'Hapus dari Wishlist',
                                  onPressed: onDelete,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _buildTargetPrice(),
                            const SizedBox(height: AppSpacing.sm),
                            _buildBestPrice(isReached),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Divider(
                    color: AppColors.border.withValues(alpha: 0.55),
                    height: 1,
                    thickness: 1,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTargetStatusIndicator(isReached),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        item.aktif ? 'Pantau aktif' : 'Nonaktif',
                        style: AppTypography.labelSmall.copyWith(
                          color: item.aktif
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                          fontWeight: item.aktif
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Switch(
                        value: item.aktif,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryContainer,
                        inactiveThumbColor: AppColors.textMuted,
                        inactiveTrackColor: AppColors.surfaceElevated,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onChanged: onToggleActive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return Hero(
      tag: gameCoverHeroTag(_heroGame(), 'wishlist'),
      child: ClipRRect(
        borderRadius: AppRadius.controlLargeBorderRadius,
        child: Container(
          width: 80,
          height: 108,
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
    );
  }

  Widget _buildTargetPrice() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: AppSpacing.xxs,
      children: [
        Text(
          'Target: ',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        Text(
          '\$${item.hargaTarget.toStringAsFixed(2)}',
          style: AppTypography.tabular(
            AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
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
    );
  }

  Widget _buildBestPrice(bool isReached) {
    if (!item.hargaTersedia || item.hargaTerendah == null) {
      return Row(
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
            ),
          ),
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        Text(
          '${item.tokoTermurah ?? 'Termurah'}: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '\$${item.hargaTerendah!.toStringAsFixed(2)}',
          style: AppTypography.tabular(
            AppTypography.titleSmall.copyWith(
              color: isReached ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
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
              horizontal: AppSpacing.xs + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.smBorderRadius,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.38),
              ),
            ),
            child: Text(
              '-${item.diskonPersen!.toStringAsFixed(0)}%',
              style: AppTypography.tabular(
                AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
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
          Flexible(
            child: Text(
              'Belum terpantau',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      );
    }

    if (isReached) {
      final double saving = (item.hargaTarget - item.hargaTerendah!).clamp(
        0.0,
        9999.0,
      );
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.fullBorderRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.onPrimary,
              size: 13,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                saving > 0
                    ? 'Mencapai target! Hemat \$${saving.toStringAsFixed(2)}'
                    : 'Mencapai target!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.tabular(
                  AppTypography.labelSmall.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final double diff =
        item.selisihHargaTarget ?? (item.hargaTerendah! - item.hargaTarget);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.arrow_upward_rounded,
          size: 13,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '+\$${diff.toStringAsFixed(2)} dari target',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
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
