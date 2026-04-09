/// Subscription Management API Response Model
/// Contains all subscription data returned from the API
class SubscriptionManageResponse {
  final bool success;
  final SubscriptionManageData data;

  SubscriptionManageResponse({required this.success, required this.data});

  factory SubscriptionManageResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionManageResponse(
      success: json['success'] ?? json['Success'] ?? false,
      data: SubscriptionManageData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data.toJson()};
  }
}

/// Main data container for subscription management
class SubscriptionManageData {
  final SubscriptionUser? user;
  final SubscriptionPlan? plan;
  final SubscriptionDetails subscription;
  final SubscriptionProjection subscriptionProjection;
  final CutOffInfo? cutOffInfo;
  final List<TodayMeal> todayMeals;
  final FeedbackPopupInfo? feedbackPopup;
  final String? subscriptionId;
  final String? screen;

  SubscriptionManageData({
    this.user,
    this.plan,
    required this.subscription,
    required this.subscriptionProjection,
    this.cutOffInfo,
    this.todayMeals = const [],
    this.feedbackPopup,
    this.subscriptionId,
    this.screen,
  });

  factory SubscriptionManageData.fromJson(Map<String, dynamic> json) {
    return SubscriptionManageData(
      subscriptionId: json['subscription_id']?.toString() ?? json['subscriptionId']?.toString(),
      user: json['user'] != null
          ? SubscriptionUser.fromJson(json['user'])
          : null,
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'])
          : null,
      subscription: SubscriptionDetails.fromJson(json['subscription'] ?? {}),
      subscriptionProjection: SubscriptionProjection.fromJson(
        json['subscription_projection'] ?? json['subscriptionProjection'] ?? {},
      ),
      cutOffInfo: (json['cut_off_info'] ?? json['cutOffInfo']) != null
          ? CutOffInfo.fromJson(json['cut_off_info'] ?? json['cutOffInfo'])
          : null,
      todayMeals: (json['today_meals'] as List<dynamic>? ??
                  json['todayMeals'] as List<dynamic>?)
              ?.map((e) => TodayMeal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <TodayMeal>[],
      feedbackPopup: (json['feedback_popup'] ?? json['feedbackPopup']) != null
          ? FeedbackPopupInfo.fromJson(
              json['feedback_popup'] ?? json['feedbackPopup'],
            )
          : null,
      screen: json['screen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'plan': plan?.toJson(),
      'subscription': subscription.toJson(),
      'subscriptionProjection': subscriptionProjection.toJson(),
      'cutOffInfo': cutOffInfo?.toJson(),
      'todayMeals': todayMeals.map((e) => e.toJson()).toList(),
      'feedbackPopup': feedbackPopup?.toJson(),
      'subscription_id': subscriptionId,
      'screen': screen,
    };
  }
}

/// User details from the API
class SubscriptionUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;

  SubscriptionUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory SubscriptionUser.fromJson(Map<String, dynamic> json) {
    return SubscriptionUser(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'fullName': fullName, 'email': email, 'phone': phone};
  }

  /// Check if user has valid data
  bool get hasData => id.isNotEmpty && fullName.isNotEmpty;

  /// Get first name
  String get firstName => fullName.split(' ').first;
}

/// Plan details from the API
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final String planType; // "weekly" or "monthly"
  final int durationDays;
  final int mealsPerDay;
  final List<String> mealTypes;
  final double price;
  final Map<String, dynamic>? weeklyMenu;
  final Map<String, dynamic>? monthlyMenu;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.planType,
    required this.durationDays,
    required this.mealsPerDay,
    required this.mealTypes,
    required this.price,
    this.weeklyMenu,
    this.monthlyMenu,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      planType: json['planType'] ?? json['plan_type'] ?? 'weekly',
      durationDays: json['durationDays'] ?? json['duration_days'] ?? 0,
      mealsPerDay: json['mealsPerDay'] ?? json['meals_per_day'] ?? 0,
      mealTypes: (json['meal_types'] as List<dynamic>? ??
                  json['mealTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      price: (json['price'] ?? 0) is String
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : (json['price'] ?? 0).toDouble(),
      weeklyMenu:
          (json['weeklyMenu'] ?? json['weekly_menu']) as Map<String, dynamic>?,
      monthlyMenu:
          (json['monthlyMenu'] ?? json['monthly_menu'])
              as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'planType': planType,
      'durationDays': durationDays,
      'mealsPerDay': mealsPerDay,
      'mealTypes': mealTypes,
      'price': price,
      'weeklyMenu': weeklyMenu,
      'monthlyMenu': monthlyMenu,
    };
  }

  /// Check if plan has valid data
  bool get hasData => id.isNotEmpty && name.isNotEmpty;

