class GameModel {
  final int id;
  final int rawgId;
  final String judul;
  final String? coverUrl;
  final double rating;
  final String genre;
  final List<String> genres;
  final String platform;
  final List<String> platforms;
  final String? tanggalRilis;
  final String? deskripsi;

  const GameModel({
    required this.id,
    required this.rawgId,
    required this.judul,
    this.coverUrl,
    required this.rating,
    required this.genre,
    required this.genres,
    required this.platform,
    required this.platforms,
    this.tanggalRilis,
    this.deskripsi,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    // Parse list genre
    List<String> parsedGenres = [];
    if (json['genres'] is List) {
      for (final g in json['genres'] as List) {
        if (g is String) {
          parsedGenres.add(g);
        } else if (g is Map && g['nama'] != null) {
          parsedGenres.add(g['nama'].toString());
        } else if (g is Map && g['name'] != null) {
          parsedGenres.add(g['name'].toString());
        }
      }
    }

    // Parse list platform
    List<String> parsedPlatforms = [];
    if (json['platforms'] is List) {
      for (final p in json['platforms'] as List) {
        if (p is String) {
          parsedPlatforms.add(p);
        } else if (p is Map && p['nama'] != null) {
          parsedPlatforms.add(p['nama'].toString());
        } else if (p is Map && p['name'] != null) {
          parsedPlatforms.add(p['name'].toString());
        }
      }
    }

    final double parsedRating = json['rating'] is num
        ? (json['rating'] as num).toDouble()
        : double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0;

    return GameModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      rawgId: json['rawg_id'] is int
          ? json['rawg_id'] as int
          : int.tryParse(json['rawg_id']?.toString() ?? '0') ?? 0,
      judul: (json['judul'] ?? json['name'] ?? 'Untitled Game').toString(),
      coverUrl: json['cover_url']?.toString() ?? json['background_image']?.toString(),
      rating: parsedRating,
      genre: (json['genre'] ?? (parsedGenres.isNotEmpty ? parsedGenres.join(', ') : '')).toString(),
      genres: parsedGenres,
      platform: (json['platform'] ?? (parsedPlatforms.isNotEmpty ? parsedPlatforms.join(', ') : '')).toString(),
      platforms: parsedPlatforms,
      tanggalRilis: json['tanggal_rilis']?.toString() ?? json['released']?.toString(),
      deskripsi: json['deskripsi']?.toString() ?? json['description_raw']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawg_id': rawgId,
      'judul': judul,
      'cover_url': coverUrl,
      'rating': rating,
      'genre': genre,
      'genres': genres,
      'platform': platform,
      'platforms': platforms,
      'tanggal_rilis': tanggalRilis,
      'deskripsi': deskripsi,
    };
  }
}
