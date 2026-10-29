import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../games/data/models/game_model.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../../data/models/library_entry_model.dart';
import '../controllers/library_notifier.dart';
import 'library_status_badge.dart';

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
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memperbarui entry.'),
            backgroundColor: AppTheme.error,
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
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menambahkan ke library.'),
            backgroundColor: AppTheme.error,
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
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          'Hapus dari Library?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus "$_gameJudul" dari koleksi library kamu?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
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
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menghapus game.'),
          backgroundColor: AppTheme.error,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1.2),
          left: BorderSide(color: AppTheme.border, width: 1.2),
          right: BorderSide(color: AppTheme.border, width: 1.2),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Info Game
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 68,
                        child: _gameCoverUrl != null && _gameCoverUrl!.isNotEmpty
                            ? Image.network(
                                _gameCoverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppTheme.surfaceElevated,
                                  child: const Icon(Icons.sports_esports_rounded, color: AppTheme.textMuted),
                                ),
                              )
                            : Container(
                                color: AppTheme.surfaceElevated,
                                child: const Icon(Icons.sports_esports_rounded, color: AppTheme.textMuted),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Kelola di Library' : 'Tambah ke Library',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _gameJudul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 18),

                // ── Status Selector ───────────────────────────────
                const Text(
                  'Status Bermain',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LibraryStatusHelper.statuses.map((status) {
                    final bool isSelected = _selectedStatus == status;
                    final Color statusColor = LibraryStatusHelper.getStatusColor(status);

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? statusColor.withValues(alpha: 0.22)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? statusColor
                                : AppTheme.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LibraryStatusHelper.getStatusIcon(status),
                              size: 15,
                              color: isSelected ? statusColor : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Rating Pribadi (1-10) ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rating Pribadi (1 - 10)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (_ratingPribadi != null)
                      GestureDetector(
                        onTap: () => setState(() => _ratingPribadi = null),
                        child: const Text(
                          'Hapus Rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
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
                                    ? const Color(0xFFFACC15)
                                    : AppTheme.textMuted,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _ratingPribadi != null
                                    ? '$_ratingPribadi / 10'
                                    : 'Belum dinilai',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _ratingPribadi != null
                                      ? Colors.white
                                      : AppTheme.textMuted,
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Slider 1-10
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFACC15),
                          inactiveTrackColor: AppTheme.border,
                          thumbColor: const Color(0xFFFACC15),
                          overlayColor: const Color(0xFFFACC15).withValues(alpha: 0.2),
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
                const SizedBox(height: 20),

                // ── Jam Bermain ───────────────────────────────────
                const Text(
                  'Jam Bermain (jam)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _jamMainController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.textSecondary, size: 20),
                    suffixText: 'jam',
                    suffixStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    hintText: '0',
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
                const SizedBox(height: 20),

                // ── Catatan Pribadi ───────────────────────────────
                const Text(
                  'Catatan Pribadi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _catatanController,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Tulis kesan, progres misi, atau catatan pribadi...',
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tombol Simpan ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving || _isDeleting ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditing ? 'Simpan Perubahan' : 'Tambahkan ke Library',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                // ── Tombol Hapus (jika sedang mengedit) ────────────
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving || _isDeleting ? null : _handleDelete,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.error),
                              ),
                            )
                          : const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                      label: Text(
                        _isDeleting ? 'Menghapus...' : 'Hapus dari Library',
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
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
