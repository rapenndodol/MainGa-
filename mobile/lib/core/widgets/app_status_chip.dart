import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Helper mapping status game koleksi ke warna dan ikon tema baru
class AppStatusHelper {
  AppStatusHelper._();

  static const List<String> statuses = [
    'Sedang Dimainkan',
    'Tamat',
    'Backlog',
    'Wishlist',
    'Dropped',
  ];

  static Color getStatusColor(String status) {
    switch (status) {
      case 'Sedang Dimainkan':
        return AppColors.statusPlaying;
      case 'Tamat':
        return AppColors.statusCompleted;
      case 'Backlog':
        return AppColors.statusBacklog;
      case 'Wishlist':
        return AppColors.statusWishlist;
      case 'Dropped':
        return AppColors.statusDropped;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'Sedang Dimainkan':
        return Icons.play_circle_fill_rounded;
      case 'Tamat':
        return Icons.check_circle_rounded;
      case 'Backlog':
        return Icons.inventory_2_rounded;
      case 'Wishlist':
        return Icons.bookmark_added_rounded;
      case 'Dropped':
        return Icons.remove_circle_outline_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }
}

/// Status chip bersama untuk Library & Detail Game.
class AppStatusChip extends StatelessWidget {
  final String status;
  final bool compact;
  final bool isSelected;
  final VoidCallback? onTap;

  const AppStatusChip({
    super.key,
    required this.status,
    this.compact = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppStatusHelper.getStatusColor(status);
    final icon = AppStatusHelper.getStatusIcon(status);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.xs + 3,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.25)
            : color.withValues(alpha: 0.12),
        borderRadius: AppRadius.fullBorderRadius,
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.35),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs + 1),
          Text(
            status,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: AppRadius.fullBorderRadius,
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
