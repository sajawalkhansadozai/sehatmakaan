import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';
import 'package:sehat_makaan_flutter/services/session_storage_service.dart';

class VerificationPage extends StatefulWidget {
  final String? userId;

  const VerificationPage({super.key, this.userId});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  @override
  void initState() {
    super.initState();
    _startListeningToUserStatus();
  }

  void _startListeningToUserStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Listen to real-time status changes
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) async {
          if (!mounted) return;

          if (snapshot.exists) {
            final data = snapshot.data();
            final status = data?['status'];
            final isActive = data?['isActive'] ?? false;

            // If approved, update local storage and navigate
            if (status == 'approved' && isActive) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_id', currentUser.uid);
              await prefs.setString('user_email', data?['email'] ?? '');
              await prefs.setString('user_full_name', data?['fullName'] ?? '');
              await prefs.setString('registration_status', 'approved');
              await prefs.setString('login_status', 'logged_in');
              await prefs.setString('user_type', data?['userType'] ?? 'doctor');

              if (mounted) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '✅ Your registration has been approved! Redirecting to dashboard...',
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );

                // Navigate directly to dashboard (user already authenticated)
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                    arguments: {
                      'id': currentUser.uid,
                      'email': data?['email'],
                      'fullName': data?['fullName'],
                      'userType': data?['userType'] ?? 'doctor',
                      'status': 'approved',
                      'isActive': true,
                    },
                  );
                }
              }
            }
            // If rejected, show message and logout
            else if (status == 'rejected') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '❌ Your registration was rejected. Please contact support.',
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                  ),
                );
                await Future.delayed(const Duration(seconds: 3));
                if (mounted) {
                  _handleLogout(context);
                }
              }
            }
          }
        });
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? You can login again once your registration is approved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear encrypted session
      final sessionService = SessionStorageService();
      await sessionService.clearUserSession();
      debugPrint('🔓 Session cleared from secure storage');

      // Clear local storage (backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('registration_status');
      await prefs.remove('user_email');
      await prefs.remove('user_id');
      await prefs.remove('login_status');
      await prefs.remove('user_type');

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to landing page
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/landing', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: const Text(
          'Verification',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: 700,
        child: Center(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: ResponsiveHelper.isMobile(context) ? 100 : 120,
                  height: ResponsiveHelper.isMobile(context) ? 100 : 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFF90D26D),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    size: ResponsiveHelper.isMobile(context) ? 50 : 60,
                    color: const Color(0xFF006876),
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) * 2,
                ),
                Text(
                  'Registration Submitted',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      32,
                    ),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006876),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) * 0.8,
                ),
                Text(
                  'Thank you for registering! Your application is now pending admin review. You will receive an email notification once your registration is approved.',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      18,
                    ),
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) * 2,
                ),
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveSpacing(context) * 1.6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPulsingDot(0),
                          SizedBox(
                            width:
                                ResponsiveHelper.getResponsiveSpacing(context) *
                                0.8,
                          ),
                          _buildPulsingDot(500),
                          SizedBox(
                            width:
                                ResponsiveHelper.getResponsiveSpacing(context) *
                                0.8,
                          ),
                          _buildPulsingDot(1000),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Awaiting admin approval',
                        style: TextStyle(
                          color: Color(0xFF006876),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'You will receive an email notification once verification is complete.',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your email regularly for updates.',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF006876).withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingDot(int delayMillis) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFFF6B35).withValues(alpha: 0.3),
              const Color(0xFFFF6B35),
              value,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {},
    );
  }
}
