import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Atribusi resmi RAWG.io dengan gaya warm obsidian dan tautan aktif.
class AppRawgAttribution extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const AppRawgAttribution({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.lg),
  });

  Future<void> _launchRawg() async {
    final uri = Uri.parse('https://rawg.io');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.fullBorderRadius,
            onTap: _launchRawg,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.fullBorderRadius,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Data by ',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    'RAWG.io',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryLight.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: AppColors.primaryLight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
