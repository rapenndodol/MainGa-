import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, destructive, ghost }

/// Tombol bersama bergaya pill dengan umpan balik tekan yang halus.
class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? side;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = AppColors.onPrimary;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.surfaceElevated;
        foregroundColor = AppColors.textPrimary;
        side = const BorderSide(color: AppColors.border, width: 1);
        break;
      case AppButtonVariant.outline:
        backgroundColor = AppColors.transparent;
        foregroundColor = AppColors.textPrimary;
        side = const BorderSide(color: AppColors.border, width: 1.2);
        break;
      case AppButtonVariant.destructive:
        backgroundColor = AppColors.error.withValues(alpha: 0.15);
        foregroundColor = AppColors.error;
        side = BorderSide(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1,
        );
        break;
      case AppButtonVariant.ghost:
        backgroundColor = AppColors.transparent;
        foregroundColor = AppColors.textPrimary;
        break;
    }

    final bool isDisabled = widget.onPressed == null;
    final bool isBusy = isDisabled || widget.isLoading;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      value: widget.isLoading ? 'Memuat' : null,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedScale(
          scale: _pressed && !isBusy ? 0.98 : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          child: Material(
            color: isDisabled
                ? backgroundColor.withValues(alpha: 0.45)
                : backgroundColor,
            borderRadius: AppRadius.fullBorderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: AppRadius.fullBorderRadius,
              onHighlightChanged: (value) {
                if (isBusy) return;
                setState(() => _pressed = value);
              },
              onTap: isBusy
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onPressed!();
                    },
              child: Container(
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.fullBorderRadius,
                  border: side != null
                      ? Border.fromBorderSide(
                          isDisabled
                              ? side.copyWith(
                                  color: side.color.withValues(alpha: 0.4),
                                )
                              : side,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(foregroundColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 18,
                              color: foregroundColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            widget.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge.copyWith(
                              color: isDisabled
                                  ? foregroundColor.withValues(alpha: 0.5)
                                  : foregroundColor,
                            ),
                          ),
                          if (widget.trailingIcon != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            widget.trailingIcon!,
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
