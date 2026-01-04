import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/addon_model.dart';
import 'api_constants.dart';

/// Service class for Addon-related API calls
class AddonService {
  /// Fetch all addons from the API
  ///
  /// Parameters:
  /// - [accessToken]: User's authentication token
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of items per page (default: 50)
  /// - [category]: Optional category filter
  ///
  /// Returns [AddonsResponse] containing list of addons and pagination info
  /// Throws [Exception] on error
  static Future<AddonsResponse> fetchAddons({
    required String accessToken,
    int page = 1,
    int limit = 50,
    String? category,
  }) async {
    try {
      // Build URL with query parameters
      final uri = Uri.parse(ApiConstants.getUrl(ApiConstants.addons)).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );

      // Make GET request
      final response = await http
          .get(uri, headers: ApiConstants.authHeaders(accessToken))
          .timeout(ApiConstants.requestTimeout);

      // Handle response
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AddonsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Addons endpoint not found.');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to fetch addons';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Network error. Please try again.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Add addon to cart (placeholder for future implementation)
  ///
  /// Parameters:
  /// - [accessToken]: User's authentication token
  /// - [addonId]: ID of the addon to add
  /// - [quantity]: Quantity to add
  ///
  /// Returns [bool] indicating success
  static Future<bool> addToCart({
    required String accessToken,
    required String addonId,
    required int quantity,
  }) async {
    try {
      // TODO: Implement actual API call when cart endpoint is available
      // For now, return success after a delay
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      throw Exception('Failed to add to cart: ${e.toString()}');
    }
  }

  /// Get addon details by ID (placeholder for future implementation)
  ///
  /// Parameters:
  /// - [accessToken]: User's authentication token
  /// - [addonId]: ID of the addon
  ///
  /// Returns [AddOnProduct] with addon details
  static Future<AddOnProduct?> getAddonById({
    required String accessToken,
    required String addonId,
  }) async {
    try {
      // TODO: Implement actual API call when addon detail endpoint is available
      // For now, fetch all and filter
      final response = await fetchAddons(accessToken: accessToken);
      return response.addons.firstWhere(
        (addon) => addon.id == addonId,
        orElse: () => throw Exception('Addon not found'),
      );
    } catch (e) {
      throw Exception('Failed to fetch addon details: ${e.toString()}');
    }
  }
}
