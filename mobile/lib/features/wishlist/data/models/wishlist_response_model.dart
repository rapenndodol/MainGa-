import 'wishlist_item_model.dart';

class WishlistResponseModel {
  final bool success;
  final String message;
  final List<WishlistItemModel> wishlists;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const WishlistResponseModel({
    required this.success,
    required this.message,
    required this.wishlists,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory WishlistResponseModel.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] is bool ? json['success'] as bool : false;
    final String message = json['message']?.toString() ?? '';

    List<WishlistItemModel> items = [];
    int curPage = 1;
    int lstPage = 1;
    int pPage = 20;
    int tot = 0;

    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;

      if (data['wishlists'] is List) {
        items = (data['wishlists'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => WishlistItemModel.fromJson(item))
            .toList();
      }

      if (data['pagination'] is Map<String, dynamic>) {
        final pag = data['pagination'] as Map<String, dynamic>;
        curPage = pag['current_page'] is int
            ? pag['current_page'] as int
            : int.tryParse(pag['current_page']?.toString() ?? '1') ?? 1;
        lstPage = pag['last_page'] is int
            ? pag['last_page'] as int
            : int.tryParse(pag['last_page']?.toString() ?? '1') ?? 1;
        pPage = pag['per_page'] is int
            ? pag['per_page'] as int
            : int.tryParse(pag['per_page']?.toString() ?? '20') ?? 20;
        tot = pag['total'] is int
            ? pag['total'] as int
            : int.tryParse(pag['total']?.toString() ?? '0') ?? 0;
      }
    } else if (json['data'] is List) {
      items = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => WishlistItemModel.fromJson(item))
          .toList();
      tot = items.length;
    }

    return WishlistResponseModel(
      success: success,
      message: message,
      wishlists: items,
      currentPage: curPage,
      lastPage: lstPage,
      perPage: pPage,
      total: tot,
    );
  }
}
