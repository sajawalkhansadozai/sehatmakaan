import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for email queue management
/// Emails are queued in Firestore and processed by Cloud Functions
class EmailQueueHelper {
  static Future<void> queueEmail({
    required FirebaseFirestore firestore,
    required String to,
    required String subject,
    required String htmlContent,
    Map<String, dynamic>? data,
    String? userId, // Optional: to check user's email preferences
  }) async {
    // Check user's email notification settings if userId provided
    if (userId != null) {
      try {
        final userDoc = await firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final emailNotifications = userData?['emailNotifications'] ?? true;

          // If user has disabled email notifications, skip sending
          if (!emailNotifications) {
            debugPrint(
              '📧 Email skipped: User $userId has disabled email notifications',
            );
            return;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error checking email preferences for $userId: $e');
        // Continue sending email if check fails (fail-safe approach)
      }
    }

    await firestore.collection('email_queue').add({
      'to': to,
      'subject': subject,
      'html': htmlContent,
      'data': data ?? {},
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'attempts': 0,
    });
  }
}
