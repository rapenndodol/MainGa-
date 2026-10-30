import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_game_card.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_rawg_attribution.dart';
import '../../data/datasources/game_remote_data_source.dart';
import '../../data/models/game_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/models/platform_model.dart';

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

  String _selectedGenre = 'Semua';
  String _selectedPlatform = 'Semua';
  double _minRating = 0.0;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadFiltersAndInitialGames();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    // Ambil genres dan platforms secara paralel
    final genresFuture = _gameDataSource.getGenres();
    final platformsFuture = _gameDataSource.getPlatforms();

    final results = await Future.wait([genresFuture, platformsFuture]);
    _genres = results[0] as List<GenreModel>;
    _platforms = results[1] as List<PlatformModel>;

    await _fetchGames(resetPage: true);
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
                  // Handle bar
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

                  // Header Modal
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

                  // Filter Platform
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

                  // Filter Rating Minimum
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

                  // Tombol Terapkan
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
                  // Kolom Pencarian
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

                  // Tombol Filter Modal
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
                onRefresh: () => _fetchGames(resetPage: true),
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
    // State Loading Awal: Gunakan skeleton shimmer, bukan spinner polos!
    if (_isLoadingInitial) {
      return const AppListSkeleton(itemCount: 6);
    }

    // State Error: Tampilan komunikatif dengan opsi coba lagi
    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Gagal Memuat Game',
        message: _errorMessage!,
        onRetry: () => _fetchGames(resetPage: true),
      );
    }

    // State Kosong: Komposisi informatif dengan tombol reset
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

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        96.0, // Memberikan ruang cukup di atas floating bottom navigation dock
      ),
      itemCount: _games.length + 1, // +1 untuk footer loading atau atribusi
      itemBuilder: (context, index) {
        if (index < _games.length) {
          return AppGameCard(game: _games[index]);
        }

        // Footer item
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

        // Atribusi RAWG di bagian paling bawah
        return const AppRawgAttribution();
      },
    );
  }
}
