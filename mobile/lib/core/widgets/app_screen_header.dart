import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Header layar besar bergaya editorial untuk tab utama Fase 3.
///
/// Menjaga satu pola judul: eyebrow kecil dengan penanda lime, judul display
/// yang tegas, subjudul ringkas, area aksi di kanan, dan slot footer untuk
/// kontrol yang harus selalu terlihat (mis. tombol Acak atau chip filter).
class AppScreenHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const AppScreenHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.sm,
    ),
  });

  bool get _hasEyebrow => eyebrow != null && eyebrow!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null || _hasEyebrow) ...[
            Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xxs),
                ] else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (leading == null && _hasEyebrow)
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xxs),
                if (_hasEyebrow)
                  Expanded(
                    child: Text(
                      eyebrow!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.overline.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 30,
                    letterSpacing: -0.9,
                  ),
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.md),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
          // Subtitle memakai lebar penuh agar tidak terhimpit tombol aksi
          // pada layar 360dp dengan text scale besar.
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs + 1),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}
