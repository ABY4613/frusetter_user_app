/// API Constants for Frusette Customer App
class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://api.frusette.com';

  // API Version
  static const String apiVersion = '/v1';

  // Full Base URL with version
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // User Endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';

  // Subscription Endpoints
  static const String subscriptions = '/subscriptions';
  static const String activeSubscription = '/subscriptions/active';
  static const String subscriptionPlan = '/customer/subscription/plan';
  static const String subscriptionManage = '/customer/subscription/manage';
  static const String subscriptionPause = '/customer/subscription/pause';
  static const String subscriptionResume = '/customer/subscription/resume';

  // Delivery Endpoints
  static const String deliveries = '/deliveries';
  static const String addresses = '/addresses';
  static const String customerAddresses = '/customer/addresses';

  // Order Endpoints
  static const String orders = '/orders';
  static const String orderTracking = '/orders/tracking';

  // Payment Endpoints
  static const String paymentStatus = '/customer/payment-status';

  // Addon Endpoints
  static const String addons = '/customer/addons';

  // Notification Endpoints
  static const String notifications = '/customer/notifications';
  static const String feedback = '/customer/feedback';
  static const String mealAddress = '/customer/meals/address';
  static const String mealAddresses = '/customer/meals/addresses';
  static String markNotificationRead(String id) =>
      '/customer/notifications/$id/read';

  // Meal Endpoints
  static String mealUnpause(String mealId) => '/customer/meals/$mealId/unpause';
  static String mealPause(String mealId) => '/customer/meals/$mealId/pause';

  // Helper method to get full URL
  static String getUrl(String endpoint) => '$apiBaseUrl$endpoint';

  // Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
