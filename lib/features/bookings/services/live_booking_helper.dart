import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LiveBookingHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a live slot booking
  Future<bool> createLiveBooking({
    required BuildContext context,
    required String userId,
    required String specialty,
    required DateTime selectedDate,
    required String selectedTime,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String? selectedSubscriptionId,
    required List<Map<String, dynamic>> subscriptions,
  }) async {
    try {
      final durationMinutes =
          (endTime.hour * 60 + endTime.minute) -
          (startTime.hour * 60 + startTime.minute);
      final durationHours = (durationMinutes / 60).ceil();

      int minutesToDeduct = durationMinutes;
      bool hasExtendedHoursBonus = false;

      // Check for Extended Hours addon
      if (selectedSubscriptionId != null) {
        final selectedSub = subscriptions.firstWhere(
          (sub) => sub['id'] == selectedSubscriptionId,
          orElse: () => {},
        );

        if (selectedSub.isNotEmpty) {
          final addons = selectedSub['selectedAddons'] as List?;
          if (addons != null) {
            hasExtendedHoursBonus = addons.any(
              (addon) => addon['code'] == 'extended_hours',
            );
          }
        }
      }

      // Extended Hours addon: Always subtract 30 min bonus, minimum 0
      if (hasExtendedHoursBonus) {
        minutesToDeduct = durationMinutes > 30 ? durationMinutes - 30 : 0;
      }

      // Validate sufficient hours
      int selectedSubRemainingMins = 0;
      if (selectedSubscriptionId != null) {
        final selectedSub = subscriptions.firstWhere(
          (sub) => sub['id'] == selectedSubscriptionId,
          orElse: () => {},
        );
        if (selectedSub.isNotEmpty) {
          final hours = selectedSub['remainingHours'] as int? ?? 0;
          final mins = selectedSub['remainingMinutes'] as int? ?? 0;
          selectedSubRemainingMins = (hours * 60) + mins;
        }
      }

      if (minutesToDeduct > selectedSubRemainingMins) {
        final totalHours = selectedSubRemainingMins / 60.0;
        final requiredHours = minutesToDeduct / 60.0;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Not enough time! Need ${requiredHours.toStringAsFixed(1)}h but only have ${totalHours.toStringAsFixed(1)}h',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      // Check for conflicts within the same suite type only
      final suiteType = _getSuiteTypeForSpecialty(specialty);
      final hasConflict = await _checkConflicts(
        selectedDate: selectedDate,
        startTime: startTime,
        endTime: endTime,
        context: context,
        suiteType: suiteType,
      );
      if (hasConflict) return false;

      // Validate Priority Booking
      if (!await _validatePriorityBooking(
        context: context,
        selectedDate: selectedDate,
        startTime: startTime,
        endTime: endTime,
        selectedSubscriptionId: selectedSubscriptionId,
        subscriptions: subscriptions,
      )) {
        return false;
      }

      final startTimeStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      // Create booking datetime with actual start time
      final bookingDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );

      // Create booking
      await _firestore.collection('bookings').add({
        'userId': userId,
        'subscriptionId': selectedSubscriptionId,
        'suiteType': _getSuiteTypeForSpecialty(specialty),
        'specialty': specialty,
        'bookingDate': Timestamp.fromDate(bookingDateTime),
        'timeSlot': selectedTime,
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'durationHours': durationHours,
        'durationMins': durationMinutes % 60,
        'totalDurationMins': durationMinutes,
        'chargedMinutes': minutesToDeduct,
        'hasExtendedHoursBonus': hasExtendedHoursBonus,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update subscription
      await _updateSubscription(
        subscriptionId: selectedSubscriptionId!,
        subscriptions: subscriptions,
        minutesToDeduct: minutesToDeduct,
      );

      if (context.mounted) {
        final exactHours = durationMinutes / 60.0;
        final hoursText = exactHours == exactHours.floor()
            ? '${exactHours.toInt()} hour${exactHours.toInt() > 1 ? 's' : ''}'
            : '${exactHours.toStringAsFixed(1)} hours';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Slot booked! $hoursText deducted.'),
            backgroundColor: const Color(0xFF90D26D),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  /// Check for booking conflicts within the same suite type only
  /// Each suite (dental/medical/aesthetic) has independent time slots
  Future<bool> _checkConflicts({
    required DateTime selectedDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required BuildContext context,
    required String suiteType,
  }) async {
    final startMins = startTime.hour * 60 + startTime.minute;
    final endMins = endTime.hour * 60 + endTime.minute;

    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Filter bookings by suite type - conflicts only within same suite
    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('suiteType', isEqualTo: suiteType)
        .where(
          'bookingDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['confirmed', 'in_progress'])
        .get();

    for (final doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final parts1 = (data['startTime'] as String?)?.split(':');
      final parts2 = (data['endTime'] as String?)?.split(':');

      if (parts1 != null && parts2 != null) {
        final bStart = int.parse(parts1[0]) * 60 + int.parse(parts1[1]);
        final bEnd = int.parse(parts2[0]) * 60 + int.parse(parts2[1]);

        if (startMins < bEnd && endMins > bStart) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Time slot conflicts with existing booking'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> _validatePriorityBooking({
    required BuildContext context,
    required DateTime selectedDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String? selectedSubscriptionId,
    required List<Map<String, dynamic>> subscriptions,
  }) async {
    final isWeekend =
        selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;
    final isPriorityTime =
        startTime.hour >= 18 || endTime.hour >= 18 || endTime.hour == 0;

    if (isWeekend || isPriorityTime) {
      bool hasPriority = false;

      if (selectedSubscriptionId != null) {
        final sub = subscriptions.firstWhere(
          (s) => s['id'] == selectedSubscriptionId,
          orElse: () => {},
        );

        if (sub.isNotEmpty) {
          final addons = sub['selectedAddons'] as List?;
          hasPriority =
              addons?.any((a) => a['code'] == 'priority_booking') ?? false;
        }
      }

      if (!hasPriority) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isWeekend
                    ? '❌ Weekend bookings require Priority Booking addon'
                    : '❌ After 17:00 requires Priority Booking addon',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _updateSubscription({
    required String subscriptionId,
    required List<Map<String, dynamic>> subscriptions,
    required int minutesToDeduct,
  }) async {
    final sub = subscriptions.firstWhere(
      (s) => s['id'] == subscriptionId,
      orElse: () => {},
    );

    if (sub.isNotEmpty) {
      final hours = sub['remainingHours'] as int? ?? 0;
      final mins = sub['remainingMinutes'] as int? ?? 0;
      final totalMins = (hours * 60) + mins;

      if (totalMins >= minutesToDeduct) {
        final newTotal = totalMins - minutesToDeduct;
        final newHours = newTotal ~/ 60;
        final newMins = newTotal % 60;

        await _firestore
            .collection('subscriptions')
            .doc(subscriptionId)
            .update({
              'remainingHours': newHours,
              'remainingMinutes': newMins,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    }
  }

  String _getSuiteTypeForSpecialty(String specialty) {
    if (specialty.contains('dentist') || specialty.contains('orthodontist')) {
      return 'dental';
    } else if (specialty.contains('aesthetic') || specialty.contains('derma')) {
      return 'aesthetic';
    }
    return 'medical';
  }
}
