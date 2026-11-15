import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Input field bersama dengan permukaan gelap dan batas fokus lime.
/// Label tetap terlihat di atas field; pesan galat tampil tepat di bawah
/// field melalui mekanisme validator FormField.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          autocorrect: !obscureText,
          enableSuggestions: !obscureText,
          keyboardAppearance: Brightness.dark,
          cursorColor: AppColors.primary,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            height: 1.35,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textMuted, size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.inputBackground,
            errorMaxLines: 2,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg + AppSpacing.xxs,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.controlLargeBorderRadius,
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.controlLargeBorderRadius,
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.controlLargeBorderRadius,
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.controlLargeBorderRadius,
              borderSide: const BorderSide(
                color: AppColors.borderFocused,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.controlLargeBorderRadius,
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.controlLargeBorderRadius,
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
