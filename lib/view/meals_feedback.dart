import 'package:flutter/material.dart';

class MealsFeedback extends StatelessWidget {
  final String mealId;
  final String mealName;

  const MealsFeedback({
    super.key,
    this.mealId = '',
    this.mealName = '',
  });

  static const Color primaryGreen = Color(0xFF8AC53D);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: textPrimary),
        ),
        title: const Text(
          'Meals Feedback',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_border_rounded,
                size: 60,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Meals Feedback',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: TextStyle(fontSize: 16, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
