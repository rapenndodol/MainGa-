import 'package:flutter/material.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorderRadius,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Konfirmasi Logout',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar dari akun MainGa??',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
            ),
          ),
          AppButton(
            text: 'Keluar',
            onPressed: () => Navigator.pop(ctx, true),
            variant: AppButtonVariant.destructive,
            height: 40,
            width: 90,
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
      appBar: AppBar(
        title: Text(
          'Profil Pengguna',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // ── Ikon Lonceng Notifikasi dengan Badge ─────────────────
          ListenableBuilder(
            listenable: NotificationNotifier.instance,
            builder: (context, _) {
              final unreadCount = NotificationNotifier.instance.unreadCount;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: IconButton(
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
                          right: -3,
                          top: -3,
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
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
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
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              100.0, // Ruang untuk floating bottom navigation dock
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Kartu Pengguna ────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.xlBorderRadius,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          nama.isNotEmpty ? nama[0].toUpperCase() : 'G',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
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
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs - 2),
                            Text(
                              email,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Header Bagian Statistik ───────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      'Statistik Bermain',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Isi Statistik ─────────────────────────────────
                _buildStatsSection(),

                const SizedBox(height: AppSpacing.xxl),

                // ── Tombol Logout ─────────────────────────────────
                AppButton(
                  text: _isLoggingOut ? 'Sedang keluar...' : 'Keluar dari Akun',
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
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 80)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: AppSkeletonBox(height: 80)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: AppSkeletonBox(height: 80)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSkeletonBox(height: 220),
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
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.secondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gagal Memuat Statistik',
              style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _statsErrorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Coba Lagi',
              onPressed: _fetchStats,
              variant: AppButtonVariant.outline,
              height: 38,
            ),
          ],
        ),
      );
    }

    // Tampilan metrik ringkasan (Total Game, Jam Bermain, Game Tamat)
    return Column(
      children: [
        SummaryStatsRow(
          totalGame: _stats.totalGame,
          totalJam: _stats.totalJam,
          jumlahTamat: _stats.jumlahTamat,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Jika library kosong, tampilkan empty state informatif
        if (_stats.totalGame == 0)
          Container(
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
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Belum ada data. Tambahkan game ke library untuk melihat statistikmu.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          // Grafik Game Tamat 12 Bulan Terakhir
          MonthlyCompletedChart(data: _stats.gameTamatPerBulan),

          // Grafik Genre Favorit (jika ada data genre)
          if (_stats.genreFavorit.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            FavoriteGenresChart(genres: _stats.genreFavorit),
          ],
        ],
      ],
    );
  }
}
