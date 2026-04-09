import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/subscription_controller.dart';
import '../controller/auth_controller.dart';
import '../model/subscription_model.dart';

class PauseDetailsScreen extends StatelessWidget {
  const PauseDetailsScreen({super.key});

  static const Color primaryGreen = Color(0xFF8AC53D);
  static const Color lightGreen = Color(0xFFE8F5D9);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color warningYellow = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final subscriptionController = context.watch<SubscriptionController>();
    final pauseInfo = subscriptionController.projection?.pauseInfo;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Pause Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textPrimary,
              size: 18,
            ),
          ),
        ),
      ),
      body: pauseInfo == null || !pauseInfo.hasPausedData
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(pauseInfo),
                  const SizedBox(height: 24),
                  const Text(
                    'Paused Deliveries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pauseInfo.pausedMeals.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final meal = pauseInfo.pausedMeals[index];
                      return _buildPausedMealCard(context, meal);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pause_circle_outline_rounded,
              size: 64,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Paused Deliveries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your subscription is running as scheduled.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PauseInfo pauseInfo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen, Color(0xFF6BA82E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL PAUSED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pauseInfo.pausedDays} Days',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${pauseInfo.pausedMealsCount} meals will be deferred to later dates.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedMealCard(BuildContext context, PausedMeal meal) {
    IconData mealIcon;
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast':
        mealIcon = Icons.free_breakfast_rounded;
        break;
      case 'lunch':
        mealIcon = Icons.lunch_dining_rounded;
        break;
      case 'dinner':
        mealIcon = Icons.dinner_dining_rounded;
        break;
      default:
        mealIcon = Icons.restaurant_rounded;
    }

    Color typeColor;
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast':
        typeColor = const Color(0xFFFF9800);
        break;
      case 'lunch':
        typeColor = const Color(0xFF4CAF50);
        break;
      case 'dinner':
        typeColor = const Color(0xFF9C27B0);
        break;
      default:
        typeColor = primaryGreen;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              mealIcon,
              color: typeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      meal.formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meal.mealType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'resume') {
                _resumeMeal(context, meal);
              }
            },
            icon: const Icon(Icons.more_vert_rounded, color: textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'resume',
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        color: primaryGreen, size: 20),
                    const SizedBox(width: 12),
                    const Text('Resume Meal', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Resume a specific paused meal
  Future<void> _resumeMeal(BuildContext context, PausedMeal meal) async {
    final authController = context.read<AuthController>();
    final subscriptionController = context.read<SubscriptionController>();

    if (authController.accessToken == null) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      ),
    );

    // Call meal-specific unpause API
    final success = await subscriptionController.unpauseMeal(
      authController.accessToken!,
      meal.id,
    );

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal resumed successfully'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subscriptionController.errorMessage ?? 'Failed to resume meal'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
