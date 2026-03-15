
class FeedbackRequest {
  final String deliveryId;
  final int foodQualityRating;
  final int deliveryRating;
  final String comments;

  FeedbackRequest({
    required this.deliveryId,
    required this.foodQualityRating,
    required this.deliveryRating,
    required this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'delivery_id': deliveryId,
      'food_quality_rating': foodQualityRating,
      'delivery_rating': deliveryRating,
      'comments': comments,
    };
  }
}
