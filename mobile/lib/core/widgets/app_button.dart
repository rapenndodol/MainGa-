import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, destructive, ghost }

/// Tombol bersama bergaya Pill modern sesuai referensi visual.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? trailingIcon;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 50.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? side;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.surfaceElevated;
        foregroundColor = AppColors.textPrimary;
        side = const BorderSide(color: AppColors.border, width: 1);
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.textPrimary;
        side = const BorderSide(color: AppColors.border, width: 1.2);
        break;
      case AppButtonVariant.destructive:
        backgroundColor = AppColors.error.withValues(alpha: 0.15);
        foregroundColor = AppColors.error;
        side = BorderSide(color: AppColors.error.withValues(alpha: 0.4), width: 1);
        break;
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primaryLight;
        break;
    }

    final bool isDisabled = onPressed == null || isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: isDisabled ? backgroundColor.withValues(alpha: 0.45) : backgroundColor,
        borderRadius: AppRadius.fullBorderRadius,
        child: InkWell(
          borderRadius: AppRadius.fullBorderRadius,
          onTap: isDisabled ? null : onPressed,
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: AppRadius.fullBorderRadius,
              border: side != null
                  ? Border.fromBorderSide(
                      isDisabled ? side.copyWith(color: side.color.withValues(alpha: 0.4)) : side,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: foregroundColor),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        text,
                        style: AppTypography.labelLarge.copyWith(
                          color: isDisabled
                              ? foregroundColor.withValues(alpha: 0.5)
                              : foregroundColor,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        trailingIcon!,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
