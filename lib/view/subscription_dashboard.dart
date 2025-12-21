import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import '../controller/subscription_controller.dart';
import 'login_screen.dart';
import 'delivery_adress_management.dart';
import 'live_order_track.dart';
import 'meals_feedback.dart';
import 'notification_screen.dart';
import 'help_desk_screen.dart';

class SubscriptionDashboard extends StatefulWidget {
  const SubscriptionDashboard({super.key});

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

  // Calendar state
  DateTime _currentMonth = DateTime(2023, 10); // October 2023
  final DateTime _selectedDate = DateTime(2023, 10, 5);

  // Subscription state - now fetched from API
  // These are fallback values used when API data is not available
  String _planName = 'Loading...';
  String _subscriptionId = '';
  String _subscriptionStatus = 'ACTIVE';
  int _mealsPerDay = 0;
  int _daysRemaining = 0;
  int _totalMeals = 0;

  // Delivery dates (for calendar marking)
  final Set<int> _deliveryDates = {
    5,
    6,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
  };
  final Set<int> _pausedDates = {7, 21};

  // End dates
  String _currentEndDate = '';
  String _newEndDate = '';
  int _pausedDays = 0;

  // Action permissions from API
  bool _canPausePlan = false;
  bool _canResumePlan = false;

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
    });
  }

  /// Fetch subscription data from API
  Future<void> _fetchSubscriptionData() async {
    final authController = context.read<AuthController>();
    final subscriptionController = context.read<SubscriptionController>();

    if (authController.accessToken != null) {
      final success = await subscriptionController.fetchSubscriptionData(
        authController.accessToken!,
      );

      if (success && mounted) {
        _updateStateFromController(subscriptionController);
      }
    }
  }

  /// Update local state from controller data
  void _updateStateFromController(SubscriptionController controller) {
    final subscription = controller.subscription;
    final projection = controller.projection;

    if (subscription != null && mounted) {
      setState(() {
        _planName = subscription.planName;
        _subscriptionId = subscription.id;
        _subscriptionStatus = subscription.status;
        _mealsPerDay = subscription.mealInfo.mealsPerDay;
        _daysRemaining = subscription.mealInfo.daysRemaining;
        _totalMeals = subscription.mealInfo.totalMeals;
        _canPausePlan = subscription.actions.pausePlan;
        _canResumePlan = subscription.actions.resumePlan;
      });
    }

    if (projection != null && mounted) {
      setState(() {
        _currentEndDate = _formatDateFromString(projection.currentEndDate);
        _newEndDate = _formatDateFromString(projection.newEndDate);
        _pausedDays = projection.pauseInfo.pausedDays;
      });
    }
  }

  /// Format date string from API (YYYY-MM-DD) to display format
  String _formatDateFromString(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return _formatDate(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Subscription Info Card
                      _buildSubscriptionCard(),
                      const SizedBox(height: 16),
                      // Warning Banner
                      _buildWarningBanner(), // Delivery Schedule
                      const SizedBox(height: 24),
                      // Subscription Projection
                      _buildSubscriptionProjection(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            // Update Button
            _buildUpdateButton(),
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

  Widget _buildSubscriptionCard() {
    final subscriptionController = context.watch<SubscriptionController>();
    final bool isLoading = subscriptionController.isLoading;
    final bool isActive = _subscriptionStatus.toUpperCase() == 'ACTIVE';
    final bool isPaused = _subscriptionStatus.toUpperCase() == 'PAUSED';

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
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          : Column(
              children: [
                // Plan info row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badges
                          Row(
                            children: [
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
                                  _subscriptionStatus.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total: $_totalMeals Meals',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Plan name
                          Text(
                            _planName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Plan details
                          Text(
                            '$_mealsPerDay Meals / Day • $_daysRemaining Days Remaining',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Meal image
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green[100]!,
                                    Colors.orange[100]!,
                                  ],
                                ),
                              ),
                            ),
                            const Center(
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: primaryGreen,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child:
                          (_canPausePlan ||
                              _subscriptionStatus.toUpperCase() == 'ACTIVE')
                          ? OutlinedButton.icon(
                              onPressed: () {
                                _showPausePlanDialog();
                              },
                              icon: const Icon(
                                Icons.pause_circle_outline,
                                size: 18,
                              ),
                              label: const Text('Pause Plan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: const BorderSide(color: cardBorder),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            )
                          : (_canResumePlan ||
                                _subscriptionStatus.toUpperCase() == 'PAUSED')
                          ? ElevatedButton.icon(
                              onPressed: () async {
                                await _resumePlan();
                              },
                              icon: const Icon(
                                Icons.play_circle_outline,
                                size: 18,
                              ),
                              label: const Text('Resume Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('No Actions Available'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textSecondary,
                                side: const BorderSide(color: cardBorder),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
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
        _updateStateFromController(subscriptionController);
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

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warningYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningText.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: warningText, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily cut-off: 10:00 PM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modifications for tomorrow must be made by 10 PM today to be effective.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          ..._buildCalendarWeeks(),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarWeeks() {
    final List<Widget> weeks = [];
    final int daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final int firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    List<Widget> currentWeek = [];

    // Add empty cells for days before the 1st
    for (int i = 0; i < firstWeekday; i++) {
      currentWeek.add(_buildEmptyDayCell());
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(_buildDayCell(day));

      if (currentWeek.length == 7) {
        weeks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: currentWeek,
            ),
          ),
        );
        currentWeek = [];
      }
    }

    // Add remaining empty cells
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(_buildEmptyDayCell());
      }
      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: currentWeek,
        ),
      );
    }

    return weeks;
  }

  Widget _buildEmptyDayCell() {
    return const SizedBox(width: 36, height: 36);
  }

  Widget _buildDayCell(int day) {
    final bool isDelivery = _deliveryDates.contains(day);
    final bool isPaused = _pausedDates.contains(day);
    final bool isToday = day == 5; // Simulating today is Oct 5
    final bool isSelected = day == _selectedDate.day;

    return GestureDetector(
      onTap: () => _onDayTap(day),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? primaryGreen
              : isPaused
              ? textSecondary.withOpacity(0.2)
              : isDelivery
              ? lightGreen
              : Colors.transparent,
          border: isToday && !isSelected
              ? Border.all(color: primaryGreen, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isPaused
                    ? textSecondary
                    : textPrimary,
              ),
            ),
            // Delivery dot
            if (isDelivery && !isPaused && !isSelected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionProjection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current End Date',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              Text(
                _currentEndDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // New End Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New End Date',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _newEndDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                  if (_pausedDays > 0)
                    Text(
                      '($_pausedDays day paused)',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
    );
  }

  // Helper methods

  void _onDayTap(int day) {
    // Show options for this day
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'October $day, 2023',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (_deliveryDates.contains(day) && !_pausedDates.contains(day))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.pause, color: textSecondary),
                ),
                title: const Text('Pause this delivery'),
                subtitle: const Text('Skip delivery on this day'),
                onTap: () {
                  setState(() {
                    _pausedDates.add(day);
                    _pausedDays++;
                    _newEndDate = 'Oct ${26 + _pausedDays - 1}, 2023';
                  });
                  Navigator.pop(context);
                },
              ),
            if (_pausedDates.contains(day))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow, color: primaryGreen),
                ),
                title: const Text('Resume this delivery'),
                subtitle: const Text('Enable delivery on this day'),
                onTap: () {
                  setState(() {
                    _pausedDates.remove(day);
                    _pausedDays = _pausedDays > 0 ? _pausedDays - 1 : 0;
                    _newEndDate = _pausedDays == 0
                        ? _currentEndDate
                        : 'Oct ${26 + _pausedDays - 1}, 2023';
                  });
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history, color: primaryGreen),
              title: const Text('View Order History'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_outlined, color: primaryGreen),
              title: const Text('View Invoices'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: const Text(
                'Cancel Subscription',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCancelConfirmation();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
                            onPressed: () {
                              // Validate based on mode
                              if (pauseForOneDay) {
                                if (singlePauseDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                  return;
                                }
                                if (!pauseBreakfast &&
                                    !pauseLunch &&
                                    !pauseDinner) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                  return;
                                }

                                // Single day mode - show success and close
                                Navigator.pop(dialogContext);
                                final meals = _getSelectedMealsText(
                                  pauseBreakfast,
                                  pauseLunch,
                                  pauseDinner,
                                );
                                ScaffoldMessenger.of(this.context).showSnackBar(
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
                                            '$meals paused for ${_formatDate(singlePauseDate!)}',
                                          ),
                                        ),
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
                              } else {
                                // Date range mode
                                if (pauseStartDate == null ||
                                    pauseEndDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Please select both dates'),
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

                                final int pauseDays =
                                    pauseEndDate!
                                        .difference(pauseStartDate!)
                                        .inDays +
                                    1;

                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(this.context).showSnackBar(
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
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
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

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Subscription?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to cancel your subscription? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Subscription',
              style: TextStyle(color: textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showUpdateConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Subscription updated successfully!'),
          ],
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDrawer() {
    // Get user data from AuthController
    final authController = context.watch<AuthController>();
    final user = authController.user;
    final userName = user?.fullName ?? 'Guest User';
    final userEmail = user?.email ?? 'Not logged in';
    final subscriptionPlan = _planName;

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
