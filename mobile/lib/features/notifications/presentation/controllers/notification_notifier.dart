import 'package:flutter/foundation.dart';
import '../../data/datasources/notification_remote_data_source.dart';

class NotificationNotifier extends ChangeNotifier {
  NotificationNotifier._();
  static final NotificationNotifier instance = NotificationNotifier._();

  final NotificationRemoteDataSource _dataSource = NotificationRemoteDataSource();

  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Muat jumlah unread notifikasi dari server
  Future<void> fetchUnreadCount() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final count = await _dataSource.fetchUnreadCount();
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
      // Abaikan galat jaringan ringan agar UI tidak crash
    } finally {
      _isLoading = false;
    }
  }

  void setUnreadCount(int count) {
    _unreadCount = count < 0 ? 0 : count;
    notifyListeners();
  }

  void decrementUnreadCount({int by = 1}) {
    _unreadCount = (_unreadCount - by).clamp(0, 999999);
    notifyListeners();
  }

  /// Tandai satu notifikasi sebagai dibaca dan kurangi badge jika belum dibaca
  Future<bool> markAsRead(int id, {bool wasUnread = true}) async {
    final result = await _dataSource.markAsRead(id);
    if (result['success'] == true) {
      if (wasUnread) {
        decrementUnreadCount(by: 1);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Tandai seluruh notifikasi sebagai dibaca dan set badge menjadi 0
  Future<bool> markAllAsRead() async {
    final result = await _dataSource.markAllAsRead();
    if (result['success'] == true) {
      _unreadCount = 0;
      notifyListeners();
      return true;
    }
    return false;
  }
}
