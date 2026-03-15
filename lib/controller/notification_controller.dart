import 'package:flutter/material.dart';
import '../model/notification_model.dart';
import '../utlits/notification_service.dart';

class NotificationController with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications(String accessToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await NotificationService.fetchNotifications(
        accessToken: accessToken,
      );
      _notifications = response.data.notifications;
      _unreadCount = response.data.unreadCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String accessToken, String notificationId) async {
    try {
      final success = await NotificationService.markAsRead(
        accessToken: accessToken,
        notificationId: notificationId,
      );

      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = NotificationItem(
            id: _notifications[index].id,
            userId: _notifications[index].userId,
            title: _notifications[index].title,
            message: _notifications[index].message,
            notificationType: _notifications[index].notificationType,
            isRead: true,
            metadata: _notifications[index].metadata,
            createdAt: _notifications[index].createdAt,
          );
          _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
