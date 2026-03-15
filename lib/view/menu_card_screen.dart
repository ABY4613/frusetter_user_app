import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';

// Color constants matching the app theme
const Color primaryGreen = Color(0xFF8AC53D);
const Color lightGreen = Color(0xFFF0F7E6);
const Color textPrimary = Color(0xFF1F2937);
const Color textSecondary = Color(0xFF6B7280);
const Color cardBorder = Color(0xFFE5E7EB);
const Color backgroundColor = Color(0xFFFAFAFA);

class UpcomingMeal {
  final String id;
  final String date;
  final String mealType;
  final String mealName;
  final String status;

  UpcomingMeal({
    required this.id,
    required this.date,
    required this.mealType,
    required this.mealName,
    required this.status,
  });

  factory UpcomingMeal.fromJson(Map<String, dynamic> json) {
    return UpcomingMeal(
      id: json['ID'] ?? '',
      date: json['DeliveryDate'] ?? '',
      mealType: json['MealType'] ?? '',
      mealName: json['meal_name'] ?? '',
      status: json['Status'] ?? '',
    );
  }
}

class MenuCardScreen extends StatefulWidget {
  const MenuCardScreen({super.key});

  @override
  State<MenuCardScreen> createState() => _MenuCardScreenState();
}

class _MenuCardScreenState extends State<MenuCardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<UpcomingMeal> _upcomingMeals = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingMeals();
  }

  Future<void> _fetchUpcomingMeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authController = context.read<AuthController>();
      final token = authController.accessToken;

      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('https://frusette-backend-ym62.onrender.com/v1/customer/meals/upcoming');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> mealsData = data['data'];
          setState(() {
            _upcomingMeals = mealsData.map((e) => UpcomingMeal.fromJson(e)).toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load menu data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateString(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final parsed = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Menu Card',
        style: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: cardBorder),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              "Failed to load menu",
              style: TextStyle(fontSize: 18, color: textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchUpcomingMeals,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_upcomingMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
             const SizedBox(height: 16),
             const Text('No upcoming meals', style: TextStyle(fontSize: 18, color: textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _fetchUpcomingMeals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingMeals.length,
        itemBuilder: (context, index) {
          return _buildMealCard(_upcomingMeals[index]);
        },
      ),
    );
  }

  Widget _buildMealCard(UpcomingMeal meal) {
    String formattedDate = _formatDateString(meal.date);

    // Determine status color
    Color statusColor = textSecondary;
    Color statusBg = Colors.grey.shade100;
    
    if (meal.status.toLowerCase() == 'delivered') {
      statusColor = Colors.green.shade700;
      statusBg = Colors.green.shade50;
    } else if (meal.status.toLowerCase() == 'scheduled') {
      statusColor = Colors.blue.shade700;
      statusBg = Colors.blue.shade50;
    } else if (meal.status.toLowerCase() == 'ready') {
      statusColor = Colors.orange.shade700;
      statusBg = Colors.orange.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        meal.mealType.toLowerCase() == 'lunch' ? Icons.lunch_dining_rounded : Icons.dinner_dining_rounded,
                        color: primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.mealType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meal.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: cardBorder),
            const SizedBox(height: 16),
            // Dish Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal.mealName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
