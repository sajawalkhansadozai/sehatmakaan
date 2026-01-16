import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/utils/constants.dart';

class LiveSlotBookingWidget extends StatefulWidget {
  final Map<String, dynamic> userSession;
  final VoidCallback? onBooked;

  const LiveSlotBookingWidget({
    super.key,
    required this.userSession,
    this.onBooked,
  });

  @override
  State<LiveSlotBookingWidget> createState() => _LiveSlotBookingWidgetState();
}

class _LiveSlotBookingWidgetState extends State<LiveSlotBookingWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSpecialty;
  String? _selectedTime;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  List<Map<String, dynamic>> _subscriptions = [];
  String? _selectedSubscriptionId; // Track which subscription to use
  final List<String> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadSubscriptions();
    await _loadAvailableSlots();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final userId = widget.userSession['id']?.toString();
      debugPrint('🔍 Loading subscriptions for userId: $userId');

      if (userId == null || userId.isEmpty) {
        debugPrint('❌ Error: User ID is null or empty in userSession');
        debugPrint('UserSession contents: ${widget.userSession}');
        return;
      }

      final query = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('📦 Found ${query.docs.length} subscriptions');

      for (var doc in query.docs) {
        debugPrint('   Subscription ${doc.id}:');
        debugPrint('   - status: ${doc.data()['status']}');
        debugPrint('   - selectedAddons: ${doc.data()['selectedAddons']}');
      }

      if (mounted) {
        setState(() {
          _subscriptions = query.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          debugPrint('🔢 Total subscriptions loaded: ${_subscriptions.length}');
          for (var i = 0; i < _subscriptions.length; i++) {
            final sub = _subscriptions[i];
            debugPrint(
              '   ${i + 1}. ${sub['packageType']} - ${sub['remainingHours']} hrs',
            );
          }

          // Auto-select first subscription if only one exists
          if (_subscriptions.length == 1) {
            _selectedSubscriptionId = _subscriptions[0]['id'] as String;
            debugPrint('   🎯 Auto-selected single subscription');
          } else if (_subscriptions.length > 1) {
            debugPrint('   ⚠️ Multiple subscriptions - user must select!');
          }
        });
        debugPrint(
          '✅ Loaded ${_subscriptions.length} subscriptions into state',
        );
        if (_selectedSubscriptionId != null) {
          debugPrint(
            '   🎯 Auto-selected subscription: $_selectedSubscriptionId',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading subscriptions: $e');
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoadingSlots = true);

    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .get();

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

      final available = <String>[];
      final now = DateTime.now();
      final isToday =
          _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;

      // Find the last booking end time for today
      int? lastBookingEndMins;
      for (final range in bookedRanges) {
        if (lastBookingEndMins == null || range['end']! > lastBookingEndMins) {
          lastBookingEndMins = range['end'];
        }
      }
      debugPrint(
        '📍 Last booking ends at: ${lastBookingEndMins != null ? '${lastBookingEndMins ~/ 60}:${(lastBookingEndMins % 60).toString().padLeft(2, '0')}' : 'N/A'}',
      );

      // Check if selected subscription has Priority Booking or Extended Hours addons
      // If no subscription selected, use the first one for filtering purposes
      bool hasPriorityBooking = false;
      bool hasExtendedHours = false;

      final subscriptionToCheck =
          _selectedSubscriptionId ??
          (_subscriptions.isNotEmpty
              ? _subscriptions[0]['id'] as String?
              : null);

      if (subscriptionToCheck != null) {
        final selectedSub = _subscriptions.firstWhere(
          (sub) => sub['id'] == subscriptionToCheck,
          orElse: () => {},
        );

        if (selectedSub.isNotEmpty) {
          debugPrint(
            '🔍 Checking addons for subscription: $subscriptionToCheck ${_selectedSubscriptionId == null ? '(auto-using first)' : '(user selected)'}',
          );
          final addons = selectedSub['selectedAddons'] as List?;
          debugPrint('   Addons: $addons');

          if (addons != null) {
            for (final addon in addons) {
              debugPrint('   - ${addon['name']} (${addon['code']})');
              if (addon['code'] == 'priority_booking') {
                hasPriorityBooking = true;
                debugPrint('   ✅ Priority Booking FOUND!');
              }
              if (addon['code'] == 'extended_hours') {
                hasExtendedHours = true;
                debugPrint('   ✅ Extended Hours FOUND!');
              }
            }
          }
        }
      }

      debugPrint('🎯 Final addon status:');
      debugPrint('   hasPriorityBooking: $hasPriorityBooking');
      debugPrint('   hasExtendedHours: $hasExtendedHours');

      // For monthly live slot bookings, don't include extended hours (23:00-00:00)
      // Extended Hours addon only adds +30 mins to bookings, not late night slots
      final allTimeSlots = AppConstants.getAllTimeSlots(
        includeExtended: false, // Monthly subscriptions: only up to 22:00
      );
      debugPrint('⏰ Total slots available: ${allTimeSlots.length}');
      debugPrint(
        '📅 Selected date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      );
      debugPrint('📅 Is today? $isToday');
      debugPrint('🕐 Current time: ${now.hour}:${now.minute}');

      for (final slot in allTimeSlots) {
        final parts = slot.split(':');
        final slotHour = int.parse(parts[0]);
        final slotMins = slotHour * 60 + int.parse(parts[1]);

        debugPrint('🔍 Checking slot: $slot (${slotMins} mins)');

        // Check if slot is in priority time (weekends or 6pm-10pm)
        final isWeekend =
            _selectedDate.weekday == DateTime.saturday ||
            _selectedDate.weekday == DateTime.sunday;
        final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
        final isPrioritySlot = isWeekend || isPriorityTime;

        if (isPrioritySlot) {
          debugPrint(
            '   🔶 Priority slot detected - Weekend: $isWeekend, Evening: ${slotHour >= 18 && slotHour <= 22}',
          );
        }

        // Skip priority slots if user doesn't have Priority Booking addon
        if (isPrioritySlot && !hasPriorityBooking) {
          debugPrint('   ⏭️  Skipping priority slot $slot (no addon)');
          continue;
        } else if (isPrioritySlot && hasPriorityBooking) {
          debugPrint('   ✅ Including priority slot $slot (addon active)');
        }

        // ❌ Skip past time slots for today ONLY
        if (isToday) {
          final currentMinutes = now.hour * 60 + now.minute;
          if (slotMins <= currentMinutes) {
            debugPrint(
              '   ⏭️  Skipping past slot $slot (current time: ${now.hour}:${now.minute})',
            );
            continue; // This slot has already passed
          }
        }

        bool isAvailable = true;
        for (final range in bookedRanges) {
          if (slotMins >= range['start']! && slotMins < range['end']!) {
            isAvailable = false;
            debugPrint('   ❌ Slot $slot conflicts with existing booking');
            break;
          }
        }

        if (isAvailable) {
          debugPrint('   ✅ Adding available slot: $slot');
          available.add(slot);
        }
      }

      // ✅ Add custom slot immediately after last booking (if exists)
      // This allows back-to-back bookings with proper 5-minute gap
      if (lastBookingEndMins != null) {
        final nextAvailableMins = lastBookingEndMins + 5; // 5 minute buffer
        final nextHour = nextAvailableMins ~/ 60;
        final nextMin = nextAvailableMins % 60;

        // Only add if it's within working hours and not already in list
        if (nextHour < 24) {
          final customSlot =
              '${nextHour.toString().padLeft(2, '0')}:${nextMin.toString().padLeft(2, '0')}';

          // Check if this custom slot is during priority hours
          final isWeekend =
              _selectedDate.weekday == DateTime.saturday ||
              _selectedDate.weekday == DateTime.sunday;
          final isPriorityTime = (nextHour >= 18 && nextHour <= 22);
          final isPrioritySlot = isWeekend || isPriorityTime;

          // Only add if user has addon for priority time, or it's regular time
          final canAddSlot = !isPrioritySlot || hasPriorityBooking;

          if (canAddSlot && !available.contains(customSlot)) {
            // Check if it's not in the past
            if (isToday) {
              final currentMinutes = now.hour * 60 + now.minute;
              if (nextAvailableMins > currentMinutes) {
                available.insert(
                  0,
                  customSlot,
                ); // Add at beginning for priority
                debugPrint(
                  '✨ Added custom slot after last booking: $customSlot',
                );
              }
            } else {
              available.insert(0, customSlot);
              debugPrint('✨ Added custom slot after last booking: $customSlot');
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableSlots.clear();
          debugPrint('✅ Final available slots: ${available.length}');
          debugPrint('   Slots: $available');
          _availableSlots.addAll(available);
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading available slots: $e');
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  Future<void> _bookSlot() async {
    if (_selectedSpecialty == null ||
        _selectedTime == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    // Check if subscription is selected (for multiple subscriptions)
    if (_subscriptions.length > 1 && _selectedSubscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select which subscription to use'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final durationMinutes =
        (_endTime!.hour * 60 + _endTime!.minute) -
        (_startTime!.hour * 60 + _startTime!.minute);
    final durationHours = (durationMinutes / 60).ceil();
    final exactHours =
        durationMinutes / 60.0; // Exact hours with decimals (e.g., 1.5)

    // Get selected subscription's remaining time
    int selectedSubRemainingMins = 0;
    if (_selectedSubscriptionId != null) {
      final selectedSub = _subscriptions.firstWhere(
        (sub) => sub['id'] == _selectedSubscriptionId,
        orElse: () => {},
      );
      if (selectedSub.isNotEmpty) {
        final hours = selectedSub['remainingHours'] as int? ?? 0;
        final mins = selectedSub['remainingMinutes'] as int? ?? 0;
        selectedSubRemainingMins = (hours * 60) + mins;
      }
    }

    // Check if selected subscription has enough time
    if (durationMinutes > selectedSubRemainingMins) {
      final totalHours = selectedSubRemainingMins / 60.0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough time in selected subscription! You need ${exactHours.toStringAsFixed(1)} hours but only have ${totalHours.toStringAsFixed(1)} hours remaining.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Validate that selected time range doesn't conflict with existing bookings
    final startMins = _startTime!.hour * 60 + _startTime!.minute;
    final endMins = _endTime!.hour * 60 + _endTime!.minute;

    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingBookings = await _firestore
          .collection('bookings')
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .get();

      for (final doc in existingBookings.docs) {
        final data = doc.data();
        final bookingStart = data['startTime'] as String?;
        final bookingEnd = data['endTime'] as String?;

        if (bookingStart != null && bookingEnd != null) {
          final bookingStartParts = bookingStart.split(':');
          final bookingEndParts = bookingEnd.split(':');
          final bookingStartMins =
              int.parse(bookingStartParts[0]) * 60 +
              int.parse(bookingStartParts[1]);
          final bookingEndMins =
              int.parse(bookingEndParts[0]) * 60 +
              int.parse(bookingEndParts[1]);

          // Check for overlap: booking starts before existing ends AND booking ends after existing starts
          if (startMins < bookingEndMins && endMins > bookingStartMins) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This time slot conflicts with an existing booking. Please choose different hours.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking booking conflicts: $e');
    }

    setState(() => _isLoading = true);

    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isLoading = false);
        }
        debugPrint('❌ Error: User ID is null in booking');
        debugPrint('UserSession: ${widget.userSession}');
        return;
      }

      final startTimeStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final endTimeStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

      // Create booking
      await _firestore.collection('bookings').add({
        'userId': userId,
        'suiteType': _getSuiteTypeForSpecialty(_selectedSpecialty!),
        'specialty': _selectedSpecialty,
        'bookingDate': Timestamp.fromDate(_selectedDate),
        'timeSlot': _selectedTime,
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'durationHours': durationHours,
        'durationMins': durationMinutes % 60,
        'totalDurationMins': durationMinutes,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update subscription hours (deduct from SELECTED subscription only)
      if (_selectedSubscriptionId != null) {
        final selectedSub = _subscriptions.firstWhere(
          (sub) => sub['id'] == _selectedSubscriptionId,
          orElse: () => {},
        );

        if (selectedSub.isNotEmpty) {
          final subId = selectedSub['id'] as String;
          final remainingHours = selectedSub['remainingHours'] as int? ?? 0;
          final remainingMins = selectedSub['remainingMinutes'] as int? ?? 0;
          final totalRemainingMins = (remainingHours * 60) + remainingMins;

          if (totalRemainingMins >= durationMinutes) {
            // Calculate new remaining time
            final newTotalRemainingMins = totalRemainingMins - durationMinutes;
            final newRemainingHours = newTotalRemainingMins ~/ 60;
            final newRemainingMinutes = newTotalRemainingMins % 60;

            debugPrint(
              '💰 Deducting $durationMinutes mins from selected subscription $subId',
            );
            debugPrint('   Before: $remainingHours hours, $remainingMins mins');
            debugPrint(
              '   After: $newRemainingHours hours, $newRemainingMinutes mins',
            );

            await _firestore.collection('subscriptions').doc(subId).update({
              'remainingHours': newRemainingHours,
              'remainingMinutes': newRemainingMinutes,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            debugPrint('⚠️ Selected subscription does not have enough hours!');
          }
        }
      }

      if (mounted) {
        final exactHours = durationMinutes / 60.0;
        final hoursText = exactHours == exactHours.floor()
            ? '${exactHours.toInt()} hour${exactHours.toInt() > 1 ? 's' : ''}'
            : '${exactHours.toStringAsFixed(1)} hours';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Slot booked! $hoursText deducted from your subscription.',
            ),
            backgroundColor: const Color(0xFF90D26D),
            duration: const Duration(seconds: 3),
          ),
        );

        // Call the callback first
        widget.onBooked?.call();

        // Small delay before closing to ensure UI updates complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Check mounted and canPop before popping
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('❌ Error booking slot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking slot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

  int get _remainingHours {
    return _subscriptions.fold<int>(
      0,
      (total, sub) => total + (sub['remainingHours'] as int? ?? 0),
    );
  }

  int get _remainingMinutes {
    return _subscriptions.fold<int>(
      0,
      (total, sub) => total + (sub['remainingMinutes'] as int? ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Book Live Slot',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show subscription count debug info
            if (_subscriptions.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Text(
                  '⚠️ Loading subscriptions...',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              Text(
                _remainingMinutes > 0
                    ? 'Total Remaining: $_remainingHours hours $_remainingMinutes mins'
                    : 'Total Remaining Hours: $_remainingHours',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B35),
                ),
              ),
            const SizedBox(height: 16),

            // IMPORTANT: Subscription selector (if multiple subscriptions)
            if (_subscriptions.length > 1) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You have multiple subscriptions. Please select one:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select Subscription *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF006876), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubscriptionId,
                    isExpanded: true,
                    hint: const Text(
                      '👆 Tap here to choose subscription',
                      style: TextStyle(color: Colors.grey),
                    ),
                    items: _subscriptions.map((sub) {
                      final subId = sub['id'] as String;
                      final packageType =
                          sub['packageType'] as String? ?? 'Package';
                      final remainingHours = sub['remainingHours'] as int? ?? 0;
                      final remainingMins =
                          sub['remainingMinutes'] as int? ?? 0;
                      final addons = sub['selectedAddons'] as List? ?? [];

                      return DropdownMenuItem<String>(
                        value: subId,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    packageType.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$remainingHours hrs${remainingMins > 0 ? ' $remainingMins mins' : ''} • ${addons.isNotEmpty ? '${addons.length} addon${addons.length > 1 ? 's' : ''}' : 'No addons'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubscriptionId = value;
                        debugPrint('🎯 User selected subscription: $value');
                      });
                      // Reload slots to update addon-based filtering
                      _loadAvailableSlots();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  _loadAvailableSlots();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF006876)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF006876)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Specialty',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'general-dentist',
                  child: Text('General Dentist'),
                ),
                DropdownMenuItem(
                  value: 'orthodontist',
                  child: Text('Orthodontist'),
                ),
                DropdownMenuItem(
                  value: 'endodontist',
                  child: Text('Endodontist'),
                ),
                DropdownMenuItem(
                  value: 'aesthetic-dermatology',
                  child: Text('Aesthetic Dermatology'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedSpecialty = value);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Time Slot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a slot to set your start time',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSlots.map((slot) {
                      final isSelected = _selectedTime == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _handleSlotSelection(slot);
                          }
                        },
                        selectedColor: const Color(0xFF006876),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
            if (_selectedTime != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Select Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how long you need the suite',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fine-tune your exact start and end time',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker('Start Time', _startTime, (time) {
                      setState(() {
                        _startTime = time;
                        if (_endTime != null) {
                          final startMins = time.hour * 60 + time.minute;
                          final endMins =
                              _endTime!.hour * 60 + _endTime!.minute;
                          if (endMins <= startMins) {
                            _endTime = TimeOfDay(
                              hour: (time.hour + 1) % 24,
                              minute: time.minute,
                            );
                          }
                        }
                      });
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker('End Time', _endTime, (time) {
                      if (_startTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select start time first'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      final startMins =
                          _startTime!.hour * 60 + _startTime!.minute;
                      final endMins = time.hour * 60 + time.minute;
                      if (endMins <= startMins) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End time must be after start time'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      setState(() => _endTime = time);
                    }),
                  ),
                ],
              ),
              if (_startTime != null && _endTime != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF006876).withValues(alpha: 0.1),
                        const Color(0xFF008C9E).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF006876),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Duration:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF006876),
                        ),
                      ),
                      Text(
                        '${((_endTime!.hour * 60 + _endTime!.minute) - (_startTime!.hour * 60 + _startTime!.minute)) ~/ 60}h ${((_endTime!.hour * 60 + _endTime!.minute) - (_startTime!.hour * 60 + _startTime!.minute)) % 60}m',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006876),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _bookSlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Book Slot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSlotSelection(String slot, {int durationHours = 1}) {
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    setState(() {
      _selectedTime = slot;
      _startTime = TimeOfDay(hour: hour, minute: minute);
      int endHour = hour + durationHours;
      int endMinute = minute;

      if (endHour >= 24) {
        endHour = 23;
        endMinute = 59;
      }

      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }

  void _setDuration(int hours) {
    if (_startTime == null) return;

    // Check if SELECTED subscription has Extended Hours addon (adds +30 mins)
    bool hasExtendedHours = false;

    final subscriptionToCheck =
        _selectedSubscriptionId ??
        (_subscriptions.isNotEmpty ? _subscriptions[0]['id'] as String? : null);

    if (subscriptionToCheck != null) {
      final selectedSub = _subscriptions.firstWhere(
        (sub) => sub['id'] == subscriptionToCheck,
        orElse: () => {},
      );

      if (selectedSub.isNotEmpty) {
        final addons = selectedSub['selectedAddons'] as List?;
        if (addons != null) {
          hasExtendedHours = addons.any(
            (addon) => addon['code'] == 'extended_hours',
          );
        }
      }
    }

    final extraMinutes = hasExtendedHours ? 30 : 0;
    final totalMinutes = (hours * 60) + _startTime!.minute + extraMinutes;
    int endHour = _startTime!.hour + (totalMinutes ~/ 60);
    int endMinute = totalMinutes % 60;

    if (endHour >= 24) {
      endHour = 23;
      endMinute = 59;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duration adjusted to fit within operating hours'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    });

    if (hasExtendedHours && extraMinutes > 0) {
      debugPrint('✅ Extended Hours: Added +30 mins to booking');
    }
  }

  Widget _buildDurationButton(int hours, String label) {
    // Check if SELECTED subscription has Extended Hours addon
    bool hasExtendedHours = false;

    final subscriptionToCheck =
        _selectedSubscriptionId ??
        (_subscriptions.isNotEmpty ? _subscriptions[0]['id'] as String? : null);

    if (subscriptionToCheck != null) {
      final selectedSub = _subscriptions.firstWhere(
        (sub) => sub['id'] == subscriptionToCheck,
        orElse: () => {},
      );

      if (selectedSub.isNotEmpty) {
        final addons = selectedSub['selectedAddons'] as List?;
        if (addons != null) {
          hasExtendedHours = addons.any(
            (addon) => addon['code'] == 'extended_hours',
          );
        }
      }
    }

    final extraMinutes = hasExtendedHours ? 30 : 0;
    final expectedDuration = (hours * 60) + extraMinutes;

    final isSelected =
        _startTime != null &&
        _endTime != null &&
        ((_endTime!.hour * 60 + _endTime!.minute) -
                (_startTime!.hour * 60 + _startTime!.minute)) ==
            expectedDuration;

    return InkWell(
      onTap: () {
        if (_startTime != null) {
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
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onTimePicked,
  ) {
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
              initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF006876),
                    ),
                  ),
                  child: child!,
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
