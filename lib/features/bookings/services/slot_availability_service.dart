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

      final allTimeSlots = AppConstants.getAllTimeSlots(includeExtended: false);

      for (final slot in allTimeSlots) {
        final parts = slot.split(':');
        final slotHour = int.parse(parts[0]);
        final slotMins = slotHour * 60 + int.parse(parts[1]);

        // Check if slot is in priority time
        final isWeekend =
            selectedDate.weekday == DateTime.saturday ||
            selectedDate.weekday == DateTime.sunday;
        final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
        final isPrioritySlot = isWeekend || isPriorityTime;

        // Skip priority slots if user doesn't have addon
        if (isPrioritySlot && !hasPriorityBooking) {
          continue;
        }

        // Hard limit: Skip slots where 1-hour booking would exceed 22:00
        const hardLimitMins = 22 * 60;
        const minBookingMins = 60;
        if (slotMins + minBookingMins > hardLimitMins) {
          continue;
        }

        // Skip past time slots for today
        if (isToday) {
          final currentMinutes = now.hour * 60 + now.minute;
          const gracePeriodMins = 30;
          if (slotMins + gracePeriodMins < currentMinutes) {
            continue;
          }
        }

        // Check availability and calculate max possible duration
        bool isAvailable = true;
        int? nextBookingStartMins;

        for (final range in bookedRanges) {
          if (slotMins >= range['start']! && slotMins < range['end']!) {
            isAvailable = false;
            break;
          }
          // Find next booking after this slot
          if (range['start']! > slotMins) {
            if (nextBookingStartMins == null ||
                range['start']! < nextBookingStartMins) {
              nextBookingStartMins = range['start'];
            }
          }
        }

        if (isAvailable) {
          // Calculate max possible duration in hours
          const hardLimitMins = 22 * 60; // 22:00 hard limit
          int maxEndMins = hardLimitMins;

          if (nextBookingStartMins != null) {
            // Cap at next booking minus buffer time
            maxEndMins = nextBookingStartMins - bufferTimeMins;
          }

          final maxDurationMins = maxEndMins - slotMins;
          final maxDurationHours = (maxDurationMins / 60).floor();

          available.add({
            'slot': slot,
            'maxPossibleDuration': maxDurationHours >= 1 ? maxDurationHours : 1,
          });
        }
      }

      // Add custom slot after last booking with mandatory buffer
      if (lastBookingEndMins != null) {
        final nextAvailableMins = lastBookingEndMins + bufferTimeMins;
        final nextHour = nextAvailableMins ~/ 60;
        final nextMin = nextAvailableMins % 60;

        const hardLimitMins = 22 * 60;
        const minBookingMins = 60;
        final wouldExceedLimit =
            nextAvailableMins + minBookingMins > hardLimitMins;

        if (nextHour < 22 && !wouldExceedLimit) {
          final customSlot =
              '${nextHour.toString().padLeft(2, '0')}:${nextMin.toString().padLeft(2, '0')}';

          final isWeekend =
              selectedDate.weekday == DateTime.saturday ||
              selectedDate.weekday == DateTime.sunday;
          final isPriorityTime = (nextHour >= 18 && nextHour <= 22);
          final isPrioritySlot = isWeekend || isPriorityTime;

          final canAddSlot = !isPrioritySlot || hasPriorityBooking;

          if (canAddSlot && !available.any((s) => s['slot'] == customSlot)) {
            const hardLimitMins = 22 * 60;
            final maxDurationMins = hardLimitMins - nextAvailableMins;
            final maxDurationHours = (maxDurationMins / 60).floor();

            if (isToday) {
              final currentMinutes = now.hour * 60 + now.minute;
              const gracePeriodMins = 30;
              if (nextAvailableMins + gracePeriodMins > currentMinutes) {
                available.insert(0, {
                  'slot': customSlot,
                  'maxPossibleDuration': maxDurationHours >= 1
                      ? maxDurationHours
                      : 1,
                });
              }
            } else {
              available.insert(0, {
                'slot': customSlot,
                'maxPossibleDuration': maxDurationHours >= 1
                    ? maxDurationHours
                    : 1,
              });
            }
          }
        }
      }

      // Sort slots chronologically
      available.sort((a, b) {
        final aParts = (a['slot'] as String).split(':');
        final bParts = (b['slot'] as String).split(':');
        final aMins = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
        final bMins = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
        return aMins.compareTo(bMins);
      });

      return available;
    } catch (e) {
      debugPrint('Error loading available slots: $e');
      return [];
    }
  }
}
