import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controller/auth_controller.dart';
import '../controller/payment_status_controller.dart';
import '../controller/notification_controller.dart';
import '../model/notification_model.dart';
import 'widgets/feedback_popup.dart';

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

    // Fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      _startAutoRefresh();
    });
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    final authController = context.read<AuthController>();
    final paymentStatusController = context.read<PaymentStatusController>();
    final notificationController = context.read<NotificationController>();

    if (authController.accessToken != null) {
      final token = authController.accessToken!;
      await Future.wait([
        paymentStatusController.fetchPaymentStatus(token),
        notificationController.fetchNotifications(token),
      ]);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _fetchData,
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
      actions: [
        Consumer<NotificationController>(
          builder: (context, controller, child) {
            if (controller.unreadCount > 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${controller.unreadCount} New',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildNotificationList() {
    final paymentStatusController = context.watch<PaymentStatusController>();
    final notificationController = context.watch<NotificationController>();
    
    final bool hasPaymentNotification = paymentStatusController.paymentRequired;
    final notifications = notificationController.notifications;

    if (!hasPaymentNotification && notifications.isEmpty && !notificationController.isLoading) {
      return _buildEmptyState();
    }

    if (notificationController.isLoading && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
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

        // Other Notifications Section
        if (notifications.isNotEmpty) ...[
          _buildSectionHeader(
            'UPDATES',
            icon: Icons.notifications_active_rounded,
            iconColor: primaryGreen,
            bgColor: lightGreen,
          ),
          const SizedBox(height: 12),
          ...notifications.map((n) => _buildNotificationCard(n)),
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
            decoration: const BoxDecoration(
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
          const Text(
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
                        style: const TextStyle(fontSize: 12, color: textSecondary),
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
                const Text(
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

  Widget _buildNotificationCard(NotificationItem notification) {
    final statusInfo = _getNotificationStatusInfo(notification);
    final bool isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.red.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? cardBorder : Colors.red.withOpacity(0.3),
          width: notification.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showNotificationDetail(notification),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Icon with Animated Color
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.red.withOpacity(0.1) : statusInfo.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusInfo.icon,
                      color: isUnread ? Colors.red : statusInfo.iconColor,
                      size: 24,
                    ),
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isUnread ? FontWeight.w800 : FontWeight.w400,
                                  color: isUnread ? textPrimary : textSecondary,
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getTimeAgo(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary.withOpacity(0.7),
                              ),
                            ),
                            // View Button - Only show for Unread
                            if (isUnread)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(NotificationItem notification) {
    final authController = context.read<AuthController>();
    final notificationController = context.read<NotificationController>();

    // Mark as read automatically
    if (!notification.isRead) {
      if (authController.accessToken != null) {
        notificationController.markAsRead(
          authController.accessToken!,
          notification.id,
        );
      }
    }

    // Special handling for feedback request 
    if (notification.notificationType == 'delivery_feedback_request' &&
        notification.metadata?.deliveryId != null &&
        notification.metadata?.feedbackSubmitted == false &&
        // Double check persistent cache
        !notificationController.isFeedbackSubmitted(notification.metadata?.deliveryId ?? '') &&
        // Only show for recent deliveries (similar to dashboard)
        DateTime.now().difference(notification.createdAt).inHours < 24) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => FeedbackPopup(
          deliveryId: notification.metadata!.deliveryId!,
          mealName: notification.metadata!.mealName ?? 'meal',
          accessToken: authController.accessToken!,
          onDismissed: () => Navigator.pop(context),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Received on: ${DateFormat('MMM dd, yyyy - hh:mm a').format(notification.createdAt)}',
              style: const TextStyle(fontSize: 12, color: textSecondary),
            ),
            if (notification.metadata?.mealName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Meal: ${notification.metadata!.mealName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  NotificationStatusInfo _getNotificationStatusInfo(NotificationItem notification) {
    switch (notification.notificationType) {
      case 'order_update':
      case 'delivery_update':
        return NotificationStatusInfo(
          icon: Icons.delivery_dining_rounded,
          iconColor: blue,
          bgColor: lightBlue,
          label: 'DELIVERY',
        );
      case 'delivery_feedback_request':
        return NotificationStatusInfo(
          icon: Icons.rate_review_rounded,
          iconColor: Colors.orange,
          bgColor: Colors.orange.withOpacity(0.12),
          label: 'FEEDBACK',
        );
      case 'payment':
        return NotificationStatusInfo(
          icon: Icons.payment_rounded,
          iconColor: red,
          bgColor: lightRed,
          label: 'PAYMENT',
        );
      default:
        return NotificationStatusInfo(
          icon: Icons.notifications_rounded,
          iconColor: primaryGreen,
          bgColor: lightGreen,
          label: 'NOTIFICATION',
        );
    }
  }
}

// Visual info helper
class NotificationStatusInfo {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;

  NotificationStatusInfo({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
  });
}
