import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import '../utlits/api_constants.dart';

// Color constants matching the app theme
const Color primaryGreen = Color(0xFF8AC53D);
const Color lightGreen = Color(0xFFF0F7E6);
const Color textPrimary = Color(0xFF1F2937);
const Color textSecondary = Color(0xFF6B7280);
const Color cardBorder = Color(0xFFE5E7EB);
const Color backgroundColor = Color(0xFFFAFAFA);

class MenuCardScreen extends StatefulWidget {
  const MenuCardScreen({super.key});

  @override
  State<MenuCardScreen> createState() => _MenuCardScreenState();
}

class _MenuCardScreenState extends State<MenuCardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _monthlyMenu;
  String _planName = "Universal Meal Plan";
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
    if (!mounted) return;
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

      final url = Uri.parse(ApiConstants.getUrl(ApiConstants.subscriptionPlan));
      final response = await http.get(
        url,
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final planData = data['data'];
          setState(() {
            _monthlyMenu = planData['monthly_menu'] ?? planData['monthlyMenu'];
            _planName = planData['name'] ?? "Universal Meal Plan";
            _isLoading = false;
            
            if (_monthlyMenu != null) {
               _tabController = TabController(length: _monthlyMenu!.length, vsync: this);
            }
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

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Card',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!_isLoading && _planName.isNotEmpty)
            Text(
              _planName,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      bottom: _monthlyMenu != null && _tabController != null
          ? TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: primaryGreen,
              unselectedLabelColor: textSecondary,
              indicatorColor: primaryGreen,
              tabs: _monthlyMenu!.keys.map((week) {
                return Tab(text: week.replaceAll('week', 'Week '));
              }).toList(),
            )
          : PreferredSize(
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
      return _buildErrorView();
    }

    if (_monthlyMenu == null || _monthlyMenu!.isEmpty) {
      return _buildEmptyView();
    }

    return TabBarView(
      controller: _tabController,
      children: _monthlyMenu!.keys.map((weekKey) {
        final weekData = _monthlyMenu![weekKey] as Map<String, dynamic>;
        return _buildWeekMenu(weekData);
      }).toList(),
    );
  }

  Widget _buildWeekMenu(Map<String, dynamic> weekData) {
    // Sort days to ensure they follow Monday-Sunday order
    final dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final sortedDays = weekData.keys.toList()
      ..sort((a, b) => dayOrder.indexOf(a.toLowerCase()).compareTo(dayOrder.indexOf(b.toLowerCase())));

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _fetchMenuData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDays.length,
        itemBuilder: (context, index) {
          final day = sortedDays[index];
          final dayData = weekData[day] as Map<String, dynamic>;
          return _buildDayCard(day, dayData);
        },
      ),
    );
  }

  Widget _buildDayCard(String day, Map<String, dynamic> dayData) {
    // Collect non-null meals
    final meals = <MapEntry<String, dynamic>>[];
    if (dayData['breakfast'] != null) meals.add(MapEntry('breakfast', dayData['breakfast']));
    if (dayData['lunch'] != null) meals.add(MapEntry('lunch', dayData['lunch']));
    if (dayData['dinner'] != null) meals.add(MapEntry('dinner', dayData['dinner']));

    if (meals.isEmpty) return const SizedBox.shrink();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: cardBorder),
          ...meals.map((entry) => _buildMealItem(entry.key, entry.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealItem(String type, dynamic meal) {
    final name = meal['name'] ?? 'Unnamed Meal';
    
    IconData icon;
    Color iconColor;
    switch (type.toLowerCase()) {
      case 'breakfast':
        icon = Icons.wb_sunny_outlined;
        iconColor = Colors.orange;
        break;
      case 'lunch':
        icon = Icons.lunch_dining_rounded;
        iconColor = Colors.green;
        break;
      case 'dinner':
        icon = Icons.nightlight_round_outlined;
        iconColor = Colors.indigo;
        break;
      default:
        icon = Icons.restaurant_menu;
        iconColor = primaryGreen;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textSecondary.withOpacity(0.7),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              onPressed: _fetchMenuData,
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
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No menu details available',
            style: TextStyle(fontSize: 18, color: textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
