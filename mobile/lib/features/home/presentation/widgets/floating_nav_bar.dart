import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// Navigation dock mengambang dengan indikator lime yang bergeser halus.
/// Keempat label tetap terlihat agar tujuan tab selalu jelas, sementara
/// ikon terisi menandai tab aktif tanpa mengorbankan ruang vertikal.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Jelajah',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    _NavDestination(
      label: 'Library',
      icon: Icons.collections_bookmark_outlined,
      activeIcon: Icons.collections_bookmark_rounded,
    ),
    _NavDestination(
      label: 'Wishlist',
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
    ),
    _NavDestination(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.98),
          borderRadius: AppRadius.fullBorderRadius,
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.fullBorderRadius,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth =
                  constraints.maxWidth / _destinations.length;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppMotion.base,
                    curve: AppMotion.curve,
                    left: itemWidth * currentIndex + AppSpacing.xs,
                    top: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    width: itemWidth - AppSpacing.sm,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.fullBorderRadius,
                      ),
                    ),
                  ),
                  Row(
                    children: List<Widget>.generate(
                      _destinations.length,
                      (int index) {
                        final bool isSelected = currentIndex == index;
                        return Expanded(
                          child: _NavItem(
                            destination: _destinations[index],
                            isSelected: isSelected,
                            onTap: () => onSelected(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        isSelected ? AppColors.onPrimary : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? destination.activeIcon : destination.icon,
                  size: 21,
                  color: foreground,
                ),
                const SizedBox(height: AppSpacing.xxs + 1),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
