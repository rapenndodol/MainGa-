import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'auth_brand_mark.dart';

/// Kerangka layar autentikasi yang bersih, aman terhadap keyboard dan layar
/// sempit 360dp, serta memakai judul besar sebagai fokus utama.
class AuthPageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final List<Widget> children;

  const AuthPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - AppSpacing.huge)
                      .clamp(0.0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (onBack != null)
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              tooltip: 'Kembali',
                              onPressed: onBack,
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        const Spacer(),
                        const AuthBrandMark(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.huge),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: reduceMotion
                          ? Duration.zero
                          : AppMotion.slow,
                      curve: AppMotion.curve,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 8),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            title,
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 40,
                              height: 1.05,
                              letterSpacing: -1.6,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            subtitle,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.huge),
                    ...children,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
