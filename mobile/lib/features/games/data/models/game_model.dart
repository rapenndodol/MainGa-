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
  final String? libraryStatus;
  final Map<String, dynamic>? libraryEntryData;

  // Wishlist & Price Tracker Information (US-04 & US-05)
  final bool inWishlist;
  final String? wishlistStatus;
  final Map<String, dynamic>? wishlistAlertData;
  final bool hargaTersedia;
  final String? statusHarga;
  final double? hargaTerendah;
  final int? hargaTerendahIdrEstimasi;
  final String? tokoTermurah;
  final List<dynamic>? hargaTerkini;

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
    this.libraryStatus,
    this.libraryEntryData,
    this.inWishlist = false,
    this.wishlistStatus,
    this.wishlistAlertData,
    this.hargaTersedia = false,
    this.statusHarga,
    this.hargaTerendah,
    this.hargaTerendahIdrEstimasi,
    this.tokoTermurah,
    this.hargaTerkini,
  });

  /// Wishlist alert id jika game ada di wishlist
  int? get wishlistAlertId => wishlistAlertData != null && wishlistAlertData!['id'] is int
      ? wishlistAlertData!['id'] as int
      : (wishlistAlertData != null ? int.tryParse(wishlistAlertData!['id']?.toString() ?? '') : null);

  /// Target harga dalam USD jika ada di wishlist
  double? get wishlistHargaTarget => wishlistAlertData != null
      ? (wishlistAlertData!['harga_target'] is num
          ? (wishlistAlertData!['harga_target'] as num).toDouble()
          : double.tryParse(wishlistAlertData!['harga_target']?.toString() ?? ''))
      : null;

  /// Status aktif pantauan jika ada di wishlist
  bool get isWishlistActive =>
      wishlistAlertData != null && (wishlistAlertData!['aktif'] == true || wishlistAlertData!['aktif'] == 1);

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

    final bool inWl = json['in_wishlist'] is bool
        ? json['in_wishlist'] as bool
        : (json['in_wishlist'] == 1 || json['in_wishlist']?.toString() == 'true');

    final bool priceAvail = json['harga_tersedia'] is bool
        ? json['harga_tersedia'] as bool
        : (json['harga_tersedia'] == 1 || json['harga_tersedia']?.toString() == 'true');

    final double? lowestPrice = json['harga_terendah'] != null
        ? (json['harga_terendah'] is num
            ? (json['harga_terendah'] as num).toDouble()
            : double.tryParse(json['harga_terendah'].toString()))
        : null;

    final int? lowestPriceIdr = json['harga_terendah_idr_estimasi'] != null
        ? (json['harga_terendah_idr_estimasi'] is int
            ? json['harga_terendah_idr_estimasi'] as int
            : int.tryParse(json['harga_terendah_idr_estimasi'].toString()))
        : null;

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
      libraryStatus: json['library_status']?.toString(),
      libraryEntryData: json['library_entry'] is Map<String, dynamic>
          ? json['library_entry'] as Map<String, dynamic>
          : null,
      inWishlist: inWl,
      wishlistStatus: json['wishlist_status']?.toString(),
      wishlistAlertData: json['wishlist_alert'] is Map<String, dynamic>
          ? json['wishlist_alert'] as Map<String, dynamic>
          : null,
      hargaTersedia: priceAvail,
      statusHarga: json['status_harga']?.toString(),
      hargaTerendah: lowestPrice,
      hargaTerendahIdrEstimasi: lowestPriceIdr,
      tokoTermurah: json['toko_termurah']?.toString(),
      hargaTerkini: json['harga_terkini'] is List ? json['harga_terkini'] as List : null,
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
      'library_status': libraryStatus,
      'library_entry': libraryEntryData,
      'in_wishlist': inWishlist,
      'wishlist_status': wishlistStatus,
      'wishlist_alert': wishlistAlertData,
      'harga_tersedia': hargaTersedia,
      'status_harga': statusHarga,
      'harga_terendah': hargaTerendah,
      'harga_terendah_idr_estimasi': hargaTerendahIdrEstimasi,
      'toko_termurah': tokoTermurah,
      'harga_terkini': hargaTerkini,
    };
  }

  GameModel copyWith({
    int? id,
    int? rawgId,
    String? judul,
    String? coverUrl,
    double? rating,
    String? genre,
    List<String>? genres,
    String? platform,
    List<String>? platforms,
    String? tanggalRilis,
    String? deskripsi,
    String? libraryStatus,
    Map<String, dynamic>? libraryEntryData,
    bool clearLibraryStatus = false,
    bool? inWishlist,
    String? wishlistStatus,
    Map<String, dynamic>? wishlistAlertData,
    bool clearWishlistStatus = false,
    bool? hargaTersedia,
    String? statusHarga,
    double? hargaTerendah,
    int? hargaTerendahIdrEstimasi,
    String? tokoTermurah,
    List<dynamic>? hargaTerkini,
  }) {
    return GameModel(
      id: id ?? this.id,
      rawgId: rawgId ?? this.rawgId,
      judul: judul ?? this.judul,
      coverUrl: coverUrl ?? this.coverUrl,
      rating: rating ?? this.rating,
      genre: genre ?? this.genre,
      genres: genres ?? this.genres,
      platform: platform ?? this.platform,
      platforms: platforms ?? this.platforms,
      tanggalRilis: tanggalRilis ?? this.tanggalRilis,
      deskripsi: deskripsi ?? this.deskripsi,
      libraryStatus: clearLibraryStatus ? null : (libraryStatus ?? this.libraryStatus),
      libraryEntryData: clearLibraryStatus ? null : (libraryEntryData ?? this.libraryEntryData),
      inWishlist: clearWishlistStatus ? false : (inWishlist ?? this.inWishlist),
      wishlistStatus: clearWishlistStatus ? null : (wishlistStatus ?? this.wishlistStatus),
      wishlistAlertData: clearWishlistStatus ? null : (wishlistAlertData ?? this.wishlistAlertData),
      hargaTersedia: hargaTersedia ?? this.hargaTersedia,
      statusHarga: statusHarga ?? this.statusHarga,
      hargaTerendah: hargaTerendah ?? this.hargaTerendah,
      hargaTerendahIdrEstimasi: hargaTerendahIdrEstimasi ?? this.hargaTerendahIdrEstimasi,
      tokoTermurah: tokoTermurah ?? this.tokoTermurah,
      hargaTerkini: hargaTerkini ?? this.hargaTerkini,
    );
  }
}
