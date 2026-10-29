class PlatformModel {
  final int id;
  final String nama;
  final int? rawgId;

  const PlatformModel({
    required this.id,
    required this.nama,
    this.rawgId,
  });

  factory PlatformModel.fromJson(Map<String, dynamic> json) {
    return PlatformModel(
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
