/// Payment Status Model for Frusette Customer App
/// Represents the payment status data from API

class PaymentStatusResponse {
  final bool success;
  final PaymentStatusData data;

  PaymentStatusResponse({required this.success, required this.data});

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      success: json['success'] ?? false,
      data: PaymentStatusData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data.toJson()};
  }
}

class PaymentStatusData {
  final double amountPaid;
  final double balanceAmount;
  final bool hasSubscription;
  final bool paymentRequired;
  final String paymentStatus;
  final String planName;
  final String subscriptionId;
  final double totalAmount;

  PaymentStatusData({
    required this.amountPaid,
    required this.balanceAmount,
    required this.hasSubscription,
    required this.paymentRequired,
    required this.paymentStatus,
    required this.planName,
    required this.subscriptionId,
    required this.totalAmount,
  });

  factory PaymentStatusData.fromJson(Map<String, dynamic> json) {
    return PaymentStatusData(
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      balanceAmount: (json['balance_amount'] ?? 0).toDouble(),
      hasSubscription: json['has_subscription'] ?? false,
      paymentRequired: json['payment_required'] ?? false,
      paymentStatus: json['payment_status'] ?? '',
      planName: json['plan_name'] ?? '',
      subscriptionId: json['subscription_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount_paid': amountPaid,
      'balance_amount': balanceAmount,
      'has_subscription': hasSubscription,
      'payment_required': paymentRequired,
      'payment_status': paymentStatus,
      'plan_name': planName,
      'subscription_id': subscriptionId,
      'total_amount': totalAmount,
    };
  }

  /// Check if payment is overdue (status is pending and payment is required)
  bool get isOverdue =>
      paymentRequired && paymentStatus.toLowerCase() == 'pending';

  /// Get formatted balance amount
  String get formattedBalance => '₹${balanceAmount.toStringAsFixed(0)}';

  /// Get formatted total amount
  String get formattedTotal => '₹${totalAmount.toStringAsFixed(0)}';

  /// Get formatted amount paid
  String get formattedAmountPaid => '₹${amountPaid.toStringAsFixed(0)}';
}
