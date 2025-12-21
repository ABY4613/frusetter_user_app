import 'package:flutter/material.dart';

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
  static const Color cardBorder = Color.fromARGB(255, 15, 26, 47);
  static const Color dividerColor = Color(0xFFF3F4F6);

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _selectedTabIndex = 0;

  // Dummy notification data
  final List<NotificationItem> _allNotifications = [
    NotificationItem(
      id: '1',
      type: NotificationType.paymentOverdue,
      title: 'Payment Overdue',
      message: 'Your subscription for the Weekly Plan is on hold.',
      amount: 55.00,
      time: 'Just now',
      isUrgent: true,
      category: 'payment',
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.delivery,
      title: 'Driver is nearby',
      message: 'Your meal box is about 10 minutes away. Prepare for arrival!',
      time: '10m ago',
      category: 'update',
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.system,
      title: 'System Update',
      message: 'We\'ve updated our privacy policy. Tap to read more.',
      time: '2h ago',
      category: 'update',
    ),
    NotificationItem(
      id: '4',
      type: NotificationType.paymentSuccess,
      title: 'Payment Successful',
      message: 'We received your payment of \$55.00 for the Monthly Plan.',
      time: '1d ago',
      category: 'payment',
    ),
    NotificationItem(
      id: '5',
      type: NotificationType.newMenu,
      title: 'New Menu Items!',
      message:
          'Check out the new vegan lasagna added for next week\'s rotation.',
      time: '1d ago',
      hasImage: true,
      category: 'update',
    ),
    NotificationItem(
      id: '6',
      type: NotificationType.addressUpdate,
      title: 'Address Updated',
      message: 'Your default delivery location was successfully changed.',
      time: '5d ago',
      category: 'update',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<NotificationItem> get _filteredNotifications {
    switch (_selectedTabIndex) {
      case 1: // Payments
        return _allNotifications.where((n) => n.category == 'payment').toList();
      case 2: // Updates
        return _allNotifications.where((n) => n.category == 'update').toList();
      default: // All
        return _allNotifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(child: _buildNotificationList()),
          ],
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
        icon: const Icon(Icons.arrow_back, color: textPrimary, size: 24),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            _showSettingsBottomSheet();
          },
          icon: const Icon(
            Icons.settings_outlined,
            color: textPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: dividerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Payments'),
          Tab(text: 'Updates'),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    final notifications = _filteredNotifications;

    // Group notifications by date
    final todayNotifications = notifications
        .where(
          (n) =>
              n.time.contains('m ago') ||
              n.time.contains('h ago') ||
              n.time == 'Just now',
        )
        .toList();
    final yesterdayNotifications = notifications
        .where((n) => n.time.contains('1d ago'))
        .toList();
    final lastWeekNotifications = notifications
        .where((n) => n.time.contains('d ago') && !n.time.contains('1d ago'))
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Payment overdue card (if exists)
        ...notifications
            .where((n) => n.isUrgent)
            .map((n) => _buildPaymentOverdueCard(n)),

        // Today section
        if (todayNotifications.where((n) => !n.isUrgent).isNotEmpty) ...[
          _buildSectionHeader('TODAY'),
          ...todayNotifications
              .where((n) => !n.isUrgent)
              .map((n) => _buildNotificationCard(n)),
        ],

        // Yesterday section
        if (yesterdayNotifications.isNotEmpty) ...[
          _buildSectionHeader('YESTERDAY'),
          ...yesterdayNotifications.map((n) => _buildNotificationCard(n)),
        ],

        // Last week section
        if (lastWeekNotifications.isNotEmpty) ...[
          _buildSectionHeader('LAST WEEK'),
          ...lastWeekNotifications.map((n) => _buildNotificationCard(n)),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaymentOverdueCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightRed, width: 1),
        boxShadow: [
          BoxShadow(
            color: red.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red warning icon
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Dismiss button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _allNotifications.removeWhere(
                      (n) => n.id == notification.id,
                    );
                  });
                },
                child: Icon(Icons.close, color: textSecondary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Due amount
          Text(
            '\$${notification.amount?.toStringAsFixed(2)} due immediately',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: red,
            ),
          ),
          const SizedBox(height: 16),
          // Pay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showPaymentDialog(notification.amount ?? 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Pay \$${notification.amount?.toStringAsFixed(2)} Now',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          _buildNotificationIcon(notification.type),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      notification.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
              ],
            ),
          ),
          // Image thumbnail if exists
          if (notification.hasImage) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: primaryGreen,
                  size: 24,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (type) {
      case NotificationType.paymentOverdue:
        icon = Icons.error_outline_rounded;
        bgColor = lightRed;
        iconColor = red;
        break;
      case NotificationType.paymentSuccess:
        icon = Icons.check_circle_outline_rounded;
        bgColor = lightGreen;
        iconColor = primaryGreen;
        break;
      case NotificationType.delivery:
        icon = Icons.local_shipping_outlined;
        bgColor = lightGreen;
        iconColor = primaryGreen;
        break;
      case NotificationType.system:
        icon = Icons.info_outline_rounded;
        bgColor = const Color(0xFFE0E7FF);
        iconColor = const Color(0xFF6366F1);
        break;
      case NotificationType.newMenu:
        icon = Icons.restaurant_menu_outlined;
        bgColor = const Color(0xFFFCE7F3);
        iconColor = const Color(0xFFEC4899);
        break;
      case NotificationType.addressUpdate:
        icon = Icons.location_on_outlined;
        bgColor = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0EA5E9);
        break;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  void _showPaymentDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Payment',
          style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        ),
        content: Text(
          'Pay \$${amount.toStringAsFixed(2)} to reactivate your subscription?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPaymentSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Payment successful! Subscription reactivated.'),
          ],
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Remove the overdue notification
    setState(() {
      _allNotifications.removeWhere((n) => n.isUrgent);
    });
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingOption(
              icon: Icons.notifications_active_outlined,
              title: 'Push Notifications',
              value: true,
            ),
            _buildSettingOption(
              icon: Icons.mail_outline_rounded,
              title: 'Email Notifications',
              value: true,
            ),
            _buildSettingOption(
              icon: Icons.payment_outlined,
              title: 'Payment Reminders',
              value: true,
            ),
            _buildSettingOption(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery Updates',
              value: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _allNotifications.clear();
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Clear All Notifications',
                  style: TextStyle(color: red, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          Switch(value: value, onChanged: (val) {}, activeColor: primaryGreen),
        ],
      ),
    );
  }
}

// Notification data models
enum NotificationType {
  paymentOverdue,
  paymentSuccess,
  delivery,
  system,
  newMenu,
  addressUpdate,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String time;
  final double? amount;
  final bool isUrgent;
  final bool hasImage;
  final String category;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.amount,
    this.isUrgent = false,
    this.hasImage = false,
    required this.category,
  });
}
