import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// App Bar / Header bersama untuk seluruh layar.
/// Tinggi toolbar memberi ruang aman hingga text scale 1.3.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  double get _toolbarHeight => subtitle != null ? 76.0 : 60.0;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bg,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: _toolbarHeight,
      titleSpacing: AppSpacing.lg,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ??
          (Navigator.canPop(context) && automaticallyImplyLeading
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              : null),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight);
}
