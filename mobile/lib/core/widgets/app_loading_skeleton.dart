import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Skeleton box tunggal dengan animasi pulse halus.
class AppSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? AppRadius.smBorderRadius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
        );
      },
    );
  }
}

/// Skeleton untuk kartu game dalam daftar.
class AppGameCardSkeleton extends StatelessWidget {
  const AppGameCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover skeleton
          AppSkeletonBox(
            width: 80,
            height: 110,
            borderRadius: AppRadius.mdBorderRadius,
          ),
          const SizedBox(width: AppSpacing.md),
          // Content info skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                AppSkeletonBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                AppSkeletonBox(
                  width: 140,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    AppSkeletonBox(
                      width: 50,
                      height: 22,
                      borderRadius: AppRadius.fullBorderRadius,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppSkeletonBox(
                      width: 44,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton untuk daftar list game (misal saat Jelajah / Library sedang loading)
class AppListSkeleton extends StatelessWidget {
  final int itemCount;

  const AppListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: itemCount,
      itemBuilder: (_, _) => const AppGameCardSkeleton(),
    );
  }
}
