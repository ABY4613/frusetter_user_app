import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import '../controller/subscription_controller.dart';
import '../controller/payment_status_controller.dart';
import '../model/subscription_model.dart';
import 'login_screen.dart';
import 'delivery_adress_management.dart';
import 'live_order_track.dart';
import 'meals_feedback.dart';
import 'notification_screen.dart';
import 'help_desk_screen.dart';
import 'addons_list_screen.dart';

class SubscriptionDashboard extends StatefulWidget {
  final bool showAppBar;

  const SubscriptionDashboard({super.key, this.showAppBar = true});

  @override
  State<SubscriptionDashboard> createState() => _SubscriptionDashboardState();
}

class _SubscriptionDashboardState extends State<SubscriptionDashboard>
    with SingleTickerProviderStateMixin {
  // App colors
  static const Color primaryGreen = Color(0xFF8AC53D);
  static const Color lightGreen = Color(0xFFE8F5D9);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color warningYellow = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFD97706);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Auto-refresh timer
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 300);

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

    // Fetch subscription data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubscriptionData();
      _startAutoRefresh();
    });
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _fetchSubscriptionData();
      }
    });
  }

  /// Fetch subscription data from API
  Future<void> _fetchSubscriptionData() async {
    final authController = context.read<AuthController>();
    final subscriptionController = context.read<SubscriptionController>();
    final paymentStatusController = context.read<PaymentStatusController>();

    if (authController.accessToken != null) {
      // Fetch subscription data
      // Fetch subscription data
      await subscriptionController.fetchSubscriptionData(
        authController.accessToken!,
      );

      // Fetch payment status
      await paymentStatusController.fetchPaymentStatus(
        authController.accessToken!,
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _carouselTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionController = context.watch<SubscriptionController>();
    final paymentStatusController = context.watch<PaymentStatusController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: widget.showAppBar ? _buildAppBar() : null,
      drawer: widget.showAppBar ? _buildDrawer() : null,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchSubscriptionData,
                color: primaryGreen,
                backgroundColor: Colors.white,
                child:
                    subscriptionController.isLoading &&
                        !subscriptionController.hasData
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              if (subscriptionController.user != null)
                                _buildUserGreeting(subscriptionController),

                              const SizedBox(height: 16),

                              // Add-ons Banner
                              _buildAddOnsBanner(),

                              const SizedBox(height: 16),

                              // Payment Reminder Banner
                              if (paymentStatusController.paymentRequired)
                                _buildPaymentReminderBanner(
                                  paymentStatusController,
                                ),

                              // Main Subscription Card
                              _buildMainSubscriptionCard(
                                subscriptionController,
                              ),

                              const SizedBox(height: 16),

                              // Meal Stats Row
                              _buildMealStatsRow(subscriptionController),

                              const SizedBox(height: 16),

                              // Dates Card
                              _buildDatesCard(subscriptionController),

                              const SizedBox(height: 16),

                              // Subscription Projection
                              _buildSubscriptionProjectionCard(
                                subscriptionController,
                              ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build user greeting section
  Widget _buildUserGreeting(SubscriptionController controller) {
    final user = controller.user;
    if (user == null || !user.hasData) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.firstName}!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                if (user.email.isNotEmpty)
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
          if (user.phone.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    user.phone.length > 10
                        ? '...${user.phone.substring(user.phone.length - 10)}'
                        : user.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build add-ons promotional carousel
  Widget _buildAddOnsBanner() {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        onPageChanged: (index) {
          setState(() {
            _currentCarouselPage = index % 3;
          });
        },
        itemBuilder: (context, index) {
          final carouselIndex = index % 3;
          return _buildCarouselItem(carouselIndex);
        },
      ),
    );
  }

  int _currentCarouselPage = 0;
  Timer? _carouselTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start auto-scroll carousel
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentCarouselPage = (_currentCarouselPage + 1) % 3;
        });
      }
    });
  }

  Widget _buildCarouselItem(int index) {
    final carouselData = [
      {
        'title': 'Protein Power',
        'subtitle': 'Boost your energy with smoothies',
        'image':
            'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=800&q=80',
      },
      {
        'title': 'Healthy Snacks',
        'subtitle': 'Nutritious bites for any time',
        'image':
            'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=800&q=80',
      },
      {
        'title': 'Fresh Juices',
        'subtitle': 'Natural refreshment daily',
        'image':
            'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=800&q=80',
      },
    ];

    final data = carouselData[index];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddOnsListScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  data['image'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: const Color(0xFF8AC53D));
                  },
                ),
              ),
              // Decorative circles
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      data['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    Text(
                      data['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Shop Now Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Shop Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Page Indicator
              Positioned(
                bottom: 16,
                right: 24,
                child: Row(
                  children: List.generate(
                    3,
                    (dotIndex) => Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: dotIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build payment reminder banner
  Widget _buildPaymentReminderBanner(PaymentStatusController controller) {
    const Color red = Color(0xFFEF4444);
    const Color lightRed = Color(0xFFFEE2E2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightRed,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: red.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: red.withOpacity(0.1),
            blurRadius: 10,
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 22,
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
                            'Payment Required',
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
                    const SizedBox(height: 6),
                    Text(
                      'Your subscription payment for ${controller.planName} is pending. Please pay to continue service.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Amount Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white),
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
    );
  }

  /// Build main subscription card with plan details
  Widget _buildMainSubscriptionCard(SubscriptionController controller) {
    final plan = controller.plan;
    final subscription = controller.subscription;

    if (subscription == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: const Center(
          child: Text(
            'No subscription data available',
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    final bool isActive = subscription.isActive;
    final bool isPaused = subscription.isPaused;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Plan info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Subscription status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? primaryGreen
                                : isPaused
                                ? warningText
                                : textSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subscription.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Plan type badge (if plan exists)
                        if (plan != null && plan.planType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plan.planType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        // Payment status badge
                        if (subscription.paymentStatus.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: subscription.isPaymentPending
                                  ? const Color(0xFFFEE2E2)
                                  : lightGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subscription.paymentStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: subscription.isPaymentPending
                                    ? const Color(0xFFEF4444)
                                    : primaryGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Plan name
                    Text(
                      plan?.name ?? 'Premium Plan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    // Plan description (if exists)
                    if (plan != null && plan.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Plan details row
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (plan != null && plan.mealsPerDay > 0)
                          _buildDetailChip(
                            Icons.restaurant_menu,
                            '${plan.mealsPerDay} Meals/Day',
                          ),
                        if (plan != null && plan.durationDays > 0)
                          _buildDetailChip(
                            Icons.calendar_today,
                            '${plan.durationDays} Days',
                          ),
                        if (subscription.mealInfo.daysRemaining > 0)
                          _buildDetailChip(
                            Icons.timer,
                            '${subscription.mealInfo.daysRemaining} Left',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price tag
              if (plan != null && plan.price > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        plan.formattedPrice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: primaryGreen,
                        ),
                      ),
                      Text(
                        '/${plan.planType}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Meal types (if exists)
          if (plan != null && plan.mealTypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lunch_dining,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Includes: ${plan.mealTypesDisplay}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Action buttons
          _buildActionButtons(subscription),
        ],
      ),
    );
  }

  /// Build detail chip widget
  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build action buttons for subscription
  Widget _buildActionButtons(SubscriptionDetails subscription) {
    final bool canPause =
        subscription.actions.pausePlan || subscription.isActive;
    final bool canResume =
        subscription.actions.resumePlan || subscription.isPaused;

    return Row(
      children: [
        Expanded(
          child: canPause && subscription.isActive
              ? OutlinedButton.icon(
                  onPressed: _showPausePlanDialog,
                  icon: const Icon(Icons.pause_circle_outline, size: 18),
                  label: const Text('Pause Plan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: const BorderSide(color: cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('No Actions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: const BorderSide(color: cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// Build meal stats row
  Widget _buildMealStatsRow(SubscriptionController controller) {
    final subscription = controller.subscription;
    final projection = controller.projection;

    if (subscription == null) return const SizedBox.shrink();

    final mealInfo = subscription.mealInfo;
    final pauseInfo = projection?.pauseInfo;

    return Row(
      children: [
        // Total Meals
        Expanded(
          child: _buildStatCard(
            icon: Icons.restaurant_rounded,
            iconColor: primaryGreen,
            label: 'Total Meals',
            value: '${mealInfo.totalMeals}',
            backgroundColor: lightGreen,
          ),
        ),
        const SizedBox(width: 12),
        // Days Remaining
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF3B82F6),
            label: 'Days Left',
            value: '${mealInfo.daysRemaining}',
            backgroundColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 12),
        // Paused Days (if any)
        Expanded(
          child: _buildStatCard(
            icon: Icons.pause_circle_rounded,
            iconColor: warningText,
            label: 'Paused',
            value: pauseInfo != null && pauseInfo.pausedDays > 0
                ? '${pauseInfo.pausedDays}d'
                : '0d',
            subtitle: pauseInfo != null && pauseInfo.pausedMealsCount > 0
                ? '${pauseInfo.pausedMealsCount} meals'
                : null,
            backgroundColor: warningYellow,
          ),
        ),
      ],
    );
  }

  /// Build stat card widget
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  /// Build dates card
  Widget _buildDatesCard(SubscriptionController controller) {
    final subscription = controller.subscription;
    if (subscription == null) return const SizedBox.shrink();

    final dates = subscription.dates;
    if (!dates.hasData) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Subscription Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dates timeline
          if (dates.formattedStartDate.isNotEmpty)
            _buildDateRow(
              'Start Date',
              dates.formattedStartDate,
              Icons.play_arrow_rounded,
              primaryGreen,
            ),
          if (dates.formattedOriginalEndDate.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: DashedLine(),
            ),
            _buildDateRow(
              'Original End',
              dates.formattedOriginalEndDate,
              Icons.flag_outlined,
              textSecondary,
            ),
          ],
          if (dates.formattedAdjustedEndDate.isNotEmpty &&
              dates.adjustedEndDate != dates.originalEndDate) ...[
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: DashedLine(),
            ),
            _buildDateRow(
              'Adjusted End',
              dates.formattedAdjustedEndDate,
              Icons.flag_rounded,
              primaryGreen,
              isHighlighted: true,
            ),
          ],
        ],
      ),
    );
  }

  /// Build date row widget
  Widget _buildDateRow(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              color: isHighlighted ? primaryGreen : textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build subscription projection card
  Widget _buildSubscriptionProjectionCard(SubscriptionController controller) {
    final projection = controller.projection;
    if (projection == null || !projection.hasData)
      return const SizedBox.shrink();

    final pauseInfo = projection.pauseInfo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Subscription Projection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Current End Date
          if (projection.formattedCurrentEndDate.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current End Date',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                Text(
                  projection.formattedCurrentEndDate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          if (projection.formattedNewEndDate.isNotEmpty &&
              projection.newEndDate != projection.currentEndDate) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // New End Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New End Date',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      projection.formattedNewEndDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    if (pauseInfo.hasPausedData)
                      Text(
                        pauseInfo.label.isNotEmpty
                            ? pauseInfo.label
                            : '${pauseInfo.pausedDays} days paused',
                        style: const TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
          // Pause info summary
          if (pauseInfo.hasPausedData) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: warningYellow.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: warningText),
                  const SizedBox(width: 8),
                  Text(
                    '${pauseInfo.pausedDays} days paused • ${pauseInfo.pausedMealsCount} meals skipped',
                    style: TextStyle(
                      fontSize: 12,
                      color: warningText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text(
        'Manage Subscription',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        // Help Desk Icon
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpDeskScreen()),
            );
          },
          tooltip: 'Help & Support',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: primaryGreen,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Resume the paused plan
  Future<void> _resumePlan() async {
    final authController = context.read<AuthController>();
    final subscriptionController = context.read<SubscriptionController>();

    if (authController.accessToken != null) {
      final success = await subscriptionController.resumePlan(
        authController.accessToken!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Subscription resumed successfully!'),
              ],
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (mounted && subscriptionController.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subscriptionController.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showPausePlanDialog() {
    debugPrint('=== _showPausePlanDialog called ===');
    DateTime? pauseStartDate;
    DateTime? pauseEndDate;
    DateTime? singlePauseDate;
    bool isSubmitting = false;
    bool pauseForOneDay = false;

    // Meal selection for single day pause
    bool pauseBreakfast = false;
    bool pauseLunch = false;
    bool pauseDinner = false;

    // TODO: Add reasonController and selectedReason when API integration is implemented

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: warningYellow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.pause_circle_outline_rounded,
                                color: warningText,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pause Subscription',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Temporarily pause your deliveries',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Toggle for single day pause
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: pauseForOneDay ? lightGreen : Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: pauseForOneDay ? primaryGreen : cardBorder,
                          width: pauseForOneDay ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: pauseForOneDay
                                  ? primaryGreen.withOpacity(0.15)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.today_rounded,
                              color: pauseForOneDay
                                  ? primaryGreen
                                  : textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pause for One Day',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Skip specific meals on a single day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: pauseForOneDay,
                              onChanged: (value) {
                                setStateDialog(() {
                                  pauseForOneDay = value;
                                  if (value) {
                                    // Reset date range when switching to single day
                                    pauseStartDate = null;
                                    pauseEndDate = null;
                                  } else {
                                    // Reset single day and meals when switching to range
                                    singlePauseDate = null;
                                    pauseBreakfast = false;
                                    pauseLunch = false;
                                    pauseDinner = false;
                                  }
                                });
                              },
                              activeColor: primaryGreen,
                              activeTrackColor: lightGreen,
                              inactiveThumbColor: textSecondary,
                              inactiveTrackColor: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Conditional UI based on toggle
                    if (pauseForOneDay) ...[
                      // Single Day Mode
                      const Text(
                        'Select Date to Pause',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Single Date Picker
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                singlePauseDate ??
                                DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            helpText: 'SELECT DATE TO PAUSE',
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryGreen,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              singlePauseDate = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: singlePauseDate != null
                                  ? primaryGreen
                                  : cardBorder,
                              width: singlePauseDate != null ? 2 : 1,
                            ),
                            boxShadow: singlePauseDate != null
                                ? [
                                    BoxShadow(
                                      color: primaryGreen.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: singlePauseDate != null
                                      ? lightGreen
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: singlePauseDate != null
                                      ? primaryGreen
                                      : textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pause Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      singlePauseDate != null
                                          ? _formatDate(singlePauseDate!)
                                          : 'Select a date',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: singlePauseDate != null
                                            ? textPrimary
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: singlePauseDate != null
                                    ? primaryGreen
                                    : textSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Meal Selection (only show when date is selected)
                      if (singlePauseDate != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Select Meals to Pause',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose which meals to skip on ${_formatDate(singlePauseDate!)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        const SizedBox(height: 12),

                        // Meal Checkboxes
                        _buildMealCheckbox(
                          icon: Icons.free_breakfast_rounded,
                          title: 'Breakfast',
                          subtitle: 'Morning meal delivery',
                          isSelected: pauseBreakfast,
                          color: const Color(0xFFFF9800),
                          onChanged: (value) {
                            setStateDialog(() {
                              pauseBreakfast = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildMealCheckbox(
                          icon: Icons.lunch_dining_rounded,
                          title: 'Lunch',
                          subtitle: 'Afternoon meal delivery',
                          isSelected: pauseLunch,
                          color: const Color(0xFF4CAF50),
                          onChanged: (value) {
                            setStateDialog(() {
                              pauseLunch = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildMealCheckbox(
                          icon: Icons.dinner_dining_rounded,
                          title: 'Dinner',
                          subtitle: 'Evening meal delivery',
                          isSelected: pauseDinner,
                          color: const Color(0xFF9C27B0),
                          onChanged: (value) {
                            setStateDialog(() {
                              pauseDinner = value ?? false;
                            });
                          },
                        ),

                        // Summary for single day pause
                        if (pauseBreakfast || pauseLunch || pauseDinner) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: primaryGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: primaryGreen,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Pause Summary',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildSummaryRow(
                                  'Date',
                                  _formatDate(singlePauseDate!),
                                ),
                                const SizedBox(height: 8),
                                _buildSummaryRow(
                                  'Meals',
                                  _getSelectedMealsText(
                                    pauseBreakfast,
                                    pauseLunch,
                                    pauseDinner,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ] else ...[
                      // Date Range Mode
                      const Text(
                        'Select Pause Duration',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Start Date Picker
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                pauseStartDate ??
                                DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            helpText: 'SELECT PAUSE START DATE',
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryGreen,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              pauseStartDate = picked;
                              // Reset end date if it's before start date
                              if (pauseEndDate != null &&
                                  pauseEndDate!.isBefore(picked)) {
                                pauseEndDate = null;
                              }
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: pauseStartDate != null
                                  ? primaryGreen
                                  : cardBorder,
                              width: pauseStartDate != null ? 2 : 1,
                            ),
                            boxShadow: pauseStartDate != null
                                ? [
                                    BoxShadow(
                                      color: primaryGreen.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: pauseStartDate != null
                                      ? lightGreen
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: pauseStartDate != null
                                      ? primaryGreen
                                      : textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pause Start Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pauseStartDate != null
                                          ? _formatDate(pauseStartDate!)
                                          : 'Select start date',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: pauseStartDate != null
                                            ? textPrimary
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: pauseStartDate != null
                                    ? primaryGreen
                                    : textSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // End Date Picker
                      InkWell(
                        onTap: () async {
                          if (pauseStartDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Please select start date first'),
                                  ],
                                ),
                                backgroundColor: warningText,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                            return;
                          }
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: pauseEndDate ?? pauseStartDate!,
                            firstDate: pauseStartDate!,
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            helpText: 'SELECT PAUSE END DATE',
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryGreen,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              pauseEndDate = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: pauseEndDate != null
                                  ? primaryGreen
                                  : cardBorder,
                              width: pauseEndDate != null ? 2 : 1,
                            ),
                            boxShadow: pauseEndDate != null
                                ? [
                                    BoxShadow(
                                      color: primaryGreen.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: pauseEndDate != null
                                      ? lightGreen
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.event_rounded,
                                  color: pauseEndDate != null
                                      ? primaryGreen
                                      : textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pause End Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pauseEndDate != null
                                          ? _formatDate(pauseEndDate!)
                                          : 'Select end date',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: pauseEndDate != null
                                            ? textPrimary
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: pauseEndDate != null
                                    ? primaryGreen
                                    : textSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Duration info card (shown when both dates are selected)
                      if (pauseStartDate != null && pauseEndDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: primaryGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Duration: ${pauseEndDate!.difference(pauseStartDate!).inDays + 1} day(s)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Summary Card (only show when dates are selected)
                      if (pauseStartDate != null && pauseEndDate != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: primaryGreen,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Pause Summary',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSummaryRow(
                                'Start Date',
                                _formatDate(pauseStartDate!),
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'End Date',
                                _formatDate(pauseEndDate!),
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Total Days',
                                '${pauseEndDate!.difference(pauseStartDate!).inDays + 1} days',
                              ),
                              // TODO: Add reason summary when API integration is implemented
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textSecondary,
                              side: const BorderSide(color: cardBorder),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Confirm Button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    // Validate based on mode
                                    if (pauseForOneDay) {
                                      if (singlePauseDate == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 12),
                                                Text('Please select a date'),
                                              ],
                                            ),
                                            backgroundColor: warningText,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                        return;
                                      }
                                      if (!pauseBreakfast &&
                                          !pauseLunch &&
                                          !pauseDinner) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Please select at least one meal',
                                                ),
                                              ],
                                            ),
                                            backgroundColor: warningText,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                        return;
                                      }

                                      // Single day mode - Collect selected meals and make single API call
                                      setStateDialog(() {
                                        isSubmitting = true;
                                      });

                                      final authController = this.context
                                          .read<AuthController>();
                                      final subscriptionController = this
                                          .context
                                          .read<SubscriptionController>();

                                      if (authController.accessToken != null) {
                                        // Format date as YYYY-MM-DD
                                        final dateStr =
                                            '${singlePauseDate!.year}-${singlePauseDate!.month.toString().padLeft(2, '0')}-${singlePauseDate!.day.toString().padLeft(2, '0')}';

                                        // Collect all selected meal types
                                        List<String> selectedMealTypes = [];
                                        List<String> displayMealNames = [];

                                        if (pauseBreakfast) {
                                          selectedMealTypes.add('breakfast');
                                          displayMealNames.add('Breakfast');
                                        }
                                        if (pauseLunch) {
                                          selectedMealTypes.add('lunch');
                                          displayMealNames.add('Lunch');
                                        }
                                        if (pauseDinner) {
                                          selectedMealTypes.add('dinner');
                                          displayMealNames.add('Dinner');
                                        }

                                        // Make single API call with all selected meals
                                        final success =
                                            await subscriptionController
                                                .pauseSingleDay(
                                                  authController.accessToken!,
                                                  date: dateStr,
                                                  mealTypes: selectedMealTypes,
                                                  reason: 'Skipping meal(s)',
                                                );

                                        setStateDialog(() {
                                          isSubmitting = false;
                                        });

                                        if (success) {
                                          Navigator.pop(dialogContext);
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      '${displayMealNames.join(', ')} paused for ${_formatDate(singlePauseDate!)}',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: primaryGreen,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      subscriptionController
                                                              .errorMessage ??
                                                          'Failed to pause subscription',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      // Date range mode
                                      if (pauseStartDate == null ||
                                          pauseEndDate == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Please select both dates',
                                                ),
                                              ],
                                            ),
                                            backgroundColor: warningText,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                        return;
                                      }

                                      setStateDialog(() {
                                        isSubmitting = true;
                                      });

                                      final authController = this.context
                                          .read<AuthController>();
                                      final subscriptionController = this
                                          .context
                                          .read<SubscriptionController>();

                                      if (authController.accessToken != null) {
                                        // Format dates as YYYY-MM-DD
                                        final fromDateStr =
                                            '${pauseStartDate!.year}-${pauseStartDate!.month.toString().padLeft(2, '0')}-${pauseStartDate!.day.toString().padLeft(2, '0')}';
                                        final toDateStr =
                                            '${pauseEndDate!.year}-${pauseEndDate!.month.toString().padLeft(2, '0')}-${pauseEndDate!.day.toString().padLeft(2, '0')}';

                                        final success =
                                            await subscriptionController
                                                .pauseDateRange(
                                                  authController.accessToken!,
                                                  fromDate: fromDateStr,
                                                  toDate: toDateStr,
                                                  reason: 'Travel',
                                                );

                                        setStateDialog(() {
                                          isSubmitting = false;
                                        });

                                        if (success) {
                                          final int pauseDays =
                                              pauseEndDate!
                                                  .difference(pauseStartDate!)
                                                  .inDays +
                                              1;

                                          Navigator.pop(dialogContext);
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Subscription paused for $pauseDays days',
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: primaryGreen,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      subscriptionController
                                                              .errorMessage ??
                                                          'Failed to pause subscription',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: primaryGreen.withOpacity(
                                0.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    pauseForOneDay
                                        ? 'Pause Selected Meals'
                                        : 'Pause Subscription',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Helper method to build meal checkbox widget
  Widget _buildMealCheckbox({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to get selected meals as text
  String _getSelectedMealsText(bool breakfast, bool lunch, bool dinner) {
    final List<String> meals = [];
    if (breakfast) meals.add('Breakfast');
    if (lunch) meals.add('Lunch');
    if (dinner) meals.add('Dinner');

    if (meals.length == 3) return 'All meals';
    if (meals.isEmpty) return 'No meals';
    return meals.join(', ');
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
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

  Widget _buildDrawer() {
    // Get user data from AuthController
    final authController = context.watch<AuthController>();
    final user = authController.user;
    final userName = user?.fullName ?? 'Guest User';
    final userEmail = user?.email ?? 'Not logged in';
    final subscriptionPlan =
        context.watch<SubscriptionController>().plan?.name ?? 'Premium Plan';

    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          // Drawer Header with User Info
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryGreen, Color(0xFF6BA82E)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                // User Name
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // User Email
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                // Subscription Plan Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subscriptionPlan,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isSelected: true,
                  onTap: () => Navigator.pop(context),
                ),

                _buildDrawerItem(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery Address',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeliveryAddressManagement(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Track Order',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveOrderTrack(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.star_border_rounded,
                  title: 'Meals Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MealsFeedback(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Add-ons',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddOnsListScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpDeskScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Logout Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && mounted) {
                    // Close drawer
                    Navigator.pop(context);

                    // Call logout
                    await context.read<AuthController>().logout();

                    // Navigate to login screen
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? lightGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryGreen : textSecondary,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? primaryGreen : textPrimary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class DashedLine extends StatelessWidget {
  final double height;
  final double dashWidth;
  final Color color;

  const DashedLine({
    super.key,
    this.height = 24,
    this.dashWidth = 4,
    this.color = const Color(0xFFE5E7EB),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxHeight = constraints.constrainHeight();
          final dashHeight = dashWidth;
          final dashCount = (boxHeight / (2 * dashHeight)).floor();
          return Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: 1,
                height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              );
            }),
          );
        },
      ),
    );
  }
}
