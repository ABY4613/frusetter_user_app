/// Subscription Model for Customer App
/// This model represents the subscription management API response

class SubscriptionManageResponse {
  final bool success;
  final SubscriptionManageData data;

  SubscriptionManageResponse({required this.success, required this.data});

  factory SubscriptionManageResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionManageResponse(
      success: json['success'] ?? false,
      data: SubscriptionManageData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data.toJson()};
  }
}

class SubscriptionManageData {
  final String screen;
  final SubscriptionDetails subscription;
  final SubscriptionProjection subscriptionProjection;

  SubscriptionManageData({
    required this.screen,
    required this.subscription,
    required this.subscriptionProjection,
  });

  factory SubscriptionManageData.fromJson(Map<String, dynamic> json) {
    return SubscriptionManageData(
      screen: json['screen'] ?? '',
      subscription: SubscriptionDetails.fromJson(json['subscription'] ?? {}),
      subscriptionProjection: SubscriptionProjection.fromJson(
        json['subscriptionProjection'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screen': screen,
      'subscription': subscription.toJson(),
      'subscriptionProjection': subscriptionProjection.toJson(),
    };
  }
}

class SubscriptionDetails {
  final String id;
  final String planName;
  final String status;
  final String paymentStatus;
  final SubscriptionActions actions;
  final SubscriptionDates dates;
  final MealInfo mealInfo;

  SubscriptionDetails({
    required this.id,
    required this.planName,
    required this.status,
    required this.paymentStatus,
    required this.actions,
    required this.dates,
    required this.mealInfo,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      id: json['id'] ?? '',
      planName: json['planName'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      actions: SubscriptionActions.fromJson(json['actions'] ?? {}),
      dates: SubscriptionDates.fromJson(json['dates'] ?? {}),
      mealInfo: MealInfo.fromJson(json['mealInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'status': status,
      'paymentStatus': paymentStatus,
      'actions': actions.toJson(),
      'dates': dates.toJson(),
      'mealInfo': mealInfo.toJson(),
    };
  }

  /// Check if subscription is active
  bool get isActive => status.toUpperCase() == 'ACTIVE';

  /// Check if subscription is paused
  bool get isPaused => status.toUpperCase() == 'PAUSED';
}

class SubscriptionActions {
  final bool pausePlan;
  final bool resumePlan;

  SubscriptionActions({required this.pausePlan, required this.resumePlan});

  factory SubscriptionActions.fromJson(Map<String, dynamic> json) {
    return SubscriptionActions(
      pausePlan: json['pausePlan'] ?? false,
      resumePlan: json['resumePlan'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'pausePlan': pausePlan, 'resumePlan': resumePlan};
  }
}

class SubscriptionDates {
  final String startDate;
  final String originalEndDate;
  final String adjustedEndDate;

  SubscriptionDates({
    required this.startDate,
    required this.originalEndDate,
    required this.adjustedEndDate,
  });

  factory SubscriptionDates.fromJson(Map<String, dynamic> json) {
    return SubscriptionDates(
      startDate: json['startDate'] ?? '',
      originalEndDate: json['originalEndDate'] ?? '',
      adjustedEndDate: json['adjustedEndDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'originalEndDate': originalEndDate,
      'adjustedEndDate': adjustedEndDate,
    };
  }

  /// Parse start date to DateTime
  DateTime? get startDateTime => _parseDate(startDate);

  /// Parse original end date to DateTime
  DateTime? get originalEndDateTime => _parseDate(originalEndDate);

  /// Parse adjusted end date to DateTime
  DateTime? get adjustedEndDateTime => _parseDate(adjustedEndDate);

  DateTime? _parseDate(String date) {
    if (date.isEmpty) return null;
    try {
      return DateTime.parse(date);
    } catch (e) {
      return null;
    }
  }
}

class MealInfo {
  final int mealsPerDay;
  final int totalMeals;
  final int daysRemaining;
  final int upcomingMeals;

  MealInfo({
    required this.mealsPerDay,
    required this.totalMeals,
    required this.daysRemaining,
    required this.upcomingMeals,
  });

  factory MealInfo.fromJson(Map<String, dynamic> json) {
    return MealInfo(
      mealsPerDay: json['mealsPerDay'] ?? 0,
      totalMeals: json['totalMeals'] ?? 0,
      daysRemaining: json['daysRemaining'] ?? 0,
      upcomingMeals: json['upcomingMeals'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealsPerDay': mealsPerDay,
      'totalMeals': totalMeals,
      'daysRemaining': daysRemaining,
      'upcomingMeals': upcomingMeals,
    };
  }
}

class SubscriptionProjection {
  final String currentEndDate;
  final String newEndDate;
  final PauseInfo pauseInfo;

  SubscriptionProjection({
    required this.currentEndDate,
    required this.newEndDate,
    required this.pauseInfo,
  });

  factory SubscriptionProjection.fromJson(Map<String, dynamic> json) {
    return SubscriptionProjection(
      currentEndDate: json['currentEndDate'] ?? '',
      newEndDate: json['newEndDate'] ?? '',
      pauseInfo: PauseInfo.fromJson(json['pauseInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentEndDate': currentEndDate,
      'newEndDate': newEndDate,
      'pauseInfo': pauseInfo.toJson(),
    };
  }

  /// Parse current end date to DateTime
  DateTime? get currentEndDateTime => _parseDate(currentEndDate);

  /// Parse new end date to DateTime
  DateTime? get newEndDateTime => _parseDate(newEndDate);

  DateTime? _parseDate(String date) {
    if (date.isEmpty) return null;
    try {
      return DateTime.parse(date);
    } catch (e) {
      return null;
    }
  }
}

class PauseInfo {
  final bool isPaused;
  final String label;
  final int pausedDays;

  PauseInfo({
    required this.isPaused,
    required this.label,
    required this.pausedDays,
  });

  factory PauseInfo.fromJson(Map<String, dynamic> json) {
    return PauseInfo(
      isPaused: json['isPaused'] ?? false,
      label: json['label'] ?? '',
      pausedDays: json['pausedDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'isPaused': isPaused, 'label': label, 'pausedDays': pausedDays};
  }
}
