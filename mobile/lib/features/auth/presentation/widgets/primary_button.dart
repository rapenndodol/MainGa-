import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';

/// Adapter PrimaryButton yang mendelegasikan ke AppButton terpusat.
/// Menggantikan gradient ungu lama dengan bentuk Pill solid coral red.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      variant: AppButtonVariant.primary,
      height: 52,
    );
  }
}
