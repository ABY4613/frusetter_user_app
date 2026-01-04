import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import '../controller/payment_status_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  // App colors - matching subscription dashboard
  static const Color primaryGreen = Color(0xFF8AC53D);
  static const Color lightGreen = Color(0xFFE8F5D9);
  static const Color red = Color(0xFFEF4444);
  static const Color lightRed = Color(0xFFFEE2E2);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFDBEAFE);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Auto-refresh timer
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30);

  // Delivery Status notifications (dummy data - will be from API later)
  final List<DeliveryNotification> _deliveryNotifications = [
    DeliveryNotification(
      id: '1',
      title: 'Order Picked Up',
      message: 'Your lunch order has been picked up by the delivery partner.',
      time: '5m ago',
      status: DeliveryStatus.pickedUp,
    ),
    DeliveryNotification(
      id: '2',
      title: 'Driver is Nearby',
      message:
          'Your food is about 10 minutes away. Please be ready to receive.',
      time: '10m ago',
      status: DeliveryStatus.nearby,
    ),
    DeliveryNotification(
      id: '3',
      title: 'Out for Delivery',
      message: 'Your dinner is on the way! Estimated arrival in 25 minutes.',
      time: '1h ago',
      status: DeliveryStatus.outForDelivery,
    ),
    DeliveryNotification(
      id: '4',
      title: 'Food Delivered',
      message: 'Your lunch has been delivered successfully. Enjoy your meal!',
      time: '3h ago',
      status: DeliveryStatus.delivered,
    ),
    DeliveryNotification(
      id: '5',
      title: 'Preparing Your Order',
      message: 'Your breakfast is being prepared in the kitchen.',
      time: '1d ago',
      status: DeliveryStatus.preparing,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Fetch payment status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPaymentStatus();
      _startAutoRefresh();
    });
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _fetchPaymentStatus();
      }
    });
  }

  Future<void> _fetchPaymentStatus() async {
    final authController = context.read<AuthController>();
    final paymentStatusController = context.read<PaymentStatusController>();

    if (authController.accessToken != null) {
      await paymentStatusController.fetchPaymentStatus(
        authController.accessToken!,
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _fetchPaymentStatus,
          color: primaryGreen,
          backgroundColor: Colors.white,
          child: _buildNotificationList(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: dividerColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 18,
          ),
        ),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildNotificationList() {
    final paymentStatusController = context.watch<PaymentStatusController>();
    final bool hasPaymentNotification = paymentStatusController.paymentRequired;
    final bool hasDeliveryNotifications = _deliveryNotifications.isNotEmpty;

    if (!hasPaymentNotification && !hasDeliveryNotifications) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        const SizedBox(height: 8),

        // Payment Overdue Section (from API)
        if (hasPaymentNotification) ...[
          _buildSectionHeader(
            'PAYMENT DUE',
            icon: Icons.warning_amber_rounded,
            iconColor: red,
            bgColor: lightRed,
          ),
          const SizedBox(height: 12),
          _buildPaymentOverdueCard(paymentStatusController),
          const SizedBox(height: 16),
        ],

        // Delivery Status Section
        if (hasDeliveryNotifications) ...[
          _buildSectionHeader(
            'DELIVERY UPDATES',
            icon: Icons.delivery_dining_rounded,
            iconColor: primaryGreen,
            bgColor: lightGreen,
          ),
          const SizedBox(height: 12),
          ..._deliveryNotifications.map((n) => _buildDeliveryStatusCard(n)),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: primaryGreen,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! Check back later.',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: iconColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOverdueCard(PaymentStatusController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: red.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: red.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightRed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Payment Overdue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              controller.paymentStatusText.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.planName,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your subscription payment is pending. Please pay now to continue enjoying uninterrupted service.',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Row
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount Due',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        controller.paymentStatus?.formattedBalance ?? '₹0',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatusCard(DeliveryNotification notification) {
    final statusInfo = _getDeliveryStatusInfo(notification.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusInfo.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusInfo.icon, color: statusInfo.iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo.bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusInfo.iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DeliveryStatusInfo _getDeliveryStatusInfo(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.preparing:
        return DeliveryStatusInfo(
          icon: Icons.restaurant_rounded,
          iconColor: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFEF3C7),
          label: 'PREPARING',
        );
      case DeliveryStatus.pickedUp:
        return DeliveryStatusInfo(
          icon: Icons.inventory_2_rounded,
          iconColor: blue,
          bgColor: lightBlue,
          label: 'PICKED UP',
        );
      case DeliveryStatus.outForDelivery:
        return DeliveryStatusInfo(
          icon: Icons.delivery_dining_rounded,
          iconColor: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFEDE9FE),
          label: 'ON THE WAY',
        );
      case DeliveryStatus.nearby:
        return DeliveryStatusInfo(
          icon: Icons.near_me_rounded,
          iconColor: primaryGreen,
          bgColor: lightGreen,
          label: 'NEARBY',
        );
      case DeliveryStatus.delivered:
        return DeliveryStatusInfo(
          icon: Icons.check_circle_rounded,
          iconColor: primaryGreen,
          bgColor: lightGreen,
          label: 'DELIVERED',
        );
    }
  }
}

// Delivery status types
enum DeliveryStatus { preparing, pickedUp, outForDelivery, nearby, delivered }

// Delivery status visual info
class DeliveryStatusInfo {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;

  DeliveryStatusInfo({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
  });
}

// Delivery notification model
class DeliveryNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final DeliveryStatus status;

  DeliveryNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.status,
  });
}
