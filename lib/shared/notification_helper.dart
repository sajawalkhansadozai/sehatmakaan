/// Notification Helper - Easy to use push notification functions
import 'package:flutter/foundation.dart';
import 'fcm_service.dart';

/// Global FCM Service instance for easy access
final fcmService = FCMService();

/// Notification Helper Class
/// Provides convenience methods for sending different types of notifications
class NotificationHelper {
  static final FCMService _fcmService = FCMService();

  /// Send booking cancelled notification
  static Future<bool> sendBookingCancelledNotification({
    required String userId,
    required String bookingDate,
    required String specialty,
    String? refundAmount,
  }) async {
    final message = refundAmount != null
        ? 'Your booking for $specialty on $bookingDate has been cancelled. $refundAmount refunded.'
        : 'Your booking for $specialty on $bookingDate has been cancelled.';

    return await _fcmService.pushNotification(
      userId: userId,
      title: '❌ Booking Cancelled',
      message: message,
      type: 'booking_cancelled',
      data: {
        'bookingDate': bookingDate,
        'specialty': specialty,
        'refundAmount': refundAmount ?? 'No refund',
      },
    );
  }

  /// Send booking confirmed notification
  static Future<bool> sendBookingConfirmedNotification({
    required String userId,
    required String bookingDate,
    required String timeSlot,
    required String specialty,
    String? bookingId,
  }) async {
    return await _fcmService.pushNotification(
      userId: userId,
      title: '✅ Booking Confirmed',
      message:
          'Your booking for $specialty on $bookingDate at $timeSlot is confirmed!',
      type: 'booking_confirmed',
      data: {
        'bookingId': bookingId ?? '',
        'bookingDate': bookingDate,
        'timeSlot': timeSlot,
        'specialty': specialty,
      },
    );
  }

