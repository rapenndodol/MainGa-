import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_filter_chip_bar.dart';
import '../../../../core/widgets/app_game_card.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_rawg_attribution.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/game_hero_tag.dart';
import '../../../library/presentation/controllers/library_notifier.dart';
import '../../data/datasources/game_remote_data_source.dart';
import '../../data/models/game_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/models/platform_model.dart';
import 'game_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _gameDataSource = GameRemoteDataSource();

  List<GameModel> _games = [];
  List<GenreModel> _genres = [];
  List<PlatformModel> _platforms = [];
  List<GameModel> _recommendations = [];

  String _selectedGenre = 'Semua';
  String _selectedPlatform = 'Semua';
  String _searchQuery = '';
  double _minRating = 0.0;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isLoadingRecommendations = false;
  String? _errorMessage;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadFiltersAndInitialGames();
    _scrollController.addListener(_onScroll);
    LibraryNotifier.instance.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    LibraryNotifier.instance.removeListener(_onLibraryChanged);
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLibraryChanged() {
    if (!mounted) return;
    _fetchRecommendations();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_isLoadingMore &&
        !_isLoadingInitial &&
        _currentPage < _lastPage) {
      _loadMoreGames();
    }
  }

  Future<void> _loadFiltersAndInitialGames() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
    });

    final genresFuture = _gameDataSource.getGenres();
    final platformsFuture = _gameDataSource.getPlatforms();

    final results = await Future.wait([genresFuture, platformsFuture]);
    _genres = results[0] as List<GenreModel>;
    _platforms = results[1] as List<PlatformModel>;

    await Future.wait([_fetchGames(resetPage: true), _fetchRecommendations()]);
  }

  Future<void> _fetchRecommendations() async {
    if (!mounted) return;
    setState(() => _isLoadingRecommendations = true);

    try {
      final recs = await _gameDataSource.getRecommendations();
      if (!mounted) return;
      setState(() {
        _recommendations = recs;
        _isLoadingRecommendations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRecommendations = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([_fetchGames(resetPage: true), _fetchRecommendations()]);
  }

  Future<void> _fetchGames({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
      _games = [];
      setState(() {
        _isLoadingInitial = true;
        _errorMessage = null;
      });
    }

    final querySearch = _searchController.text.trim();
    final result = await _gameDataSource.fetchGames(
      search: querySearch.isNotEmpty ? querySearch : null,
      genre: _selectedGenre != 'Semua' ? _selectedGenre : null,
      platform: _selectedPlatform != 'Semua' ? _selectedPlatform : null,
      rating: _minRating > 0 ? _minRating : null,
      page: _currentPage,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _games = resetPage ? result.games : [..._games, ...result.games];
        _lastPage = result.lastPage;
        _isLoadingInitial = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingInitial = false;
        _errorMessage = result.message;
      });
    }
  }

  Future<void> _loadMoreGames() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    final querySearch = _searchController.text.trim();
    final result = await _gameDataSource.fetchGames(
      search: querySearch.isNotEmpty ? querySearch : null,
      genre: _selectedGenre != 'Semua' ? _selectedGenre : null,
      platform: _selectedPlatform != 'Semua' ? _selectedPlatform : null,
      rating: _minRating > 0 ? _minRating : null,
      page: _currentPage,
    );

    if (!mounted) return;

    setState(() {
      if (result.success) {
        _games.addAll(result.games);
        _lastPage = result.lastPage;
      }
      _isLoadingMore = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchGames(resetPage: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _fetchGames(resetPage: true);
  }

  void _showFilterModal() {
    String tempPlatform = _selectedPlatform;
    double tempRating = _minRating;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: 0.65),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTopBorderRadius,
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.sheetTopBorderRadius,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  bottomInset + AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter Pencarian',
                                style: AppTypography.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Persempit katalog sesuai selera.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempPlatform = 'Semua';
                              tempRating = 0.0;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      'Platform',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: AppRadius.controlLargeBorderRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempPlatform,
                          dropdownColor: AppColors.surfaceElevated,
                          borderRadius: AppRadius.mdBorderRadius,
                          isExpanded: true,
                          isDense: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'Semua',
                              child: Text('Semua Platform'),
                            ),
                            ..._platforms.map(
                              (p) => DropdownMenuItem(
                                value: p.nama,
                                child: Text(p.nama),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => tempPlatform = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rating Minimum',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ratingStar.withValues(alpha: 0.15),
                            borderRadius: AppRadius.fullBorderRadius,
                            border: Border.all(
                              color: AppColors.ratingStar.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.ratingStar,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                tempRating > 0
                                    ? tempRating.toStringAsFixed(1)
                                    : 'Semua',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.ratingStar,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: tempRating,
                        min: 0.0,
                        max: 4.5,
                        divisions: 9,
                        label: tempRating > 0
                            ? tempRating.toStringAsFixed(1)
                            : 'Semua',
                        onChanged: (v) {
                          setModalState(() => tempRating = v);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppButton(
                      text: 'Terapkan Filter',
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedPlatform = tempPlatform;
                          _minRating = tempRating;
                        });
                        _fetchGames(resetPage: true);
                      },
                      variant: AppButtonVariant.primary,
                      icon: Icons.tune_rounded,
                      height: 52,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters =
        _selectedPlatform != 'Semua' || _minRating > 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(hasActiveFilters),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasActiveFilters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jelajah Game',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 30,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs + 1),
                    Text(
                      'Temukan judul berikutnya untuk koleksimu.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadius.controlLargeBorderRadius,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _fetchGames(resetPage: true),
                  keyboardAppearance: Brightness.dark,
                  cursorColor: AppColors.primary,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari judul game...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 14.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md + 2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.lgBorderRadius,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.lgBorderRadius,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.lgBorderRadius,
                      borderSide: const BorderSide(
                        color: AppColors.borderFocused,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Stack(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppColors.surfaceHighlight
                          : AppColors.surface,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(
                        color: hasActiveFilters
                            ? AppColors.primary
                            : AppColors.border,
                        width: hasActiveFilters ? 1.4 : 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: hasActiveFilters
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: _showFilterModal,
                      tooltip: 'Filter Platform & Rating',
                    ),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          AppFilterChipBar(
            options: ['Semua', ..._genres.map((genre) => genre.nama)],
            selected: _selectedGenre,
            onSelected: (genre) {
              if (genre == _selectedGenre) return;
              setState(() => _selectedGenre = genre);
              _fetchGames(resetPage: true);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.55)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingInitial) {
      return const AppListSkeleton(
        itemCount: 6,
        surfaced: false,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.bottomDock,
        ),
      );
    }

    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Gagal memuat game',
        message: _errorMessage!,
        onRetry: () => _fetchGames(resetPage: true),
      );
    }

    if (_games.isEmpty) {
      return AppEmptyState(
        icon: Icons.sports_esports_outlined,
        title: 'Tidak ada game ditemukan',
        description: 'Coba ubah kata kunci pencarian atau sesuaikan opsi filter genre dan rating.',
        actionText:
            (_searchController.text.isNotEmpty ||
                _selectedGenre != 'Semua' ||
                _selectedPlatform != 'Semua' ||
                _minRating > 0)
            ? 'Reset Semua Filter'
            : null,
        onAction: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
            _selectedGenre = 'Semua';
            _selectedPlatform = 'Semua';
            _minRating = 0.0;
          });
          _fetchGames(resetPage: true);
        },
      );
    }

    final bool isSearching = _searchController.text.trim().isNotEmpty;
    final bool hasActiveFilters =
        _selectedGenre != 'Semua' ||
        _selectedPlatform != 'Semua' ||
        _minRating > 0;
    final bool showRecommendations = !isSearching && !hasActiveFilters;

    final int headerOffset = showRecommendations ? 1 : 0;
    final int totalItems = _games.length + headerOffset + 1; // +1 untuk footer

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.bottomDock,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (showRecommendations && index == 0) {
          return _buildRecommendationsSection();
        }

        final int gameIndex = index - headerOffset;
        if (gameIndex < _games.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: AppGameCard(
              game: _games[gameIndex],
              index: gameIndex,
              heroScope: 'katalog',
            ),
          );
        }

        if (_isLoadingMore) {
          return const _ListFooterLoading();
        }

        return const AppRawgAttribution();
      },
    );
  }

  /// Bagian "Rekomendasi untuk kamu" berupa carousel dengan penanda halaman.
  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: AppSectionHeader(
            title: 'Rekomendasi untuk kamu',
            trailing: _isLoadingRecommendations
                ? const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        if (_isLoadingRecommendations && _recommendations.isEmpty)
          const AppRecommendationSkeleton(height: 208)
        else if (_recommendations.isEmpty)
          _buildRecommendationsEmpty()
        else
          _RecommendationCarousel(games: _recommendations),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: AppSectionHeader(
            title: 'Katalog Game',
            trailing: Text(
              '${_games.length} judul',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  Widget _buildRecommendationsEmpty() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.controlLargeBorderRadius,
            ),
            child: const Icon(
              Icons.sports_esports_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Tambahkan game ke library untuk mendapat rekomendasi',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListFooterLoading extends StatelessWidget {
  const _ListFooterLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Text(
            'Memuat game lainnya',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carousel rekomendasi dengan kartu poster penuh dan indikator titik.
class _RecommendationCarousel extends StatefulWidget {
  final List<GameModel> games;

  const _RecommendationCarousel({required this.games});

  @override
  State<_RecommendationCarousel> createState() =>
      _RecommendationCarouselState();
}

class _RecommendationCarouselState extends State<_RecommendationCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  @override
  void didUpdateWidget(covariant _RecommendationCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.games.length) {
      _currentPage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpToPage(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Column(
      children: [
        SizedBox(
          height: 208,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: widget.games.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  right: AppSpacing.md,
                  bottom: AppSpacing.sm,
                  top: AppSpacing.xxs,
                ),
                child: _RecommendationCard(game: widget.games[index]),
              );
            },
          ),
        ),
        if (widget.games.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(widget.games.length, (index) {
                final bool isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : AppMotion.fast,
                  curve: AppMotion.curve,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs + 1,
                  ),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.border,
                    borderRadius: AppRadius.fullBorderRadius,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

/// Kartu rekomendasi imersif: cover penuh, judul tegas, dan alasan singkat.
class _RecommendationCard extends StatelessWidget {
  final GameModel game;

  const _RecommendationCard({required this.game});

  String get _heroTag => gameCoverHeroTag(game, 'rekomendasi');

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(game: game, heroTag: _heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.cardBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: _heroTag, child: _buildCover()),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.black.withValues(alpha: 0.25),
                    AppColors.transparent,
                    AppColors.black.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.36, 1.0],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: AppBadge.rating(game.rating, compact: true),
            ),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.fullBorderRadius,
                ),
                child: Text(
                  'UNTUKMU',
                  style: AppTypography.overline.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 9,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 1),
                      Expanded(
                        child: Text(
                          game.alasan != null && game.alasan!.isNotEmpty
                              ? game.alasan!
                              : (game.genre.isNotEmpty
                                    ? game.genre
                                    : 'Pilihan dari katalog MainGa?'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color:
                                game.alasan != null && game.alasan!.isNotEmpty
                                ? AppColors.primaryLight
                                : AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    final String? coverUrl = game.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      return _buildCoverFallback();
    }

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      cacheWidth: 720,
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
              size: 40,
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
          size: 40,
        ),
      ),
    );
  }
}
