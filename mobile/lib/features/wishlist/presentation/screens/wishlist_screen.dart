import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_filter_chip_bar.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/game_hero_tag.dart';
import '../../../games/data/models/game_model.dart';
import '../../../games/presentation/screens/game_detail_screen.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';
import '../../data/models/wishlist_item_model.dart';
import '../controllers/wishlist_notifier.dart';
import '../widgets/wishlist_game_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _wishlistDataSource = WishlistRemoteDataSource();
  final _scrollController = ScrollController();

  List<WishlistItemModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  bool? _filterAktif; // null: semua, true: aktif saja, false: nonaktif saja

  static const List<String> _filterOptions = [
    'Semua',
    'Pantauan Aktif',
    'Nonaktif',
  ];

  String get _selectedFilter {
    if (_filterAktif == null) return 'Semua';
    return _filterAktif! ? 'Pantauan Aktif' : 'Nonaktif';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WishlistNotifier.instance.addListener(_onWishlistChanged);
    Future.microtask(() => _fetchWishlist(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WishlistNotifier.instance.removeListener(_onWishlistChanged);
    super.dispose();
  }

  void _onWishlistChanged() {
    if (mounted) {
      _fetchWishlist(refresh: true);
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

  Future<void> _fetchWishlist({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }

    final response = await _wishlistDataSource.fetchWishlist(
      aktif: _filterAktif,
      page: 1,
    );

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _items = response.wishlists;
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
    final response = await _wishlistDataSource.fetchWishlist(
      aktif: _filterAktif,
      page: nextPage,
    );

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _items.addAll(response.wishlists);
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _isLoadingMore = false;
      });
    } else {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _toggleActive(WishlistItemModel item, bool newStatus) async {
    // Update lokal terlebih dahulu untuk feedback instan
    final int index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      setState(() {
        _items[index] = item.copyWith(aktif: newStatus);
      });
    }

    final res = await _wishlistDataSource.updateWishlist(
      id: item.id,
      aktif: newStatus,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      WishlistNotifier.instance.notifyToggled(
        item.id,
        newStatus,
        gameId: item.gameId,
      );
    } else {
      // Revert jika gagal
      if (index != -1) {
        setState(() {
          _items[index] = item;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengubah status pantauan'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(WishlistItemModel item) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Hapus dari Wishlist?',
      message: 'Game "${item.judul}" akan dihapus dari daftar wishlist kamu.',
      confirmText: 'Hapus',
    );

    if (!confirmed || !mounted) return;

    final res = await _wishlistDataSource.deleteWishlist(id: item.id);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _items.removeWhere((e) => e.id == item.id);
        _total = (_total - 1).clamp(0, 99999);
      });

      WishlistNotifier.instance.notifyDeleted(item.id, gameId: item.gameId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ?? 'Game berhasil dihapus dari wishlist',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menghapus game'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openDetail(WishlistItemModel item) {
    final gameModel =
        item.game ??
        GameModel(
          id: item.gameId,
          rawgId: item.game?.rawgId ?? item.gameId,
          judul: item.judul,
          coverUrl: item.coverUrl,
          rating: item.rating,
          genre: '',
          genres: [],
          platform: '',
          platforms: [],
          inWishlist: true,
          wishlistAlertData: item.toJson(),
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(
          game: gameModel,
          heroTag: gameCoverHeroTag(gameModel, 'wishlist'),
        ),
      ),
    ).then((_) {
      if (mounted) _fetchWishlist(refresh: true);
    });
  }

  String get _subtitle {
    if (_isLoading) return 'Memuat daftar incaran...';
    if (_selectedFilter != 'Semua') {
      return '$_total game · filter $_selectedFilter.';
    }
    if (_total > 0) {
      return '$_total game dipantau · harga terbaik otomatis.';
    }
    return 'Simpan incaran, tetapkan target, biarkan harga yang mengejar.';
  }

  void _onFilterSelected(String label) {
    final bool? value = switch (label) {
      'Pantauan Aktif' => true,
      'Nonaktif' => false,
      _ => null,
    };
    if (_filterAktif == value) return;
    setState(() {
      _filterAktif = value;
    });
    _fetchWishlist(refresh: true);
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
              eyebrow: 'Daftar incaran',
              title: 'Wishlist Incaran',
              subtitle: _subtitle,
              footer: AppFilterChipBar(
                options: _filterOptions,
                selected: _selectedFilter,
                onSelected: _onFilterSelected,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchWishlist(refresh: true),
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
        shape: AppCardSkeletonShape.wishlist,
        itemCount: 4,
      );
    }

    if (_errorMessage != null) {
      return AppErrorState(
        message: _errorMessage!,
        onRetry: () => _fetchWishlist(refresh: true),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AppEmptyState(
            icon: Icons.favorite_rounded,
            title: 'Belum ada game di wishlist',
            description: 'Daftar game incaran dengan target harga akan muncul di sini. Buka tab Jelajah untuk mulai mencari game yang ingin dipantau.',
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.bottomDock,
      ),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        final item = _items[index];

        return Dismissible(
          key: ValueKey('wishlist_item_${item.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            await _confirmDelete(item);
            return false; // Penanganan hapus dilakukan di _confirmDelete
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.9),
              borderRadius: AppRadius.lgBorderRadius,
            ),
            alignment: Alignment.centerRight,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Hapus',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          child: WishlistGameCard(
            item: item,
            index: index,
            onTap: () => _openDetail(item),
            onToggleActive: (newVal) => _toggleActive(item, newVal),
            onDelete: () => _confirmDelete(item),
          ),
        );
      },
    );
  }
}