  /// Send subscription expiry warning
  static Future<bool> sendSubscriptionExpiryWarning({
    required String userId,
    required String subscriptionType,
    required int daysRemaining,
    String? subscriptionId,
  }) async {
    final title = daysRemaining == 1
        ? '⚠️ Subscription Expires Tomorrow!'
        : '⏰ Subscription Expiring Soon';

    final message = daysRemaining == 1
        ? 'Your $subscriptionType subscription expires tomorrow. Renew now!'
        : 'Your $subscriptionType subscription expires in $daysRemaining days. Renew to avoid losing your benefits!';

    return await _fcmService.pushNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'subscription_expiry_warning',
      data: {
        'subscriptionId': subscriptionId ?? '',
        'subscriptionType': subscriptionType,
        'daysRemaining': daysRemaining.toString(),
      },
    );
  }

  /// Send workshop notification
  static Future<bool> sendWorkshopNotification({
    required String userId,
    required String workshopTitle,
    String? message,
    String? workshopId,
  }) async {
    return await _fcmService.pushNotification(
      userId: userId,
      title: '📚 Workshop Update',
      message: message ?? 'Check out: $workshopTitle',
      type: 'workshop_notification',
      data: {'workshopId': workshopId ?? '', 'workshopTitle': workshopTitle},
    );
  }

  /// Send system notification to multiple users
  static Future<bool> sendSystemNotification({
    required List<String> userIds,
    required String title,
    required String message,
    String? type,
  }) async {
    return await _fcmService.pushBulkNotification(
      userIds: userIds,
      title: title,
      message: message,
      type: type ?? 'system_notification',
    );
  }

  /// Send announcement to all users (via topic)
  static Future<bool> sendAnnouncement({
    required String title,
    required String message,
    String? topic = 'all_users',
  }) async {
    return await _fcmService.pushTopicNotification(
      topic: topic ?? 'all_users',
      title: title,
      message: message,
      type: 'announcement',
    );
  }

  /// Send maintenance notification
  static Future<bool> sendMaintenanceNotification({
    required String maintenanceTime,
    String? duration,
  }) async {
    return await _fcmService.pushTopicNotification(
      topic: 'all_users',
      title: '🔧 Scheduled Maintenance',
      message:
          'App maintenance scheduled at $maintenanceTime. ${duration != null ? 'Expected duration: $duration' : ''}',
      type: 'maintenance_notification',
    );
  }

  /// Send payment success notification
  static Future<bool> sendPaymentSuccessNotification({
    required String userId,
    required String amount,
    String? orderId,
  }) async {
    return await _fcmService.pushNotification(
      userId: userId,
      title: '✅ Payment Successful',
      message: 'Payment of $amount completed successfully.',
      type: 'payment_success',
      data: {'orderId': orderId ?? '', 'amount': amount},
    );
  }

  /// Send payment failed notification
  static Future<bool> sendPaymentFailedNotification({
    required String userId,
    required String amount,
    String? reason,
  }) async {
    return await _fcmService.pushNotification(
      userId: userId,
      title: '❌ Payment Failed',
      message: 'Payment of $amount failed. ${reason ?? 'Please try again.'}',
      type: 'payment_failed',
      data: {'amount': amount, 'reason': reason ?? 'Unknown'},
    );
  }

  /// Send welcome notification for new user
  static Future<bool> sendWelcomeNotification({
    required String userId,
    required String userName,
  }) async {
    return await _fcmService.pushNotification(
      userId: userId,
      title: '👋 Welcome to Sehat Makaan!',
      message: 'Hi $userName! Welcome to our platform. Start exploring today.',
      type: 'welcome',
      data: {'userName': userName},
    );
  }

  /// Send approval notification
  static Future<bool> sendApprovalNotification({
    required String userId,
    required String approvalType,
    required bool approved,
  }) async {
    final title = approved ? '✅ Approved!' : '❌ Not Approved';
    final message = approved
        ? 'Your $approvalType request has been approved!'
        : 'Your $approvalType request was not approved. Please try again.';

    return await _fcmService.pushNotification(
      userId: userId,
      title: title,
      message: message,
      type: approved ? 'approval_accepted' : 'approval_rejected',
      data: {'approvalType': approvalType, 'approved': approved.toString()},
    );
  }

  /// Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return _fcmService.getNotificationCount(userId);
  }

  /// Get all user notifications
  static Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _fcmService.getUserNotifications(userId);
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) {
    return _fcmService.markAsRead(notificationId);
  }

  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) {
    return _fcmService.deleteNotification(notificationId);
  }

  /// Clear all notifications for user
  static Future<bool> clearAll(String userId) {
    return _fcmService.clearAllNotifications(userId);
  }
}

/// Quick notification sender for testing/admin purposes
class QuickNotification {
  /// Send test notification to verify FCM is working
  static Future<bool> sendTest(String userId) {
    return NotificationHelper.sendWelcomeNotification(
      userId: userId,
      userName: 'Test User',
    );
  }

  /// Debug: Print all functions available
  static void printAvailableFunctions() {
    debugPrint('''
╔════════════════════════════════════════════════════════════╗
║         AVAILABLE NOTIFICATION FUNCTIONS                   ║
╠════════════════════════════════════════════════════════════╣
║ 1. sendBookingCancelledNotification()                       ║
║ 2. sendBookingConfirmedNotification()                       ║
║ 3. sendSubscriptionExpiryWarning()                          ║
║ 4. sendWorkshopNotification()                               ║
║ 5. sendSystemNotification() - Multiple users                ║
║ 6. sendAnnouncement() - All users                           ║
║ 7. sendMaintenanceNotification()                            ║
║ 8. sendPaymentSuccessNotification()                         ║
║ 9. sendPaymentFailedNotification()                          ║
║ 10. sendWelcomeNotification()                               ║
║ 11. sendApprovalNotification()                              ║
║ 12. getUnreadCount() - Stream<int>                          ║
║ 13. getNotifications() - Stream<List>                       ║
║ 14. markAsRead()                                            ║
║ 15. deleteNotification()                                    ║
║ 16. clearAll()                                              ║
╚════════════════════════════════════════════════════════════╝
''');
  }
}
