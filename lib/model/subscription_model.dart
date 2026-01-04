/// Subscription Management API Response Model
/// Contains all subscription data returned from the API
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

/// Main data container for subscription management
class SubscriptionManageData {
  final SubscriptionUser? user;
  final SubscriptionPlan? plan;
  final SubscriptionDetails subscription;
  final SubscriptionProjection subscriptionProjection;
  final CutOffInfo? cutOffInfo;

  SubscriptionManageData({
    this.user,
    this.plan,
    required this.subscription,
    required this.subscriptionProjection,
    this.cutOffInfo,
  });

  factory SubscriptionManageData.fromJson(Map<String, dynamic> json) {
    return SubscriptionManageData(
      user: json['user'] != null
          ? SubscriptionUser.fromJson(json['user'])
          : null,
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'])
          : null,
      subscription: SubscriptionDetails.fromJson(json['subscription'] ?? {}),
      subscriptionProjection: SubscriptionProjection.fromJson(
        json['subscriptionProjection'] ?? {},
      ),
      cutOffInfo: json['cutOffInfo'] != null
          ? CutOffInfo.fromJson(json['cutOffInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'plan': plan?.toJson(),
      'subscription': subscription.toJson(),
      'subscriptionProjection': subscriptionProjection.toJson(),
      'cutOffInfo': cutOffInfo?.toJson(),
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
      fullName: json['fullName'] ?? '',
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
      planType: json['planType'] ?? 'weekly',
      durationDays: json['durationDays'] ?? 0,
      mealsPerDay: json['mealsPerDay'] ?? 0,
      mealTypes:
          (json['mealTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      price: (json['price'] ?? 0).toDouble(),
      weeklyMenu: json['weeklyMenu'] as Map<String, dynamic>?,
      monthlyMenu: json['monthlyMenu'] as Map<String, dynamic>?,
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
      paymentStatus: json['paymentStatus'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      actions: SubscriptionActions.fromJson(json['actions'] ?? {}),
      dates: SubscriptionDates.fromJson(json['dates'] ?? {}),
      mealInfo: MealInfo.fromJson(json['mealInfo'] ?? {}),
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
      pausePlan: json['pausePlan'] ?? false,
      resumePlan: json['resumePlan'] ?? false,
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
  final int pausedMealsCount;

  PauseInfo({
    required this.isPaused,
    required this.label,
    required this.pausedDays,
    required this.pausedMealsCount,
  });

  factory PauseInfo.fromJson(Map<String, dynamic> json) {
    return PauseInfo(
      isPaused: json['isPaused'] ?? false,
      label: json['label'] ?? '',
      pausedDays: json['pausedDays'] ?? 0,
      pausedMealsCount: json['pausedMealsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPaused': isPaused,
      'label': label,
      'pausedDays': pausedDays,
      'pausedMealsCount': pausedMealsCount,
    };
  }

  /// Check if there are any paused days or meals
  bool get hasPausedData => pausedDays > 0 || pausedMealsCount > 0;
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
