import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/subscription_model.dart';
import '../utlits/api_constants.dart';

/// Subscription Controller using ChangeNotifier for Provider state management
class SubscriptionController extends ChangeNotifier {
  SubscriptionManageData? _subscriptionData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasData = false;

  // Getters for main data objects
  SubscriptionManageData? get subscriptionData => _subscriptionData;
  SubscriptionUser? get user => _subscriptionData?.user;
  SubscriptionPlan? get plan => _subscriptionData?.plan;
  SubscriptionDetails? get subscription => _subscriptionData?.subscription;
  SubscriptionProjection? get projection =>
      _subscriptionData?.subscriptionProjection;
  CutOffInfo? get cutOffInfo => _subscriptionData?.cutOffInfo;

  // State getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _hasData;

  // User convenience getters
  String get userName => user?.fullName ?? '';
  String get userEmail => user?.email ?? '';
  String get userPhone => user?.phone ?? '';
  String get userFirstName => user?.firstName ?? '';

  // Plan convenience getters
  String get planName => plan?.name ?? 'Premium Plan';
  String get planDescription => plan?.description ?? '';
  String get planType => plan?.planType ?? 'weekly';
  double get planPrice => plan?.price ?? 0.0;
  String get formattedPlanPrice => plan?.formattedPrice ?? '₹0';
  int get planMealsPerDay => plan?.mealsPerDay ?? 0;
  int get planDurationDays => plan?.durationDays ?? 0;
  String get planMealTypes => plan?.mealTypesDisplay ?? '';

  /// Fetch subscription management data from API
  Future<bool> fetchSubscriptionData(String accessToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiConstants.getUrl(ApiConstants.subscriptionManage);
      debugPrint('SubscriptionController: Fetching data from $url');

      final response = await http
          .get(Uri.parse(url), headers: ApiConstants.authHeaders(accessToken))
          .timeout(ApiConstants.requestTimeout);

      debugPrint(
        'SubscriptionController: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final subscriptionResponse = SubscriptionManageResponse.fromJson(
          responseData,
        );

        if (subscriptionResponse.success) {
          _subscriptionData = subscriptionResponse.data;
          _hasData = true;
          _isLoading = false;
          debugPrint('SubscriptionController: Data fetched successfully');
          debugPrint(
            'SubscriptionController: Plan: ${_subscriptionData?.plan?.name ?? "N/A"}',
          );
          debugPrint(
            'SubscriptionController: Subscription ID: ${_subscriptionData?.subscription.id}',
          );
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Failed to load subscription data';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final responseData = jsonDecode(response.body);
        _errorMessage =
            responseData['message'] ?? 'Failed to load subscription data';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('SubscriptionController: Error fetching data: $e');
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Pause subscription for a single day with specific meal(s)
  /// [date] - Date to pause (YYYY-MM-DD format)
  /// [mealTypes] - List of meal types to pause: ['breakfast'], ['lunch'], ['dinner'], or multiple
  /// [reason] - Reason for pausing (optional)
  Future<bool> pauseSingleDay(
    String accessToken, {
    required String date,
    required List<String> mealTypes,
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiConstants.getUrl(ApiConstants.subscriptionPause);
      debugPrint('SubscriptionController: Pausing single day at $url');
      debugPrint(
        'SubscriptionController: date: $date, meal_types: $mealTypes, reason: $reason',
      );

      final body = <String, dynamic>{
        'pause_type': 'single',
        'date': date,
        'meal_types': mealTypes,
      };

      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConstants.authHeaders(accessToken),
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint(
        'SubscriptionController: Pause response status: ${response.statusCode}',
      );
      debugPrint(
        'SubscriptionController: Pause response body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          // Refresh subscription data after pausing
          await fetchSubscriptionData(accessToken);
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to pause plan';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final responseData = jsonDecode(response.body);
      _errorMessage = responseData['message'] ?? 'Failed to pause plan';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('SubscriptionController: Error pausing plan: $e');
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Pause subscription for a date range
  /// [fromDate] - Start date of pause (YYYY-MM-DD format)
  /// [toDate] - End date of pause (YYYY-MM-DD format)
  /// [reason] - Reason for pausing (optional)
  Future<bool> pauseDateRange(
    String accessToken, {
    required String fromDate,
    required String toDate,
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiConstants.getUrl(ApiConstants.subscriptionPause);
      debugPrint('SubscriptionController: Pausing date range at $url');
      debugPrint(
        'SubscriptionController: from_date: $fromDate, to_date: $toDate, reason: $reason',
      );

      final body = <String, dynamic>{
        'pause_type': 'dateRange',
        'from_date': fromDate,
        'to_date': toDate,
      };

      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConstants.authHeaders(accessToken),
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint(
        'SubscriptionController: Pause response status: ${response.statusCode}',
      );
      debugPrint(
        'SubscriptionController: Pause response body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          // Refresh subscription data after pausing
          await fetchSubscriptionData(accessToken);
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to pause plan';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final responseData = jsonDecode(response.body);
      _errorMessage = responseData['message'] ?? 'Failed to pause plan';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('SubscriptionController: Error pausing plan: $e');
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resume subscription plan
  Future<bool> resumePlan(String accessToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiConstants.getUrl(ApiConstants.subscriptionResume);
      debugPrint('SubscriptionController: Resuming plan at $url');

      final response = await http
          .post(Uri.parse(url), headers: ApiConstants.authHeaders(accessToken))
          .timeout(ApiConstants.requestTimeout);

      debugPrint(
        'SubscriptionController: Resume response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          // Refresh subscription data after resuming
          await fetchSubscriptionData(accessToken);
          return true;
        }
      }

      final responseData = jsonDecode(response.body);
      _errorMessage = responseData['message'] ?? 'Failed to resume plan';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('SubscriptionController: Error resuming plan: $e');
      _errorMessage = 'Network error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset controller state
  void reset() {
    _subscriptionData = null;
    _isLoading = false;
    _errorMessage = null;
    _hasData = false;
    notifyListeners();
  }
}
