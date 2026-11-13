import 'package:flutter/material.dart';
import '../../features/games/data/models/game_model.dart';
import '../../features/games/presentation/screens/game_detail_screen.dart';
import '../theme/app_theme.dart';
import 'app_badge.dart';
import 'game_hero_tag.dart';

/// Kartu game reusable bergaya editorial: cover poster dominan, judul tegas,
/// metadata ringkas, dan animasi masuk yang halus saat item pertama dibangun.
class AppGameCard extends StatefulWidget {
  final GameModel game;
  final VoidCallback? onTap;
  final String heroScope;

  /// Baris ke berapa kartu ini ditampilkan. Dipakai untuk stagger masuk yang
  /// singkat; nilai besar dibatasi agar daftar panjang tidak terasa lambat.
  final int index;

  const AppGameCard({
    super.key,
    required this.game,
    this.onTap,
    this.heroScope = 'katalog',
    this.index = 0,
  });

  @override
  State<AppGameCard> createState() => _AppGameCardState();
}

class _AppGameCardState extends State<AppGameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _pressed = false;
  bool _reduceMotion = false;

  String get _heroTag => gameCoverHeroTag(widget.game, widget.heroScope);

  @override
  void initState() {
    super.initState();
    final int delay = widget.index.clamp(0, 6).toInt() * 24; // maksimal 144 ms
    final int total = AppMotion.slow.inMilliseconds + delay;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    final double start = total == 0 ? 0.0 : delay / total;
    final CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1.0, curve: AppMotion.curve),
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.value = 1.0;
    } else if (!_controller.isAnimating && _controller.value < 1.0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetail() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(
          game: widget.game,
          heroTag: _heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1.0,
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            child: Material(
              color: _pressed ? AppColors.surface : AppColors.transparent,
              borderRadius: AppRadius.lgBorderRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: AppRadius.lgBorderRadius,
                onHighlightChanged: (value) =>
                    setState(() => _pressed = value),
                onTap: _openDetail,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Cover poster 3:4 ─────────────────────────
                      Hero(
                        tag: _heroTag,
                        child: ClipRRect(
                          borderRadius: AppRadius.mdBorderRadius,
                          child: SizedBox(
                            width: 88,
                            height: 118,
                            child: _buildCover(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md + AppSpacing.xxs),

                      // ── Informasi game ──────────────────────────
                      Expanded(
                        child: SizedBox(
                          height: 118,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.game.judul,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.arrow_outward_rounded,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.game.genre.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs + 1),
                                Text(
                                  widget.game.genre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Row(
                                children: [
                                  AppBadge.rating(
                                    widget.game.rating,
                                    compact: true,
                                  ),
                                  if (_year.isNotEmpty) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      _year,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                  if (_firstPlatform.isNotEmpty) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: AppColors.textMuted,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        _firstPlatform,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _year {
    final String? release = widget.game.tanggalRilis;
    if (release == null || release.isEmpty) return '';
    return release.length >= 4 ? release.substring(0, 4) : release;
  }

  String get _firstPlatform {
    if (widget.game.platforms.isNotEmpty) {
      return widget.game.platforms.first;
    }
    if (widget.game.platform.isNotEmpty) {
      return widget.game.platform.split(',').first.trim();
    }
    return '';
  }

  Widget _buildCover() {
    final String? coverUrl = widget.game.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      return _buildCoverFallback();
    }

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      cacheWidth: 264,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _buildCoverFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surfaceElevated,
          child: const Center(
            child: Icon(
              Icons.sports_esports_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: AppColors.textMuted,
          size: 28,
        ),
      ),
    );
  }
}
