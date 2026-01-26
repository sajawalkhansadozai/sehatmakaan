import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/user_status_service.dart';
import '../../../shared/fcm_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _animationController.forward();

    // Check registration status and navigate accordingly
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final loginStatus = prefs.getString('login_status');
    final registrationStatus = prefs.getString('registration_status');
    final userType = prefs.getString('user_type');

    // Priority 1: Check if user is already logged in
    if (loginStatus == 'logged_in') {
      // Route based on user type
      if (userType == 'admin') {
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else {
        // Validate current user status from Firestore before allowing access
        final userId = prefs.getString('user_id') ?? '';

        if (userId.isNotEmpty) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();

            if (!userDoc.exists) {
              // User deleted - clear session and show landing
              await prefs.clear();
              Navigator.of(context).pushReplacementNamed('/landing');
              return;
            }

            final userData = userDoc.data()!;
            final status = userData['status'] as String?;
            final isActive = userData['isActive'] as bool? ?? false;

            debugPrint('🔍 Splash Check - User: $userId');
            debugPrint('🔍 Splash Check - Status: $status');
            debugPrint('🔍 Splash Check - isActive: $isActive');

            // ✅ ROBUST REDIRECTION: Check status immediately
            if (status == 'suspended') {
              debugPrint('⛔ SUSPENDED - Redirecting to suspension page');
              await prefs.clear();
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed(
                '/account-suspended',
                arguments:
                    userData['suspensionReason'] ??
                    'Terms and Conditions Violation',
              );
              return;
            }

            if (status == 'pending') {
              debugPrint('⏳ PENDING - Redirecting to verification page');
              await prefs.clear();
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/verification');
              return;
            }

            if (status == 'rejected' || !isActive) {
              debugPrint('⛔ Account blocked - Redirecting to landing page');
              await prefs.clear();
              await FirebaseAuth.instance.signOut();

              String reason = '';
              if (status == 'suspended') {
                reason = 'Terms and Conditions Violation';
              } else if (status == 'rejected') {
                reason =
                    'Account Rejected: ${userData['rejectionReason'] ?? 'Contact support'}';
              } else {
                reason = 'Account Deactivated - Contact Admin';
              }

              // Redirect to suspension page
              if (mounted) {
                debugPrint(
                  '🚀 Navigating to /account-suspended with reason: $reason',
                );
                Navigator.of(
                  context,
                ).pushReplacementNamed('/account-suspended', arguments: reason);
              }
              return;
            }

            debugPrint('✅ Account valid - Proceeding to dashboard');

            // Start real-time status monitoring
            await UserStatusService.startMonitoring(context, userId);
            debugPrint('✅ User status monitoring started from splash');

            // Initialize FCM for push notifications
            final fcmService = FCMService();
            await fcmService.initialize(userId);
            debugPrint('✅ FCM initialized in splash screen for user: $userId');

            // Account is valid - proceed to dashboard
            final userEmail = prefs.getString('user_email') ?? '';
            final fullName = prefs.getString('user_full_name') ?? '';

            Navigator.of(context).pushReplacementNamed(
              '/dashboard',
              arguments: {
                'id': userId,
                'email': userEmail,
                'fullName': fullName,
                'userType': userType,
                'status': status,
                'isActive': isActive,
              },
            );
          } catch (e) {
            debugPrint('Error validating session: $e');
            // On error, clear session and show landing
            await prefs.clear();
            Navigator.of(context).pushReplacementNamed('/landing');
          }
        } else {
          // No user ID - show landing
          Navigator.of(context).pushReplacementNamed('/landing');
        }
      }
    }
    // Priority 2: Check if registration is pending approval
    else if (registrationStatus == 'pending') {
      Navigator.of(context).pushReplacementNamed('/verification');
    }
    // Priority 3: Show landing page
    else {
      Navigator.of(context).pushReplacementNamed('/landing');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final iconSize = isSmallScreen ? 60.0 : 80.0;
    final titleSize = isSmallScreen ? 28.0 : 36.0;
    final subtitleSize = isSmallScreen ? 14.0 : 16.0;
    final padding = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFF006876), // App primary color
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF006876), const Color(0xFF008899)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              width: iconSize,
                              height: iconSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Animated App Name
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Sehat Makaan',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Healthcare Practice Partner',
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                // Loading Indicator
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B35), // Orange accent color
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
