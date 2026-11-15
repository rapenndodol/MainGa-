import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_rawg_attribution.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/game_hero_tag.dart';
import '../../../library/data/models/library_entry_model.dart';
import '../../../library/presentation/controllers/library_notifier.dart';
import '../../../library/presentation/widgets/library_entry_sheet.dart';
import '../../../wishlist/data/models/wishlist_item_model.dart';
import '../../../wishlist/presentation/controllers/wishlist_notifier.dart';
import '../../../wishlist/presentation/widgets/price_tracker_section.dart';
import '../../../wishlist/presentation/widgets/wishlist_form_sheet.dart';
import '../../data/datasources/game_remote_data_source.dart';
import '../../data/models/game_model.dart';

class GameDetailScreen extends StatefulWidget {
  final GameModel game;
  final String? heroTag;

  const GameDetailScreen({super.key, required this.game, this.heroTag});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late GameModel _game;
  bool _isLoadingDetail = false;
  bool _isDescriptionExpanded = false;
  List<GameModel> _similarGames = [];
  final _gameDataSource = GameRemoteDataSource();

  String get _heroTag => widget.heroTag ?? gameCoverHeroTag(_game, 'detail');

  @override
  void initState() {
    super.initState();
    _game = widget.game;

    // Selalu fetch detail terbaru untuk sinkronisasi deskripsi, status library, dan wishlist
    _fetchFullDetail();

    // Dengarkan perubahan library dan wishlist agar layar detail langsung ikut ter-update
    LibraryNotifier.instance.addListener(_onLibraryChanged);
    WishlistNotifier.instance.addListener(_onWishlistChanged);
  }

