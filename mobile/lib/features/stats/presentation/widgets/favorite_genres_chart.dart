import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_stats_model.dart';

class FavoriteGenresChart extends StatelessWidget {
  final List<GenreStats> genres;

  const FavoriteGenresChart({
    super.key,
    required this.genres,
  });

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.statusCompleted,
    AppColors.statusWishlist,
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const SizedBox.shrink();
    }

    final int totalCount = genres.fold<int>(0, (sum, item) => sum + item.jumlah);

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
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Maksimal 5 genre teratas di library',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Donut Chart ──────────────────────────────────────
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 38,
                sectionsSpace: 3,
                borderData: FlBorderData(show: false),
                sections: List.generate(genres.length, (index) {
                  final item = genres[index];
                  final color = _palette[index % _palette.length];
                  final double pct = totalCount > 0 ? (item.jumlah / totalCount) * 100 : 0;

                  return PieChartSectionData(
                    color: color,
                    value: item.jumlah.toDouble(),
                    title: '${pct.round()}%',
                    radius: 36,
                    titleStyle: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: index == 1 ? Colors.black87 : Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Legend ──────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: genres.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs + 2),
            itemBuilder: (context, index) {
              final item = genres[index];
              final color = _palette[index % _palette.length];
              final double pct = totalCount > 0 ? (item.jumlah / totalCount) * 100 : 0;

              return Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.nama,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.jumlah} game (${pct.toStringAsFixed(0)}%)',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
