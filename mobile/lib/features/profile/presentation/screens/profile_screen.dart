import 'package:flutter/material.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../library/presentation/controllers/library_notifier.dart';
import '../../../notifications/presentation/controllers/notification_notifier.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';
import '../../../stats/data/datasources/stats_remote_data_source.dart';
import '../../../stats/data/models/user_stats_model.dart';
import '../../../stats/presentation/widgets/favorite_genres_chart.dart';
import '../../../stats/presentation/widgets/monthly_completed_chart.dart';
import '../../../stats/presentation/widgets/summary_stats_row.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoggingOut = false;
  final _authDataSource = AuthRemoteDataSource();
  final _statsDataSource = StatsRemoteDataSource();

  UserStatsModel _stats = UserStatsModel.empty;
  bool _isLoadingStats = true;
  String? _statsErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    if (_currentUser == null) {
      _loadUser();
    }
    _fetchStats();
    NotificationNotifier.instance.fetchUnreadCount();

    // Dengarkan perubahan library agar statistik selalu up to date tanpa reload aplikasi
    LibraryNotifier.instance.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    LibraryNotifier.instance.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) {
      _fetchStats();
    }
  }

  Future<void> _loadUser() async {
    final userMap = await TokenStorage.getUser();
    if (userMap != null && mounted) {
      setState(() {
        _currentUser = UserModel.fromJson(userMap);
      });
    }

    final token = await TokenStorage.getToken();
    if (token != null) {
      final remoteUser = await _authDataSource.getProfile(token);
      if (remoteUser != null && mounted) {
        setState(() {
          _currentUser = remoteUser;
        });
        await TokenStorage.saveUser(remoteUser.toJson());
      }
    }
  }

  Future<void> _fetchStats() async {
    final result = await _statsDataSource.fetchStats();
    if (!mounted) return;

    setState(() {
      _isLoadingStats = false;
      if (result.success) {
        _stats = result.stats;
        _statsErrorMessage = null;
      } else {
        _statsErrorMessage = result.message;
      }
    });
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _loadUser(),
      _fetchStats(),
      NotificationNotifier.instance.fetchUnreadCount(),
    ]);
  }

  Future<void> _handleLogout() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Konfirmasi Logout',
      message: 'Apakah kamu yakin ingin keluar dari akun MainGa??',
      confirmText: 'Keluar',
      icon: Icons.logout_rounded,
    );

    if (!confirm) return;

    setState(() => _isLoggingOut = true);

    final token = await TokenStorage.getToken();
    if (token != null) {
      await _authDataSource.logout(token);
    }
    await TokenStorage.clearAll();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = _currentUser?.nama ?? 'Gamer';
    final email = _currentUser?.email ?? 'gamer@mainga.com';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppScreenHeader(
              eyebrow: 'Akun',
              title: 'Profil Pengguna',
              subtitle: 'Koleksi, statistik, dan pengaturan akunmu.',
              actions: [_buildNotificationBell()],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.textPrimary,
                backgroundColor: AppColors.surfaceElevated,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xs,
                    AppSpacing.xl,
                    108.0, // Ruang untuk floating bottom navigation dock
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(nama, email),
                      const SizedBox(height: AppSpacing.xxl),
                      const AppSectionHeader(title: 'Statistik Bermain'),
                      const SizedBox(height: AppSpacing.md),
                      _buildStatsSection(),
                      const SizedBox(height: AppSpacing.xxl),
                      AppButton(
                        text: _isLoggingOut
                            ? 'Sedang keluar...'
                            : 'Keluar dari Akun',
                        icon: Icons.logout_rounded,
                        onPressed: _isLoggingOut ? null : _handleLogout,
                        isLoading: _isLoggingOut,
                        variant: AppButtonVariant.destructive,
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return ListenableBuilder(
      listenable: NotificationNotifier.instance,
      builder: (context, _) {
        final unreadCount = NotificationNotifier.instance.unreadCount;

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: AppColors.textPrimary,
                size: 24,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        textAlign: TextAlign.center,
                        style: AppTypography.tabular(
                          AppTypography.labelSmall.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Notifikasi',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            ).then((_) {
              // Perbarui badge saat kembali dari layar notifikasi
              NotificationNotifier.instance.fetchUnreadCount();
            });
          },
        );
      },
    );
  }

  Widget _buildProfileCard(String nama, String email) {
    final String initial = nama.isNotEmpty ? nama[0].toUpperCase() : 'G';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.displayMedium.copyWith(
                fontSize: 26,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadius.fullBorderRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Pemain MainGa?',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return Column(
        children: const [
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 96)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: AppSkeletonBox(height: 96)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: AppSkeletonBox(height: 96)),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          AppSkeletonBox(height: 220),
          SizedBox(height: AppSpacing.lg),
          AppSkeletonBox(height: 240),
        ],
      );
    }

    if (_statsErrorMessage != null && _stats.totalGame == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlBorderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: AppRadius.controlLargeBorderRadius,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gagal Memuat Statistik',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _statsErrorMessage!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Coba Lagi',
              onPressed: _fetchStats,
              variant: AppButtonVariant.outline,
              height: 48,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SummaryStatsRow(
          totalGame: _stats.totalGame,
          totalJam: _stats.totalJam,
          jumlahTamat: _stats.jumlahTamat,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_stats.totalGame == 0)
          _buildEmptyStats()
        else ...[
          MonthlyCompletedChart(data: _stats.gameTamatPerBulan),
          if (_stats.genreFavorit.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            FavoriteGenresChart(genres: _stats.genreFavorit),
          ],
        ],
      ],
    );
  }

  Widget _buildEmptyStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada data',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Belum ada data. Tambahkan game ke library untuk melihat statistikmu.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
