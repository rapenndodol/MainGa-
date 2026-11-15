import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../games/data/models/game_model.dart';
import '../../../games/presentation/screens/game_detail_screen.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/models/notification_model.dart';
import '../controllers/notification_notifier.dart';
import '../widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _dataSource = NotificationRemoteDataSource();
  final _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isMarkingAllAsRead = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchNotifications(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }

    final response = await _dataSource.fetchNotifications(page: 1);

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _notifications = response.notifications;
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _isLoading = false;
        _errorMessage = null;
      });
      // Sinkronkan badge notifikasi di notifier
      NotificationNotifier.instance.fetchUnreadCount();
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
    final response = await _dataSource.fetchNotifications(page: nextPage);

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _notifications.addAll(response.notifications);
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _isLoadingMore = false;
      });
    } else {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    if (_isMarkingAllAsRead) return;

    setState(() => _isMarkingAllAsRead = true);

    final success = await NotificationNotifier.instance.markAllAsRead();

    if (!mounted) return;

    setState(() {
      _isMarkingAllAsRead = false;
      if (success) {
        _notifications = _notifications.map((n) {
          return n.copyWith(sudahDibaca: true, statusDibaca: 'dibaca');
        }).toList();
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi telah ditandai sebagai dibaca'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Jika belum dibaca, tandai sudah dibaca di server dan lokal
    if (!notification.sudahDibaca) {
      NotificationNotifier.instance.markAsRead(
        notification.id,
        wasUnread: true,
      );
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.id == notification.id) {
            return n.copyWith(sudahDibaca: true, statusDibaca: 'dibaca');
          }
          return n;
        }).toList();
      });
    }

    // Buka detail game terkait
    final gameModel = GameModel(
      id: notification.gameId,
      rawgId: 0,
      judul: notification.judulGame,
      coverUrl: notification.game?.coverUrl,
      rating: 0,
      genre: '',
      genres: const [],
      platform: '',
      platforms: const [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailScreen(game: gameModel),
      ),
    );
  }

  String get _subtitle {
    if (_isLoading) return 'Memuat pemberitahuan...';
    if (_notifications.isEmpty) {
      return 'Diskon dan penurunan harga incaranmu.';
    }
    final int unread = _notifications.where((n) => !n.sudahDibaca).length;
    if (unread > 0) {
      return '$unread pemberitahuan belum dibaca.';
    }
    return 'Semua pemberitahuan sudah dibaca.';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = _notifications.any((n) => !n.sudahDibaca);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppScreenHeader(
              eyebrow: 'Pemberitahuan',
              title: 'Notifikasi',
              subtitle: _subtitle,
              leading: IconButton(
                tooltip: 'Kembali',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (!_isLoading && _notifications.isNotEmpty)
                  IconButton(
                    tooltip: 'Tandai semua dibaca',
                    onPressed: hasUnread && !_isMarkingAllAsRead
                        ? _handleMarkAllAsRead
                        : null,
                    icon: _isMarkingAllAsRead
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.done_all_rounded,
                            color: hasUnread
                                ? AppColors.primaryLight
                                : AppColors.textMuted,
                          ),
                  ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchNotifications(refresh: true),
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
        shape: AppCardSkeletonShape.notification,
        itemCount: 5,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xs,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
      );
    }

    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Gagal Memuat Notifikasi',
        message: _errorMessage!,
        onRetry: () => _fetchNotifications(refresh: true),
      );
    }

    if (_notifications.isEmpty) {
      return const AppEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Belum ada notifikasi',
        description: 'Pemberitahuan diskon dan penurunan harga game di wishlistmu akan muncul di sini.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
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

        final notification = _notifications[index];
        return NotificationCard(
          notification: notification,
          index: index,
          onTap: () => _handleNotificationTap(notification),
        );
      },
    );
  }
}
