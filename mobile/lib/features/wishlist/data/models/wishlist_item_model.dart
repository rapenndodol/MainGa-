import '../../../games/data/models/game_model.dart';

class WishlistItemModel {
  final int id;
  final int userId;
  final int gameId;
  final double hargaTarget;
  final int hargaTargetIdrEstimasi;
  final bool aktif;
  final bool hargaTersedia;
  final double? hargaTerendah;
  final int? hargaTerendahIdrEstimasi;
  final String? tokoTermurah;
  final double? diskonPersen;
  final double? selisihHargaTarget;
  final int? selisihHargaTargetIdrEstimasi;
  final double kursUsdKeIdrEstimasi;
  final String? dicekTerakhir;
  final String? createdAt;
  final String? updatedAt;
  final GameModel? game;

  const WishlistItemModel({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.hargaTarget,
    required this.hargaTargetIdrEstimasi,
    required this.aktif,
    required this.hargaTersedia,
    this.hargaTerendah,
    this.hargaTerendahIdrEstimasi,
    this.tokoTermurah,
    this.diskonPersen,
    this.selisihHargaTarget,
    this.selisihHargaTargetIdrEstimasi,
    this.kursUsdKeIdrEstimasi = 16000.0,
    this.dicekTerakhir,
    this.createdAt,
    this.updatedAt,
    this.game,
  });

  /// Indikator apakah harga terendah sudah mencapai atau di bawah harga target
  bool get isTargetReached {
    if (!hargaTersedia || hargaTerendah == null) return false;
    return hargaTerendah! <= hargaTarget;
  }

  /// Judul game dari nested object game atau fallback
  String get judul => game?.judul ?? 'Game #$gameId';

  /// URL Cover game
  String? get coverUrl => game?.coverUrl;

  /// Rating game
  double get rating => game?.rating ?? 0.0;

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    GameModel? parsedGame;
    if (json['game'] is Map<String, dynamic>) {
      parsedGame = GameModel.fromJson(json['game'] as Map<String, dynamic>);
    }

    final double target = json['harga_target'] is num
        ? (json['harga_target'] as num).toDouble()
        : double.tryParse(json['harga_target']?.toString() ?? '0') ?? 0.0;

    final double? terendah = json['harga_terendah'] != null
        ? (json['harga_terendah'] is num
            ? (json['harga_terendah'] as num).toDouble()
            : double.tryParse(json['harga_terendah'].toString()))
        : null;

    final double? diskon = json['diskon_persen'] != null
        ? (json['diskon_persen'] is num
            ? (json['diskon_persen'] as num).toDouble()
            : double.tryParse(json['diskon_persen'].toString()))
        : null;

    final double? selisih = json['selisih_harga_target'] != null
        ? (json['selisih_harga_target'] is num
            ? (json['selisih_harga_target'] as num).toDouble()
            : double.tryParse(json['selisih_harga_target'].toString()))
        : null;

    final double kurs = json['kurs_usd_ke_idr_estimasi'] is num
        ? (json['kurs_usd_ke_idr_estimasi'] as num).toDouble()
        : double.tryParse(json['kurs_usd_ke_idr_estimasi']?.toString() ?? '16000') ?? 16000.0;

    return WishlistItemModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      gameId: json['game_id'] is int
          ? json['game_id'] as int
          : int.tryParse(json['game_id']?.toString() ?? '0') ?? 0,
      hargaTarget: target,
      hargaTargetIdrEstimasi: json['harga_target_idr_estimasi'] is int
          ? json['harga_target_idr_estimasi'] as int
          : int.tryParse(json['harga_target_idr_estimasi']?.toString() ?? '0') ?? (target * kurs).round(),
      aktif: json['aktif'] is bool
          ? json['aktif'] as bool
          : (json['aktif'] == 1 || json['aktif']?.toString() == 'true'),
      hargaTersedia: json['harga_tersedia'] is bool
          ? json['harga_tersedia'] as bool
          : (json['harga_tersedia'] == 1 || json['harga_tersedia']?.toString() == 'true'),
      hargaTerendah: terendah,
      hargaTerendahIdrEstimasi: json['harga_terendah_idr_estimasi'] is int
          ? json['harga_terendah_idr_estimasi'] as int
          : (json['harga_terendah_idr_estimasi'] != null
              ? int.tryParse(json['harga_terendah_idr_estimasi'].toString())
              : (terendah != null ? (terendah * kurs).round() : null)),
      tokoTermurah: json['toko_termurah']?.toString(),
      diskonPersen: diskon,
      selisihHargaTarget: selisih,
      selisihHargaTargetIdrEstimasi: json['selisih_harga_target_idr_estimasi'] is int
          ? json['selisih_harga_target_idr_estimasi'] as int
          : (json['selisih_harga_target_idr_estimasi'] != null
              ? int.tryParse(json['selisih_harga_target_idr_estimasi'].toString())
              : (selisih != null ? (selisih * kurs).round() : null)),
      kursUsdKeIdrEstimasi: kurs,
      dicekTerakhir: json['dicek_terakhir']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      game: parsedGame,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_id': gameId,
      'harga_target': hargaTarget,
      'harga_target_idr_estimasi': hargaTargetIdrEstimasi,
      'aktif': aktif,
      'harga_tersedia': hargaTersedia,
      'harga_terendah': hargaTerendah,
      'harga_terendah_idr_estimasi': hargaTerendahIdrEstimasi,
      'toko_termurah': tokoTermurah,
      'diskon_persen': diskonPersen,
      'selisih_harga_target': selisihHargaTarget,
      'selisih_harga_target_idr_estimasi': selisihHargaTargetIdrEstimasi,
      'kurs_usd_ke_idr_estimasi': kursUsdKeIdrEstimasi,
      'dicek_terakhir': dicekTerakhir,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'game': game?.toJson(),
    };
  }

  WishlistItemModel copyWith({
    int? id,
    int? userId,
    int? gameId,
    double? hargaTarget,
    int? hargaTargetIdrEstimasi,
    bool? aktif,
    bool? hargaTersedia,
    double? hargaTerendah,
    int? hargaTerendahIdrEstimasi,
    String? tokoTermurah,
    double? diskonPersen,
    double? selisihHargaTarget,
    int? selisihHargaTargetIdrEstimasi,
    double? kursUsdKeIdrEstimasi,
    String? dicekTerakhir,
    String? createdAt,
    String? updatedAt,
    GameModel? game,
  }) {
    return WishlistItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      hargaTarget: hargaTarget ?? this.hargaTarget,
      hargaTargetIdrEstimasi: hargaTargetIdrEstimasi ?? this.hargaTargetIdrEstimasi,
      aktif: aktif ?? this.aktif,
      hargaTersedia: hargaTersedia ?? this.hargaTersedia,
      hargaTerendah: hargaTerendah ?? this.hargaTerendah,
      hargaTerendahIdrEstimasi: hargaTerendahIdrEstimasi ?? this.hargaTerendahIdrEstimasi,
      tokoTermurah: tokoTermurah ?? this.tokoTermurah,
      diskonPersen: diskonPersen ?? this.diskonPersen,
      selisihHargaTarget: selisihHargaTarget ?? this.selisihHargaTarget,
      selisihHargaTargetIdrEstimasi: selisihHargaTargetIdrEstimasi ?? this.selisihHargaTargetIdrEstimasi,
      kursUsdKeIdrEstimasi: kursUsdKeIdrEstimasi ?? this.kursUsdKeIdrEstimasi,
      dicekTerakhir: dicekTerakhir ?? this.dicekTerakhir,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      game: game ?? this.game,
    );
  }
}
