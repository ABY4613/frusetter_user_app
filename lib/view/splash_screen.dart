import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frusette_customer_app/utlits/app_color.dart';
import 'package:frusette_customer_app/controller/auth_controller.dart';
import 'login_screen.dart';
import 'main_layout.dart';

class SplashScreen extends StatefulWidget {
  /// The screen to navigate to after the splash animation completes
  final Widget? nextScreen;

  /// Duration of the splash screen in milliseconds
  final int splashDuration;

  const SplashScreen({super.key, this.nextScreen, this.splashDuration = 3000});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade controller for text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Pulse animation for loading
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Logo scale animation - smooth entrance
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Logo opacity
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text animations
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );
  }

  void _startAnimationSequence() async {
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Start text animation after logo
    await Future.delayed(const Duration(milliseconds: 600));
    _fadeController.forward();

    // Check auth status and navigate
    await Future.delayed(Duration(milliseconds: widget.splashDuration));
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    debugPrint('SplashScreen: Checking auth status...');

    // Get AuthController and check if user is logged in
    final authController = context.read<AuthController>();
    final isLoggedIn = await authController.checkAuth();

    debugPrint('SplashScreen: isLoggedIn = $isLoggedIn');

    if (!mounted) return;

    // Navigate based on auth status
    if (isLoggedIn) {
      // User is logged in, go to dashboard
      debugPrint('SplashScreen: Navigating to Dashboard');
      _navigateToScreen(const MainLayout());
    } else {
      // User not logged in, go to login screen
      debugPrint('SplashScreen: Navigating to Login');
      _navigateToScreen(const LoginScreen());
    }
  }

  void _navigateToScreen(Widget screen) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _fadeController,
          _pulseController,
        ]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.white,
            child: Stack(
              children: [
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with animation
                      _buildLogo(),
                      const SizedBox(height: 32),
                      // App name
                      _buildAppName(),
                      const SizedBox(height: 12),
                      // Tagline
                      _buildTagline(),
                    ],
                  ),
                ),
                // Loading indicator at bottom
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: _buildLoadingIndicator(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Transform.scale(
      scale: _logoScale.value,
      child: Opacity(
        opacity: _logoOpacity.value.clamp(0.0, 1.0),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.border,
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Image.asset(
                'assets/images/image copy.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryColor, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 60,
                      color: AppColors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return SlideTransition(
      position: _textSlide,
      child: Opacity(
        opacity: _textOpacity.value.clamp(0.0, 1.0),
        child: Text(
          'FRUSETTE',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return SlideTransition(
      position: _textSlide,
      child: Opacity(
        opacity: _textOpacity.value.clamp(0.0, 1.0),
        child: Text(
          'Fresh • Healthy • Delicious',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Opacity(
      opacity: _textOpacity.value.clamp(0.0, 1.0),
      child: Column(
        children: [
          // Animated dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final animValue = ((_pulseController.value + delay) % 1.0);
                  final scale = 0.5 + (animValue * 0.5);
                  final opacity = 0.3 + (animValue * 0.7);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
