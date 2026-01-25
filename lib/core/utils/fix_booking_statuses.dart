import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Utility to fix booking statuses - marks future bookings as confirmed instead of completed
class BookingStatusFixer {
  final FirebaseFirestore _firestore;

  BookingStatusFixer(this._firestore);

  /// Fix all future bookings that were incorrectly marked as completed
  Future<int> fixFutureBookings() async {
    try {
      debugPrint('🔍 Fetching all bookings with completed status...');

      final snapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .get();

      debugPrint('Found ${snapshot.docs.length} completed bookings');

      final now = DateTime.now();
      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final bookingId = doc.id;

        DateTime? bookingDateTime;

        // Parse booking date
        final bookingDateField = data['bookingDate'];

        if (bookingDateField is Timestamp) {
          bookingDateTime = bookingDateField.toDate();
        } else if (bookingDateField is String) {
          try {
            final parts = bookingDateField.split('/');
            if (parts.length == 3) {
              final month = int.parse(parts[0]);
              final day = int.parse(parts[1]);
              final year = int.parse(parts[2]);

              bookingDateTime = DateTime(year, month, day);

              // Add time if available
              final timeSlot = data['timeSlot'] as String?;
              if (timeSlot != null) {
                final timeParts = timeSlot.split(':');
                if (timeParts.length >= 2) {
                  final hour = int.tryParse(timeParts[0]) ?? 0;
                  final minute = int.tryParse(timeParts[1]) ?? 0;
                  bookingDateTime = DateTime(year, month, day, hour, minute);
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing booking date: $bookingDateField - $e');
          }
        }

        // If booking is in the future, change status to confirmed
        if (bookingDateTime != null && bookingDateTime.isAfter(now)) {
          debugPrint('📅 Fixing future booking $bookingId: $bookingDateTime');
          await _firestore.collection('bookings').doc(bookingId).update({
            'status': 'confirmed',
          });
          updatedCount++;
        }
      }

      debugPrint('✅ Updated $updatedCount future bookings to confirmed status');
      return updatedCount;
    } catch (e) {
      debugPrint('❌ Error fixing booking statuses: $e');
      rethrow;
    }
  }
}
