import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../../data/models/library_entry_model.dart';
import '../controllers/library_notifier.dart';

class RandomGameSheet extends StatefulWidget {
  final LibraryEntryModel? initialEntry;
  final bool initialBacklogEmpty;

  const RandomGameSheet({
    super.key,
    this.initialEntry,
    this.initialBacklogEmpty = false,
  });

  static Future<void> show(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const RandomGameSheet(),
    );
  }

  @override
  State<RandomGameSheet> createState() => _RandomGameSheetState();
}

class _RandomGameSheetState extends State<RandomGameSheet> {
  final _dataSource = LibraryRemoteDataSource();

  LibraryEntryModel? _entry;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isEmptyBacklog = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      _entry = widget.initialEntry;
      _isLoading = false;
      _isEmptyBacklog = false;
    } else if (widget.initialBacklogEmpty) {
      _isLoading = false;
      _isEmptyBacklog = true;
    } else {
      _fetchRandomGame();
    }
  }

  Future<void> _fetchRandomGame() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _dataSource.getRandomBacklogGame();
    if (!mounted) return;

    if (result['success'] == true && result['entry'] is LibraryEntryModel) {
      setState(() {
        _entry = result['entry'] as LibraryEntryModel;
        _isLoading = false;
        _isEmptyBacklog = false;
        _errorMessage = null;
      });
    } else if (result['isEmptyBacklog'] == true) {
      setState(() {
        _isLoading = false;
        _isEmptyBacklog = true;
        _entry = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message']?.toString() ?? 'Gagal memilih game acak';
      });
    }
  }

  Future<void> _handlePlayNow() async {
    if (_entry == null || _isUpdating) return;

    setState(() => _isUpdating = true);

    final result = await _dataSource.updateEntry(
      id: _entry!.id,
      status: 'Sedang Dimainkan',
      ratingPribadi: _entry!.ratingPribadi,
      jamMain: _entry!.jamMain,
      catatan: _entry!.catatan,
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (result['success'] == true) {
      final updatedEntry = result['entry'] is LibraryEntryModel
          ? result['entry'] as LibraryEntryModel
          : _entry!;

      // Beritahu listeners agar Tab Library dan Layar Profil Statistik langsung ter-update
      LibraryNotifier.instance.notifyUpdated(updatedEntry);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updatedEntry.judul} kini berstatus Sedang Dimainkan!'),
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Gagal mengubah status game'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.md,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(
          top: AppRadius.rXl,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadius.smBorderRadius,
                ),
                child: const Icon(
                  Icons.casino_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acak Game Backlog',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Pilihan game untuk kamu mainkan berikutnya',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Body
          if (_isLoading)
            _buildLoadingState()
          else if (_isEmptyBacklog)
            _buildEmptyBacklogState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_entry != null)
            _buildGameCard(_entry!),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Mengacak game dari backlog...',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBacklogState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.collections_bookmark_rounded,
              color: AppColors.secondary,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Backlog Kosong',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Backlog kosong. Tambahkan game dengan status Backlog dulu.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Mengerti',
            onPressed: () => Navigator.pop(context),
            variant: AppButtonVariant.outline,
            height: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? 'Terjadi kesalahan',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Coba Lagi',
            onPressed: _fetchRandomGame,
            variant: AppButtonVariant.outline,
            height: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(LibraryEntryModel entry) {
    final coverUrl = entry.coverUrl;
    final rating = entry.gameRating;
    final genre = entry.genre;

    return Column(
      children: [
        // Kartu Game Terpilih
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.xlBorderRadius,
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Game
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null && coverUrl.isNotEmpty)
                      Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surfaceHighlight,
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            color: AppColors.textMuted,
                            size: 48,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.surfaceHighlight,
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: AppColors.textMuted,
                          size: 48,
                        ),
                      ),
                    // Gradient scrim
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.surface.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Detail Game
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.judul,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (genre.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppRadius.fullBorderRadius,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              genre,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (rating > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.ratingStar,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Dua Tombol Aksi: "Mainkan sekarang" & "Acak ulang"
        Row(
          children: [
            Expanded(
              flex: 1,
              child: AppButton(
                text: 'Acak Ulang',
                icon: Icons.replay_rounded,
                onPressed: _isUpdating ? null : _fetchRandomGame,
                variant: AppButtonVariant.outline,
                height: 48,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: AppButton(
                text: 'Mainkan Sekarang',
                icon: Icons.play_arrow_rounded,
                onPressed: _isUpdating ? null : _handlePlayNow,
                isLoading: _isUpdating,
                variant: AppButtonVariant.primary,
                height: 48,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
