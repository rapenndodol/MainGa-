class StorePriceItem {
  final int? id;
  final String toko;
  final double harga;
  final int hargaIdrEstimasi;
  final double diskonPersen;
  final DateTime? dicekPada;
  final String? dicekPadaRaw;

  const StorePriceItem({
    this.id,
    required this.toko,
    required this.harga,
    required this.hargaIdrEstimasi,
    required this.diskonPersen,
    this.dicekPada,
    this.dicekPadaRaw,
  });

  factory StorePriceItem.fromJson(Map<String, dynamic> json) {
    final double price = json['harga'] is num
        ? (json['harga'] as num).toDouble()
        : double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0;

    final double discount = json['diskon_persen'] is num
        ? (json['diskon_persen'] as num).toDouble()
        : double.tryParse(json['diskon_persen']?.toString() ?? '0') ?? 0.0;

    final int idr = json['harga_idr_estimasi'] is int
        ? json['harga_idr_estimasi'] as int
        : int.tryParse(json['harga_idr_estimasi']?.toString() ?? '0') ?? (price * 16000).round();

    DateTime? parsedDate;
    final dateStr = json['dicek_pada']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (_) {}
    }

    return StorePriceItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      toko: json['toko']?.toString() ?? 'Toko',
      harga: price,
      hargaIdrEstimasi: idr,
      diskonPersen: discount,
      dicekPada: parsedDate,
      dicekPadaRaw: dateStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toko': toko,
      'harga': harga,
      'harga_idr_estimasi': hargaIdrEstimasi,
      'diskon_persen': diskonPersen,
      'dicek_pada': dicekPadaRaw,
    };
  }
}

class GamePricesResponseModel {
  final bool success;
  final String message;
  final bool hargaTersedia;
  final String statusKeterangan;
  final double? hargaTerendah;
  final int? hargaTerendahIdrEstimasi;
  final String? tokoTermurah;
  final double kursUsdKeIdrEstimasi;
  final List<StorePriceItem> hargaTerkini;
  final List<StorePriceItem> riwayatHarga;

  const GamePricesResponseModel({
    required this.success,
    required this.message,
    required this.hargaTersedia,
    required this.statusKeterangan,
    this.hargaTerendah,
    this.hargaTerendahIdrEstimasi,
    this.tokoTermurah,
    this.kursUsdKeIdrEstimasi = 16000.0,
    required this.hargaTerkini,
    required this.riwayatHarga,
  });

  factory GamePricesResponseModel.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] is bool ? json['success'] as bool : false;
    final String message = json['message']?.toString() ?? '';

    bool available = false;
    String status = 'Harga belum tersedia';
    double? lowest;
    int? lowestIdr;
    String? cheapestStore;
    double rate = 16000.0;
    List<StorePriceItem> currentList = [];
    List<StorePriceItem> historyList = [];

    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;

      available = data['harga_tersedia'] is bool
          ? data['harga_tersedia'] as bool
          : (data['harga_tersedia'] == 1 || data['harga_tersedia']?.toString() == 'true');

      status = data['status_keterangan']?.toString() ?? (available ? 'Harga tersedia' : 'Harga belum tersedia');

      if (data['harga_terendah'] != null) {
        lowest = data['harga_terendah'] is num
            ? (data['harga_terendah'] as num).toDouble()
            : double.tryParse(data['harga_terendah'].toString());
      }

      if (data['harga_terendah_idr_estimasi'] != null) {
        lowestIdr = data['harga_terendah_idr_estimasi'] is int
            ? data['harga_terendah_idr_estimasi'] as int
            : int.tryParse(data['harga_terendah_idr_estimasi'].toString());
      } else if (lowest != null) {
        lowestIdr = (lowest * rate).round();
      }

      cheapestStore = data['toko_termurah']?.toString();

      if (data['kurs_usd_ke_idr_estimasi'] is num) {
        rate = (data['kurs_usd_ke_idr_estimasi'] as num).toDouble();
      }

      if (data['harga_terkini'] is List) {
        currentList = (data['harga_terkini'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => StorePriceItem.fromJson(e))
            .toList();
      }

      if (data['riwayat_harga'] is List) {
        historyList = (data['riwayat_harga'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => StorePriceItem.fromJson(e))
            .toList();
      }
    }

    return GamePricesResponseModel(
      success: success,
      message: message,
      hargaTersedia: available,
      statusKeterangan: status,
      hargaTerendah: lowest,
      hargaTerendahIdrEstimasi: lowestIdr,
      tokoTermurah: cheapestStore,
      kursUsdKeIdrEstimasi: rate,
      hargaTerkini: currentList,
      riwayatHarga: historyList,
    );
  }
}
