import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';

/// Subscription Service for Firebase Firestore
/// Handles monthly and hourly subscription packages
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create new subscription
  Future<Map<String, dynamic>> createSubscription({
    required String userId,
    required String suiteType,
    required String packageType,
    required double price,
    required int hours,
    required String type, // 'monthly' or 'hourly'
    String? specialty,
    String? roomType,
    String? details,
    String paymentMethod = 'payfast',
    String? paymentId,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = type == 'monthly'
          ? DateTime(now.year, now.month + 1, now.day)
          : DateTime(now.year, now.month, now.day + 30); // 30 days for hourly

      final subscriptionRef = await _firestore.collection('subscriptions').add({
        'userId': userId,
        'suiteType': suiteType,
        'packageType': packageType,
        'price': price,
        'hours': hours,
        'hoursUsed': 0,
        'remainingHours': hours,
        'remainingMinutes':
            0, // For tracking fractional hours (Extended Hours addon)
        'slotsRemaining': type == 'monthly' ? hours : 0,
        'type': type,
        'specialty': specialty,
        'roomType': roomType,
        'details': details,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'isActive': true,
        'status': 'active',
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentId != null ? 'paid' : 'pending',
        'paymentId': paymentId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Subscription created: ${subscriptionRef.id}');
      return {
        'success': true,
        'subscriptionId': subscriptionRef.id,
        'message': 'Subscription created successfully',
      };
    } catch (e) {
      debugPrint('❌ Create subscription error: $e');
      return {
        'success': false,
        'error': 'Failed to create subscription. Please try again.',
      };
    }
  }

  /// Get user subscriptions
  Stream<List<SubscriptionModel>> getUserSubscriptions(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SubscriptionModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get active subscriptions for user
  Stream<List<SubscriptionModel>> getActiveSubscriptions(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SubscriptionModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get subscription by ID
  Future<SubscriptionModel?> getSubscriptionById(String subscriptionId) async {
    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();
      if (doc.exists) {
        return SubscriptionModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get subscription error: $e');
      return null;
    }
  }

  /// Update subscription hours used
  Future<Map<String, dynamic>> updateHoursUsed({
    required String subscriptionId,
    required int hoursToDeduct,
  }) async {
    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();
      if (!doc.exists) {
        return {'success': false, 'error': 'Subscription not found'};
      }

      final data = doc.data()!;
      final hoursUsed = (data['hoursUsed'] ?? 0) + hoursToDeduct;
      final hours = data['hours'] ?? 0;
      final remainingHours = hours - hoursUsed;

      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'hoursUsed': hoursUsed,
        'remainingHours': remainingHours,
        'slotsRemaining': data['type'] == 'monthly'
            ? remainingHours
            : data['slotsRemaining'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If no hours remaining, deactivate subscription
      if (remainingHours <= 0) {
        await deactivateSubscription(subscriptionId);
      }

      debugPrint('✅ Subscription hours updated: $subscriptionId');
      return {
        'success': true,
        'remainingHours': remainingHours,
        'message': 'Hours updated successfully',
      };
    } catch (e) {
      debugPrint('❌ Update hours error: $e');
      return {'success': false, 'error': 'Failed to update hours.'};
    }
  }

  /// Deactivate subscription
  Future<Map<String, dynamic>> deactivateSubscription(
    String subscriptionId,
  ) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'isActive': false,
        'status': 'expired',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Subscription deactivated: $subscriptionId');
      return {'success': true, 'message': 'Subscription deactivated'};
    } catch (e) {
      debugPrint('❌ Deactivate subscription error: $e');
      return {'success': false, 'error': 'Failed to deactivate subscription.'};
    }
  }

  /// Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'isActive': false,
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Subscription cancelled: $subscriptionId');
      return {
        'success': true,
        'message': 'Subscription cancelled successfully',
      };
    } catch (e) {
      debugPrint('❌ Cancel subscription error: $e');
      return {'success': false, 'error': 'Failed to cancel subscription.'};
    }
  }

  /// Update payment status
  Future<Map<String, dynamic>> updatePaymentStatus({
    required String subscriptionId,
    required String paymentStatus,
    String? paymentId,
  }) async {
    try {
      final updates = {
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (paymentId != null) {
        updates['paymentId'] = paymentId;
      }

      await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .update(updates);

      debugPrint('✅ Payment status updated: $subscriptionId -> $paymentStatus');
      return {'success': true, 'message': 'Payment status updated'};
    } catch (e) {
      debugPrint('❌ Update payment status error: $e');
      return {'success': false, 'error': 'Failed to update payment status.'};
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final query = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Check active subscription error: $e');
      return false;
    }
  }

  /// Get subscription statistics
  Future<Map<String, dynamic>> getSubscriptionStats(String userId) async {
    try {
      final subscriptions = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      int total = subscriptions.docs.length;
      int active = subscriptions.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;
      int expired = subscriptions.docs
          .where((doc) => doc.data()['status'] == 'expired')
          .length;

      int totalHours = 0;
      int usedHours = 0;

      for (var doc in subscriptions.docs) {
        totalHours += (doc.data()['hours'] ?? 0) as int;
        usedHours += (doc.data()['hoursUsed'] ?? 0) as int;
      }

      return {
        'total': total,
        'active': active,
        'expired': expired,
        'totalHours': totalHours,
        'usedHours': usedHours,
        'remainingHours': totalHours - usedHours,
      };
    } catch (e) {
      debugPrint('❌ Get subscription stats error: $e');
      return {
        'total': 0,
        'active': 0,
        'expired': 0,
        'totalHours': 0,
        'usedHours': 0,
        'remainingHours': 0,
      };
    }
  }

  /// Auto-expire subscriptions past end date
  Future<void> expireOldSubscriptions() async {
    try {
      final now = Timestamp.now();
      final query = await _firestore
          .collection('subscriptions')
          .where('isActive', isEqualTo: true)
          .where('endDate', isLessThan: now)
          .get();

      for (var doc in query.docs) {
        await doc.reference.update({
          'isActive': false,
          'status': 'expired',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Auto-expired subscription: ${doc.id}');
      }
    } catch (e) {
      debugPrint('❌ Auto-expire subscriptions error: $e');
    }
  }
}
