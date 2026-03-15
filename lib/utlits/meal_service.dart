import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class MealService {
  static Future<bool> updateMealAddress({
    required String accessToken,
    required String deliveryDate,
    required String mealType,
    required String addressId,
  }) async {
    try {
      final url = ApiConstants.getUrl(ApiConstants.mealAddress);
      final body = jsonEncode({
        'delivery_date': deliveryDate,
        'meal_type': mealType.toLowerCase(),
        'address_id': addressId,
      });

      debugPrint('MealService: Updating meal address at $url');
      debugPrint('MealService: Request body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(accessToken),
        body: body,
      ).timeout(ApiConstants.requestTimeout);

      debugPrint('MealService: Response status code: ${response.statusCode}');
      debugPrint('MealService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? true;
      } else {
        debugPrint('MealService: Update failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('MealService: Error updating meal address: $e');
      return false;
    }
  }
}
