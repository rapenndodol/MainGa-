import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../../data/models/library_entry_model.dart';
import '../controllers/library_notifier.dart';
import '../widgets/library_game_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _libraryDataSource = LibraryRemoteDataSource();
  final _scrollController = ScrollController();

  String _selectedStatus = 'Semua';
  List<LibraryEntryModel> _entries = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  static const List<String> _filterOptions = [
    'Semua',
    'Wishlist',
    'Backlog',
    'Sedang Dimainkan',
    'Tamat',
    'Dropped',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    LibraryNotifier.instance.addListener(_onLibraryChanged);
    Future.microtask(() => _fetchLibrary(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    LibraryNotifier.instance.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) {
      _fetchLibrary(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _fetchLibrary({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }

    final response = await _libraryDataSource.fetchLibrary(
      status: _selectedStatus == 'Semua' ? null : _selectedStatus,
      page: 1,
    );

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _entries = response.entries;
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _total = response.total;
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = response.message;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;

    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final response = await _libraryDataSource.fetchLibrary(
      status: _selectedStatus == 'Semua' ? null : _selectedStatus,
      page: nextPage,
    );

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _entries.addAll(response.entries);
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _total = response.total;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onStatusFilterSelected(String status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
    });
    _fetchLibrary(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Library Koleksi',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (!_isLoading && _total > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadius.fullBorderRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$_total game',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Horizontal Filter Chips ────────────────────────
            _buildStatusFilters(),
            const SizedBox(height: AppSpacing.sm),

            // ── Main Content Area ──────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchLibrary(refresh: true),
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

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final bool isSelected = _selectedStatus == option;
          final Color badgeColor = option == 'Semua'
              ? AppColors.primary
              : AppStatusHelper.getStatusColor(option);

          return ChoiceChip(
            label: Text(
              option,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => _onStatusFilterSelected(option),
            selectedColor: badgeColor,
            backgroundColor: AppColors.surfaceElevated,
            side: BorderSide(
              color: isSelected ? badgeColor : AppColors.border,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.fullBorderRadius,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    // Loading skeleton daripada spinner polos
    if (_isLoading) {
      return const AppListSkeleton(itemCount: 5);
    }

    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Gagal Memuat Library',
        message: _errorMessage!,
        onRetry: () => _fetchLibrary(refresh: true),
      );
    }

    if (_entries.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        96.0, // Ruang untuk floating bottom dock
      ),
      itemCount: _entries.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _entries.length) {
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

        final entry = _entries[index];
        return LibraryGameCard(
          entry: entry,
          onUpdated: () => _fetchLibrary(refresh: true),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final bool isFiltered = _selectedStatus != 'Semua';

    return AppEmptyState(
      icon: Icons.collections_bookmark_rounded,
      title: 'Belum ada game',
      description: isFiltered
          ? 'Belum ada game dengan status "$_selectedStatus" di library pribadimu.'
          : 'Koleksi game dan backlog bermainmu akan muncul di sini. Buka tab Jelajah untuk mulai mencari dan menambahkan game.',
      actionText: isFiltered ? 'Lihat Semua Status' : null,
      onAction: isFiltered ? () => _onStatusFilterSelected('Semua') : null,
    );
  }
}
