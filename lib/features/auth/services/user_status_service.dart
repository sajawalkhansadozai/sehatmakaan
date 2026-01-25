import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sehat_makaan_flutter/shared/fcm_service.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';

/// Service to monitor user status in real-time
/// Automatically logs out user if account is suspended/deactivated
class UserStatusService {
  static StreamSubscription<DocumentSnapshot>? _statusSubscription;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Start monitoring user status
  /// Call this after successful login
  static Future<void> startMonitoring(
    BuildContext context,
    String userId,
  ) async {
    // Cancel any existing subscription
    await stopMonitoring();

    debugPrint('👀 Starting user status monitoring for: $userId');

    _statusSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) async {
            if (!snapshot.exists) {
              debugPrint('❌ User document deleted - Logging out');
              await _handleAccountIssue(
                context,
                'Account Deleted',
                'Your account has been deleted.',
              );
              return;
            }

            final data = snapshot.data();
            if (data == null) return;

            final status = data['status'] as String?;
            final isActive = data['isActive'] as bool? ?? false;

            debugPrint('📊 User Status Update: $status, isActive: $isActive');

            // Check if account is suspended
            if (status == 'suspended') {
              debugPrint('⛔ ACCOUNT SUSPENDED - Forcing logout');
              await _handleSuspension(context);
              return;
            }

            // Check if account is rejected
            if (status == 'rejected') {
              debugPrint('⛔ ACCOUNT REJECTED - Forcing logout');
              await _handleAccountIssue(
                context,
                'Account Rejected',
                'Your account has been rejected. Contact support for details.',
              );
              return;
            }

            // Check if account is deactivated
            if (!isActive) {
              debugPrint('⛔ ACCOUNT DEACTIVATED - Forcing logout');
              await _handleAccountIssue(
                context,
                'Account Deactivated',
                'Your account has been deactivated. Contact admin.',
              );
              return;
            }

            // Check if approval was revoked
            if (status != 'approved') {
              debugPrint('⚠️ APPROVAL REVOKED - Forcing logout');
              await _handleAccountIssue(
                context,
                'Account Status Changed',
                'Your account approval has been revoked.',
              );
              return;
            }
          },
          onError: (error) {
            debugPrint('❌ Error monitoring user status: $error');
          },
        );
  }

  /// Handle account suspension
  static Future<void> _handleSuspension(BuildContext context) async {
    // Stop monitoring
    await stopMonitoring();

    // Remove FCM token
    final user = _auth.currentUser;
    if (user != null) {
      final fcmService = FCMService();
      await fcmService.removeFCMToken(user.uid);
    }

    // Clear session
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Sign out from Firebase
    await _auth.signOut();

    // Navigate to suspension page
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/account-suspended',
        (route) => false,
        arguments: 'Terms and Conditions Violation',
      );
    }
  }

  /// Handle other account issues (deleted, rejected, deactivated)
  static Future<void> _handleAccountIssue(
    BuildContext context,
    String title,
    String message,
  ) async {
    // Stop monitoring
    await stopMonitoring();

    // Remove FCM token
    final user = _auth.currentUser;
    if (user != null) {
      final fcmService = FCMService();
      await fcmService.removeFCMToken(user.uid);
    }

    // Clear session
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Sign out from Firebase
    await _auth.signOut();

    // Navigate to landing page with message
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/landing', (route) => false);

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$title: $message',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: ResponsiveHelper.getResponsivePadding(context),
        ),
      );
    }
  }

  /// Stop monitoring user status
  /// Call this on logout
  static Future<void> stopMonitoring() async {
    if (_statusSubscription != null) {
      debugPrint('🛑 Stopping user status monitoring');
      await _statusSubscription!.cancel();
      _statusSubscription = null;
    }
  }
}
