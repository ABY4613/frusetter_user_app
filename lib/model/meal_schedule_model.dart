import 'address_model.dart';

class MealSchedule {
  final String mealId;
  final DateTime deliveryDate;
  final String mealType;
  final String mealName;
  final String status;
  final Address? address;
  final bool isCustom;

  MealSchedule({
    required this.mealId,
    required this.deliveryDate,
    required this.mealType,
    required this.mealName,
    required this.status,
    this.address,
    required this.isCustom,
  });

  factory MealSchedule.fromJson(Map<String, dynamic> json) {
    return MealSchedule(
      mealId: json['meal_id'] ?? '',
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : DateTime.now(),
      mealType: json['meal_type'] ?? '',
      mealName: json['meal_name'] ?? '',
      status: json['status'] ?? '',
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      isCustom: json['is_custom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meal_id': mealId,
      'delivery_date': deliveryDate.toIso8601String().split('T')[0],
      'meal_type': mealType,
      'meal_name': mealName,
      'status': status,
      'address': address?.toJson(),
      'is_custom': isCustom,
    };
  }
}

class MealScheduleResponse {
  final bool success;
  final List<MealSchedule> data;
  final int count;

  MealScheduleResponse({
    required this.success,
    required this.data,
    required this.count,
  });

  factory MealScheduleResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<MealSchedule> mealSchedules =
        list.map((i) => MealSchedule.fromJson(i)).toList();

    return MealScheduleResponse(
      success: json['success'] ?? false,
      data: mealSchedules,
      count: json['count'] ?? 0,
    );
  }
}
