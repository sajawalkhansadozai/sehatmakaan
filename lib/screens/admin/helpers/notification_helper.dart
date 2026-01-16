import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for creating notifications
class NotificationHelper {
  static Future<void> createNotification({
    required FirebaseFirestore firestore,
    required String userId,
    required String type,
    required String title,
    required String message,
  }) async {
    await firestore.collection('notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
