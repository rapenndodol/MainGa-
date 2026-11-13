import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Pesan galat form yang tampil inline, bukan lewat SnackBar.
class AuthInlineError extends StatelessWidget {
  final String message;

  const AuthInlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppRadius.mdBorderRadius,
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
