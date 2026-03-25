
class NotificationResponse {
  final bool success;
  final NotificationData data;

  NotificationResponse({
    required this.success,
    required this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'] ?? false,
      data: NotificationData.fromJson(json['data'] ?? {}),
    );
  }
}

class NotificationData {
  final List<NotificationItem> notifications;
  final int unreadCount;

  NotificationData({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    var list = json['notifications'] as List? ?? [];
    List<NotificationItem> notificationList =
        list.map((i) => NotificationItem.fromJson(i)).toList();

    return NotificationData(
      notifications: notificationList,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final NotificationMetadata? metadata;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    this.metadata,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? notificationType,
    bool? isRead,
    NotificationMetadata? metadata,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['ID'] ?? '',
      userId: json['UserID'] ?? '',
      title: json['Title'] ?? '',
      message: json['Message'] ?? '',
      notificationType: json['NotificationType'] ?? '',
      isRead: json['IsRead'] ?? false,
      metadata: json['Metadata'] != null
          ? NotificationMetadata.fromJson(json['Metadata'])
          : null,
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : DateTime.now(),
    );
  }
}

class NotificationMetadata {
  final String? deliveryId;
  final String? mealName;
  final String? mealType;
  final String? scheduledMealId;
  final bool feedbackSubmitted;

  NotificationMetadata({
    this.deliveryId,
    this.mealName,
    this.mealType,
    this.scheduledMealId,
    this.feedbackSubmitted = false,
  });

  NotificationMetadata copyWith({
    String? deliveryId,
    String? mealName,
    String? mealType,
    String? scheduledMealId,
    bool? feedbackSubmitted,
  }) {
    return NotificationMetadata(
      deliveryId: deliveryId ?? this.deliveryId,
      mealName: mealName ?? this.mealName,
      mealType: mealType ?? this.mealType,
      scheduledMealId: scheduledMealId ?? this.scheduledMealId,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
    );
  }

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      deliveryId: json['delivery_id'],
      mealName: json['meal_name'],
      mealType: json['meal_type'],
      scheduledMealId: json['scheduled_meal_id'],
      feedbackSubmitted: json['feedback_submitted'] ?? false,
    );
  }
}
