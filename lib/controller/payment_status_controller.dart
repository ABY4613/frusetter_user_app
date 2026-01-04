import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/payment_status_model.dart';
import '../utlits/api_constants.dart';

/// Payment Status Controller using ChangeNotifier for Provider state management
class PaymentStatusController extends ChangeNotifier {
  PaymentStatusData? _paymentStatus;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasData = false;

  // Getters
  PaymentStatusData? get paymentStatus => _paymentStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _hasData;

  /// Check if payment is required (main flag for showing payment banner)
  bool get paymentRequired => _paymentStatus?.paymentRequired ?? false;

  /// Check if user has subscription
  bool get hasSubscription => _paymentStatus?.hasSubscription ?? false;

  /// Get balance amount
  double get balanceAmount => _paymentStatus?.balanceAmount ?? 0;

  /// Get plan name
  String get planName => _paymentStatus?.planName ?? '';

  /// Get payment status string
  String get paymentStatusText => _paymentStatus?.paymentStatus ?? '';

  /// Check if payment is overdue
  bool get isOverdue => _paymentStatus?.isOverdue ?? false;

  /// Fetch payment status from API
  Future<bool> fetchPaymentStatus(String accessToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiConstants.getUrl(ApiConstants.paymentStatus);
      debugPrint('PaymentStatusController: Fetching data from $url');

      final response = await http
          .get(Uri.parse(url), headers: ApiConstants.authHeaders(accessToken))
          .timeout(ApiConstants.requestTimeout);

      debugPrint(
        'PaymentStatusController: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final paymentResponse = PaymentStatusResponse.fromJson(responseData);

        if (paymentResponse.success) {
          _paymentStatus = paymentResponse.data;
          _hasData = true;
          _isLoading = false;
          debugPrint('PaymentStatusController: Data fetched successfully');
          debugPrint(
            'PaymentStatusController: Payment Required: ${_paymentStatus?.paymentRequired}',
          );
          debugPrint(
            'PaymentStatusController: Balance: ${_paymentStatus?.balanceAmount}',
          );
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Failed to load payment status';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final responseData = jsonDecode(response.body);
        _errorMessage =
            responseData['message'] ?? 'Failed to load payment status';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('PaymentStatusController: Error fetching data: $e');
      _errorMessage = 'Network error. Please check your connection.';
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
    _paymentStatus = null;
    _isLoading = false;
    _errorMessage = null;
    _hasData = false;
    notifyListeners();
  }
}
