import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';
import 'package:sehat_makaan_flutter/features/bookings/models/booking_model.dart';

/// Booking Service for Firebase Firestore
/// Handles all booking operations including create, read, update, delete
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create new booking with atomic transaction
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String suiteType,
    required DateTime bookingDate,
    required String timeSlot,
    DateTime? startTime,
    required int durationMins,
    required double baseRate,
    List<String> addons = const [],
    required double totalAmount,
    String? subscriptionId,
    String paymentMethod = 'payfast',
    String? paymentId,
  }) async {
    try {
      // ============================================================================
      // GOD MODE: SYSTEM CHECKS
      // ============================================================================

      // 1. Check Maintenance Mode
      final systemSettings = await _getSystemSettings();
      final isMaintenanceMode = systemSettings['isMaintenanceMode'] ?? false;
      final maintenanceMessage =
          systemSettings['maintenanceMessage'] ??
          'The system is currently under maintenance. Please try again later.';

      if (isMaintenanceMode) {
        return {'success': false, 'error': maintenanceMessage};
      }

      // 2. Check Shadow Ban
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final isShadowBanned = userData['isShadowBanned'] ?? false;

        if (isShadowBanned) {
          return {
            'success': false,
            'error':
                'Action restricted. Please contact support if you believe this is an error.',
          };
        }
      }

      // PRE-TRANSACTION VALIDATION: Check for conflicts (queries not allowed in transaction)
      final hasConflictResult = await hasConflict(
        date: bookingDate,
        suiteType: suiteType,
        timeSlot: timeSlot,
        durationMins: durationMins,
      );

      if (hasConflictResult) {
        return {
          'success': false,
          'error':
              'This time slot is not available. Please select another time.',
        };
      }

      // If subscription booking, verify balance before transaction
      if (subscriptionId != null) {
        final subscriptionDoc = await _firestore
            .collection('subscriptions')
            .doc(subscriptionId)
            .get();

        if (!subscriptionDoc.exists) {
          return {'success': false, 'error': 'Subscription not found'};
        }

        final subscriptionData = subscriptionDoc.data()!;
        final hours = subscriptionData['remainingHours'] as int? ?? 0;
        final mins = subscriptionData['remainingMinutes'] as int? ?? 0;
        final totalMins = (hours * 60) + mins;

        if (totalMins < durationMins) {
          return {
            'success': false,
            'error': 'Insufficient subscription balance',
          };
        }
      }

      String? bookingId;

      // Calculate time range for schedule lock
      final startMinutes = _timeSlotToMinutes(timeSlot);
      final endMinutes = startMinutes + durationMins;
      const bufferMins = AppConstants.turnoverBufferMinutes;

      // ATOMIC TRANSACTION: Schedule lock + Booking + Subscription update together
      await _firestore.runTransaction((transaction) async {
        // 1. Check schedule document for conflicts (INSIDE transaction)
        final scheduleDocId = _getScheduleDocId(suiteType, bookingDate);
        final scheduleRef = _firestore
            .collection('schedules')
            .doc(scheduleDocId);
        final scheduleDoc = await transaction.get(scheduleRef);

        List<Map<String, dynamic>> bookedRanges = [];
        if (scheduleDoc.exists) {
          final data = scheduleDoc.data()!;
          bookedRanges = List<Map<String, dynamic>>.from(data['ranges'] ?? []);
        }

        // Check for conflicts with buffer time
        for (final range in bookedRanges) {
          final existingStart = range['start'] as int;
          final existingEnd = range['end'] as int;

          if (startMinutes < (existingEnd + bufferMins) &&
              (endMinutes + bufferMins) > existingStart) {
            throw Exception('Time slot conflict detected in transaction');
          }
        }

        // 2. Add new booking to schedule
        bookedRanges.add({
          'start': startMinutes,
          'end': endMinutes,
          'bookingId': null, // Will be set after creating booking
        });

        transaction.set(scheduleRef, {
          'suiteType': suiteType,
          'date': Timestamp.fromDate(bookingDate),
          'ranges': bookedRanges,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 3. Create booking reference
        final bookingRef = _firestore.collection('bookings').doc();
        bookingId = bookingRef.id;

        // Update the schedule to include bookingId
        bookedRanges.last['bookingId'] = bookingId;
        transaction.update(scheduleRef, {'ranges': bookedRanges});

        transaction.set(bookingRef, {
          'userId': userId,
          'suiteType': suiteType,
          'bookingDate': Timestamp.fromDate(bookingDate),
          'timeSlot': timeSlot,
          'startTime': startTime != null ? Timestamp.fromDate(startTime) : null,
          'durationMins': durationMins,
          'baseRate': baseRate,
          'addons': addons,
          'totalAmount': totalAmount,
          'status': 'confirmed',
          'cancellationType': null,
          'paymentMethod': paymentMethod,
          'paymentStatus': paymentId != null ? 'paid' : 'pending',
          'paymentId': paymentId,
          'subscriptionId': subscriptionId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // If subscription booking, deduct hours atomically
        if (subscriptionId != null) {
          final subscriptionRef = _firestore
              .collection('subscriptions')
              .doc(subscriptionId);
          final subscriptionDoc = await transaction.get(subscriptionRef);

          if (subscriptionDoc.exists) {
            final data = subscriptionDoc.data()!;
            final hours = data['remainingHours'] as int? ?? 0;
            final mins = data['remainingMinutes'] as int? ?? 0;
            final totalMins = (hours * 60) + mins;

            // Re-verify balance inside transaction
            if (totalMins >= durationMins) {
              final newTotal = totalMins - durationMins;
              final newHours = newTotal ~/ 60;
              final newMins = newTotal % 60;

              transaction.update(subscriptionRef, {
                'remainingHours': newHours,
                'remainingMinutes': newMins,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      });

      debugPrint('✅ Booking created: $bookingId');
      return {
        'success': true,
        'bookingId': bookingId,
        'message': 'Booking created successfully',
      };
    } catch (e) {
      debugPrint('❌ Create booking error: $e');
      return {
        'success': false,
        'error': 'Failed to create booking. Please try again.',
      };
    }
  }

  /// Get user bookings
  Stream<List<BookingModel>> getUserBookings(String userId, {int? limit}) {
    Query query = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('bookingDate', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get booking error: $e');
      return null;
    }
  }

  /// Get bookings by date
  Stream<List<BookingModel>> getBookingsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('bookings')
        .where(
          'bookingDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('bookingDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('bookingDate')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get active bookings
  Stream<List<BookingModel>> getActiveBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'confirmed')
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Cancel booking
  /// Cancel booking and release the slot back to availability
  ///
  /// This atomically:
  /// 1. Removes the time range from schedules document (makes slot available)
  /// 2. Updates booking status to 'cancelled'
  /// 3. If subscription booking, refunds the hours
  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    required String cancellationType,
    String? refundReason,
  }) async {
    try {
      // Get booking data to extract schedule information
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        return {'success': false, 'error': 'Booking not found'};
      }

      final bookingData = bookingDoc.data()!;
      final suiteType = bookingData['suiteType'] as String;
      final bookingDate = (bookingData['bookingDate'] as Timestamp).toDate();
      final subscriptionId = bookingData['subscriptionId'] as String?;
      final durationMins = bookingData['durationMins'] as int? ?? 0;

      // ATOMIC TRANSACTION: Remove from schedule + Update status + Refund hours
      await _firestore.runTransaction((transaction) async {
        // 1. Remove booking from schedule document
        final scheduleDocId = _getScheduleDocId(suiteType, bookingDate);
        final scheduleRef = _firestore
            .collection('schedules')
            .doc(scheduleDocId);
        final scheduleDoc = await transaction.get(scheduleRef);

        if (scheduleDoc.exists) {
          final data = scheduleDoc.data()!;
          List<Map<String, dynamic>> ranges = List<Map<String, dynamic>>.from(
            data['ranges'] ?? [],
          );

          // Remove this booking's range
          ranges.removeWhere((range) => range['bookingId'] == bookingId);

          transaction.update(scheduleRef, {
            'ranges': ranges,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 2. Update booking status
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        transaction.update(bookingRef, {
          'status': 'cancelled',
          'cancellationType': cancellationType,
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. If subscription booking, refund hours
        if (subscriptionId != null && durationMins > 0) {
          final subscriptionRef = _firestore
              .collection('subscriptions')
              .doc(subscriptionId);
          final subscriptionDoc = await transaction.get(subscriptionRef);

          if (subscriptionDoc.exists) {
            final data = subscriptionDoc.data()!;
            final hours = data['remainingHours'] as int? ?? 0;
            final mins = data['remainingMinutes'] as int? ?? 0;
            final totalMins = (hours * 60) + mins + durationMins;
            final newHours = totalMins ~/ 60;
            final newMins = totalMins % 60;

            transaction.update(subscriptionRef, {
              'remainingHours': newHours,
              'remainingMinutes': newMins,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      debugPrint('✅ Booking cancelled and slot released: $bookingId');
      return {'success': true, 'message': 'Booking cancelled successfully'};
    } catch (e) {
      debugPrint('❌ Cancel booking error: $e');
      return {
        'success': false,
        'error': 'Failed to cancel booking. Please try again.',
      };
    }
  }

  /// Update booking status
  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Booking status updated: $bookingId -> $status');
      return {'success': true, 'message': 'Booking status updated'};
    } catch (e) {
      debugPrint('❌ Update booking status error: $e');
      return {'success': false, 'error': 'Failed to update booking status.'};
    }
  }

  /// Update payment status
  Future<Map<String, dynamic>> updatePaymentStatus({
    required String bookingId,
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

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      debugPrint('✅ Payment status updated: $bookingId -> $paymentStatus');
      return {'success': true, 'message': 'Payment status updated'};
    } catch (e) {
      debugPrint('❌ Update payment status error: $e');
      return {'success': false, 'error': 'Failed to update payment status.'};
    }
  }

  /// Get available time slots - DEPRECATED
  /// Use SlotAvailabilityService.loadAvailableSlots() instead
  /// This maintains a single source of truth for availability logic
  @Deprecated('Use SlotAvailabilityService.loadAvailableSlots() instead')
  Future<List<String>> getAvailableSlots({
    required DateTime date,
    required String suiteType,
  }) async {
    debugPrint(
      '⚠️ DEPRECATED: Use SlotAvailabilityService.loadAvailableSlots() for consistency',
    );
    return [];
  }

  /// Delete booking and release the slot back to availability
  ///
  /// This atomically:
  /// 1. Removes the time range from schedules document (makes slot available)
  /// 2. Deletes the booking document
  Future<Map<String, dynamic>> deleteBooking(String bookingId) async {
    try {
      // Get booking data to extract schedule information
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        return {'success': false, 'error': 'Booking not found'};
      }

      final bookingData = bookingDoc.data()!;
      final suiteType = bookingData['suiteType'] as String;
      final bookingDate = (bookingData['bookingDate'] as Timestamp).toDate();

      // ATOMIC TRANSACTION: Remove from schedule + Delete booking
      await _firestore.runTransaction((transaction) async {
        // 1. Remove booking from schedule document
        final scheduleDocId = _getScheduleDocId(suiteType, bookingDate);
        final scheduleRef = _firestore
            .collection('schedules')
            .doc(scheduleDocId);
        final scheduleDoc = await transaction.get(scheduleRef);

        if (scheduleDoc.exists) {
          final data = scheduleDoc.data()!;
          List<Map<String, dynamic>> ranges = List<Map<String, dynamic>>.from(
            data['ranges'] ?? [],
          );

          // Remove this booking's range
          ranges.removeWhere((range) => range['bookingId'] == bookingId);

          transaction.update(scheduleRef, {
            'ranges': ranges,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 2. Delete booking
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        transaction.delete(bookingRef);
      });

      debugPrint('✅ Booking deleted and slot released: $bookingId');
      return {'success': true, 'message': 'Booking deleted successfully'};
    } catch (e) {
      debugPrint('❌ Delete booking error: $e');
      return {'success': false, 'error': 'Failed to delete booking.'};
    }
  }

  /// Get available purchased addons for user
  Future<List<Map<String, dynamic>>> getAvailableAddons(String userId) async {
    try {
      final addons = await _firestore
          .collection('purchased_addons')
          .where('userId', isEqualTo: userId)
          .where('isUsed', isEqualTo: false)
          .get();

      return addons.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('❌ Get available addons error: $e');
      return [];
    }
  }

  /// Link purchased addon to booking
  Future<Map<String, dynamic>> linkAddonToBooking({
    required String addonId,
    required String bookingId,
  }) async {
    try {
      await _firestore.collection('purchased_addons').doc(addonId).update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
        'usedInBookingId': bookingId,
      });

      debugPrint('✅ Addon linked to booking: $addonId -> $bookingId');
      return {
        'success': true,
        'message': 'Addon linked to booking successfully',
      };
    } catch (e) {
      debugPrint('❌ Link addon error: $e');
      return {
        'success': false,
        'error': 'Failed to link addon. Please try again.',
      };
    }
  }

  /// Get user's purchased addons
  Future<List<Map<String, dynamic>>> getUserAddons(String userId) async {
    try {
      final addons = await _firestore
          .collection('purchased_addons')
          .where('userId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .get();

      return addons.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('❌ Get user addons error: $e');
      return [];
    }
  }

  /// Purchase addon
  Future<Map<String, dynamic>> purchaseAddon({
    required String userId,
    required String addonCode,
    required String addonName,
    required double price,
    required String suiteType,
    int quantity = 1,
    String type = 'other',
    int? durationMins,
  }) async {
    try {
      await _firestore.collection('purchased_addons').add({
        'userId': userId,
        'addonCode': addonCode,
        'addonName': addonName,
        'price': price,
        'suiteType': suiteType,
        'quantity': quantity,
        'isUsed': false,
        'usedAt': null,
        'usedInBookingId': null,
        'purchasedAt': FieldValue.serverTimestamp(),
        'expiresAt': null,
        'type': type,
        'durationMins': durationMins ?? 30,
      });

      debugPrint('✅ Addon purchased: $addonName');
      return {'success': true, 'message': 'Addon purchased successfully'};
    } catch (e) {
      debugPrint('❌ Purchase addon error: $e');
      return {
        'success': false,
        'error': 'Failed to purchase addon. Please try again.',
      };
    }
  }

  /// Get booking statistics
  Future<Map<String, int>> getBookingStats(String userId) async {
    try {
      final bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      int total = bookings.docs.length;
      int confirmed = bookings.docs
          .where((doc) => doc.data()['status'] == 'confirmed')
          .length;
      int cancelled = bookings.docs
          .where((doc) => doc.data()['status'] == 'cancelled')
          .length;
      int completed = bookings.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      return {
        'total': total,
        'confirmed': confirmed,
        'cancelled': cancelled,
        'completed': completed,
      };
    } catch (e) {
      debugPrint('❌ Get booking stats error: $e');
      return {'total': 0, 'confirmed': 0, 'cancelled': 0, 'completed': 0};
    }
  }

  /// Check for booking conflicts with buffer time (overlapping time slots)
  /// Uses AppConstants.turnoverBufferMinutes for mandatory cleaning/turnover buffer
  Future<bool> hasConflict({
    required DateTime date,
    required String suiteType,
    required String timeSlot,
    required int durationMins,
  }) async {
    try {
      const bufferMins = AppConstants.turnoverBufferMinutes;

      // Parse time slot to minutes (e.g., "14:00" -> 840 minutes)
      final timeSlotParts = timeSlot.split(':');
      final startMinutes =
          int.parse(timeSlotParts[0]) * 60 +
          (timeSlotParts.length > 1 ? int.parse(timeSlotParts[1]) : 0);
      final endMinutes = startMinutes + durationMins;

      // Get all confirmed bookings for the same date and suite type
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final bookings = await _firestore
          .collection('bookings')
          .where('suiteType', isEqualTo: suiteType)
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'bookingDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .where('status', isEqualTo: 'confirmed')
          .get();

      // Check each booking for time overlap WITH BUFFER TIME
      for (final doc in bookings.docs) {
        final data = doc.data();
        final existingSlot = data['timeSlot'] as String?;
        final existingDuration = data['durationMins'] as int? ?? 60;

        if (existingSlot == null) continue;

        // Parse existing booking time
        final existingParts = existingSlot.split(':');
        final existingStart =
            int.parse(existingParts[0]) * 60 +
            (existingParts.length > 1 ? int.parse(existingParts[1]) : 0);
        final existingEnd = existingStart + existingDuration;

        // BUFFER-SAFE CONFLICT LOGIC:
        // Conflict if: newStart < (existingEnd + buffer) AND (newEnd + buffer) > existingStart
        if (startMinutes < (existingEnd + bufferMins) &&
            (endMinutes + bufferMins) > existingStart) {
          debugPrint(
            '⚠️ Booking conflict detected (with ${bufferMins}min buffer): '
            'Requested $timeSlot-${_minutesToTime(endMinutes)} '
            'conflicts with $existingSlot-${_minutesToTime(existingEnd)}',
          );
          return true; // Conflict found
        }
      }

      return false; // No conflict
    } catch (e) {
      debugPrint('❌ Check conflict error: $e');
      return true; // Return true to be safe (prevent booking on error)
    }
  }

  /// Helper: Convert minutes to time string (e.g., 840 -> "14:00")
  String _minutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Get user bookings with pagination
  Future<Map<String, dynamic>> getUserBookingsPaginated({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('bookingDate', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();

      return {
        'success': true,
        'bookings': bookings,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      debugPrint('❌ Get paginated bookings error: $e');
      return {
        'success': false,
        'error': 'Failed to load bookings',
        'bookings': <BookingModel>[],
        'hasMore': false,
      };
    }
  }

  /// Reschedule booking to new date and time with atomic transaction
  Future<Map<String, dynamic>> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newTimeSlot,
    int? newDurationMins,
  }) async {
    try {
      // Get existing booking
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        return {'success': false, 'error': 'Booking not found'};
      }

      final bookingData = bookingDoc.data()!;
      final currentRescheduleCount =
          bookingData['rescheduleCount'] as int? ?? 0;

      // Check reschedule limit (max 2 reschedules)
      if (currentRescheduleCount >= 2) {
        return {
          'success': false,
          'error': 'Maximum reschedule limit (2) reached for this booking',
        };
      }

      final suiteType = bookingData['suiteType'] as String;
      final durationMins =
          newDurationMins ?? (bookingData['durationMins'] as int? ?? 60);

      // PRE-TRANSACTION: Check if new slot has conflict (with 15-min buffer)
      final hasConflictResult = await hasConflict(
        date: newDate,
        suiteType: suiteType,
        timeSlot: newTimeSlot,
        durationMins: durationMins,
      );

      if (hasConflictResult) {
        return {
          'success': false,
          'error':
              'The new time slot is not available. Please choose another time.',
        };
      }

      final userId = bookingData['userId'] as String;
      final oldDate = (bookingData['bookingDate'] as Timestamp).toDate();

      // Calculate time ranges for schedule locks
      final newStartMinutes = _timeSlotToMinutes(newTimeSlot);
      final newEndMinutes = newStartMinutes + durationMins;
      const bufferMins = AppConstants.turnoverBufferMinutes;

      // ATOMIC TRANSACTION: Schedule locks + Booking update + Notification creation together
      await _firestore.runTransaction((transaction) async {
        // 1. Remove old slot from old schedule
        final oldScheduleDocId = _getScheduleDocId(suiteType, oldDate);
        final oldScheduleRef = _firestore
            .collection('schedules')
            .doc(oldScheduleDocId);
        final oldScheduleDoc = await transaction.get(oldScheduleRef);

        if (oldScheduleDoc.exists) {
          final data = oldScheduleDoc.data()!;
          List<Map<String, dynamic>> ranges = List<Map<String, dynamic>>.from(
            data['ranges'] ?? [],
          );
          ranges.removeWhere((range) => range['bookingId'] == bookingId);
          transaction.update(oldScheduleRef, {'ranges': ranges});
        }

        // 2. Check new schedule for conflicts (INSIDE transaction)
        final newScheduleDocId = _getScheduleDocId(suiteType, newDate);
        final newScheduleRef = _firestore
            .collection('schedules')
            .doc(newScheduleDocId);
        final newScheduleDoc = await transaction.get(newScheduleRef);

        List<Map<String, dynamic>> newRanges = [];
        if (newScheduleDoc.exists) {
          final data = newScheduleDoc.data()!;
          newRanges = List<Map<String, dynamic>>.from(data['ranges'] ?? []);
        }

        // Check for conflicts with buffer time
        for (final range in newRanges) {
          final existingStart = range['start'] as int;
          final existingEnd = range['end'] as int;

          if (newStartMinutes < (existingEnd + bufferMins) &&
              (newEndMinutes + bufferMins) > existingStart) {
            throw Exception('Time slot conflict detected in transaction');
          }
        }

        // 3. Add booking to new schedule
        newRanges.add({
          'start': newStartMinutes,
          'end': newEndMinutes,
          'bookingId': bookingId,
        });

        transaction.set(newScheduleRef, {
          'suiteType': suiteType,
          'date': Timestamp.fromDate(newDate),
          'ranges': newRanges,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 4. Update booking
        final bookingRef = _firestore.collection('bookings').doc(bookingId);

        transaction.update(bookingRef, {
          'bookingDate': Timestamp.fromDate(newDate),
          'timeSlot': newTimeSlot,
          'startTime': Timestamp.fromDate(newDate),
          'rescheduleCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create notification atomically
        final notificationRef = _firestore.collection('notifications').doc();
        transaction.set(notificationRef, {
          'userId': userId,
          'title': 'Booking Rescheduled',
          'message':
              'Your booking has been rescheduled to ${newDate.toLocal().toString().split(' ')[0]} at $newTimeSlot',
          'type': 'booking_rescheduled',
          'relatedBookingId': bookingId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('✅ Booking rescheduled: $bookingId');
      return {
        'success': true,
        'message': 'Booking rescheduled successfully',
        'remainingReschedules': 2 - (currentRescheduleCount + 1),
      };
    } catch (e) {
      debugPrint('❌ Reschedule booking error: $e');
      return {
        'success': false,
        'error': 'Failed to reschedule booking. Please try again.',
      };
    }
  }

  // ============================================================================
  // GOD MODE: SYSTEM SETTINGS HELPERS
  // ============================================================================

  /// Fetch system settings from Firestore (God Mode)
  Future<Map<String, dynamic>> _getSystemSettings() async {
    try {
      final settingsDoc = await _firestore
          .collection('app_settings')
          .doc('system_config')
          .get();

      if (settingsDoc.exists) {
        return settingsDoc.data() ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('⚠️ Failed to fetch system settings: $e');
      return {};
    }
  }

  /// Get global commission rate from system settings (God Mode)
  /// Returns dynamic commission instead of hardcoded 20%
  Future<double> getGlobalCommission() async {
    final settings = await _getSystemSettings();
    return (settings['globalCommission'] ?? 20.0).toDouble();
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Helper: Get schedule document ID for a specific suite and date
  /// Schedule documents track all booked time ranges for atomic conflict detection
  String _getScheduleDocId(String suiteType, DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${suiteType}_$dateStr';
  }

  /// Helper: Convert time slot to minutes since midnight
  int _timeSlotToMinutes(String timeSlot) {
    final parts = timeSlot.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Get booking analytics with required date range for performance
  ///
  /// ⚠️ IMPORTANT: Date range is REQUIRED to prevent expensive full collection scans
  /// This ensures optimal Firebase usage and fast response times
  Future<Map<String, dynamic>> getBookingAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Build query with mandatory date filters
      Query query = _firestore
          .collection('bookings')
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'bookingDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );

      final snapshot = await query.get();
      final bookings = snapshot.docs;

      if (bookings.isEmpty) {
        return {
          'success': true,
          'totalBookings': 0,
          'totalRevenue': 0.0,
          'averageDuration': 0.0,
          'cancellationRate': 0.0,
          'topSuite': 'N/A',
          'peakHour': 'N/A',
          'suiteBreakdown': {},
          'hourlyBreakdown': {},
          'statusBreakdown': {},
        };
      }

      // Calculate metrics
      int totalBookings = bookings.length;
      double totalRevenue = 0.0;
      int totalDuration = 0;
      int cancelledCount = 0;
      Map<String, int> suiteBreakdown = {};
      Map<String, int> hourlyBreakdown = {};
      Map<String, int> statusBreakdown = {};

      for (final doc in bookings) {
        final data = doc.data() as Map<String, dynamic>;

        // Revenue
        totalRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

        // Duration
        totalDuration += (data['durationMins'] as int?) ?? 0;

        // Status
        final status = data['status'] as String? ?? 'unknown';
        statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;
        if (status == 'cancelled') cancelledCount++;

        // Suite type
        final suite = data['suiteType'] as String? ?? 'unknown';
        suiteBreakdown[suite] = (suiteBreakdown[suite] ?? 0) + 1;

        // Time slot
        final timeSlot = data['timeSlot'] as String?;
        if (timeSlot != null) {
          final hour = timeSlot.split(':')[0];
          hourlyBreakdown[hour] = (hourlyBreakdown[hour] ?? 0) + 1;
        }
      }

      // Calculate averages and percentages
      double averageDuration = totalBookings > 0
          ? totalDuration / totalBookings
          : 0.0;
      double cancellationRate = totalBookings > 0
          ? (cancelledCount / totalBookings) * 100
          : 0.0;

      // Find top suite
      String topSuite = 'N/A';
      int maxSuiteCount = 0;
      suiteBreakdown.forEach((suite, suiteCount) {
        if (suiteCount > maxSuiteCount) {
          maxSuiteCount = suiteCount;
          topSuite = suite;
        }
      });

      // Find peak hour
      String peakHour = 'N/A';
      int maxHourCount = 0;
      hourlyBreakdown.forEach((hour, hourCount) {
        if (hourCount > maxHourCount) {
          maxHourCount = hourCount;
          peakHour = '$hour:00';
        }
      });

      return {
        'success': true,
        'totalBookings': totalBookings,
        'totalRevenue': totalRevenue,
        'averageDuration': averageDuration,
        'cancellationRate': cancellationRate,
        'topSuite': topSuite,
        'peakHour': peakHour,
        'suiteBreakdown': suiteBreakdown,
        'hourlyBreakdown': hourlyBreakdown,
        'statusBreakdown': statusBreakdown,
      };
    } catch (e) {
      debugPrint('❌ Get booking analytics error: $e');
      return {'success': false, 'error': 'Failed to get analytics'};
    }
  }
}
