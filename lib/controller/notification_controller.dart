import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/notification_model.dart';
import '../utlits/notification_service.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  
  // Persistent tracking of submitted feedbacks to prevent showing popups again
  // even after app restart, in case the backend hasn't updated yet.
  final Set<String> _submittedFeedbackDeliveryIds = {};
  static const String _prefKeySubmittedFeedbacks = 'submitted_feedback_delivery_ids';

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Check if feedback for a delivery has been submitted locally/persistently
  bool isFeedbackSubmitted(String deliveryId) {
    if (deliveryId.isEmpty) return false;
    return _submittedFeedbackDeliveryIds.contains(deliveryId);
  }

  /// Initialize and load persistent data
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedIds = prefs.getStringList(_prefKeySubmittedFeedbacks);
      if (savedIds != null) {
        _submittedFeedbackDeliveryIds.addAll(savedIds);
        debugPrint('NotificationController: Loaded ${_submittedFeedbackDeliveryIds.length} submitted feedback IDs from storage');
      }
    } catch (e) {
      debugPrint('NotificationController: Error loading persistent state: $e');
    }
  }

  Future<void> fetchNotifications(String accessToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await NotificationService.fetchNotifications(
        accessToken: accessToken,
      );
      
      // Update with backend response
      _notifications = response.data.notifications;
      _unreadCount = response.data.unreadCount;
      
      // Apply local overrides for just-submitted feedback
      _applyLocalFeedbackOverrides();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark feedback as submitted for a deliveryId locally and on backend
  Future<void> markFeedbackAsSubmitted(String accessToken, String deliveryId) async {
    if (deliveryId.isEmpty) return;
    
    // Add to local set
    _submittedFeedbackDeliveryIds.add(deliveryId);
    
    // Persist to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKeySubmittedFeedbacks, _submittedFeedbackDeliveryIds.toList());
    } catch (e) {
      debugPrint('NotificationController: Error persisting submission status: $e');
    }

    _applyLocalFeedbackOverrides();
    notifyListeners();
    
    // Also proactively mark all related notifications as read on the backend
    // to avoid phantom popups next time the app opens
    await markAllForDeliveryAsRead(accessToken, deliveryId);
    
    debugPrint('NotificationController: Marked feedback for $deliveryId as submitted persistently');
  }

  /// Mark all notifications related to a deliveryId as read on the backend
  Future<void> markAllForDeliveryAsRead(String accessToken, String deliveryId) async {
    if (deliveryId.isEmpty) return;
    
    // Find all unread notifications for this deliveryId
    final relatedNotifications = _notifications.where(
      (n) => !n.isRead && n.metadata?.deliveryId == deliveryId
    ).toList();
    
    if (relatedNotifications.isEmpty) return;
    
    // We update local state first for immediate UI response
    for (var n in relatedNotifications) {
      final index = _notifications.indexWhere((item) => item.id == n.id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
      }
    }
    notifyListeners();
    
    // Then call API for each in parallel
    try {
      await Future.wait(
        relatedNotifications.map((n) => NotificationService.markAsRead(
          accessToken: accessToken,
          notificationId: n.id,
        ))
      );
    } catch (e) {
      debugPrint('NotificationController: Error marking multiple notifications as read: $e');
    }
  }

  /// Internally apply local session state to the current notification list
  void _applyLocalFeedbackOverrides() {
    if (_submittedFeedbackDeliveryIds.isEmpty) return;
    
    for (int i = 0; i < _notifications.length; i++) {
       final deliveryId = _notifications[i].metadata?.deliveryId;
       if (deliveryId != null && _submittedFeedbackDeliveryIds.contains(deliveryId)) {
         // Also mark as read for good measure if it's been submitted
         _notifications[i] = _notifications[i].copyWith(
           isRead: true,
           metadata: _notifications[i].metadata?.copyWith(feedbackSubmitted: true),
         );
       }
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
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