  @override
  void dispose() {
    LibraryNotifier.instance.removeListener(_onLibraryChanged);
    WishlistNotifier.instance.removeListener(_onWishlistChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (!mounted) return;
    final notifier = LibraryNotifier.instance;
    final gameId = _game.id > 0 ? _game.id : _game.rawgId;

    if (notifier.lastModifiedGameId == gameId ||
        notifier.lastModifiedGameId == _game.id ||
        notifier.lastModifiedGameId == _game.rawgId) {
      if (notifier.lastActionWasDelete) {
        setState(() {
          _game = _game.copyWith(clearLibraryStatus: true);
        });
      } else if (notifier.lastModifiedStatus != null) {
        setState(() {
          _game = _game.copyWith(
            libraryStatus: notifier.lastModifiedStatus,
            libraryEntryData: notifier.lastModifiedEntry?.toJson(),
          );
        });
      }
    }
  }

  void _onWishlistChanged() {
    if (!mounted) return;
    final notifier = WishlistNotifier.instance;
    final gameId = _game.id > 0 ? _game.id : _game.rawgId;

    if (notifier.lastModifiedGameId == gameId ||
        notifier.lastModifiedGameId == _game.id ||
        notifier.lastModifiedGameId == _game.rawgId ||
        (notifier.lastModifiedWishlistId != null &&
            notifier.lastModifiedWishlistId == _game.wishlistAlertId)) {
      if (notifier.lastActionWasDelete) {
        setState(() {
          _game = _game.copyWith(clearWishlistStatus: true);
        });
      } else if (notifier.lastModifiedItem != null) {
        final item = notifier.lastModifiedItem!;
        setState(() {
          _game = _game.copyWith(
            inWishlist: true,
            wishlistStatus: item.aktif ? 'Aktif' : 'Nonaktif',
            wishlistAlertData: item.toJson(),
          );
        });
      } else if (notifier.lastModifiedActive != null) {
        final bool isAktif = notifier.lastModifiedActive!;
        final currentData = Map<String, dynamic>.from(
          _game.wishlistAlertData ?? {},
        );
        currentData['aktif'] = isAktif;
        setState(() {
          _game = _game.copyWith(
            wishlistStatus: isAktif ? 'Aktif' : 'Nonaktif',
            wishlistAlertData: currentData,
          );
        });
      } else {
        _fetchFullDetail();
      }
    }
  }

  Future<void> _fetchFullDetail() async {
    setState(() => _isLoadingDetail = true);
    final gameId = _game.id > 0 ? _game.id : _game.rawgId;
    final detailFuture = _gameDataSource.getGameDetail(gameId);
    final similarFuture = _gameDataSource.getSimilarGames(gameId);

    final results = await Future.wait([detailFuture, similarFuture]);
    if (!mounted) return;

    final detail = results[0] as GameModel?;
    final similar = results[1] as List<GameModel>;

    setState(() {
      if (detail != null) {
        _game = detail;
      }
      _similarGames = similar;
      _isLoadingDetail = false;
    });
  }

  Future<void> _openLibraryForm() async {
    LibraryEntryModel? entry;
    if (_game.libraryEntryData != null) {
      entry = LibraryEntryModel.fromJson(_game.libraryEntryData!);
    }

    final changed = await LibraryEntrySheet.show(
      context,
      game: _game,
      entry: entry,
    );

    if (changed == true) {
      _fetchFullDetail();
    }
  }

  Future<void> _openWishlistForm() async {
    WishlistItemModel? wishlistItem;
    if (_game.wishlistAlertData != null) {
      wishlistItem = WishlistItemModel.fromJson(_game.wishlistAlertData!);
    }

    final changed = await WishlistFormSheet.show(
      context,
      game: _game,
      wishlistItem: wishlistItem,
    );

    if (changed == true) {
      _fetchFullDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> genreValues = _game.genres.isNotEmpty
        ? _game.genres
        : _game.genre
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    final List<String> platformValues = _game.platforms.isNotEmpty
        ? _game.platforms
        : _game.platform
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildHeroAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Judul & Metadata Utama ─────────────────────
                  Text(
                    _game.judul,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.displayMedium.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppBadge.rating(_game.rating),
                      if (_game.tanggalRilis != null &&
                          _game.tanggalRilis!.isNotEmpty)
                        AppBadge(
                          label: _game.tanggalRilis!,
                          icon: Icons.calendar_today_rounded,
                          variant: AppBadgeVariant.neutral,
                        ),
                      if (_game.libraryStatus != null)
                        AppBadge(
                          label: _game.libraryStatus!,
                          icon: Icons.bookmark_rounded,
                          customColor: AppStatusHelper.getStatusColor(
                            _game.libraryStatus!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Aksi Library & Wishlist ────────────────────
                  _buildActionButtons(),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Genre & Platform ───────────────────────────
                  if (genreValues.isNotEmpty) ...[
                    _buildTagSection(title: 'Genre', values: genreValues),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (platformValues.isNotEmpty) ...[
                    _buildTagSection(
                      title: 'Platform',
                      values: platformValues,
                      muted: true,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // ── Tentang Game ───────────────────────────────
                  _buildAboutCard(),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Harga & Riwayat Harga (US-05) ──────────────
                  PriceTrackerSection(
                    gameIdOrRawgId: _game.id > 0 ? _game.id : _game.rawgId,
                    initialPriceStatus: _game.priceStatus,
                  ),

                  // ── Game Serupa (F-11) ─────────────────────────
                  if (_similarGames.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _buildSimilarGamesSection(),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Atribusi RAWG dengan link aktif ────────────
                  const AppRawgAttribution(),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar() {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.bg,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        child: _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Kembali',
          onTap: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: _heroTag, child: _buildCoverImage()),
            // Scrim atas agar tombol kembali selalu terbaca.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.black.withValues(alpha: 0.7),
                    AppColors.black.withValues(alpha: 0.15),
                    AppColors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.24, 0.46],
                ),
              ),
            ),
            // Scrim bawah menyatu dengan latar konten.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.transparent,
                    AppColors.bg.withValues(alpha: 0.72),
                    AppColors.bg,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.42, 0.82, 1.0],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xl,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'DETAIL GAME',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    final String? coverUrl = _game.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      return _buildCoverFallback();
    }

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      cacheWidth: 900,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _buildCoverFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildCoverFallback();
      },
    );
  }

  Widget _buildTagSection({
    required String title,
    required List<String> values,
    bool muted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: values.map((value) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadius.fullBorderRadius,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
                child: Text(
                  value,
                  style: AppTypography.labelSmall.copyWith(
                    color: muted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Tentang Game'),
          const SizedBox(height: AppSpacing.md),
          if (_isLoadingDetail)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(width: double.infinity, height: 13),
                SizedBox(height: AppSpacing.sm),
                AppSkeletonBox(width: double.infinity, height: 13),
                SizedBox(height: AppSpacing.sm),
                AppSkeletonBox(width: 220, height: 13),
              ],
            )
          else ...[
            Text(
              _game.deskripsi != null && _game.deskripsi!.isNotEmpty
                  ? _game.deskripsi!
                  : 'Deskripsi lengkap game ini belum tersedia.',
              maxLines: _isDescriptionExpanded ? null : 4,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.65,
              ),
            ),
            if (_game.deskripsi != null && _game.deskripsi!.length > 200) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isDescriptionExpanded
                          ? 'Sembunyikan'
                          : 'Baca selengkapnya',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      _isDescriptionExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildLibraryActionButton()),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildWishlistActionButton()),
        ],
      ),
    );
  }

  Widget _buildLibraryActionButton() {
    final status = _game.libraryStatus;

    if (status == null) {
      return Material(
        color: AppColors.primary,
        borderRadius: AppRadius.lgBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openLibraryForm,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bookmark_add_outlined,
                  size: 18,
                  color: AppColors.onPrimary,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Flexible(
                  child: Text(
                    'Ke Library',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Color statusColor = AppStatusHelper.getStatusColor(status);

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorderRadius,
        side: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: InkWell(
        onTap: _openLibraryForm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AppStatusChip(status: status, compact: true),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.edit_outlined, size: 15, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistActionButton() {
    if (!_game.inWishlist) {
      return Material(
        color: AppColors.primaryContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorderRadius,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: _openWishlistForm,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 18,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Flexible(
                  child: Text(
                    'Tambah ke Wishlist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double? target = _game.wishlistHargaTarget;
    final bool isAktif = _game.isWishlistActive;

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorderRadius,
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: _openWishlistForm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 18,
                color: isAktif ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wishlist',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      target != null
                          ? 'Target: \$${target.toStringAsFixed(2)}'
                          : (isAktif ? 'Aktif' : 'Nonaktif'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Game Serupa',
          trailing: Text(
            '${_similarGames.length} game',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Tinggi mengikuti isi kartu secara intrinsik agar cover, judul, dan
        // genre tidak memicu overflow pada text scale berapa pun.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _similarGames.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                _SimilarGameCard(game: _similarGames[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: AppColors.textMuted,
          size: 56,
        ),
      ),
    );
  }
}

/// Kartu game serupa dengan cover poster dan judul ringkas.
class _SimilarGameCard extends StatelessWidget {
  final GameModel game;

  const _SimilarGameCard({required this.game});

  String get _heroTag => gameCoverHeroTag(game, 'serupa');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailScreen(game: game, heroTag: _heroTag),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 172,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(tag: _heroTag, child: _buildCover()),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.black.withValues(alpha: 0.3),
                            AppColors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.45],
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: AppBadge.rating(game.rating, compact: true),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      game.genre.isNotEmpty ? game.genre : 'Game serupa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    final String? coverUrl = game.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      return _buildFallback();
    }

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      cacheWidth: 360,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _buildFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildFallback();
      },
    );
  }

  Widget _buildFallback() {
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

/// Tombol ikon bulat dengan area sentuh 48dp untuk app bar imersif.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}
