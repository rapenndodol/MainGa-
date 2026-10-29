class GenreModel {
  final int id;
  final String nama;
  final int? rawgId;

  const GenreModel({
    required this.id,
    required this.nama,
    this.rawgId,
  });

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nama: (json['nama'] ?? json['name'] ?? '').toString(),
      rawgId: json['rawg_id'] is int
          ? json['rawg_id'] as int
          : int.tryParse(json['rawg_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'rawg_id': rawgId,
    };
  }
}