  /// Check if plan is weekly
  bool get isWeekly => planType.toLowerCase() == 'weekly';

  /// Check if plan is monthly
  bool get isMonthly => planType.toLowerCase() == 'monthly';

  /// Get formatted price
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  /// Get meal types as comma separated string
  String get mealTypesDisplay =>
      mealTypes.map((e) => _capitalize(e)).join(', ');

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}' : s;
}

/// Subscription details from the API
class SubscriptionDetails {
  final String id;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final double amountPaid;
  final SubscriptionActions actions;
  final SubscriptionDates dates;
  final MealInfo mealInfo;

  SubscriptionDetails({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.amountPaid,
    required this.actions,
    required this.dates,
    required this.mealInfo,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? '',
      totalAmount:
          (json['total_amount'] ?? json['totalAmount'] ?? 0).toDouble(),
      amountPaid: (json['amount_paid'] ?? json['amountPaid'] ?? 0).toDouble(),
      actions: SubscriptionActions.fromJson(json['actions'] ?? {}),
      dates: SubscriptionDates.fromJson(json['dates'] ?? {}),
      mealInfo: MealInfo.fromJson(json['meal_info'] ?? json['mealInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'paymentStatus': paymentStatus,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'actions': actions.toJson(),
      'dates': dates.toJson(),
      'mealInfo': mealInfo.toJson(),
    };
  }

  /// Check if subscription has valid data
  bool get hasData => id.isNotEmpty;

  /// Check if subscription is active
  bool get isActive => status.toUpperCase() == 'ACTIVE';

  /// Check if subscription is paused
  bool get isPaused => status.toUpperCase() == 'PAUSED';

  /// Get balance amount
  double get balanceAmount => totalAmount - amountPaid;

  /// Check if payment is pending
  bool get isPaymentPending => paymentStatus.toLowerCase() == 'pending';

  /// Check if payment is completed
  bool get isPaymentCompleted =>
      paymentStatus.toLowerCase() == 'completed' ||
      paymentStatus.toLowerCase() == 'paid';

  /// Get formatted total amount
  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(0)}';

  /// Get formatted amount paid
  String get formattedAmountPaid => '₹${amountPaid.toStringAsFixed(0)}';

  /// Get formatted balance amount
  String get formattedBalanceAmount => '₹${balanceAmount.toStringAsFixed(0)}';
}

/// Subscription action permissions
class SubscriptionActions {
  final bool pausePlan;
  final bool resumePlan;

  SubscriptionActions({required this.pausePlan, required this.resumePlan});

  factory SubscriptionActions.fromJson(Map<String, dynamic> json) {
    return SubscriptionActions(
      pausePlan: json['pause_plan'] ?? json['pausePlan'] ?? false,
      resumePlan: json['resume_plan'] ?? json['resumePlan'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'pausePlan': pausePlan, 'resumePlan': resumePlan};
  }
}

/// Subscription dates
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
      startDate: json['start_date'] ?? json['startDate'] ?? '',
      originalEndDate:
          json['original_end_date'] ?? json['originalEndDate'] ?? '',
      adjustedEndDate:
          json['adjusted_end_date'] ?? json['adjustedEndDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'originalEndDate': originalEndDate,
      'adjustedEndDate': adjustedEndDate,
    };
  }

  /// Check if dates have valid data
  bool get hasData => startDate.isNotEmpty;

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

  /// Get formatted start date
  String get formattedStartDate => _formatDate(startDateTime);

  /// Get formatted original end date
  String get formattedOriginalEndDate => _formatDate(originalEndDateTime);

  /// Get formatted adjusted end date
  String get formattedAdjustedEndDate => _formatDate(adjustedEndDateTime);

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Meal information
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
      mealsPerDay: json['meals_per_day'] ?? json['mealsPerDay'] ?? 0,
      totalMeals: json['total_meals'] ?? json['totalMeals'] ?? 0,
      daysRemaining: json['days_remaining'] ?? json['daysRemaining'] ?? 0,
      upcomingMeals: json['upcoming_meals'] ?? json['upcomingMeals'] ?? 0,
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

  /// Check if meal info has valid data
  bool get hasData => totalMeals > 0 || mealsPerDay > 0;
}

