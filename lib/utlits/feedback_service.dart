import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/feedback_model.dart';
import 'api_constants.dart';

class FeedbackService {
  static Future<bool> submitFeedback({
    required String accessToken,
    required FeedbackRequest request,
  }) async {
    try {
      final url = ApiConstants.getUrl(ApiConstants.feedback);
      final body = jsonEncode(request.toJson());
      
      debugPrint('FeedbackService: Submitting feedback to $url');
      debugPrint('FeedbackService: Request body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(accessToken),
        body: body,
      ).timeout(ApiConstants.requestTimeout);

      debugPrint('FeedbackService: Response status code: ${response.statusCode}');
      debugPrint('FeedbackService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // If statusCode is 2xx, we consider it a success even if 'success' field is missing
        return data['success'] ?? true;
      } else {
        debugPrint('FeedbackService: Submission failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('FeedbackService: Error submitting feedback: $e');
      return false;
    }
  }
}
