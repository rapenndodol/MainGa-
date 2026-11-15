import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_stats_model.dart';

class FavoriteGenresChart extends StatelessWidget {
  final List<GenreStats> genres;

  const FavoriteGenresChart({super.key, required this.genres});

  static const List<Color> _palette = [
    AppColors.chartDonutSlice1,
    AppColors.chartDonutSlice2,
    AppColors.chartDonutSlice3,
    AppColors.chartDonutSlice4,
    AppColors.chartDonutSlice5,
  ];

  @override
  Widget build(BuildContext context) {
    final int totalCount = genres.fold<int>(
      0,
      (sum, item) => sum + item.jumlah,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: AppRadius.smBorderRadius,
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Genre Favorit',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Maksimal 5 genre teratas di library',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (genres.isEmpty)
            _buildEmptyState()
          else ...[
            Semantics(
              label:
                  'Diagram donut genre favorit dari $totalCount game di library',
              child: SizedBox(
                height: 164,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 42,
                        sectionsSpace: 3,
                        borderData: FlBorderData(show: false),
                        sections: List.generate(genres.length, (index) {
                          final item = genres[index];
                          final color = _palette[index % _palette.length];
                          final double pct = totalCount > 0
                              ? (item.jumlah / totalCount) * 100
                              : 0;

                          return PieChartSectionData(
                            color: color,
                            value: item.jumlah.toDouble(),
                            title: '${pct.round()}%',
                            radius: 36,
                            titleStyle: AppTypography.tabular(
                              AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color.computeLuminance() > 0.35
                                    ? AppColors.onPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalCount',
                          style: AppTypography.tabular(
                            AppTypography.metricMedium.copyWith(fontSize: 22),
                          ),
                        ),
                        Text(
                          'game',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: genres.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = genres[index];
                final color = _palette[index % _palette.length];
                final double pct = totalCount > 0
                    ? (item.jumlah / totalCount) * 100
                    : 0;

                return Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${item.jumlah} game (${pct.toStringAsFixed(0)}%)',
                      style: AppTypography.tabular(
                        AppTypography.labelSmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.lgBorderRadius,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pie_chart_outline_rounded,
            color: AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Genre belum terpetakan',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Tambahkan genre pada game di library untuk melihat favoritmu.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
