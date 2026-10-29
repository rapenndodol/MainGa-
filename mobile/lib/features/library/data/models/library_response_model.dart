import 'library_entry_model.dart';

class LibraryResponseModel {
  final bool success;
  final String message;
  final List<LibraryEntryModel> entries;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const LibraryResponseModel({
    required this.success,
    required this.message,
    required this.entries,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory LibraryResponseModel.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] == true;
    final String message = json['message']?.toString() ?? '';

    List<LibraryEntryModel> parsedEntries = [];
    int currentPage = 1;
    int lastPage = 1;
    int perPage = 15;
    int total = 0;

    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;

      if (data['entries'] is List) {
        parsedEntries = (data['entries'] as List)
            .map((item) => LibraryEntryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (data['pagination'] is Map<String, dynamic>) {
        final pag = data['pagination'] as Map<String, dynamic>;
        currentPage = pag['current_page'] is int
            ? pag['current_page'] as int
            : int.tryParse(pag['current_page']?.toString() ?? '1') ?? 1;
        lastPage = pag['last_page'] is int
            ? pag['last_page'] as int
            : int.tryParse(pag['last_page']?.toString() ?? '1') ?? 1;
        perPage = pag['per_page'] is int
            ? pag['per_page'] as int
            : int.tryParse(pag['per_page']?.toString() ?? '15') ?? 15;
        total = pag['total'] is int
            ? pag['total'] as int
            : int.tryParse(pag['total']?.toString() ?? '0') ?? 0;
      }
    }

    return LibraryResponseModel(
      success: success,
      message: message,
      entries: parsedEntries,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
    );
  }
}
