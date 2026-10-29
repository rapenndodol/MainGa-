import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/game_remote_data_source.dart';
import '../../data/models/game_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/models/platform_model.dart';
import '../widgets/game_card.dart';
import '../widgets/rawg_attribution.dart';

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
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _fetchGames(resetPage: true);
    });
  }

  void _showFilterModal() {
    String tempPlatform = _selectedPlatform;
    double tempRating = _minRating;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Pencarian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempPlatform = 'Semua';
                            tempRating = 0.0;
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: AppTheme.primaryAccent)),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border, height: 24),

                  // Filter Platform
                  const Text(
                    'Platform',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempPlatform,
                        dropdownColor: AppTheme.surfaceElevated,
                        isExpanded: true,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        items: [
                          const DropdownMenuItem(value: 'Semua', child: Text('Semua Platform')),
                          ..._platforms.map(
                            (p) => DropdownMenuItem(value: p.nama, child: Text(p.nama)),
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
                  const SizedBox(height: 20),

                  // Filter Rating Minimum
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rating Minimum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        tempRating > 0 ? '${tempRating.toStringAsFixed(1)} ★' : 'Semua',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFACC15),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.border,
                      thumbColor: AppTheme.primaryAccent,
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
                  const SizedBox(height: 16),

                  // Tombol Terapkan
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedPlatform = tempPlatform;
                        _minRating = tempRating;
                      });
                      _fetchGames(resetPage: true);
                    },
                    child: const Text('Terapkan Filter', style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Jelajah Game'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar & Filter Button ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Kolom Pencarian
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _fetchGames(resetPage: true),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari judul game...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchGames(resetPage: true);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tombol Filter Modal
                  Stack(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: hasActiveFilters
                              ? AppTheme.primary.withValues(alpha: 0.2)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasActiveFilters ? AppTheme.primary : AppTheme.border,
                            width: 1.2,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: hasActiveFilters ? AppTheme.primaryAccent : AppTheme.textSecondary,
                            size: 22,
                          ),
                          onPressed: _showFilterModal,
                          tooltip: 'Filter Platform & Rating',
                        ),
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryAccent,
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
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _genres.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final String genreName = index == 0 ? 'Semua' : _genres[index - 1].nama;
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
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryAccent : AppTheme.border,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── Daftar Game / Status View ─────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchGames(resetPage: true),
                color: AppTheme.primary,
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
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(140, 42),
                ),
                onPressed: () => _fetchGames(resetPage: true),
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_games.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_esports_outlined,
                size: 64,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Game Ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coba ubah kata kunci pencarian atau sesuaikan opsi filter genre dan rating.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (_searchController.text.isNotEmpty ||
                  _selectedGenre != 'Semua' ||
                  _selectedPlatform != 'Semua' ||
                  _minRating > 0)
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedGenre = 'Semua';
                      _selectedPlatform = 'Semua';
                      _minRating = 0.0;
                    });
                    _fetchGames(resetPage: true);
                  },
                  child: const Text('Reset Semua Filter'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _games.length + 1, // +1 untuk footer loading atau atribusi
      itemBuilder: (context, index) {
        if (index < _games.length) {
          return GameCard(game: _games[index]);
        }

        // Footer item
        if (_isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
          );
        }

        // Atribusi RAWG di bagian paling bawah
        return const RawgAttribution();
      },
    );
  }
}
