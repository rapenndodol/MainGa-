class NotificationGameInfo {
  final int id;
  final String judul;
  final String? coverUrl;

  const NotificationGameInfo({
    required this.id,
    required this.judul,
    this.coverUrl,
  });

  factory NotificationGameInfo.fromJson(Map<String, dynamic> json) {
    return NotificationGameInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      judul: json['judul']?.toString() ?? 'Game',
      coverUrl: json['cover_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'cover_url': coverUrl,
    };
  }
}

class NotificationModel {
  final int id;
  final int userId;
  final int gameId;
  final String judul;
  final String judulGame;
  final String pesan;
  final double? harga;
  final String? toko;
  final String? dibacaPada;
  final bool sudahDibaca;
  final String statusDibaca;
  final String? waktu;
  final String? createdAt;
  final NotificationGameInfo? game;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.judul,
    required this.judulGame,
    required this.pesan,
    this.harga,
    this.toko,
    this.dibacaPada,
    required this.sudahDibaca,
    required this.statusDibaca,
    this.waktu,
    this.createdAt,
    this.game,
  });

  NotificationModel copyWith({
    int? id,
    int? userId,
    int? gameId,
    String? judul,
    String? judulGame,
    String? pesan,
    double? harga,
    String? toko,
    String? dibacaPada,
    bool? sudahDibaca,
    String? statusDibaca,
    String? waktu,
    String? createdAt,
    NotificationGameInfo? game,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      judul: judul ?? this.judul,
      judulGame: judulGame ?? this.judulGame,
      pesan: pesan ?? this.pesan,
      harga: harga ?? this.harga,
      toko: toko ?? this.toko,
      dibacaPada: dibacaPada ?? this.dibacaPada,
      sudahDibaca: sudahDibaca ?? this.sudahDibaca,
      statusDibaca: statusDibaca ?? this.statusDibaca,
      waktu: waktu ?? this.waktu,
      createdAt: createdAt ?? this.createdAt,
      game: game ?? this.game,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final double? parsedHarga = json['harga'] is num
        ? (json['harga'] as num).toDouble()
        : double.tryParse(json['harga']?.toString() ?? '');

    NotificationGameInfo? gameInfo;
    if (json['game'] is Map<String, dynamic>) {
      gameInfo = NotificationGameInfo.fromJson(json['game'] as Map<String, dynamic>);
    }

    final bool sudahDibaca = json['sudah_dibaca'] == true ||
        json['dibaca_pada'] != null ||
        json['status_dibaca'] == 'dibaca';

    return NotificationModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      gameId: json['game_id'] is int ? json['game_id'] as int : int.tryParse(json['game_id']?.toString() ?? '0') ?? 0,
      judul: json['judul']?.toString() ?? '',
      judulGame: json['judul_game']?.toString() ?? json['judul']?.toString() ?? 'Game',
      pesan: json['pesan']?.toString() ?? '',
      harga: parsedHarga,
      toko: json['toko']?.toString(),
      dibacaPada: json['dibaca_pada']?.toString(),
      sudahDibaca: sudahDibaca,
      statusDibaca: json['status_dibaca']?.toString() ?? (sudahDibaca ? 'dibaca' : 'belum_dibaca'),
      waktu: json['waktu']?.toString() ?? json['created_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      game: gameInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_id': gameId,
      'judul': judul,
      'judul_game': judulGame,
      'pesan': pesan,
      'harga': harga,
      'toko': toko,
      'dibaca_pada': dibacaPada,
      'sudah_dibaca': sudahDibaca,
      'status_dibaca': statusDibaca,
      'waktu': waktu,
      'created_at': createdAt,
      'game': game?.toJson(),
    };
  }
}
