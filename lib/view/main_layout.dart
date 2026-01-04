import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import '../controller/subscription_controller.dart';
import 'login_screen.dart';
import 'subscription_dashboard.dart';
import 'delivery_adress_management.dart';
import 'live_order_track.dart';
import 'meals_feedback.dart';
import 'notification_screen.dart';
import 'help_desk_screen.dart';    
import 'addons_list_screen.dart';

// Color constants
const Color primaryGreen = Color(0xFF8AC53D);
const Color lightGreen = Color(0xFFF0F7E6);
const Color textPrimary = Color(0xFF1F2937);
const Color textSecondary = Color(0xFF6B7280);
const Color cardBorder = Color(0xFFE5E7EB);
const Color backgroundColor = Color(0xFFFAFAFA);
 
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void _onMenuItemTapped(int index) {
    // Close drawer on mobile when item is tapped
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _getScreens(bool isLargeScreen) {
    return [
      SubscriptionDashboard(showAppBar: !isLargeScreen),
      const DeliveryAddressManagement(),
      const LiveOrderTrack(),
      const MealsFeedback(),
      const NotificationScreen(),
      const AddOnsListScreen(),
      const HelpDeskScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Check screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600; // Tablet/Desktop threshold
    final screens = _getScreens(isLargeScreen);

    if (isLargeScreen) {
      // Tablet/Desktop: Show persistent sidebar
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            // Persistent Sidebar
            _buildSidebar(),

            // Main Content Area
            Expanded(child: screens[_selectedIndex]),
          ],
        ),
      );
    } else {
      // Mobile: Use traditional drawer
      return Scaffold(
        backgroundColor: backgroundColor,
        drawer: Drawer(
          backgroundColor: backgroundColor,
          child: _buildSidebar(),
        ),
        body: screens[_selectedIndex],
      );
    }
  }

  Widget _buildSidebar() {
    final authController = context.watch<AuthController>();
    final user = authController.user;
    final userName = user?.fullName ?? 'Guest User';
    final userEmail = user?.email ?? 'Not logged in';
    final subscriptionPlan =
        context.watch<SubscriptionController>().plan?.name ?? 'Premium Plan';

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar Header with User Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                // User Name
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // User Email
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Subscription Plan Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          subscriptionPlan,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                _buildSidebarItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildSidebarItem(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery Address',
                  index: 1,
                ),
                _buildSidebarItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Track Order',
                  index: 2,
                ),
                _buildSidebarItem(
                  icon: Icons.star_border_rounded,
                  title: 'Meals Feedback',
                  index: 3,
                ),
                _buildSidebarItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  index: 4,
                ),
                _buildSidebarItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Add-ons',
                  index: 5,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildSidebarItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  index: 6,
                  isSettings: true,
                ),
                _buildSidebarItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Help & Support',
                  index: 6,
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
                    await context.read<AuthController>().logout();
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
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required int index,
    bool isSettings = false,
  }) {
    final isSelected = _selectedIndex == index;

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
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? primaryGreen : textPrimary,
          ),
        ),
        onTap: isSettings ? null : () => _onMenuItemTapped(index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
