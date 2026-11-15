import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_filter_chip_bar.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../../data/models/library_entry_model.dart';
import '../controllers/library_notifier.dart';
import '../widgets/library_game_card.dart';
import '../widgets/random_game_sheet.dart';

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

  String get _subtitle {
    if (_isLoading) return 'Menyusun koleksimu...';
    if (_selectedStatus != 'Semua') {
      return '$_total game berstatus $_selectedStatus.';
    }
    if (_total > 0) {
      return '$_total game tersimpan · pantau progres mainmu.';
    }
    return 'Koleksi, backlog, dan progres mainmu dalam satu tempat.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppScreenHeader(
              eyebrow: 'Koleksi pribadi',
              title: 'Library Koleksi',
              subtitle: _subtitle,
              actions: [
                AppButton(
                  text: 'Acak',
                  icon: Icons.casino_rounded,
                  onPressed: () => RandomGameSheet.show(context),
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                ),
              ],
              footer: AppFilterChipBar(
                options: _filterOptions,
                selected: _selectedStatus,
                onSelected: _onStatusFilterSelected,
              ),
            ),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const AppCardSkeletonList(
        shape: AppCardSkeletonShape.library,
        itemCount: 4,
      );
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        108.0, // Ruang untuk floating bottom dock
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
          index: index,
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
