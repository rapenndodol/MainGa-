import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Baris chip filter horizontal yang dipakai bersama oleh Library dan Wishlist.
///
/// Chip terpilih memakai isian putih dengan teks hitam ([AppColors.onSecondary])
/// mengikuti aturan 30% putih, sementara lime tetap disimpan untuk aksi utama.
/// Tinggi area sentuh dijaga 48dp dan status terpilih diekspos ke pembaca layar.
class AppFilterChipBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;
  final bool haptics;

  const AppFilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
    this.haptics = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final String option = options[index];
          return _AppFilterChip(
            label: option,
            isSelected: option == selected,
            haptics: haptics,
            onTap: () => onSelected(option),
          );
        },
      ),
    );
  }
}

class _AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool haptics;
  final VoidCallback onTap;

  const _AppFilterChip({
    required this.label,
    required this.isSelected,
    required this.haptics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: () {
          if (isSelected) return;
          if (haptics) HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: AppRadius.fullBorderRadius,
        child: Center(
          widthFactor: 1,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : AppMotion.fast,
            curve: AppMotion.curve,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.white : AppColors.surfaceElevated,
              borderRadius: AppRadius.fullBorderRadius,
              border: Border.all(
                color: isSelected ? AppColors.white : AppColors.border,
                width: 1,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.onSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
