import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/utils/constants.dart';
import 'package:sehat_makaan_flutter/utils/types.dart';

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
    // Reload slots if hours changed, date changed, or addons changed (for extended hours)
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

      // Filter bookings by suite type - conflicts only within same suite (like monthly booking)
      final suiteType = widget.selectedSuite?.value;
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

      // Build set of booked time ranges
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

      // Check which slots are available (not overlapping with booked ranges)
      final available = <String>[];
      final now = DateTime.now();
      final isToday =
          widget.selectedDate.year == now.year &&
          widget.selectedDate.month == now.month &&
          widget.selectedDate.day == now.day;

      // Check if user has purchased Extended Hours addon
      final hasExtendedHours = widget.selectedAddons.any(
        (addon) => addon['code'] == 'extended_hours',
      );
      final allTimeSlots = AppConstants.getAllTimeSlots(
        includeExtended: hasExtendedHours,
      );

      // Check if Priority Booking addon is active
      final hasPriorityBooking = widget.selectedAddons.any(
        (addon) => addon['code'] == 'priority_booking',
      );

      for (final slot in allTimeSlots) {
        final slotParts = slot.split(':');
        final slotHour = int.parse(slotParts[0]);
        final slotMinutes = slotHour * 60 + int.parse(slotParts[1]);

        // Check if slot is in priority time (weekends or after 6pm or midnight)
        final isWeekend =
            widget.selectedDate.weekday == DateTime.saturday ||
            widget.selectedDate.weekday == DateTime.sunday;
        final isPriorityTime =
            slotHour >= 18 || slotHour == 0; // 6pm onwards or midnight
        final isPrioritySlot = isWeekend || isPriorityTime;

        // ❌ Skip priority slots if user doesn't have Priority Booking addon
        if (isPrioritySlot && !hasPriorityBooking) {
          continue;
        }

        // ❌ Skip past time slots for today
        if (isToday) {
          final currentMinutes = now.hour * 60 + now.minute;
          if (slotMinutes <= currentMinutes) {
            continue; // This slot has already passed
          }
        }

        // Check if this slot + selected hours is available
        // Need to check the entire duration range
        final bookingEndMinutes = slotMinutes + (widget.selectedHours * 60);

        bool isAvailable = true;
        for (final range in bookedRanges) {
          // Check if booking would overlap with any existing booking
          // Overlap if: booking starts before range ends AND booking ends after range starts
          if (slotMinutes < range['end']! &&
              bookingEndMinutes > range['start']!) {
            isAvailable = false;
            break;
          }
        }

        if (isAvailable) {
          available.add(slot);
        }
      }

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
    // Parse slot to set as start time
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final startTime = TimeOfDay(hour: hour, minute: minute);

    // Check if Extended Hours addon is active (adds +30 mins)
    final hasExtendedHours = widget.selectedAddons.any(
      (addon) => addon['code'] == 'extended_hours',
    );
    final extraMinutes = hasExtendedHours ? 30 : 0;

    // Set end time based on selected duration + extra minutes
    int totalMinutes = (widget.selectedHours * 60) + minute + extraMinutes;
    int endHour = hour + (totalMinutes ~/ 60);
    int endMinute = totalMinutes % 60;

    // Handle day overflow
    if (endHour >= 24) {
      endHour = 23;
      endMinute = 59;
    }

    final endTime = TimeOfDay(hour: endHour, minute: endMinute);

    // Update parent state
    widget.onTimeSlotSelected(slot);
    widget.onStartTimeSelected(startTime);
    widget.onEndTimeSelected(endTime);
  }

  void _setDuration(int hours) {
    if (widget.startTime == null) return;

    // Check if Extended Hours addon is active (adds +30 mins)
    final hasExtendedHours = widget.selectedAddons.any(
      (addon) => addon['code'] == 'extended_hours',
    );
    final extraMinutes = hasExtendedHours ? 30 : 0;

    int totalMinutes = (hours * 60) + widget.startTime!.minute + extraMinutes;
    int endHour = widget.startTime!.hour + (totalMinutes ~/ 60);
    int endMinute = totalMinutes % 60;

    // Handle day overflow
    if (endHour >= 24) {
      endHour = 23;
      endMinute = 59;
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 4: Select Date & Time Slot',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your preferred date and time slot',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'Booking Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 12),
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
          Row(
            children: [
              const Text(
                'Available Time Slots',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
              if (widget.selectedAddons.any(
                (a) => a['code'] == 'extended_hours',
              )) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Extended Hours Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Priority Booking Info
          if (widget.selectedAddons.any((a) => a['code'] == 'priority_booking'))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFC107)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFFFC107),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Priority Booking Active: You can now book weekend slots and 6pm-10pm time slots!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Extended Hours Info
          if (widget.selectedAddons.any((a) => a['code'] == 'extended_hours'))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF9800)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFFFF9800),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Extended Hours Active: 30 minutes extra per booking!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Select a time slot to start your booking. You can adjust the exact start and end time after selection.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
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
                final isExtendedHour = AppConstants.extendedTimeSlots.contains(
                  slot,
                );

                // Check if this is a priority time slot
                final slotParts = slot.split(':');
                final slotHour = int.parse(slotParts[0]);
                final isWeekend =
                    widget.selectedDate.weekday == DateTime.saturday ||
                    widget.selectedDate.weekday == DateTime.sunday;
                final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
                final isPrioritySlot = isWeekend || isPriorityTime;

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
                          : isPrioritySlot
                          ? const Color(0xFFFFF9C4) // Light yellow for priority
                          : isExtendedHour
                          ? const Color(0xFFFFF3E0)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF006876)
                            : isPrioritySlot
                            ? const Color(0xFFFFC107)
                            : isExtendedHour
                            ? const Color(0xFFFF9800)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPrioritySlot && !isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.workspace_premium,
                              size: 16,
                              color: Color(0xFFFFC107),
                            ),
                          )
                        else if (isExtendedHour && !isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                        Text(
                          slot,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isPrioritySlot
                                ? const Color(0xFFFFC107)
                                : isExtendedHour
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF006876),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          if (widget.selectedTimeSlot != null) ...[
            // Show selected hours prominently
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF006876).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF006876), width: 2),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF006876),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Duration',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.selectedHours} Hour${widget.selectedHours > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006876),
                          ),
                        ),
                        if (widget.startTime != null &&
                            widget.endTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${widget.selectedTimeSlot} - ${widget.endTime!.hour.toString().padLeft(2, '0')}:${widget.endTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how long you need the suite',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
              'Or Adjust Manually',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fine-tune your exact start and end time',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF90D26D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90D26D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF90D26D)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Selected: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006876),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Starting at: ${widget.selectedTimeSlot}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(
                          context,
                          'Start Time',
                          widget.startTime,
                          (picked) {
                            widget.onStartTimeSelected(picked);
                            // Update timeSlot to match start time
                            widget.onTimeSlotSelected(
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                            );

                            // Validate end time if already selected
                            if (widget.endTime != null) {
                              final startMinutes =
                                  picked.hour * 60 + picked.minute;
                              final endMinutes =
                                  widget.endTime!.hour * 60 +
                                  widget.endTime!.minute;
                              if (endMinutes <= startMinutes) {
                                // Auto-adjust end time to 1 hour after new start time
                                final newEndHour = picked.hour + 1;
                                final newEndMinute = picked.minute;
                                if (newEndHour < 24) {
                                  widget.onEndTimeSelected(
                                    TimeOfDay(
                                      hour: newEndHour,
                                      minute: newEndMinute,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePicker(
                          context,
                          'End Time',
                          widget.endTime,
                          (picked) {
                            if (widget.startTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select start time first',
                                  ),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            // Check for Extended Hours addon
                            final hasExtendedHours = widget.selectedAddons.any(
                              (addon) => addon['code'] == 'extended_hours',
                            );

                            // Check hard limit: 22:00 normally, 22:30 with Extended Hours
                            final endMinutes = picked.hour * 60 + picked.minute;
                            final hardLimitMins = hasExtendedHours
                                ? (22 * 60 + 30)
                                : (22 * 60);

                            if (endMinutes > hardLimitMins) {
                              final limitTime = hasExtendedHours
                                  ? '22:30 (10:30 PM)'
                                  : '22:00 (10:00 PM)';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bookings must end by $limitTime',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            final startMinutes =
                                widget.startTime!.hour * 60 +
                                widget.startTime!.minute;
                            if (endMinutes <= startMinutes) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'End time must be after start time',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            widget.onEndTimeSelected(picked);
                          },
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
                        border: Border.all(
                          color: const Color(0xFF006876),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Color(0xFF006876),
                            size: 24,
                          ),
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationButton(int hours, String label) {
    final isSelected =
        widget.startTime != null &&
        widget.endTime != null &&
        (widget.endTime!.hour * 60 + widget.endTime!.minute) -
                (widget.startTime!.hour * 60 + widget.startTime!.minute) ==
            hours * 60;

    return InkWell(
      onTap: () {
        if (widget.startTime != null) {
          _setDuration(hours);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a start time first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF006876), Color(0xFF008C9E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF006876) : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF006876).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: isSelected ? Colors.white : const Color(0xFF006876),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF006876),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onTimePicked,
  ) {
    // Determine initial time based on label and current context
    TimeOfDay getInitialTime() {
      if (time != null) return time;
      if (label == 'End Time' && widget.startTime != null) {
        // For end time, default to 1 hour after start time
        final startMins =
            widget.startTime!.hour * 60 + widget.startTime!.minute;
        final endMins = startMins + 60;
        final hour = (endMins ~/ 60).clamp(0, 22);
        final minute = endMins % 60;
        return TimeOfDay(hour: hour, minute: minute);
      }
      return const TimeOfDay(hour: 9, minute: 0);
    }

    return Column(
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
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: getInitialTime(),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: false),
                  child: Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF006876),
                      ),
                      timePickerTheme: TimePickerThemeData(
                        hourMinuteTextColor: const Color(0xFF006876),
                        dayPeriodTextColor: const Color(0xFF006876),
                      ),
                    ),
                    child: child!,
                  ),
                );
              },
            );
            if (picked != null) {
              onTimePicked(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF006876), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time != null
                      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                      : 'Select',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: time != null ? const Color(0xFF006876) : Colors.grey,
                  ),
                ),
                const Icon(Icons.access_time, color: Color(0xFF006876)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
