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
    // IntrinsicHeight menjaga ketiga kartu tetap sama tinggi saat label
    // terpaksa turun ke baris kedua pada text scale 1.3.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              containerColor: AppColors.statusCompleted.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
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
        horizontal: AppSpacing.sm + 2,
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
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: AppRadius.smBorderRadius,
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.metricLarge.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 10.5,
              height: 1.25,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
