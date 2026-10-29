import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/data/models/library_entry_model.dart';
import '../../../library/presentation/controllers/library_notifier.dart';
import '../../../library/presentation/widgets/library_entry_sheet.dart';
import '../../../library/presentation/widgets/library_status_badge.dart';
import '../../data/datasources/game_remote_data_source.dart';
import '../../data/models/game_model.dart';
import '../widgets/rawg_attribution.dart';

class GameDetailScreen extends StatefulWidget {
  final GameModel game;

  const GameDetailScreen({
    super.key,
    required this.game,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late GameModel _game;
  bool _isLoadingDetail = false;
  bool _isDescriptionExpanded = false;
  final _gameDataSource = GameRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _game = widget.game;

    // Selalu fetch detail terbaru untuk sinkronisasi deskripsi dan status library pengguna
    _fetchFullDetail();

    // Dengarkan perubahan library agar layar detail langsung ikut ter-update
    LibraryNotifier.instance.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    LibraryNotifier.instance.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (!mounted) return;
    final notifier = LibraryNotifier.instance;
    final gameId = _game.id > 0 ? _game.id : _game.rawgId;

    if (notifier.lastModifiedGameId == gameId ||
        notifier.lastModifiedGameId == _game.id ||
        notifier.lastModifiedGameId == _game.rawgId) {
      if (notifier.lastActionWasDelete) {
        setState(() {
          _game = _game.copyWith(clearLibraryStatus: true);
        });
      } else if (notifier.lastModifiedStatus != null) {
        setState(() {
          _game = _game.copyWith(
            libraryStatus: notifier.lastModifiedStatus,
            libraryEntryData: notifier.lastModifiedEntry?.toJson(),
          );
        });
      }
    }
  }

  Future<void> _fetchFullDetail() async {
    setState(() => _isLoadingDetail = true);
    final detail = await _gameDataSource.getGameDetail(_game.id > 0 ? _game.id : _game.rawgId);
    if (!mounted) return;

    if (detail != null) {
      setState(() {
        _game = detail;
        _isLoadingDetail = false;
      });
    } else {
      setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _openLibraryForm() async {
    LibraryEntryModel? entry;
    if (_game.libraryEntryData != null) {
      entry = LibraryEntryModel.fromJson(_game.libraryEntryData!);
    }

    final changed = await LibraryEntrySheet.show(
      context,
      game: _game,
      entry: entry,
    );

    if (changed == true) {
      _fetchFullDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar dengan Cover Besar ───────────────
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: AppTheme.surface,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.55),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_game.coverUrl != null && _game.coverUrl!.isNotEmpty)
                    Image.network(
                      _game.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildCoverFallback(),
                    )
                  else
                    _buildCoverFallback(),

                  // Gradient Scrim agar tulisan/tombol tetap terbaca kontras
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          AppTheme.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Konten Detail ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Game
                  Text(
                    _game.judul,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rating dan Tanggal Rilis
                  Row(
                    children: [
                      // Rating Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFEAB308).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFFACC15),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _game.rating.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFACC15),
                              ),
                            ),
                            const Text(
                              ' / 5.0',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tanggal Rilis Badge
                      if (_game.tanggalRilis != null && _game.tanggalRilis!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _game.tanggalRilis!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Tombol Status Library ───────────────────────
                  _buildLibraryActionButton(),
                  const SizedBox(height: 24),

                  // ── Section: Genre ─────────────────────────────
                  if (_game.genres.isNotEmpty || _game.genre.isNotEmpty) ...[
                    const Text(
                      'Genre',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_game.genres.isNotEmpty
                              ? _game.genres
                              : _game.genre.split(',').map((e) => e.trim()))
                          .map(
                            (g) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryAccent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                g,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Section: Platform ──────────────────────────
                  if (_game.platforms.isNotEmpty || _game.platform.isNotEmpty) ...[
                    const Text(
                      'Platform',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_game.platforms.isNotEmpty
                              ? _game.platforms
                              : _game.platform.split(',').map((e) => e.trim()))
                          .map(
                            (p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                p,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Section: Deskripsi ─────────────────────────
                  const Text(
                    'Tentang Game',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_isLoadingDetail)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _game.deskripsi != null && _game.deskripsi!.isNotEmpty
                              ? _game.deskripsi!
                              : 'Deskripsi lengkap game ini belum tersedia.',
                          maxLines: _isDescriptionExpanded ? null : 4,
                          overflow: _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        if (_game.deskripsi != null && _game.deskripsi!.length > 200) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isDescriptionExpanded = !_isDescriptionExpanded;
                              });
                            },
                            child: Text(
                              _isDescriptionExpanded ? 'Sembunyikan' : 'Baca selengkapnya',
                              style: const TextStyle(
                                color: AppTheme.primaryAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 32),

                  // ── Atribusi RAWG dengan link aktif ────────────
                  const RawgAttribution(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryActionButton() {
    final status = _game.libraryStatus;

    if (status == null) {
      // Game belum ada di library
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _openLibraryForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.bookmark_add_outlined, size: 20, color: Colors.white),
          label: const Text(
            'Tambah ke Library',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Game sudah ada di library: tampilkan status dan tombol kelola
    final Color statusColor = LibraryStatusHelper.getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _openLibraryForm,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                LibraryStatusBadge(status: status),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tersimpan di Library',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ketuk untuk ubah status atau catatan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppTheme.primaryAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: AppTheme.textMuted,
          size: 64,
        ),
      ),
    );
  }
}
