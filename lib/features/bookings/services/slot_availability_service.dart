import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';

class SlotAvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load available time slots for a given date and subscription
  /// Each suite type (dental/medical/aesthetic) has independent time slots
  /// Returns Map with 'slot' (time string) and 'maxPossibleDuration' (hours)
  Future<List<Map<String, dynamic>>> loadAvailableSlots({
    required DateTime selectedDate,
    required String? selectedSubscriptionId,
    required List<Map<String, dynamic>> subscriptions,
  }) async {
    try {
      // Get suite type from selected subscription
      String? suiteType;
      if (selectedSubscriptionId != null && subscriptions.isNotEmpty) {
        final selectedSub = subscriptions.firstWhere(
          (sub) => sub['id'] == selectedSubscriptionId,
          orElse: () => {},
        );
        if (selectedSub.isNotEmpty) {
          suiteType = selectedSub['suiteType'] as String?;
        }
      }

      debugPrint('🏥 Loading slots for suite: $suiteType');

      final startOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Filter bookings by suite type - each suite has independent slots
      var query = _firestore
          .collection('bookings')
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['confirmed', 'in_progress']);

      // Add suite type filter if available
      if (suiteType != null && suiteType.isNotEmpty) {
        query = query.where('suiteType', isEqualTo: suiteType);
      }

      final bookingsSnapshot = await query.get();

      final bookedRanges = <Map<String, int>>[];
      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final startTime = data['startTime'] as String?;
        final endTime = data['endTime'] as String?;

        if (startTime != null && endTime != null) {
          final startParts = startTime.split(':');
          final endParts = endTime.split(':');
          final startMins =
              int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          bookedRanges.add({'start': startMins, 'end': endMins});
        }
      }

      final available = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final isToday =
          selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      const bufferTimeMins = AppConstants.turnoverBufferMinutes;

      // Find the last booking end time
      int? lastBookingEndMins;
      for (final range in bookedRanges) {
        if (lastBookingEndMins == null || range['end']! > lastBookingEndMins) {
          lastBookingEndMins = range['end'];
        }
      }

      // Check subscription addons
      bool hasPriorityBooking = false;
      final subscriptionToCheck =
          selectedSubscriptionId ??
          (subscriptions.isNotEmpty ? subscriptions[0]['id'] as String? : null);

      if (subscriptionToCheck != null) {
        final selectedSub = subscriptions.firstWhere(
          (sub) => sub['id'] == subscriptionToCheck,
          orElse: () => {},
        );

        if (selectedSub.isNotEmpty) {
          final addons = selectedSub['selectedAddons'] as List?;
          if (addons != null) {
            hasPriorityBooking = addons.any(
              (addon) => addon['code'] == 'priority_booking',
            );
          }
        }
      }

      debugPrint('🎯 hasPriorityBooking: $hasPriorityBooking');

      const hardLimitMins = 22 * 60; // 22:00
      const minBookingMins = 60; // Minimum 1 hour booking

      // 🎯 DYNAMIC SLOT GENERATION: Calculate available slots based on bookings
      // Instead of checking predefined hourly slots, we generate slots dynamically

      if (bookedRanges.isEmpty) {
        // No bookings - show standard hourly slots from 09:00
        final standardSlots = AppConstants.getAllTimeSlots(
          includeExtended: false,
        );
        for (final slot in standardSlots) {
          final parts = slot.split(':');
          final slotHour = int.parse(parts[0]);
          final slotMins = slotHour * 60 + int.parse(parts[1]);

          // Check priority and time constraints
          final isWeekend =
              selectedDate.weekday == DateTime.saturday ||
              selectedDate.weekday == DateTime.sunday;
          final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
          final isPrioritySlot = isWeekend || isPriorityTime;

          if (isPrioritySlot && !hasPriorityBooking) continue;
          if (slotMins >= hardLimitMins) continue;
          if (slotMins + minBookingMins > hardLimitMins) continue;

          if (isToday) {
            final currentMinutes = now.hour * 60 + now.minute;
            if (slotMins + 30 < currentMinutes) continue;
          }

          final maxDurationMins = hardLimitMins - slotMins;
          final maxDurationHours = (maxDurationMins / 60).floor();

          available.add({
            'slot': slot,
            'maxPossibleDuration': maxDurationHours >= 1 ? maxDurationHours : 1,
          });
        }
      } else {
        // ✅ WITH BOOKINGS: Generate slots dynamically after each booking + buffer
        bookedRanges.sort((a, b) => a['start']!.compareTo(b['start']!));

        int lastCheckedMins = 9 * 60; // Start from 09:00

        for (final range in bookedRanges) {
          final bookingStart = range['start']!;
          final bookingEnd = range['end']!;

          // Add slot BEFORE this booking if there's space
          if (bookingStart - lastCheckedMins >= minBookingMins) {
            final slotHour = lastCheckedMins ~/ 60;
            final slotMin = lastCheckedMins % 60;
            final slot =
                '${slotHour.toString().padLeft(2, '0')}:${slotMin.toString().padLeft(2, '0')}';

            // Check constraints
            final isWeekend =
                selectedDate.weekday == DateTime.saturday ||
                selectedDate.weekday == DateTime.sunday;
            final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
            final isPrioritySlot = isWeekend || isPriorityTime;

            if (!isPrioritySlot || hasPriorityBooking) {
              if (isToday) {
                final currentMinutes = now.hour * 60 + now.minute;
                if (lastCheckedMins + 30 >= currentMinutes) {
                  final maxDurationMins = bookingStart - lastCheckedMins;
                  final maxDurationHours = (maxDurationMins / 60).floor();

                  available.add({
                    'slot': slot,
                    'maxPossibleDuration': maxDurationHours >= 1
                        ? maxDurationHours
                        : 1,
                  });
                }
              } else {
                final maxDurationMins = bookingStart - lastCheckedMins;
                final maxDurationHours = (maxDurationMins / 60).floor();

                available.add({
                  'slot': slot,
                  'maxPossibleDuration': maxDurationHours >= 1
                      ? maxDurationHours
                      : 1,
                });
              }
            }
          }

          // Move to after this booking + buffer
          lastCheckedMins = bookingEnd + bufferTimeMins;
        }

        // ✅ Add slot AFTER last booking + buffer
        if (lastCheckedMins < hardLimitMins &&
            hardLimitMins - lastCheckedMins >= minBookingMins) {
          final slotHour = lastCheckedMins ~/ 60;
          final slotMin = lastCheckedMins % 60;
          final slot =
              '${slotHour.toString().padLeft(2, '0')}:${slotMin.toString().padLeft(2, '0')}';

          final isWeekend =
              selectedDate.weekday == DateTime.saturday ||
              selectedDate.weekday == DateTime.sunday;
          final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
          final isPrioritySlot = isWeekend || isPriorityTime;

          if (!isPrioritySlot || hasPriorityBooking) {
            if (isToday) {
              final currentMinutes = now.hour * 60 + now.minute;
              if (lastCheckedMins + 30 >= currentMinutes) {
                final maxDurationMins = hardLimitMins - lastCheckedMins;
                final maxDurationHours = (maxDurationMins / 60).floor();

                available.add({
                  'slot': slot,
                  'maxPossibleDuration': maxDurationHours >= 1
                      ? maxDurationHours
                      : 1,
                });
              }
            } else {
              final maxDurationMins = hardLimitMins - lastCheckedMins;
              final maxDurationHours = (maxDurationMins / 60).floor();

              available.add({
                'slot': slot,
                'maxPossibleDuration': maxDurationHours >= 1
                    ? maxDurationHours
                    : 1,
              });
            }
          }
        }
      }

      return available;
    } catch (e) {
      debugPrint('Error loading available slots: $e');
      return [];
    }
  }
}
