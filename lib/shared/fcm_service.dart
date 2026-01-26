import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Global handler for background messages (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [BACKGROUND/KILLED STATE] Message received');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');

  // Message is automatically shown as notification on Android/iOS
  // by Firebase when in background/killed state
}

/// FCM Push Notification Service
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request permissions
  /// This MUST be called BEFORE any notification can be received
  Future<void> initialize(String userId) async {
    try {
      debugPrint('🚀 [FCM] Initializing FCM Service for user: $userId');

      // STEP 1: Register background message handler (MUST be done first)
      // This handler runs even when app is terminated/killed
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      debugPrint('✅ [FCM] Background message handler registered');

      // Skip token operations on web
      if (kIsWeb) {
        debugPrint('⚠️ [FCM] Token operations skipped on web platform');
        _setupMessageHandlers();
        return;
      }

      // STEP 2: Request permissions (iOS specific)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ [FCM] User granted FCM permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('✅ [FCM] User granted provisional FCM permission');
      } else {
        debugPrint('⚠️ [FCM] User declined FCM permission');
        // Don't return - app will still receive notifications on Android
      }

      // STEP 3: Get and save FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(userId, token);
        debugPrint('✅ [FCM] Token saved: ${token.substring(0, 20)}...');
      } else {
        debugPrint('⚠️ [FCM] Could not get FCM token');
      }

      // STEP 4: Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveFCMToken(userId, newToken);
        debugPrint('✅ [FCM] Token refreshed: ${newToken.substring(0, 20)}...');
      });

      // STEP 5: Setup message handlers for foreground/background
      _setupMessageHandlers();

      debugPrint('✅ [FCM] Initialization completed successfully');
    } catch (e) {
      debugPrint('❌ [FCM] Error during initialization: $e');
    }
  }

  /// Save FCM token to Firestore with retry logic
  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'fcmTokenStatus': 'active',
      });
      debugPrint('✅ [FCM] Token saved to Firestore for user: $userId');
    } catch (e) {
      debugPrint('❌ [FCM] Error saving token: $e');
      // Retry once if failed
      try {
        await Future.delayed(const Duration(seconds: 1));
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [FCM] Token saved (retry successful)');
      } catch (retryError) {
        debugPrint('❌ [FCM] Token save failed even after retry: $retryError');
      }
    }
  }

  /// Remove FCM token on logout
  Future<void> removeFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenStatus': 'inactive',
      });
      debugPrint('✅ [FCM] Token removed for user: $userId');
    } catch (e) {
      debugPrint('❌ [FCM] Error removing token: $e');
    }
  }

  /// Setup foreground and background message handlers
  void _setupMessageHandlers() {
    // 1️⃣ FOREGROUND MESSAGE HANDLER
    // App is open and in focus - notification appears as overlay
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('');
      debugPrint('═════════════════════════════════════════');
      debugPrint('📱 [FOREGROUND] Notification received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Type: ${message.data['type']}');
      debugPrint('═════════════════════════════════════════');
      debugPrint('');

      // On iOS: notification shown automatically
      // On Android: Firebase shows as system notification with sound

      // You can also trigger custom UI actions here
      _handleNotificationReceived(message.data);
    });

    // 2️⃣ BACKGROUND MESSAGE HANDLER (App in background)
    // This listens when user taps notification while app is backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('');
      debugPrint('═════════════════════════════════════════');
      debugPrint('📲 [BACKGROUND] Notification tapped');
      debugPrint('Type: ${message.data['type']}');
      debugPrint('Data: ${message.data}');
      debugPrint('═════════════════════════════════════════');
      debugPrint('');

      // App is now brought to foreground
      // Navigate to appropriate screen
      _handleNotificationTap(message.data);
    });

    // 3️⃣ TERMINATED/KILLED STATE HANDLER
    // App was completely closed - check for pending notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('');
        debugPrint('═════════════════════════════════════════');
        debugPrint('💀 [TERMINATED] App launched from notification');
        debugPrint('Type: ${message.data['type']}');
        debugPrint('Data: ${message.data}');
        debugPrint('═════════════════════════════════════════');
        debugPrint('');

        // App is being cold-started from killed state
        // This message was tapped while app was closed
        _handleNotificationTap(message.data);
      }
    });

    debugPrint('✅ [FCM] All message handlers registered');
  }

  /// Handle notification received (show alert or toast)
  void _handleNotificationReceived(Map<String, dynamic> data) {
    final type = data['type'] ?? 'unknown';
    debugPrint('🔔 [HANDLER] Processing notification type: $type');

    // You can update app state, show dialogs, etc here
    // Example: update notification badge, refresh list, etc
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] ?? 'unknown';
    final bookingId = data['bookingId'];
    final subscriptionId = data['subscriptionId'];

    debugPrint('🔗 [NAVIGATION] Handling tap for type: $type');
    debugPrint('   - bookingId: $bookingId');
    debugPrint('   - subscriptionId: $subscriptionId');

    // Route based on notification type
    switch (type) {
      case 'booking_cancelled':
      case 'booking_confirmed':
      case 'booking_completed':
      case 'admin_booking_cancellation':
        if (bookingId != null) {
          debugPrint('   ➜ Navigate to booking details: $bookingId');
          // NavigationService.navigateTo('/booking-details', args: bookingId);
        }
        break;

      case 'subscription_expiry_warning':
        if (subscriptionId != null) {
          debugPrint('   ➜ Navigate to subscriptions: $subscriptionId');
          // NavigationService.navigateTo('/subscriptions', args: subscriptionId);
        }
        break;

      case 'workshop_notification':
        debugPrint('   ➜ Navigate to workshops');
        // NavigationService.navigateTo('/workshops');
        break;

      default:
        debugPrint('   ➜ Unknown notification type, staying on current screen');
    }
  }

  /// Subscribe to topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) {
      debugPrint('⚠️ [FCM] Topic subscription skipped on web: $topic');
      return;
    }

    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ [FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ [FCM] Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) {
      debugPrint('⚠️ [FCM] Topic unsubscription skipped on web: $topic');
      return;
    }

    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ [FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ [FCM] Error unsubscribing from topic $topic: $e');
    }
  }

  /// PUSH NOTIFICATION FUNCTION - Send notifications via Cloud Functions
  /// This triggers notifications from Firestore which are then sent via Cloud Functions
  ///
  /// Usage Example:
  /// ```dart
  /// await fcmService.pushNotification(
  ///   userId: 'user123',
  ///   title: 'Booking Cancelled',
  ///   message: 'Your booking has been cancelled',
  ///   type: 'booking_cancelled',
  ///   data: {'bookingId': 'booking456'},
  /// );
  /// ```
  Future<bool> pushNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('');
      debugPrint('═════════════════════════════════════════');
      debugPrint('📤 [PUSH] Sending notification');
      debugPrint('User: $userId');
      debugPrint('Title: $title');
      debugPrint('Type: $type');
      debugPrint('═════════════════════════════════════════');

      // Create notification document in Firestore
      // Cloud Functions will read this and send via FCM
      final notificationRef = _firestore.collection('notifications').doc();

      await notificationRef.set({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending_send', // Cloud Function will change this to 'sent'
      });

      debugPrint('✅ [PUSH] Notification created in Firestore');
      debugPrint('Document ID: ${notificationRef.id}');
      return true;
    } catch (e) {
      debugPrint('❌ [PUSH] Error creating notification: $e');
      return false;
    }
  }

  /// BULK PUSH NOTIFICATION - Send to multiple users
  ///
  /// Usage Example:
  /// ```dart
  /// await fcmService.pushBulkNotification(
  ///   userIds: ['user1', 'user2', 'user3'],
  ///   title: 'System Update',
  ///   message: 'App maintenance scheduled',
  ///   type: 'system_notification',
  /// );
  /// ```
  Future<bool> pushBulkNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('');
      debugPrint('═════════════════════════════════════════');
      debugPrint('📤 [BULK PUSH] Sending to ${userIds.length} users');
      debugPrint('Title: $title');
      debugPrint('Type: $type');
      debugPrint('═════════════════════════════════════════');

      // Use batch write for efficiency
      final batch = _firestore.batch();

      for (final userId in userIds) {
        final notificationRef = _firestore.collection('notifications').doc();

        batch.set(notificationRef, {
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
          'data': data ?? {},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending_send',
        });
      }

      await batch.commit();
      debugPrint('✅ [BULK PUSH] ${userIds.length} notifications created');
      return true;
    } catch (e) {
      debugPrint('❌ [BULK PUSH] Error creating notifications: $e');
      return false;
    }
  }

  /// TOPIC NOTIFICATION - Send to users subscribed to a topic
  ///
  /// Usage Example:
  /// ```dart
  /// await fcmService.pushTopicNotification(
  ///   topic: 'all_users',
  ///   title: 'New Workshop Available',
  ///   message: 'Check out our latest workshop',
  ///   type: 'workshop_available',
  /// );
  /// ```
  Future<bool> pushTopicNotification({
    required String topic,
    required String title,
    required String message,
    required String type,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('');
      debugPrint('═════════════════════════════════════════');
      debugPrint('📢 [TOPIC PUSH] Sending to topic: $topic');
      debugPrint('Title: $title');
      debugPrint('Type: $type');
      debugPrint('═════════════════════════════════════════');

      // Create a topic notification document
      // Cloud Functions can read topic and send to all subscribed users
      final notificationRef = _firestore
          .collection('topic_notifications')
          .doc();

      await notificationRef.set({
        'topic': topic,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending_send',
      });

      debugPrint('✅ [TOPIC PUSH] Topic notification created');
      debugPrint('Document ID: ${notificationRef.id}');
      return true;
    } catch (e) {
      debugPrint('❌ [TOPIC PUSH] Error creating topic notification: $e');
      return false;
    }
  }

  /// DIRECT FCM SEND - For admin/testing purposes
  /// Requires running Cloud Function that processes pending notifications
  ///
  /// Usage Example:
  /// ```dart
  /// await fcmService.sendDirectFCM(
  ///   fcmToken: 'device_token',
  ///   title: 'Test Notification',
  ///   message: 'This is a test',
  ///   type: 'test',
  /// );
  /// ```
  Future<bool> sendDirectFCM({
    required String fcmToken,
    required String title,
    required String message,
    required String type,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('');
      debugPrint('═════════════════════════════════════════');
      debugPrint('🔥 [DIRECT FCM] Sending directly');
      debugPrint('Title: $title');
      debugPrint('Type: $type');
      debugPrint('═════════════════════════════════════════');

      // Create a direct send request document
      // Cloud Function will read and send immediately
      final directSendRef = _firestore.collection('fcm_direct_sends').doc();

      await directSendRef.set({
        'token': fcmToken,
        'notification': {'title': title, 'body': message},
        'data': {
          'type': type,
          ...?data,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('✅ [DIRECT FCM] Direct send request created');
      return true;
    } catch (e) {
      debugPrint('❌ [DIRECT FCM] Error creating direct send: $e');
      return false;
    }
  }

  /// Get notification count for user
  Stream<int> getNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get all notifications for user
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [NOTIFICATION] Marked as read: $notificationId');
      return true;
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Error marking as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      debugPrint('✅ [NOTIFICATION] Deleted: $notificationId');
      return true;
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Error deleting: $e');
      return false;
    }
  }

  /// Clear all notifications for user
  Future<bool> clearAllNotifications(String userId) async {
    try {
      final docs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint(
        '✅ [NOTIFICATION] Cleared ${docs.docs.length} notifications for user: $userId',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Error clearing notifications: $e');
      return false;
    }
  }
}
