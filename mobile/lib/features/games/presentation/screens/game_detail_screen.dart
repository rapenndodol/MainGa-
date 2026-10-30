import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_rawg_attribution.dart';
import '../../../../core/widgets/app_status_chip.dart';
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

  const GameDetailScreen({
    super.key,
    required this.game,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late GameModel _game;
  bool _isLoadingDetail = false;
  bool _isDescriptionExpanded = false;
  final _gameDataSource = GameRemoteDataSource();

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
        final currentData =
            Map<String, dynamic>.from(_game.wishlistAlertData ?? {});
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
    final detail =
        await _gameDataSource.getGameDetail(_game.id > 0 ? _game.id : _game.rawgId);
    if (!mounted) return;

    if (detail != null) {
      setState(() {
        _game = detail;
        _isLoadingDetail = false;
      });
    } else {
      setState(() => _isLoadingDetail = false);
    }
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar dengan Cover Imersif ──────────────
          SliverAppBar(
            expandedHeight: 290.0,
            pinned: true,
            backgroundColor: AppColors.bg,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.8),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_game.coverUrl != null && _game.coverUrl!.isNotEmpty)
                    Image.network(
                      _game.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildCoverFallback(),
                    )
                  else
                    _buildCoverFallback(),

                  // Scrim gradien netral agar title & tombol tetap kontras tinggi
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                          AppColors.bg,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Konten Detail ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Game
                  Text(
                    _game.judul,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Rating dan Tanggal Rilis Badges
                  Row(
                    children: [
                      // Rating Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ratingStar.withValues(alpha: 0.15),
                          borderRadius: AppRadius.fullBorderRadius,
                          border: Border.all(
                            color: AppColors.ratingStar.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.ratingStar,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _game.rating.toStringAsFixed(1),
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.ratingStar,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' / 5.0',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Tanggal Rilis Badge
                      if (_game.tanggalRilis != null &&
                          _game.tanggalRilis!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: AppRadius.fullBorderRadius,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs + 2),
                              Text(
                                _game.tanggalRilis!,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Tombol Library & Wishlist (Berdampingan) ───────────
                  _buildActionButtons(),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Section: Genre ─────────────────────────────
                  if (_game.genres.isNotEmpty || _game.genre.isNotEmpty) ...[
                    Text(
                      'Genre',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: (_game.genres.isNotEmpty
                              ? _game.genres
                              : _game.genre.split(',').map((e) => e.trim()))
                          .map(
                            (g) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs + 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: AppRadius.fullBorderRadius,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                g,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Section: Platform ──────────────────────────
                  if (_game.platforms.isNotEmpty ||
                      _game.platform.isNotEmpty) ...[
                    Text(
                      'Platform',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: (_game.platforms.isNotEmpty
                              ? _game.platforms
                              : _game.platform.split(',').map((e) => e.trim()))
                          .map(
                            (p) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs + 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: AppRadius.fullBorderRadius,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                p,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Section: Deskripsi ─────────────────────────
                  Text(
                    'Tentang Game',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (_isLoadingDetail)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeletonBox(width: double.infinity, height: 14),
                          SizedBox(height: 8),
                          AppSkeletonBox(width: double.infinity, height: 14),
                          SizedBox(height: 8),
                          AppSkeletonBox(width: 220, height: 14),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            height: 1.6,
                          ),
                        ),
                        if (_game.deskripsi != null &&
                            _game.deskripsi!.length > 200) ...[
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isDescriptionExpanded =
                                    !_isDescriptionExpanded;
                              });
                            },
                            child: Text(
                              _isDescriptionExpanded
                                  ? 'Sembunyikan'
                                  : 'Baca selengkapnya',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Section: Harga & Riwayat Harga (US-05) ─────
                  PriceTrackerSection(
                    gameIdOrRawgId: _game.id > 0 ? _game.id : _game.rawgId,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Atribusi RAWG dengan link aktif ────────────
                  const AppRawgAttribution(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // ── Tombol / Status Library ───────────────────────────
        Expanded(
          child: _buildLibraryActionButton(),
        ),
        const SizedBox(width: AppSpacing.md),

        // ── Tombol / Status Wishlist ──────────────────────────
        Expanded(
          child: _buildWishlistActionButton(),
        ),
      ],
    );
  }

  Widget _buildLibraryActionButton() {
    final status = _game.libraryStatus;

    if (status == null) {
      // Belum ada di library: Tombol primer
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.lgBorderRadius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.lgBorderRadius,
            onTap: _openLibraryForm,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_add_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: AppSpacing.xs + 2),
                  Flexible(
                    child: Text(
                      'Ke Library',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Sudah ada di library: kartu status interaktif
    final Color statusColor = AppStatusHelper.getStatusColor(status);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgBorderRadius,
          onTap: _openLibraryForm,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppStatusChip(status: status, compact: true),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: AppColors.primaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistActionButton() {
    if (!_game.inWishlist) {
      // Belum ada di wishlist: Tombol "Tambah ke Wishlist"
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.6),
          borderRadius: AppRadius.lgBorderRadius,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.lgBorderRadius,
            onTap: _openWishlistForm,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 18,
                    color: AppColors.primaryLight,
                  ),
                  SizedBox(width: AppSpacing.xs + 2),
                  Flexible(
                    child: Text(
                      'Tambah ke Wishlist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Sudah ada di wishlist: Kartu target harga & status aktif
    final double? target = _game.wishlistHargaTarget;
    final bool isAktif = _game.isWishlistActive;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgBorderRadius,
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
                const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: AppColors.primaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: AppColors.textMuted,
          size: 64,
        ),
      ),
    );
  }
}
