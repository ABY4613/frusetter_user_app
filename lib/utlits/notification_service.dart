import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/notification_model.dart';
import 'api_constants.dart';

/// Service class for Notification-related API calls
class NotificationService {
  /// Fetch all notifications from the API
  ///
  /// Parameters:
  /// - [accessToken]: User's authentication token
  ///
  /// Returns [NotificationResponse] containing list of notifications and unread count
  static Future<NotificationResponse> fetchNotifications({
    required String accessToken,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.getUrl(ApiConstants.notifications));

      final response = await http
          .get(uri, headers: ApiConstants.authHeaders(accessToken))
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NotificationResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to fetch notifications';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Network error. Please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Mark a notification as read
  ///
  /// Parameters:
  /// - [accessToken]: User's authentication token
  /// - [notificationId]: ID of the notification to mark as read
  ///
  /// Returns [bool] indicating success
  static Future<bool> markAsRead({
    required String accessToken,
    required String notificationId,
  }) async {
    try {
      final uri = Uri.parse(
          ApiConstants.getUrl(ApiConstants.markNotificationRead(notificationId)));

      final response = await http
          .post(uri, headers: ApiConstants.authHeaders(accessToken))
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
