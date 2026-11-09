import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorderRadius,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Hapus dari Wishlist?',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Game "${item.judul}" akan dihapus dari daftar wishlist Anda.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorderRadius),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final res = await _wishlistDataSource.deleteWishlist(id: item.id);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _items.removeWhere((e) => e.id == item.id);
        _total = (_total - 1).clamp(0, 99999);
      });

      WishlistNotifier.instance.notifyDeleted(
        item.id,
        gameId: item.gameId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ?? 'Game berhasil dihapus dari wishlist',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
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
    final gameModel = item.game ??
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
        builder: (_) => GameDetailScreen(game: gameModel),
      ),
    ).then((_) {
      _fetchWishlist(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Wishlist Incaran',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_total > 0 && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppRadius.fullBorderRadius,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$_total game',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
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
            // ── Filter Chip Aktif / Semua ─────────────────────────
            _buildFilterBar(),

            // ── Konten Utama ─────────────────────────────────────
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          _buildFilterChip('Semua', null),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Pantauan Aktif', true),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Nonaktif', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool? value) {
    final bool isSelected = _filterAktif == value;
    return GestureDetector(
      onTap: () {
        if (_filterAktif == value) return;
        setState(() {
          _filterAktif = value;
        });
        _fetchWishlist(refresh: true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: AppRadius.fullBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
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
            description:
                'Daftar game incaran dengan target harga akan muncul di sini. Buka tab Jelajah untuk mulai mencari game yang ingin dipantau.',
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        100.0, // Memberikan ruang ekstra untuk floating bottom navigation bar
      ),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
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
              color: AppColors.error.withValues(alpha: 0.85),
              borderRadius: AppRadius.lgBorderRadius,
            ),
            alignment: Alignment.centerRight,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: WishlistGameCard(
            item: item,
            onTap: () => _openDetail(item),
            onToggleActive: (newVal) => _toggleActive(item, newVal),
            onDelete: () => _confirmDelete(item),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBorderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Row(
              children: [
                AppSkeletonBox(width: 80, height: 104),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonBox(width: double.infinity, height: 16),
                      SizedBox(height: 8),
                      AppSkeletonBox(width: 140, height: 14),
                      SizedBox(height: 8),
                      AppSkeletonBox(width: 100, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSkeletonBox(width: 120, height: 20),
                AppSkeletonBox(width: 60, height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
