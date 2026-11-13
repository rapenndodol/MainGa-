import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Skeleton box tunggal dengan animasi pulse tone surface -> surfaceElevated.
/// Menghormati preferensi reduce-motion pengguna.
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
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
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
        final double t = _reduceMotion ? 0.35 : _animation.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.surface,
              AppColors.surfaceElevated,
              t,
            ),
            borderRadius: widget.borderRadius ?? AppRadius.smBorderRadius,
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.25),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton untuk kartu game dalam daftar.
///
/// [surfaced] dipertahankan untuk daftar bergaya kartu (Library/Notifikasi),
/// sedangkan Jelajah memakai varian tanpa permukaan agar bentuknya sama
/// dengan [AppGameCard] yang editorial.
class AppGameCardSkeleton extends StatelessWidget {
  final bool surfaced;

  const AppGameCardSkeleton({super.key, this.surfaced = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaced ? AppColors.surface : AppColors.transparent,
        borderRadius: AppRadius.lgBorderRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover skeleton (3:4)
          AppSkeletonBox(
            width: 88,
            height: 118,
            borderRadius: AppRadius.mdBorderRadius,
          ),
          const SizedBox(width: AppSpacing.lg),
          // Content info skeleton
          Expanded(
            child: SizedBox(
              height: 118,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  AppSkeletonBox(
                    width: double.infinity,
                    height: 16,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSkeletonBox(
                    width: 140,
                    height: 14,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      AppSkeletonBox(
                        width: 52,
                        height: 22,
                        borderRadius: AppRadius.fullBorderRadius,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppSkeletonBox(
                        width: 40,
                        height: 14,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                    ],
                  ),
                ],
              ),
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
  final bool surfaced;
  final EdgeInsetsGeometry padding;

  const AppListSkeleton({
    super.key,
    this.itemCount = 6,
    this.surfaced = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (_, _) => AppGameCardSkeleton(surfaced: surfaced),
    );
  }
}

/// Skeleton horizontal untuk carousel rekomendasi di Jelajah.
class AppRecommendationSkeleton extends StatelessWidget {
  final double height;

  const AppRecommendationSkeleton({super.key, this.height = 208});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = constraints.maxWidth * 0.86;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: 2,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, _) {
              return Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardBorderRadius,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.4),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: AppSkeletonBox(
                        height: 208,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppSkeletonBox(width: 160, height: 16),
                          SizedBox(height: AppSpacing.sm),
                          AppSkeletonBox(width: 110, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
