import '../../../games/data/models/game_model.dart';

class LibraryEntryModel {
  final int id;
  final int userId;
  final int gameId;
  final String status;
  final int? ratingPribadi;
  final double jamMain;
  final String? catatan;
  final String? tanggalTamat;
  final String? createdAt;
  final String? updatedAt;
  final GameModel? game;
  final String judul;
  final String? coverUrl;
  final double gameRating;
  final String genre;
  final String platform;

  const LibraryEntryModel({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.status,
    this.ratingPribadi,
    required this.jamMain,
    this.catatan,
    this.tanggalTamat,
    this.createdAt,
    this.updatedAt,
    this.game,
    required this.judul,
    this.coverUrl,
    required this.gameRating,
    required this.genre,
    required this.platform,
  });

  factory LibraryEntryModel.fromJson(Map<String, dynamic> json) {
    GameModel? parsedGame;
    if (json['game'] is Map<String, dynamic>) {
      parsedGame = GameModel.fromJson(json['game'] as Map<String, dynamic>);
    }

    final String judul = parsedGame?.judul ??
        json['judul']?.toString() ??
        'Untitled Game';

    final String? coverUrl = parsedGame?.coverUrl ??
        json['cover_url']?.toString();

    final double gameRating = parsedGame?.rating ??
        (json['game_rating'] is num
            ? (json['game_rating'] as num).toDouble()
            : double.tryParse(json['game_rating']?.toString() ?? '0') ?? 0.0);

    final String genre = parsedGame?.genre ??
        json['genre']?.toString() ??
        '';

    final String platform = parsedGame?.platform ??
        json['platform']?.toString() ??
        '';

    final double jamMain = json['jam_main'] is num
        ? (json['jam_main'] as num).toDouble()
        : double.tryParse(json['jam_main']?.toString() ?? '0') ?? 0.0;

    final int? ratingPribadi = json['rating_pribadi'] is int
        ? json['rating_pribadi'] as int
        : int.tryParse(json['rating_pribadi']?.toString() ?? '');

    return LibraryEntryModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      gameId: json['game_id'] is int ? json['game_id'] as int : int.tryParse(json['game_id']?.toString() ?? '0') ?? 0,
      status: (json['status'] ?? 'Backlog').toString(),
      ratingPribadi: ratingPribadi,
      jamMain: jamMain,
      catatan: json['catatan']?.toString(),
      tanggalTamat: json['tanggal_tamat']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      game: parsedGame,
      judul: judul,
      coverUrl: coverUrl,
      gameRating: gameRating,
      genre: genre,
      platform: platform,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_id': gameId,
      'status': status,
      'rating_pribadi': ratingPribadi,
      'jam_main': jamMain,
      'catatan': catatan,
      'tanggal_tamat': tanggalTamat,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'game': game?.toJson(),
      'judul': judul,
      'cover_url': coverUrl,
      'game_rating': gameRating,
      'genre': genre,
      'platform': platform,
    };
  }

  LibraryEntryModel copyWith({
    int? id,
    int? userId,
    int? gameId,
    String? status,
    int? ratingPribadi,
    double? jamMain,
    String? catatan,
    String? tanggalTamat,
    String? createdAt,
    String? updatedAt,
    GameModel? game,
    String? judul,
    String? coverUrl,
    double? gameRating,
    String? genre,
    String? platform,
  }) {
    return LibraryEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      status: status ?? this.status,
      ratingPribadi: ratingPribadi ?? this.ratingPribadi,
      jamMain: jamMain ?? this.jamMain,
      catatan: catatan ?? this.catatan,
      tanggalTamat: tanggalTamat ?? this.tanggalTamat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      game: game ?? this.game,
      judul: judul ?? this.judul,
      coverUrl: coverUrl ?? this.coverUrl,
      gameRating: gameRating ?? this.gameRating,
      genre: genre ?? this.genre,
      platform: platform ?? this.platform,
    );
  }
}
