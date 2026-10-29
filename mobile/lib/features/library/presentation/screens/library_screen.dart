import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../../data/models/library_entry_model.dart';
import '../controllers/library_notifier.dart';
import '../widgets/library_game_card.dart';
import '../widgets/library_status_badge.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Library Koleksi'),
        centerTitle: false,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          if (!_isLoading && _total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '$_total game',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryAccent,
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
            const SizedBox(height: 8),

            // ── Main Content Area ──────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchLibrary(refresh: true),
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceElevated,
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
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final bool isSelected = _selectedStatus == option;
          final Color badgeColor = option == 'Semua'
              ? AppTheme.primary
              : LibraryStatusHelper.getStatusColor(option);

          return ChoiceChip(
            label: Text(
              option,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => _onStatusFilterSelected(option),
            selectedColor: badgeColor,
            backgroundColor: AppTheme.surfaceElevated,
            side: BorderSide(
              color: isSelected ? badgeColor : AppTheme.border,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Library',
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
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _fetchLibrary(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(140, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88), // 88 bottom margin untuk floating nav
      itemCount: _entries.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _entries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
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

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                size: 48,
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada game',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Belum ada game dengan status "$_selectedStatus" di library pribadimu.'
                  : 'Koleksi game dan backlog bermainmu akan muncul di sini. Buka tab Jelajah untuk mulai mencari dan menambahkan game.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => _onStatusFilterSelected('Semua'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Lihat Semua Status'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