/// Subscription projection with pause info
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
      currentEndDate:
          json['current_end_date'] ?? json['currentEndDate'] ?? '',
      newEndDate: json['new_end_date'] ?? json['newEndDate'] ?? '',
      pauseInfo: PauseInfo.fromJson(json['pause_info'] ?? json['pauseInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentEndDate': currentEndDate,
      'newEndDate': newEndDate,
      'pauseInfo': pauseInfo.toJson(),
    };
  }

  /// Check if projection has valid data
  bool get hasData => currentEndDate.isNotEmpty || newEndDate.isNotEmpty;

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

  /// Get formatted current end date
  String get formattedCurrentEndDate => _formatDate(currentEndDateTime);

  /// Get formatted new end date
  String get formattedNewEndDate => _formatDate(newEndDateTime);

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Pause information
class PauseInfo {
  final bool isPaused;
  final String label;
  final int pausedDays;
  final List<PausedMeal> pausedMeals;
  final int pausedMealsCount;

  PauseInfo({
    required this.isPaused,
    required this.label,
    required this.pausedDays,
    required this.pausedMeals,
    required this.pausedMealsCount,
  });

  factory PauseInfo.fromJson(Map<String, dynamic> json) {
    return PauseInfo(
      isPaused: json['is_paused'] ?? json['isPaused'] ?? false,
      label: json['label'] ?? '',
      pausedDays: json['paused_days'] ?? json['pausedDays'] ?? 0,
      pausedMeals: (json['paused_meals'] as List<dynamic>? ??
                  json['pausedMeals'] as List<dynamic>?)
              ?.map((e) => PausedMeal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <PausedMeal>[],
      pausedMealsCount:
          json['paused_meals_count'] ?? json['pausedMealsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPaused': isPaused,
      'label': label,
      'pausedDays': pausedDays,
      'pausedMeals': pausedMeals.map((e) => e.toJson()).toList(),
      'pausedMealsCount': pausedMealsCount,
    };
  }

  /// Check if there are any paused days or meals
  bool get hasPausedData => pausedDays > 0 || pausedMealsCount > 0;
}

/// Details of a paused meal
class PausedMeal {
  final String id;
  final String deliveryDate;
  final String mealName;
  final String mealType;

  PausedMeal({
    required this.id,
    required this.deliveryDate,
    required this.mealName,
    required this.mealType,
  });

  factory PausedMeal.fromJson(Map<String, dynamic> json) {
    return PausedMeal(
      id: json['id'] ?? '',
      deliveryDate: json['delivery_date'] ?? '',
      mealName: json['meal_name'] ?? '',
      mealType: json['meal_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_date': deliveryDate,
      'meal_name': mealName,
      'meal_type': mealType,
    };
  }

  /// Format delivery date
  String get formattedDate {
    if (deliveryDate.isEmpty) return '';
    try {
      final date = DateTime.parse(deliveryDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return deliveryDate;
    }
  }
}

/// Cut-off information for subscription modifications
class CutOffInfo {
  final String type; // "warning", "info", etc.
  final String title;
  final String time;
  final String message;

  CutOffInfo({
    required this.type,
    required this.title,
    required this.time,
    required this.message,
  });

  factory CutOffInfo.fromJson(Map<String, dynamic> json) {
    return CutOffInfo(
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'title': title, 'time': time, 'message': message};
  }

  /// Check if cutoff info has valid data
  bool get hasData => title.isNotEmpty || message.isNotEmpty;

  /// Check if this is a warning type
  bool get isWarning => type.toLowerCase() == 'warning';

  /// Check if this is an info type
  bool get isInfo => type.toLowerCase() == 'info';
}

/// Model for today's meals status
class TodayMeal {
  final String mealType;
  final String status;
  final String? mealName;
  final String? deliverySlot;
  final String? id;
  final bool canUnpause;
  final bool canPause;

  TodayMeal({
    required this.mealType,
    required this.status,
    this.mealName,
    this.deliverySlot,
    this.id,
    this.canUnpause = false,
    this.canPause = false,
  });

  factory TodayMeal.fromJson(Map<String, dynamic> json) {
    return TodayMeal(
      mealType: json['meal_type'] ?? json['mealType'] ?? '',
      status: json['status'] ?? '',
      mealName: json['meal_name'] ?? json['mealName'],
      deliverySlot: json['delivery_slot'] ?? json['deliverySlot'],
      id: json['id'],
      canUnpause: json['can_unpause'] ?? json['canUnpause'] ?? false,
      canPause: json['can_pause'] ?? json['canPause'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'status': status,
      'mealName': mealName,
      'deliverySlot': deliverySlot,
      'id': id,
      'canUnpause': canUnpause,
      'canPause': canPause,
    };
  }
}

/// Model for feedback popup info
class FeedbackPopupInfo {
  final bool show;
  final dynamic meal;

  FeedbackPopupInfo({required this.show, this.meal});

  factory FeedbackPopupInfo.fromJson(Map<String, dynamic> json) {
    return FeedbackPopupInfo(
      show: json['show'] ?? false,
      meal: json['meal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'show': show, 'meal': meal};
  }
}
