import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../games/data/models/game_model.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../../data/models/library_entry_model.dart';
import '../controllers/library_notifier.dart';

class LibraryEntrySheet extends StatefulWidget {
  final GameModel? game;
  final LibraryEntryModel? entry;

  const LibraryEntrySheet({
    super.key,
    this.game,
    this.entry,
  }) : assert(game != null || entry != null, 'Harus menyediakan game atau entry');

  static Future<bool?> show(
    BuildContext context, {
    GameModel? game,
    LibraryEntryModel? entry,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LibraryEntrySheet(
        game: game,
        entry: entry,
      ),
    );
  }

  @override
  State<LibraryEntrySheet> createState() => _LibraryEntrySheetState();
}

class _LibraryEntrySheetState extends State<LibraryEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _libraryDataSource = LibraryRemoteDataSource();

  late String _selectedStatus;
  int? _ratingPribadi;
  late TextEditingController _jamMainController;
  late TextEditingController _catatanController;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _selectedStatus = widget.entry!.status;
      _ratingPribadi = widget.entry!.ratingPribadi;
      _jamMainController = TextEditingController(
        text: widget.entry!.jamMain > 0
            ? (widget.entry!.jamMain % 1 == 0
                ? widget.entry!.jamMain.toInt().toString()
                : widget.entry!.jamMain.toString())
            : '0',
      );
      _catatanController = TextEditingController(text: widget.entry!.catatan ?? '');
    } else {
      _selectedStatus = 'Backlog';
      _ratingPribadi = null;
      _jamMainController = TextEditingController(text: '0');
      _catatanController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _jamMainController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String get _gameJudul {
    return widget.entry?.judul ?? widget.game?.judul ?? 'Untitled Game';
  }

  String? get _gameCoverUrl {
    return widget.entry?.coverUrl ?? widget.game?.coverUrl;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double jamMain = double.tryParse(_jamMainController.text.trim()) ?? 0.0;
    final String catatan = _catatanController.text.trim();

    setState(() => _isSaving = true);

    if (widget.entry != null) {
      // Update entry yang sudah ada
      final result = await _libraryDataSource.updateEntry(
        id: widget.entry!.id,
        status: _selectedStatus,
        ratingPribadi: _ratingPribadi,
        jamMain: jamMain,
        catatan: catatan.isNotEmpty ? catatan : null,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result['success'] == true) {
        final updatedEntry = result['entry'] as LibraryEntryModel? ??
            widget.entry!.copyWith(
              status: _selectedStatus,
              ratingPribadi: _ratingPribadi,
              jamMain: jamMain,
              catatan: catatan.isNotEmpty ? catatan : null,
            );

        LibraryNotifier.instance.notifyUpdated(updatedEntry);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Entry library diperbarui!'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memperbarui entry.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Tambah entry baru
      final result = await _libraryDataSource.addEntry(
        gameId: widget.game?.id != null && widget.game!.id > 0 ? widget.game!.id : null,
        rawgId: widget.game?.rawgId != null && widget.game!.rawgId > 0 ? widget.game!.rawgId : null,
        status: _selectedStatus,
        ratingPribadi: _ratingPribadi,
        jamMain: jamMain,
        catatan: catatan.isNotEmpty ? catatan : null,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result['success'] == true) {
        final newEntry = result['entry'] as LibraryEntryModel?;
        if (newEntry != null) {
          LibraryNotifier.instance.notifyAdded(newEntry);
        } else {
          LibraryNotifier.instance.notifyGeneralChange();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Game ditambahkan ke library!'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menambahkan ke library.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.entry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorderRadius,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Hapus dari Library?',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus "$_gameJudul" dari koleksi library kamu?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Batal',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
            ),
          ),
          AppButton(
            text: 'Hapus',
            onPressed: () => Navigator.pop(dialogCtx, true),
            variant: AppButtonVariant.destructive,
            height: 40,
            width: 90,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    final result = await _libraryDataSource.deleteEntry(widget.entry!.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result['success'] == true) {
      LibraryNotifier.instance.notifyDeleted(widget.entry!.gameId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Game berhasil dihapus dari library'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menghapus game.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.entry != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.2),
          left: BorderSide(color: AppColors.border, width: 1.2),
          right: BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Header Info Game
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.smBorderRadius,
                      child: SizedBox(
                        width: 50,
                        height: 66,
                        child: _gameCoverUrl != null && _gameCoverUrl!.isNotEmpty
                            ? Image.network(
                                _gameCoverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(Icons.sports_esports_rounded,
                                      color: AppColors.textMuted, size: 24),
                                ),
                              )
                            : Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.sports_esports_rounded,
                                    color: AppColors.textMuted, size: 24),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Kelola di Library' : 'Tambah ke Library',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _gameJudul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                const Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.lg),

                // ── Status Selector ───────────────────────────────
                Text(
                  'Status Bermain',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: AppStatusHelper.statuses.map((status) {
                    final bool isSelected = _selectedStatus == status;

                    return AppStatusChip(
                      status: status,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Rating Pribadi (1-10) ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rating Pribadi (1 - 10)',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_ratingPribadi != null)
                      GestureDetector(
                        onTap: () => setState(() => _ratingPribadi = null),
                        child: Text(
                          'Hapus Rating',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lgBorderRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: _ratingPribadi != null
                                    ? AppColors.ratingStar
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _ratingPribadi != null
                                    ? '$_ratingPribadi / 10'
                                    : 'Belum dinilai',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _ratingPribadi != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _ratingPribadi != null
                                ? (_ratingPribadi! >= 9
                                    ? 'Luar Biasa'
                                    : _ratingPribadi! >= 7
                                        ? 'Bagus'
                                        : _ratingPribadi! >= 5
                                            ? 'Cukup'
                                            : 'Kurang')
                                : 'Opsional',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.ratingStar,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.ratingStar,
                          overlayColor: AppColors.ratingStar.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: (_ratingPribadi ?? 0).toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          onChanged: (val) {
                            setState(() {
                              _ratingPribadi = val == 0 ? null : val.round();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Jam Bermain ───────────────────────────────────
                Text(
                  'Jam Bermain (jam)',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _jamMainController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.timer_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    suffixText: 'jam',
                    suffixStyle: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    hintText: '0',
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.lgBorderRadius,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jam bermain wajib diisi (minimal 0)';
                    }
                    final numVal = double.tryParse(value.trim());
                    if (numVal == null) {
                      return 'Masukkan angka jam yang valid';
                    }
                    if (numVal < 0) {
                      return 'Jam bermain tidak boleh bernilai negatif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Catatan Pribadi ───────────────────────────────
                Text(
                  'Catatan Pribadi',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _catatanController,
                  maxLines: 3,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tulis kesan, progres misi, atau catatan pribadi...',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.lgBorderRadius,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Tombol Simpan ─────────────────────────────────
                AppButton(
                  text: isEditing ? 'Simpan Perubahan' : 'Tambahkan ke Library',
                  onPressed: _isSaving || _isDeleting ? null : _handleSave,
                  isLoading: _isSaving,
                  variant: AppButtonVariant.primary,
                  height: 52,
                ),

                // ── Tombol Hapus (jika sedang mengedit) ────────────
                if (isEditing) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: _isDeleting ? 'Menghapus...' : 'Hapus dari Library',
                    icon: Icons.delete_outline_rounded,
                    onPressed: _isSaving || _isDeleting ? null : _handleDelete,
                    isLoading: _isDeleting,
                    variant: AppButtonVariant.destructive,
                    height: 48,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
