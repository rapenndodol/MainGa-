import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cangkang bottom sheet bersama: tone surface terangkat, sudut atas 24dp,
/// garis tepi tipis, drag handle, dan penyesuaian keyboard di satu tempat.
class AppSheetShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final bool showHandle;
  final double maxHeightFactor;

  const AppSheetShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
    this.scrollable = true,
    this.showHandle = true,
    this.maxHeightFactor = 0.94,
  });

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final Widget content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle) ...[
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.fullBorderRadius,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (scrollable)
            Flexible(child: SingleChildScrollView(child: child))
          else
            Flexible(child: child),
        ],
      ),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.sheetTopBorderRadius,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.2),
          left: BorderSide(color: AppColors.border, width: 1.2),
          right: BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: reduceMotion ? Duration.zero : AppMotion.fast,
          curve: AppMotion.curve,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: content,
        ),
      ),
    );
  }
}

/// Header konsisten untuk seluruh bottom sheet Fase 3.
class AppSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? leading;
  final IconData icon;
  final VoidCallback? onClose;
  final String closeTooltip;
  final Widget? trailing;

  const AppSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.leading,
    this.icon = Icons.tune_rounded,
    this.onClose,
    this.closeTooltip = 'Tutup',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Widget leadingWidget =
        leading ??
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: AppRadius.controlLargeBorderRadius,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.32),
            ),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leadingWidget,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null && eyebrow!.trim().isNotEmpty) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
              ],
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
        if (onClose != null)
          IconButton(
            tooltip: closeTooltip,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: onClose,
          ),
      ],
    );
  }
}
