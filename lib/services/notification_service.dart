import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Notification Service
/// Handles all notification operations including CRUD
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new notification
  Future<String> createNotification({
    required int userId,
    required String title,
    required String message,
    required String type,
    int? relatedBookingId,
  }) async {
    try {
      final docRef = await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'relatedBookingId': relatedBookingId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
      rethrow;
    }
  }

  /// Get all notifications for a user
  Stream<List<Map<String, dynamic>>> getNotifications(int userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  /// Get unread notifications for a user
  Stream<List<Map<String, dynamic>>> getUnreadNotifications(int userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  /// Get unread notification count
  Stream<int> getUnreadCount(int userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      debugPrint('✅ Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(int userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      debugPrint('✅ Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  /// Delete multiple notifications
  Future<void> deleteNotifications(List<String> notificationIds) async {
    try {
      final batch = _firestore.batch();

      for (var id in notificationIds) {
        batch.delete(_firestore.collection('notifications').doc(id));
      }

      await batch.commit();
      debugPrint('✅ ${notificationIds.length} notifications deleted');
    } catch (e) {
      debugPrint('❌ Error deleting notifications: $e');
      rethrow;
    }
  }

  /// Delete all read notifications for a user
  Future<void> deleteReadNotifications(int userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ All read notifications deleted for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting read notifications: $e');
      rethrow;
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(int userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ All notifications deleted for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting all notifications: $e');
      rethrow;
    }
  }

  /// Delete old notifications (older than specified days)
  Future<void> deleteOldNotifications(int userId, int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint(
        '✅ Old notifications (>$daysOld days) deleted for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ Error deleting old notifications: $e');
      rethrow;
    }
  }

  /// Get notification by ID
  Future<Map<String, dynamic>?> getNotification(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting notification: $e');
      rethrow;
    }
  }
}
