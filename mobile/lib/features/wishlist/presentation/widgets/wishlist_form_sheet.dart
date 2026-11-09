import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../games/data/models/game_model.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';
import '../../data/models/wishlist_item_model.dart';
import '../controllers/wishlist_notifier.dart';

class WishlistFormSheet extends StatefulWidget {
  final GameModel game;
  final WishlistItemModel? wishlistItem;

  const WishlistFormSheet({
    super.key,
    required this.game,
    this.wishlistItem,
  });

  static Future<bool?> show(
    BuildContext context, {
    required GameModel game,
    WishlistItemModel? wishlistItem,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: WishlistFormSheet(
          game: game,
          wishlistItem: wishlistItem,
        ),
      ),
    );
  }

  @override
  State<WishlistFormSheet> createState() => _WishlistFormSheetState();
}

class _WishlistFormSheetState extends State<WishlistFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _targetPriceController = TextEditingController();
  final _dataSource = WishlistRemoteDataSource();

  late bool _aktif;
  bool _isSubmitting = false;
  String? _generalError;
  double _currentUsd = 0.0;
  final double _usdRate = 16000.0;

  bool get _isEditing =>
      widget.wishlistItem != null || widget.game.inWishlist;

  int? get _wishlistId =>
      widget.wishlistItem?.id ?? widget.game.wishlistAlertId;

  @override
  void initState() {
    super.initState();

    final initialTarget = widget.wishlistItem?.hargaTarget ??
        widget.game.wishlistHargaTarget;

    if (initialTarget != null && initialTarget > 0) {
      _targetPriceController.text = initialTarget.toStringAsFixed(2);
      _currentUsd = initialTarget;
    }

    _aktif = widget.wishlistItem?.aktif ??
        widget.game.isWishlistActive;

    _targetPriceController.addListener(_onPriceChanged);
  }

  @override
  void dispose() {
    _targetPriceController.removeListener(_onPriceChanged);
    _targetPriceController.dispose();
    super.dispose();
  }

  void _onPriceChanged() {
    final parsed = double.tryParse(_targetPriceController.text.trim()) ?? 0.0;
    if (parsed != _currentUsd) {
      setState(() {
        _currentUsd = parsed;
      });
    }
  }

  String _formatIdr(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetPrice = double.tryParse(_targetPriceController.text.trim());
    if (targetPrice == null || targetPrice <= 0) {
      setState(() {
        _generalError = 'Harga target harus lebih besar dari 0 USD.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _generalError = null;
    });

    if (_isEditing && _wishlistId != null) {
      // Update existing wishlist
      final result = await _dataSource.updateWishlist(
        id: _wishlistId!,
        hargaTarget: targetPrice,
        aktif: _aktif,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final WishlistItemModel? updated = result['data'] as WishlistItemModel?;
        if (updated != null) {
          WishlistNotifier.instance.notifyUpdated(updated);
        } else {
          WishlistNotifier.instance.notifyGeneralChange();
        }

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Wishlist berhasil diperbarui',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          _generalError = result['message'] ?? 'Gagal memperbarui wishlist';
        });
      }
    } else {
      // Add new game to wishlist
      final result = await _dataSource.addWishlist(
        gameId: widget.game.id > 0 ? widget.game.id : null,
        rawgId: widget.game.rawgId > 0 ? widget.game.rawgId : null,
        hargaTarget: targetPrice,
        aktif: _aktif,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final WishlistItemModel? created = result['data'] as WishlistItemModel?;
        if (created != null) {
          WishlistNotifier.instance.notifyAdded(created);
        } else {
          WishlistNotifier.instance.notifyGeneralChange();
        }

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Game berhasil ditambahkan ke wishlist',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          _generalError = result['message'] ?? 'Gagal menambahkan ke wishlist';
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final wishlistId = _wishlistId;
    if (wishlistId == null) return;

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
          'Game "${widget.game.judul}" akan dihapus dari daftar pantauan wishlist Anda.',
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

    setState(() => _isSubmitting = true);

    final result = await _dataSource.deleteWishlist(id: wishlistId);

    if (!mounted) return;

    if (result['success'] == true) {
      WishlistNotifier.instance.notifyDeleted(
        wishlistId,
        gameId: widget.game.id > 0 ? widget.game.id : widget.game.rawgId,
      );

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Game berhasil dihapus dari wishlist',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _generalError = result['message'] ?? 'Gagal menghapus game dari wishlist';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedIdr = (_currentUsd * _usdRate).round();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle drag indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.fullBorderRadius,
                  ),
                ),
              ),

              // Header judul sheet
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppRadius.mdBorderRadius,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Ubah Target Wishlist' : 'Tambah ke Wishlist',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.game.judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Pesan Error Umum
              if (_generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: AppRadius.mdBorderRadius,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Input Harga Target (USD) ─────────────────────
              Text(
                'Harga Target (USD)',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              TextFormField(
                controller: _targetPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: 19.99',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                  suffixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    child: Center(
                      widthFactor: 1.0,
                      child: Text(
                        'USD',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Harga target wajib diisi.';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null) {
                    return 'Masukkan nominal angka yang valid.';
                  }
                  if (numVal <= 0) {
                    return 'Harga target harus lebih besar dari 0 USD.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs + 2),

              // ── Estimasi Rupiah ─────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdBorderRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_exchange_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Estimasi: ',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            TextSpan(
                              text: _currentUsd > 0
                                  ? _formatIdr(estimatedIdr)
                                  : 'Rp 0',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' (estimasi kurs Rp 16.000 / USD)',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Saklar Pantauan Aktif ────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdBorderRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pantauan Aktif',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pengecekan berkala akan memantau diskon game ini',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _aktif,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primaryContainer,
                      inactiveThumbColor: AppColors.textMuted,
                      inactiveTrackColor: AppColors.surfaceElevated,
                      onChanged: (val) {
                        setState(() {
                          _aktif = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Tombol Simpan ───────────────────────────────
              AppButton(
                text: _isEditing ? 'Simpan Perubahan' : 'Tambah ke Wishlist',
                icon: Icons.check_circle_outline_rounded,
                variant: AppButtonVariant.primary,
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
                height: 48,
              ),

              // ── Tombol Opsi Hapus (Jika mode ubah) ──────────
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: 'Hapus dari Wishlist',
                  icon: Icons.delete_outline_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: _isSubmitting ? null : _handleDelete,
                  height: 48,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
