import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SummaryStatsRow extends StatelessWidget {
  final int totalGame;
  final double totalJam;
  final int jumlahTamat;

  const SummaryStatsRow({
    super.key,
    required this.totalGame,
    required this.totalJam,
    required this.jumlahTamat,
  });

  String _formatJam(double hours) {
    if (hours % 1 == 0) {
      return '${hours.toInt()}j';
    }
    return '${hours.toStringAsFixed(1)}j';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Total Game',
            value: totalGame.toString(),
            icon: Icons.sports_esports_rounded,
            iconColor: AppColors.primary,
            containerColor: AppColors.primaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildMetricCard(
            label: 'Jam Bermain',
            value: _formatJam(totalJam),
            icon: Icons.timer_rounded,
            iconColor: AppColors.secondary,
            containerColor: AppColors.secondaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildMetricCard(
            label: 'Game Tamat',
            value: jumlahTamat.toString(),
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.statusCompleted,
            containerColor: AppColors.statusCompleted.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color containerColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: AppRadius.smBorderRadius,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs - 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
