import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Booking Cancellation Service
/// Handles booking cancellations with refund/no-refund logic
class BookingCancellationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cancel booking WITH hour refund (restore hours to subscription)
  Future<Map<String, dynamic>> cancelWithRefund({
    required String bookingId,
    required String reason,
    String? adminNotes,
  }) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final subscriptionId = bookingData['subscriptionId'] as String?;
      final hoursBooked = bookingData['hours'] as int? ?? 1;

      // Start batch operation
      final batch = _firestore.batch();

      // Update booking status
      batch.update(bookingDoc.reference, {
        'status': 'cancelled',
        'cancellationType': 'refund',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'admin',
        'adminNotes': adminNotes,
      });

      // Restore hours to subscription if exists
      if (subscriptionId != null) {
        final subscriptionDoc = _firestore
            .collection('subscriptions')
            .doc(subscriptionId);

        final subscription = await subscriptionDoc.get();
        if (subscription.exists) {
          final subscriptionData = subscription.data()!;
          final type = subscriptionData['type'] as String?;

          if (type == 'hourly') {
            // For hourly: restore slots_remaining
            final slotsRemaining =
                subscriptionData['slotsRemaining'] as int? ?? 0;
            batch.update(subscriptionDoc, {
              'slotsRemaining': slotsRemaining + 1,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else if (type == 'monthly') {
            // For monthly: restore hours_used and remaining_hours
            final hoursUsed = subscriptionData['hoursUsed'] as int? ?? 0;
            final hoursIncluded =
                subscriptionData['hoursIncluded'] as int? ?? 0;
            final newHoursUsed = (hoursUsed - hoursBooked).clamp(
              0,
              hoursIncluded,
            );
            final remainingHours = hoursIncluded - newHoursUsed;

            batch.update(subscriptionDoc, {
              'hoursUsed': newHoursUsed,
              'remainingHours': remainingHours,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Create notification for user
      final userId = bookingData['userId'] as int;
      batch.set(_firestore.collection('notifications').doc(), {
        'userId': userId,
        'title': 'Booking Cancelled with Refund',
        'message':
            'Your booking has been cancelled and hours have been refunded to your subscription. Reason: $reason',
        'type': 'booking_refunded',
        'relatedBookingId': bookingId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

      debugPrint('✅ Booking cancelled with refund: $bookingId');

      return {
        'success': true,
        'message': 'Booking cancelled successfully with hour refund',
        'hoursRefunded': hoursBooked,
        'cancellationType': 'refund',
      };
    } catch (e) {
      debugPrint('❌ Error cancelling booking with refund: $e');
      return {
        'success': false,
        'message': 'Failed to cancel booking: ${e.toString()}',
      };
    }
  }

  /// Cancel booking WITHOUT refund (no hours restored)
  Future<Map<String, dynamic>> cancelWithoutRefund({
    required String bookingId,
    required String reason,
    String? adminNotes,
  }) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;

      // Start batch operation
      final batch = _firestore.batch();

      // Update booking status (no hours refunded)
      batch.update(bookingDoc.reference, {
        'status': 'cancelled',
        'cancellationType': 'no_refund',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'admin',
        'adminNotes': adminNotes,
      });

      // Create notification for user
      final userId = bookingData['userId'] as int;
      batch.set(_firestore.collection('notifications').doc(), {
        'userId': userId,
        'title': 'Booking Cancelled',
        'message':
            'Your booking has been cancelled. Reason: $reason. Note: Hours were not refunded.',
        'type': 'booking_cancelled',
        'relatedBookingId': bookingId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

      debugPrint('✅ Booking cancelled without refund: $bookingId');

      return {
        'success': true,
        'message': 'Booking cancelled successfully (no refund)',
        'cancellationType': 'no_refund',
      };
    } catch (e) {
      debugPrint('❌ Error cancelling booking without refund: $e');
      return {
        'success': false,
        'message': 'Failed to cancel booking: ${e.toString()}',
      };
    }
  }

  /// User-initiated cancellation (with refund if within policy)
  Future<Map<String, dynamic>> userCancelBooking({
    required String bookingId,
    required int userId,
    String? reason,
  }) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;

      // Verify user owns this booking
      if (bookingData['userId'] != userId) {
        throw Exception('Unauthorized: You do not own this booking');
      }

      // Check if booking is already cancelled
      final status = bookingData['status'] as String?;
      if (status == 'cancelled') {
        throw Exception('Booking is already cancelled');
      }

      // Check cancellation policy (e.g., 24 hours before booking)
      final bookingDate = DateTime.parse(bookingData['bookingDate']);
      final timeSlot = bookingData['timeSlot'] as String;
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeSlot.split(':')[0]),
        int.parse(timeSlot.split(':')[1]),
      );

      final hoursUntilBooking = bookingDateTime
          .difference(DateTime.now())
          .inHours;
      final isEligibleForRefund = hoursUntilBooking >= 24;

      if (isEligibleForRefund) {
        // Cancel with refund
        return await cancelWithRefund(
          bookingId: bookingId,
          reason: reason ?? 'User cancelled',
          adminNotes: 'User-initiated cancellation (within policy)',
        );
      } else {
        // Cancel without refund
        return await cancelWithoutRefund(
          bookingId: bookingId,
          reason: reason ?? 'User cancelled (late cancellation)',
          adminNotes: 'User-initiated cancellation (less than 24 hours notice)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error in user cancel booking: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get cancellation policy info
  Map<String, dynamic> getCancellationPolicy() {
    return {
      'refundEligibilityHours': 24,
      'description':
          'Cancellations made 24 hours or more before the booking time are eligible for a full refund.',
      'lateCancellationPolicy':
          'Cancellations made less than 24 hours before the booking time will not receive a refund.',
      'noShowPolicy':
          'No-shows will not receive a refund and hours will not be restored.',
    };
  }

  /// Check if booking is eligible for refund
  Future<Map<String, dynamic>> checkRefundEligibility(String bookingId) async {
    try {
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final status = bookingData['status'] as String?;

      if (status == 'cancelled') {
        return {'eligible': false, 'reason': 'Booking is already cancelled'};
      }

      final bookingDate = DateTime.parse(bookingData['bookingDate']);
      final timeSlot = bookingData['timeSlot'] as String;
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeSlot.split(':')[0]),
        int.parse(timeSlot.split(':')[1]),
      );

      final hoursUntilBooking = bookingDateTime
          .difference(DateTime.now())
          .inHours;
      final isEligible = hoursUntilBooking >= 24;

      return {
        'eligible': isEligible,
        'hoursUntilBooking': hoursUntilBooking,
        'reason': isEligible
            ? 'Eligible for full refund'
            : 'Less than 24 hours notice - no refund',
      };
    } catch (e) {
      debugPrint('❌ Error checking refund eligibility: $e');
      return {'eligible': false, 'reason': e.toString()};
    }
  }

  /// Get cancelled bookings for a user
  Stream<List<Map<String, dynamic>>> getCancelledBookings(int userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'cancelled')
        .orderBy('cancelledAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }
}
