import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_game_card.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_rawg_attribution.dart';
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

    await Future.wait([
      _fetchGames(resetPage: true),
      _fetchRecommendations(),
    ]);
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
    await Future.wait([
      _fetchGames(resetPage: true),
      _fetchRecommendations(),
    ]);
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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchGames(resetPage: true);
    });
  }

  void _showFilterModal() {
    String tempPlatform = _selectedPlatform;
    double tempRating = _minRating;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Pencarian',
                        style: AppTypography.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempPlatform = 'Semua';
                            tempRating = 0.0;
                          });
                        },
                        child: Text(
                          'Reset',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Platform',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempPlatform,
                        dropdownColor: AppColors.surfaceElevated,
                        isExpanded: true,
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
                      label: tempRating > 0 ? tempRating.toStringAsFixed(1) : 'Semua',
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
                    height: 50,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = _selectedPlatform != 'Semua' || _minRating > 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Jelajah Game',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar & Filter Button ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _fetchGames(resetPage: true),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari judul game...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchGames(resetPage: true);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.fullBorderRadius,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.fullBorderRadius,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.fullBorderRadius,
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
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: hasActiveFilters
                              ? AppColors.primary.withValues(alpha: 0.16)
                              : AppColors.surfaceElevated,
                          borderRadius: AppRadius.fullBorderRadius,
                          border: Border.all(
                            color: hasActiveFilters
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: hasActiveFilters
                                ? AppColors.primaryLight
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: _showFilterModal,
                          tooltip: 'Filter Platform & Rating',
                        ),
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: 10,
                          top: 10,
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
            ),

            // ── Horizontal Chip Filter Genre ──────────────────
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _genres.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final String genreName =
                      index == 0 ? 'Semua' : _genres[index - 1].nama;
                  final bool isSelected = _selectedGenre == genreName;

                  return Center(
                    child: ChoiceChip(
                      label: Text(genreName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedGenre = genreName;
                          });
                          _fetchGames(resetPage: true);
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.fullBorderRadius,
                      ),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Daftar Game / Status View ─────────────────────
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

  Widget _buildBody() {
    if (_isLoadingInitial) {
      return const AppListSkeleton(itemCount: 6);
    }

    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Gagal Memuat Game',
        message: _errorMessage!,
        onRetry: () => _fetchGames(resetPage: true),
      );
    }

    if (_games.isEmpty) {
      return AppEmptyState(
        icon: Icons.sports_esports_outlined,
        title: 'Tidak Ada Game Ditemukan',
        description:
            'Coba ubah kata kunci pencarian atau sesuaikan opsi filter genre dan rating.',
        actionText: (_searchController.text.isNotEmpty ||
                _selectedGenre != 'Semua' ||
                _selectedPlatform != 'Semua' ||
                _minRating > 0)
            ? 'Reset Semua Filter'
            : null,
        onAction: () {
          _searchController.clear();
          setState(() {
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
        _selectedGenre != 'Semua' || _selectedPlatform != 'Semua' || _minRating > 0;
    final bool showRecommendations = !isSearching && !hasActiveFilters;

    final int headerOffset = showRecommendations ? 1 : 0;
    final int totalItems = _games.length + headerOffset + 1; // +1 untuk footer loading atau atribusi

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        96.0,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (showRecommendations && index == 0) {
          return _buildRecommendationsSection();
        }

        final int gameIndex = index - headerOffset;
        if (gameIndex < _games.length) {
          return AppGameCard(game: _games[gameIndex]);
        }

        if (_isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          );
        }

        return const AppRawgAttribution();
      },
    );
  }

  /// Bagian "Rekomendasi untuk kamu" berupa daftar horizontal
  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                'Rekomendasi untuk kamu',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_isLoadingRecommendations)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
        if (_isLoadingRecommendations && _recommendations.isEmpty)
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, _) => Container(
                width: 155,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdBorderRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(width: 155, height: 105),
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeletonBox(width: 110, height: 12),
                          SizedBox(height: 6),
                          AppSkeletonBox(width: 75, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_recommendations.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdBorderRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_esports_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Tambahkan game ke library untuk mendapat rekomendasi',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                return _RecommendationCard(game: _recommendations[index]);
              },
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Katalog Game',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// Kartu game horizontal untuk rekomendasi
class _RecommendationCard extends StatelessWidget {
  final GameModel game;

  const _RecommendationCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdBorderRadius,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailScreen(game: game),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover thumbnail dengan badge rating
              Stack(
                children: [
                  SizedBox(
                    width: 155,
                    height: 100,
                    child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                        ? Image.network(
                            game.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildCoverFallback(),
                          )
                        : _buildCoverFallback(),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: AppRadius.fullBorderRadius,
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.ratingStar,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            game.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.ratingStar,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Judul Game & Alasan Singkat
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (game.alasan != null && game.alasan!.isNotEmpty)
                      Text(
                        game.alasan!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          height: 1.25,
                        ),
                      )
                    else if (game.genre.isNotEmpty)
                      Text(
                        game.genre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
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

  Widget _buildCoverFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: AppColors.textMuted,
          size: 32,
        ),
      ),
    );
  }
}
