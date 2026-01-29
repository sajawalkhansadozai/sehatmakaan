import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehatmakaan/core/constants/constants.dart';
import 'package:sehatmakaan/core/constants/types.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';

class DateSlotSelectionStep extends StatefulWidget {
  final SuiteType? selectedSuite;
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int selectedHours;
  final List<Map<String, dynamic>> selectedAddons;
  final Function(DateTime) onDateChanged;
  final Function(String) onTimeSlotSelected;
  final Function(TimeOfDay) onStartTimeSelected;
  final Function(TimeOfDay) onEndTimeSelected;

  const DateSlotSelectionStep({
    super.key,
    required this.selectedSuite,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.startTime,
    required this.endTime,
    required this.selectedHours,
    required this.selectedAddons,
    required this.onDateChanged,
    required this.onTimeSlotSelected,
    required this.onStartTimeSelected,
    required this.onEndTimeSelected,
  });

  @override
  State<DateSlotSelectionStep> createState() => _DateSlotSelectionStepState();
}

class _DateSlotSelectionStepState extends State<DateSlotSelectionStep> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _availableSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  @override
  void didUpdateWidget(DateSlotSelectionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedHours != widget.selectedHours ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.selectedAddons.length != widget.selectedAddons.length) {
      _loadAvailableSlots();
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoadingSlots = true);

    try {
      final startOfDay = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final suiteType = widget.selectedSuite?.value;
      debugPrint('🏥 Loading slots for suite: $suiteType');

      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('suiteType', isEqualTo: suiteType)
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .get();

      final bookedRanges = <Map<String, int>>[];
      for (final doc in bookingsQuery.docs) {
        final data = doc.data();
        final startTime = data['startTime'] as String?;
        final endTime = data['endTime'] as String?;

        if (startTime != null && endTime != null) {
          final startParts = startTime.split(':');
          final endParts = endTime.split(':');

          final startMinutes =
              int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMinutes =
              int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

          bookedRanges.add({'start': startMinutes, 'end': endMinutes});
        }
      }

      final available = <String>[];
      final now = DateTime.now();
      final isToday =
          widget.selectedDate.year == now.year &&
          widget.selectedDate.month == now.month &&
          widget.selectedDate.day == now.day;

      // Find the last booking end time for custom slot insertion
      int? lastBookingEndMins;
      for (final range in bookedRanges) {
        if (lastBookingEndMins == null || range['end']! > lastBookingEndMins) {
          lastBookingEndMins = range['end'];
        }
      }

      final hasExtendedHours = widget.selectedAddons.any(
        (addon) => addon['code'] == 'extended_hours',
      );
      final allTimeSlots = AppConstants.getAllTimeSlots(
        includeExtended: hasExtendedHours,
      );

      final hasPriorityBooking = widget.selectedAddons.any(
        (addon) => addon['code'] == 'priority_booking',
      );

      debugPrint('🎯 hasPriorityBooking: $hasPriorityBooking');

      for (final slot in allTimeSlots) {
        final slotParts = slot.split(':');
        final slotHour = int.parse(slotParts[0]);
        final slotMinutes = slotHour * 60 + int.parse(slotParts[1]);

        final isWeekend =
            widget.selectedDate.weekday == DateTime.saturday ||
            widget.selectedDate.weekday == DateTime.sunday;
        final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
        final isPrioritySlot = isWeekend || isPriorityTime;

        if (isPrioritySlot && !hasPriorityBooking) {
          continue;
        }

        // Hard limit: Skip slots where 1-hour booking would exceed 22:00
        const hardLimitMins = 22 * 60;
        const minBookingMins = 60;
        if (slotMinutes + minBookingMins > hardLimitMins) {
          continue;
        }

        // Skip past time slots for today with grace period
        if (isToday) {
          final currentMinutes = now.hour * 60 + now.minute;
          const gracePeriodMins = 30;
          if (slotMinutes + gracePeriodMins < currentMinutes) {
            continue;
          }
        }

        // Check availability - ensure ENTIRE duration fits (strict gap analysis)
        bool isAvailable = true;
        const minBookingDuration = 60; // Minimum 1 hour booking
        final slotEndMinutes = slotMinutes + minBookingDuration;

        for (final range in bookedRanges) {
          // Check if slot overlaps with any existing booking
          if (slotMinutes < range['end']! && slotEndMinutes > range['start']!) {
            isAvailable = false;
            break;
          }
        }

        if (isAvailable) {
          available.add(slot);
        }
      }

      // Add custom slot after last booking with 15-minute buffer
      if (lastBookingEndMins != null) {
        const bufferTimeMins = 15; // Mandatory buffer between bookings
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
              widget.selectedDate.weekday == DateTime.saturday ||
              widget.selectedDate.weekday == DateTime.sunday;
          final isPriorityTime = (nextHour >= 18 && nextHour <= 22);
          final isPrioritySlot = isWeekend || isPriorityTime;

          final canAddSlot = !isPrioritySlot || hasPriorityBooking;

          if (canAddSlot && !available.contains(customSlot)) {
            if (isToday) {
              final currentMinutes = now.hour * 60 + now.minute;
              const gracePeriodMins = 30;
              if (nextAvailableMins + gracePeriodMins > currentMinutes) {
                available.insert(0, customSlot);
              }
            } else {
              available.insert(0, customSlot);
            }
          }
        }
      }

      // Sort slots chronologically
      available.sort((a, b) {
        final aParts = a.split(':');
        final bParts = b.split(':');
        final aMins = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
        final bMins = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
        return aMins.compareTo(bMins);
      });

      if (mounted) {
        setState(() {
          _availableSlots.clear();
          _availableSlots.addAll(available);
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading slots: $e');
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  void _handleSlotSelection(String slot) {
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final startTime = TimeOfDay(hour: hour, minute: minute);

    // Default 1-hour duration - same as monthly booking
    final startMins = hour * 60 + minute;
    final endMins = startMins + 60;
    const hardLimitMins = 22 * 60;

    TimeOfDay endTime;
    if (endMins > hardLimitMins) {
      endTime = const TimeOfDay(hour: 22, minute: 0);
    } else {
      endTime = TimeOfDay(hour: endMins ~/ 60, minute: endMins % 60);
    }

    widget.onTimeSlotSelected(slot);
    widget.onStartTimeSelected(startTime);
    widget.onEndTimeSelected(endTime);
  }

  void _setDuration(double hours) {
    if (widget.startTime == null) return;

    // Check for Extended Hours addon
    final hasExtendedHours = widget.selectedAddons.any(
      (addon) => addon['code'] == 'extended_hours',
    );

    // Calculate end time WITHOUT Extended Hours first
    final startTotalMins =
        widget.startTime!.hour * 60 + widget.startTime!.minute;
    final durationMins = (hours * 60).toInt();
    final baseEndTotalMins = startTotalMins + durationMins;
    int baseEndHour = baseEndTotalMins ~/ 60;
    int baseEndMinute = baseEndTotalMins % 60;

    // Check if user has Priority Booking addon
    final hasPriorityBooking = widget.selectedAddons.any(
      (addon) => addon['code'] == 'priority_booking',
    );

    // Check if end time falls into priority hours
    final isWeekend =
        widget.selectedDate.weekday == DateTime.saturday ||
        widget.selectedDate.weekday == DateTime.sunday;

    if (!hasPriorityBooking) {
      if (isWeekend) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Weekend bookings require Priority Booking addon\nAdd the addon to book on Saturdays and Sundays',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      } else if (baseEndHour >= 18) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ This duration would extend into priority hours (after 17:00)\nYou need Priority Booking addon or choose shorter duration',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    // Hard limit: No booking can extend beyond 22:00
    const hardLimitMins = 22 * 60;

    int endHour;
    int endMinute;

    if (baseEndTotalMins > hardLimitMins) {
      endHour = 22;
      endMinute = 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⏰ Booking capped at 22:00 (10 PM) - Hard closing time',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (hasExtendedHours) {
        final withExtraMins = baseEndTotalMins + 30;

        if (withExtraMins > hardLimitMins) {
          endHour = 22;
          endMinute = 0;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⚠️ Extended Hours +30 mins limited - Capped at 22:00 hard limit',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          endHour = withExtraMins ~/ 60;
          endMinute = withExtraMins % 60;
        }
      } else {
        endHour = baseEndHour;
        endMinute = baseEndMinute;
      }
    }

    // Check if user is late for the selected slot (same as monthly)
    final now = DateTime.now();
    final isToday =
        widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;

    if (isToday && widget.startTime != null) {
      final selectedSlotMins =
          widget.startTime!.hour * 60 + widget.startTime!.minute;
      final currentMins = now.hour * 60 + now.minute;

      if (currentMins > selectedSlotMins) {
        final lateByMins = currentMins - selectedSlotMins;

        if (lateByMins <= 30) {
          if (mounted) {
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
    }

    widget.onEndTimeSelected(TimeOfDay(hour: endHour, minute: endMinute));
  }

  String _calculateDuration() {
    if (widget.startTime == null || widget.endTime == null) return '0h 0m';
    final startMinutes = widget.startTime!.hour * 60 + widget.startTime!.minute;
    final endMinutes = widget.endTime!.hour * 60 + widget.endTime!.minute;
    final totalMinutes = endMinutes - startMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Widget _buildTimeDisplay({
    required String label,
    required TimeOfDay? time,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time != null
                ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                : '--:--',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 4: Select Date & Time Slot',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006876),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context) * 0.3,
          ),
          Text(
            'Choose your preferred date and time slot',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          Text(
            'Booking Date',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006876),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5,
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: widget.selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                widget.onDateChanged(picked);
                _loadAvailableSlots();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF006876)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF006876)),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006876),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Available Time Slots',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingSlots)
            const Center(child: CircularProgressIndicator())
          else if (_availableSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No slots available for this date. Please select another date.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableSlots.map((slot) {
                final isSelected = widget.selectedTimeSlot == slot;
                return InkWell(
                  onTap: () => _handleSlotSelection(slot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF006876)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF006876)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF006876),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          if (widget.selectedTimeSlot != null) ...[
            const Text(
              'Select Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDurationButton(1, '1 Hour')),
                const SizedBox(width: 8),
                Expanded(child: _buildDurationButton(2, '2 Hours')),
                const SizedBox(width: 8),
                Expanded(child: _buildDurationButton(3, '3 Hours')),
                const SizedBox(width: 8),
                Expanded(child: _buildDurationButton(4, '4 Hours')),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Booking Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calculated from slot selection and duration',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeDisplay(
                    label: 'Start Time',
                    time: widget.startTime,
                    subtitle: 'From slot selection',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeDisplay(
                    label: 'End Time',
                    time: widget.endTime,
                    subtitle: 'Auto-calculated',
                  ),
                ),
              ],
            ),
            if (widget.startTime != null && widget.endTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF006876).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF006876), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Color(0xFF006876), size: 24),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        const Text(
                          'Total Duration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF006876),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _calculateDuration(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006876),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDurationButton(double hours, String label) {
    // Check if user has Extended Hours addon (same logic as monthly)
    final hasExtendedHours = widget.selectedAddons.any(
      (addon) => addon['code'] == 'extended_hours',
    );

    // Calculate expected duration WITH Extended Hours bonus
    final extraMinutes = hasExtendedHours ? 30 : 0;
    final expectedDuration = (hours * 60).toInt() + extraMinutes;

    final isSelected =
        widget.startTime != null &&
        widget.endTime != null &&
        (widget.endTime!.hour * 60 + widget.endTime!.minute) -
                (widget.startTime!.hour * 60 + widget.startTime!.minute) ==
            expectedDuration;

    // Dynamic button disabling: Check if duration fits in available gap
    bool isDisabled = false;
    if (widget.startTime != null) {
      final startMins = widget.startTime!.hour * 60 + widget.startTime!.minute;
      final requiredEndMins = startMins + expectedDuration;
      const hardLimitMins = 22 * 60;

      // Disable if would exceed hard limit
      if (requiredEndMins > hardLimitMins) {
        isDisabled = true;
      }

      // Check priority hours restriction
      final hasPriorityBooking = widget.selectedAddons.any(
        (addon) => addon['code'] == 'priority_booking',
      );
      if (!hasPriorityBooking && requiredEndMins >= 18 * 60) {
        isDisabled = true;
      }

      // Check if conflicts with existing bookings
      // This is a quick check - full validation happens on booking
      final isWeekend =
          widget.selectedDate.weekday == DateTime.saturday ||
          widget.selectedDate.weekday == DateTime.sunday;
      if (isWeekend && !hasPriorityBooking) {
        isDisabled = true;
      }
    }

    return InkWell(
      onTap: isDisabled
          ? null
          : () {
              if (widget.startTime != null) {
                _setDuration(hours);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a time slot first'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected && !isDisabled
              ? const LinearGradient(
                  colors: [Color(0xFF006876), Color(0xFF008C9E)],
                )
              : null,
          color: isDisabled
              ? Colors.grey.shade300
              : (isSelected ? null : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.shade400
                : (isSelected ? const Color(0xFF006876) : Colors.grey.shade300),
            width: isSelected && !isDisabled ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: isDisabled
                  ? Colors.grey.shade600
                  : (isSelected ? Colors.white : const Color(0xFF006876)),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDisabled
                    ? Colors.grey.shade600
                    : (isSelected ? Colors.white : const Color(0xFF006876)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
