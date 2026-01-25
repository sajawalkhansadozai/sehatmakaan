import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sehat_makaan_flutter/shared/firebase_models.dart';

/// Admin Service for Firebase Firestore
/// Handles admin operations for user management and statistics
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get pending users (awaiting approval)
  Stream<List<UserModel>> getPendingUsers() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get approved users
  Stream<List<UserModel>> getApprovedUsers() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all doctors
  Stream<List<UserModel>> getAllDoctors() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get rejected users
  Stream<List<UserModel>> getRejectedUsers() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'rejected')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Approve user
  Future<Map<String, dynamic>> approveUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'approved',
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User approved: $userId');
      return {'success': true, 'message': 'User approved successfully'};
    } catch (e) {
      debugPrint('❌ Approve user error: $e');
      return {
        'success': false,
        'error': 'Failed to approve user. Please try again.',
      };
    }
  }

  /// Reject user
  Future<Map<String, dynamic>> rejectUser({
    required String userId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'rejected',
        'isApproved': false,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User rejected: $userId');
      return {'success': true, 'message': 'User rejected'};
    } catch (e) {
      debugPrint('❌ Reject user error: $e');
      return {
        'success': false,
        'error': 'Failed to reject user. Please try again.',
      };
    }
  }

  /// Delete user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      // Delete user's bookings
      final bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in bookings.docs) {
        await doc.reference.delete();
      }

      // Delete user's subscriptions
      final subscriptions = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in subscriptions.docs) {
        await doc.reference.delete();
      }

      // Delete user's notifications
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      debugPrint('✅ User deleted: $userId');
      return {
        'success': true,
        'message': 'User and all related data deleted successfully',
      };
    } catch (e) {
      debugPrint('❌ Delete user error: $e');
      return {
        'success': false,
        'error': 'Failed to delete user. Please try again.',
      };
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get user error: $e');
      return null;
    }
  }

  /// Update user status
  Future<Map<String, dynamic>> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User status updated: $userId -> $status');
      return {'success': true, 'message': 'User status updated'};
    } catch (e) {
      debugPrint('❌ Update user status error: $e');
      return {'success': false, 'error': 'Failed to update user status.'};
    }
  }

  /// Get admin statistics
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Users statistics
      final allUsers = await _firestore.collection('users').get();
      final pendingUsers = allUsers.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;
      final approvedUsers = allUsers.docs
          .where((doc) => doc.data()['status'] == 'approved')
          .length;

      // Bookings statistics
      final allBookings = await _firestore.collection('bookings').get();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final todayBookings = allBookings.docs.where((doc) {
        final bookingDate = (doc.data()['bookingDate'] as Timestamp).toDate();
        return bookingDate.isAfter(startOfDay) &&
            bookingDate.isBefore(endOfDay);
      }).length;

      final activeBookings = allBookings.docs
          .where((doc) => doc.data()['status'] == 'confirmed')
          .length;

      // Subscriptions statistics
      final allSubscriptions = await _firestore
          .collection('subscriptions')
          .get();
      final activeSubscriptions = allSubscriptions.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;

      // Revenue calculation (from paid subscriptions and bookings)
      double monthlyRevenue = 0;
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in allSubscriptions.docs) {
        final createdAt = doc.data()['createdAt'] as Timestamp?;
        if (createdAt != null && createdAt.toDate().isAfter(firstDayOfMonth)) {
          if (doc.data()['paymentStatus'] == 'paid') {
            monthlyRevenue += (doc.data()['price'] ?? 0).toDouble();
          }
        }
      }

      for (var doc in allBookings.docs) {
        final createdAt = doc.data()['createdAt'] as Timestamp?;
        if (createdAt != null && createdAt.toDate().isAfter(firstDayOfMonth)) {
          if (doc.data()['paymentStatus'] == 'paid') {
            monthlyRevenue += (doc.data()['totalAmount'] ?? 0).toDouble();
          }
        }
      }

      // Workshop statistics
      final allWorkshops = await _firestore.collection('workshops').get();
      final activeWorkshops = allWorkshops.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;

      return {
        'totalDoctors': allUsers.docs.length,
        'pendingDoctors': pendingUsers,
        'approvedDoctors': approvedUsers,
        'todayBookings': todayBookings,
        'activeBookings': activeBookings,
        'totalBookings': allBookings.docs.length,
        'activeSubscriptions': activeSubscriptions,
        'totalSubscriptions': allSubscriptions.docs.length,
        'monthlyRevenue': monthlyRevenue,
        'activeWorkshops': activeWorkshops,
        'totalWorkshops': allWorkshops.docs.length,
      };
    } catch (e) {
      debugPrint('❌ Get admin stats error: $e');
      return {
        'totalDoctors': 0,
        'pendingDoctors': 0,
        'approvedDoctors': 0,
        'todayBookings': 0,
        'activeBookings': 0,
        'totalBookings': 0,
        'activeSubscriptions': 0,
        'totalSubscriptions': 0,
        'monthlyRevenue': 0.0,
        'activeWorkshops': 0,
        'totalWorkshops': 0,
      };
    }
  }

  /// Search users by name, email, or specialty
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final queryLower = query.toLowerCase();

      // Firestore doesn't support full-text search, so we fetch all and filter
      final allUsers = await _firestore.collection('users').get();

      final filteredUsers = allUsers.docs
          .where((doc) {
            final data = doc.data();
            final fullName = (data['fullName'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final specialty = (data['specialty'] ?? '')
                .toString()
                .toLowerCase();

            return fullName.contains(queryLower) ||
                email.contains(queryLower) ||
                specialty.contains(queryLower);
          })
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      return filteredUsers;
    } catch (e) {
      debugPrint('❌ Search users error: $e');
      return [];
    }
  }

  /// Get doctor statistics
  Future<Map<String, dynamic>> getDoctorStats(String userId) async {
    try {
      final bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      final subscriptions = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalBookings': bookings.docs.length,
        'activeBookings': bookings.docs
            .where((doc) => doc.data()['status'] == 'confirmed')
            .length,
        'cancelledBookings': bookings.docs
            .where((doc) => doc.data()['status'] == 'cancelled')
            .length,
        'totalSubscriptions': subscriptions.docs.length,
        'activeSubscriptions': subscriptions.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length,
      };
    } catch (e) {
      debugPrint('❌ Get doctor stats error: $e');
      return {
        'totalBookings': 0,
        'activeBookings': 0,
        'cancelledBookings': 0,
        'totalSubscriptions': 0,
        'activeSubscriptions': 0,
      };
    }
  }

  /// Cancel booking with refund (restore hours/slots to subscription)
  Future<Map<String, dynamic>> cancelBookingWithRefund({
    required String bookingId,
    required bool restoreHours,
  }) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        return {'success': false, 'error': 'Booking not found'};
      }

      final bookingData = bookingDoc.data()!;

      if (bookingData['status'] == 'cancelled') {
        return {'success': false, 'error': 'Booking already cancelled'};
      }

      // Update booking status
      await bookingDoc.reference.update({
        'status': 'cancelled',
        'cancellationType': restoreHours ? 'refund' : 'no-refund',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If refund, restore hours to subscription
      if (restoreHours && bookingData['subscriptionId'] != null) {
        final subscriptionId = bookingData['subscriptionId'] as String;
        final durationMins = (bookingData['durationMins'] ?? 60) as int;
        final durationHours = (durationMins / 60).ceil();

        final subscriptionDoc = await _firestore
            .collection('subscriptions')
            .doc(subscriptionId)
            .get();

        if (subscriptionDoc.exists) {
          final subscriptionData = subscriptionDoc.data()!;
          final subscriptionType = subscriptionData['type'] ?? 'monthly';

          if (subscriptionType == 'monthly') {
            // For monthly subscriptions, decrease hoursUsed and increase remainingHours
            final currentHoursUsed =
                (subscriptionData['hoursUsed'] ?? 0) as int;
            final currentRemainingHours =
                (subscriptionData['remainingHours'] ?? 0) as int;

            await subscriptionDoc.reference.update({
              'hoursUsed': currentHoursUsed > durationHours
                  ? currentHoursUsed - durationHours
                  : 0,
              'remainingHours': currentRemainingHours + durationHours,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else if (subscriptionType == 'hourly') {
            // For hourly subscriptions, restore slots and hours
            final currentSlotsRemaining =
                (subscriptionData['slotsRemaining'] ?? 0) as int;
            final currentRemainingHours =
                (subscriptionData['remainingHours'] ?? 0) as int;
            final currentHoursUsed =
                (subscriptionData['hoursUsed'] ?? 0) as int;

            await subscriptionDoc.reference.update({
              'slotsRemaining': currentSlotsRemaining + 1,
              'remainingHours': currentRemainingHours + durationHours,
              'hoursUsed': currentHoursUsed > durationHours
                  ? currentHoursUsed - durationHours
                  : 0,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Create notification for the user
      final userId = bookingData['userId'] as String;
      final suiteType = bookingData['suiteType'] as String;
      final bookingDate = (bookingData['bookingDate'] as Timestamp).toDate();
      final dateStr =
          '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';

      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'booking_cancelled',
        'title': restoreHours
            ? 'Booking Cancelled with Refund'
            : 'Booking Cancelled',
        'message': restoreHours
            ? 'Your booking for $suiteType suite on $dateStr has been cancelled by admin. Hours/slots have been restored to your package.'
            : 'Your booking for $suiteType suite on $dateStr has been cancelled by admin. Package hours/slots were not restored.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '✅ Booking cancelled ${restoreHours ? "with" : "without"} refund: $bookingId',
      );
      return {
        'success': true,
        'message': restoreHours
            ? 'Booking cancelled - hours/slots restored'
            : 'Booking cancelled - hours/slots not restored',
      };
    } catch (e) {
      debugPrint('❌ Cancel booking with refund error: $e');
      return {
        'success': false,
        'error': 'Failed to cancel booking. Please try again.',
      };
    }
  }

  /// Get live bookings stream (real-time updates for admin)
  Stream<List<BookingModel>> getLiveBookings({DateTime? lastUpdate}) {
    Query query = _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true);

    if (lastUpdate != null) {
      query = query.where(
        'createdAt',
        isGreaterThan: Timestamp.fromDate(lastUpdate),
      );
    }

    return query.limit(50).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get all bookings (admin view with filters)
  Stream<List<BookingModel>> getAllBookings({
    DateTime? date,
    String? suiteType,
  }) {
    Query query = _firestore
        .collection('bookings')
        .orderBy('bookingDate', descending: true);

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      query = query
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'bookingDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          );
    }

    if (suiteType != null && suiteType.isNotEmpty) {
      query = query.where('suiteType', isEqualTo: suiteType);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }
}
