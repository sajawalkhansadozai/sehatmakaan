import 'package:flutter/material.dart';

class DurationCalculator {
  /// Calculate end time based on start time and duration
  static TimeOfDay? calculateEndTime({
    required TimeOfDay startTime,
    required double hours,
    required DateTime selectedDate,
    required bool hasExtendedHours,
    required bool hasPriorityBooking,
    required BuildContext context,
  }) {
    // Calculate end time WITHOUT Extended Hours first
    final startTotalMins = startTime.hour * 60 + startTime.minute;
    final durationMins = (hours * 60).toInt();
    final baseEndTotalMins = startTotalMins + durationMins;
    int baseEndHour = baseEndTotalMins ~/ 60;
    int baseEndMinute = baseEndTotalMins % 60;

    // Check if end time would fall into priority hours
    final isWeekend =
        selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;

    if (!hasPriorityBooking) {
      if (isWeekend) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Weekend bookings require Priority Booking addon\nAdd the addon to book on Saturdays and Sundays',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return null;
      } else if (baseEndHour >= 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ This duration would extend into priority hours (after 17:00)\nYou need Priority Booking addon or choose shorter duration',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return null;
      }
    }

    // Hard limit: No booking can extend beyond 22:00
    const hardLimitMins = 22 * 60;

    int endHour;
    int endMinute;
    bool extendedHoursApplied = false;

    if (baseEndTotalMins > hardLimitMins) {
      endHour = 22;
      endMinute = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⏰ Booking capped at 22:00 (10 PM) - Hard closing time',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      if (hasExtendedHours) {
        final withExtraMins = baseEndTotalMins + 30;

        if (withExtraMins > hardLimitMins) {
          endHour = 22;
          endMinute = 0;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Extended Hours +30 mins limited - Capped at 22:00 hard limit',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          endHour = withExtraMins ~/ 60;
          endMinute = withExtraMins % 60;
          extendedHoursApplied = true;
        }
      } else {
        endHour = baseEndHour;
        endMinute = baseEndMinute;
      }
    }

    // Check if user is late for the selected slot
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    if (isToday) {
      final selectedSlotMins = startTime.hour * 60 + startTime.minute;
      final currentMins = now.hour * 60 + now.minute;

      if (currentMins > selectedSlotMins) {
        final lateByMins = currentMins - selectedSlotMins;

        if (lateByMins <= 30) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ You are $lateByMins minutes late for this slot\n'
                'End time remains ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} - '
                'You will get ${((endHour * 60 + endMinute) - currentMins) ~/ 60}h ${((endHour * 60 + endMinute) - currentMins) % 60}m',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }

    if (extendedHoursApplied) {
      debugPrint('✅ Extended Hours: Added +30 mins to booking');
    }

    return TimeOfDay(hour: endHour, minute: endMinute);
  }

  /// Check if selected subscription has specific addon
  static bool hasAddon({
    required String? selectedSubscriptionId,
    required List<Map<String, dynamic>> subscriptions,
    required String addonCode,
  }) {
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
          return addons.any((addon) => addon['code'] == addonCode);
        }
      }
    }
    return false;
  }
}
