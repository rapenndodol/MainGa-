import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';
import '../../data/models/game_price_model.dart';

class PriceTrackerSection extends StatefulWidget {
  final int gameIdOrRawgId;

  const PriceTrackerSection({
    super.key,
    required this.gameIdOrRawgId,
  });

  @override
  State<PriceTrackerSection> createState() => _PriceTrackerSectionState();
}

class _PriceTrackerSectionState extends State<PriceTrackerSection> {
  final _dataSource = WishlistRemoteDataSource();

  GamePricesResponseModel? _pricesData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  @override
  void didUpdateWidget(covariant PriceTrackerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameIdOrRawgId != widget.gameIdOrRawgId) {
      _fetchPrices();
    }
  }

  Future<void> _fetchPrices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _dataSource.fetchGamePrices(widget.gameIdOrRawgId);
      if (!mounted) return;

      setState(() {
        _pricesData = res;
        _isLoading = false;
        _errorMessage = res.success ? null : res.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data harga: $e';
      });
    }
  }

  String _formatIdr(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime? dt, String? raw) {
    if (dt != null) {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
    }
    if (raw != null && raw.isNotEmpty) {
      return raw.split('T').first;
    }
    return '-';
  }

  String _formatShortDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d/M').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null && (_pricesData == null || !_pricesData!.hargaTersedia)) {
      return _buildUnavailableContainer();
    }

    final data = _pricesData;
    if (data == null || !data.hargaTersedia || data.hargaTerkini.isEmpty) {
      return _buildUnavailableContainer();
    }

    // Pastikan harga terkini diurutkan dari yang termurah
    final sortedStores = List<StorePriceItem>.from(data.hargaTerkini)
      ..sort((a, b) => a.harga.compareTo(b.harga));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Bagian Harga ───────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Harga',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (data.tokoTermurah != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: AppRadius.fullBorderRadius,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      size: 13,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Termurah di ${data.tokoTermurah}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Daftar Harga per Toko ──────────────────────────────
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedStores.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = sortedStores[index];
            final bool isCheapest = index == 0;

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgBorderRadius,
                border: Border.all(
                  color: isCheapest
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: isCheapest ? 1.2 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Icon Toko / Initial Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Icon(
                        _getStoreIcon(item.toko),
                        size: 18,
                        color: isCheapest
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Nama Toko & Waktu Cek Terakhir
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.toko,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCheapest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: AppRadius.smBorderRadius,
                                ),
                                child: Text(
                                  'Termurah',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dicek: ${_formatDate(item.dicekPada, item.dicekPadaRaw)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Harga USD & Estimasi Rupiah + Diskon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.diskonPersen > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: AppRadius.smBorderRadius,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '-${item.diskonPersen.toStringAsFixed(0)}%',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          Text(
                            '\$${item.harga.toStringAsFixed(2)}',
                            style: AppTypography.titleMedium.copyWith(
                              color: isCheapest
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'estimasi ${_formatIdr(item.hargaIdrEstimasi)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Grafik Riwayat Harga (fl_chart) ───────────────────
        Text(
          'Riwayat Harga',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        _buildChartContent(data.riwayatHarga),
      ],
    );
  }

  Widget _buildChartContent(List<StorePriceItem> history) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBorderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            'Harga belum tersedia',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    if (history.length == 1) {
      final singlePoint = history.first;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBorderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${singlePoint.toko}: \$${singlePoint.harga.toStringAsFixed(2)}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Riwayat belum cukup untuk grafik',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Riwayat dengan 2 titik atau lebih
    final sortedHistory = List<StorePriceItem>.from(history)
      ..sort((a, b) {
        if (a.dicekPada != null && b.dicekPada != null) {
          return a.dicekPada!.compareTo(b.dicekPada!);
        }
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });

    final spots = <FlSpot>[];
    double minPrice = double.infinity;
    double maxPrice = 0.0;

    for (int i = 0; i < sortedHistory.length; i++) {
      final p = sortedHistory[i].harga;
      spots.add(FlSpot(i.toDouble(), p));
      if (p < minPrice) minPrice = p;
      if (p > maxPrice) maxPrice = p;
    }

    if (minPrice == double.infinity) minPrice = 0;
    if (maxPrice == 0) maxPrice = 10;

    final double paddingY = (maxPrice - minPrice) * 0.2;
    final double computedMinY = (minPrice - (paddingY > 1 ? paddingY : 1)).clamp(0.0, double.infinity);
    final double computedMaxY = maxPrice + (paddingY > 1 ? paddingY : 2);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: computedMinY,
          maxY: computedMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((computedMaxY - computedMinY) / 4).clamp(1.0, 100.0),
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '\$${value.toStringAsFixed(0)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: (spots.length > 5 ? (spots.length / 4).floorToDouble() : 1),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedHistory.length) {
                    final item = sortedHistory[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _formatShortDate(item.dicekPada),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceElevated,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.spotIndex;
                  final item = idx >= 0 && idx < sortedHistory.length
                      ? sortedHistory[idx]
                      : null;
                  final storeName = item?.toko ?? 'Harga';

                  return LineTooltipItem(
                    '$storeName\n\$${spot.y.toStringAsFixed(2)}',
                    AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: AppColors.primaryLight,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.surfaceElevated,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadius.mdBorderRadius,
                ),
                child: const Icon(
                  Icons.price_change_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga belum tersedia',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Data harga multi-toko dari CheapShark belum tersedia untuk game ini.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonBox(width: 140, height: 18),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBox(width: double.infinity, height: 60),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonBox(width: double.infinity, height: 60),
        SizedBox(height: AppSpacing.lg),
        AppSkeletonBox(width: 120, height: 16),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonBox(width: double.infinity, height: 180),
      ],
    );
  }

  IconData _getStoreIcon(String toko) {
    final lower = toko.toLowerCase();
    if (lower.contains('steam')) return Icons.sports_esports_rounded;
    if (lower.contains('epic')) return Icons.gamepad_rounded;
    if (lower.contains('gog')) return Icons.shopping_bag_outlined;
    return Icons.storefront_rounded;
  }
}
