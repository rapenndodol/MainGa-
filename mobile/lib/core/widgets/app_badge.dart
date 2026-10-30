import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppBadgeVariant { neutral, primary, secondary, warning, success, error }

/// Badge kecil serbaguna untuk rating, genre, platform, counter.
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppBadgeVariant variant;
  final bool compact;
  final Color? customColor;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppBadgeVariant.neutral,
    this.compact = false,
    this.customColor,
  });

  /// Factory khusus untuk badge rating bintang
  factory AppBadge.rating(double rating, {bool compact = false}) {
    return AppBadge(
      label: rating.toStringAsFixed(1),
      icon: Icons.star_rounded,
      variant: AppBadgeVariant.warning,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    if (customColor != null) {
      textColor = customColor!;
      bgColor = customColor!.withValues(alpha: 0.15);
      borderColor = customColor!.withValues(alpha: 0.35);
    } else {
      switch (variant) {
        case AppBadgeVariant.neutral:
          textColor = AppColors.textSecondary;
          bgColor = AppColors.surfaceElevated;
          borderColor = AppColors.border;
          break;
        case AppBadgeVariant.primary:
          textColor = AppColors.primary;
          bgColor = AppColors.primary.withValues(alpha: 0.16);
          borderColor = AppColors.primary.withValues(alpha: 0.4);
          break;
        case AppBadgeVariant.secondary:
          textColor = AppColors.secondary;
          bgColor = AppColors.secondary.withValues(alpha: 0.15);
          borderColor = AppColors.secondary.withValues(alpha: 0.35);
          break;
        case AppBadgeVariant.warning:
          textColor = AppColors.ratingStar;
          bgColor = AppColors.ratingStar.withValues(alpha: 0.15);
          borderColor = AppColors.ratingStar.withValues(alpha: 0.35);
          break;
        case AppBadgeVariant.success:
          textColor = AppColors.success;
          bgColor = AppColors.success.withValues(alpha: 0.15);
          borderColor = AppColors.success.withValues(alpha: 0.35);
          break;
        case AppBadgeVariant.error:
          textColor = AppColors.error;
          bgColor = AppColors.error.withValues(alpha: 0.15);
          borderColor = AppColors.error.withValues(alpha: 0.35);
          break;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.fullBorderRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
