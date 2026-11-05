class MonthlyCompletedStats {
  final String periode;
  final String label;
  final String bulan;
  final int jumlah;

  const MonthlyCompletedStats({
    required this.periode,
    required this.label,
    required this.bulan,
    required this.jumlah,
  });

  /// Mengembalikan label bulan singkat, misal "Nov" dari "Nov 2026" atau "11" dari "2026-11"
  String get shortMonth {
    final parts = label.split(' ');
    if (parts.isNotEmpty) {
      return parts.first;
    }
    return label;
  }

  factory MonthlyCompletedStats.fromJson(Map<String, dynamic> json) {
    return MonthlyCompletedStats(
      periode: json['periode']?.toString() ?? '',
      label: json['label']?.toString() ?? json['bulan']?.toString() ?? '',
      bulan: json['bulan']?.toString() ?? json['label']?.toString() ?? '',
      jumlah: json['jumlah'] is int
          ? json['jumlah'] as int
          : int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periode': periode,
      'label': label,
      'bulan': bulan,
      'jumlah': jumlah,
    };
  }
}

class GenreStats {
  final String nama;
  final String genre;
  final int jumlah;

  const GenreStats({
    required this.nama,
    required this.genre,
    required this.jumlah,
  });

  factory GenreStats.fromJson(Map<String, dynamic> json) {
    final name = json['nama']?.toString() ?? json['genre']?.toString() ?? '';
    return GenreStats(
      nama: name,
      genre: name,
      jumlah: json['jumlah'] is int
          ? json['jumlah'] as int
          : int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'genre': genre,
      'jumlah': jumlah,
    };
  }
}

class UserStatsModel {
  final int totalGame;
  final double totalJam;
  final int jumlahTamat;
  final List<MonthlyCompletedStats> gameTamatPerBulan;
  final List<GenreStats> genreFavorit;

  const UserStatsModel({
    required this.totalGame,
    required this.totalJam,
    required this.jumlahTamat,
    required this.gameTamatPerBulan,
    required this.genreFavorit,
  });

  bool get isEmpty => totalGame == 0;
  bool get hasCompletedGames => jumlahTamat > 0;
  bool get hasFavoriteGenres => genreFavorit.isNotEmpty;

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    final totalGame = json['total_game'] is int
        ? json['total_game'] as int
        : int.tryParse(json['total_game']?.toString() ?? '0') ?? 0;

    final totalJam = json['total_jam'] is num
        ? (json['total_jam'] as num).toDouble()
        : double.tryParse(json['total_jam']?.toString() ?? '0') ?? 0.0;

    final jumlahTamat = json['jumlah_tamat'] is int
        ? json['jumlah_tamat'] as int
        : int.tryParse(json['jumlah_tamat']?.toString() ?? '0') ?? 0;

    List<MonthlyCompletedStats> monthly = [];
    if (json['game_tamat_per_bulan'] is List) {
      monthly = (json['game_tamat_per_bulan'] as List)
          .whereType<Map<String, dynamic>>()
          .map(MonthlyCompletedStats.fromJson)
          .toList();
    }

    List<GenreStats> genres = [];
    if (json['genre_favorit'] is List) {
      genres = (json['genre_favorit'] as List)
          .whereType<Map<String, dynamic>>()
          .map(GenreStats.fromJson)
          .toList();
    }

    return UserStatsModel(
      totalGame: totalGame,
      totalJam: totalJam,
      jumlahTamat: jumlahTamat,
      gameTamatPerBulan: monthly,
      genreFavorit: genres,
    );
  }

  static const empty = UserStatsModel(
    totalGame: 0,
    totalJam: 0.0,
    jumlahTamat: 0,
    gameTamatPerBulan: [],
    genreFavorit: [],
  );
}
