import 'notification_model.dart';

class NotificationsResponseModel {
  final bool success;
  final String message;
  final List<NotificationModel> notifications;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const NotificationsResponseModel({
    required this.success,
    required this.message,
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory NotificationsResponseModel.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] == true;
    final String message = json['message']?.toString() ?? '';

    final data = json['data'];
    List<NotificationModel> items = [];
    int currentPage = 1;
    int lastPage = 1;
    int perPage = 15;
    int total = 0;

    if (data is Map<String, dynamic>) {
      if (data['notifications'] is List) {
        items = (data['notifications'] as List)
            .whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList();
      }

      final pagination = data['pagination'];
      if (pagination is Map<String, dynamic>) {
        currentPage = pagination['current_page'] is int
            ? pagination['current_page'] as int
            : int.tryParse(pagination['current_page']?.toString() ?? '1') ?? 1;
        lastPage = pagination['last_page'] is int
            ? pagination['last_page'] as int
            : int.tryParse(pagination['last_page']?.toString() ?? '1') ?? 1;
        perPage = pagination['per_page'] is int
            ? pagination['per_page'] as int
            : int.tryParse(pagination['per_page']?.toString() ?? '15') ?? 15;
        total = pagination['total'] is int
            ? pagination['total'] as int
            : int.tryParse(pagination['total']?.toString() ?? '0') ?? 0;
      } else {
        total = items.length;
      }
    }

    return NotificationsResponseModel(
      success: success,
      message: message,
      notifications: items,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
    );
  }
}
