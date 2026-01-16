import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM Push Notification Service
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request permissions
  Future<void> initialize(String userId) async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted FCM permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('✅ User granted provisional FCM permission');
      } else {
        debugPrint('⚠️ User declined FCM permission');
        return;
      }

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(userId, token);
        debugPrint('✅ FCM token saved: ${token.substring(0, 20)}...');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveFCMToken(userId, newToken);
        debugPrint('✅ FCM token refreshed');
      });

      // Setup message handlers
      _setupMessageHandlers();
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Remove FCM token on logout
  Future<void> removeFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      debugPrint('✅ FCM token removed for user $userId');
    } catch (e) {
      debugPrint('❌ Error removing FCM token: $e');
    }
  }

  /// Setup foreground and background message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground message received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // You can show a local notification here if needed
      // Or update UI directly
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 Notification tapped (background)');
      debugPrint('Data: ${message.data}');

      // Navigate to specific screen based on notification type
      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app was terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📩 Notification tapped (terminated)');
        debugPrint('Data: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final bookingId = data['bookingId'];

    debugPrint('Handling notification: type=$type, bookingId=$bookingId');

    // You can use a navigation service or global key to navigate
    // Example: NavigationService.navigateTo('/booking-details', args: bookingId);
  }

  /// Subscribe to topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}
