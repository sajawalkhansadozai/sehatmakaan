import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/slot_availability_service.dart';
import '../services/live_booking_helper.dart';
import '../utils/duration_calculator.dart';
import 'duration_button_widget.dart';
import 'subscription_selector_widget.dart';
import 'specialty_dropdown_widget.dart';
import 'time_slot_grid_widget.dart';

/// Main widget for live slot booking modal
/// Separated into multiple components for better maintainability
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
  final SlotAvailabilityService _slotService = SlotAvailabilityService();
  final LiveBookingHelper _bookingHelper = LiveBookingHelper();

  DateTime _selectedDate = DateTime.now();
  String? _selectedSpecialty;
  String? _selectedTime;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  List<Map<String, dynamic>> _subscriptions = [];
  String? _selectedSubscriptionId;
  List<String> _availableSlots = [];

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
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ Error: User ID is null');
        return;
      }

      final query = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (mounted) {
        setState(() {
          _subscriptions = query.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          // Auto-select if only one subscription
          if (_subscriptions.length == 1) {
            _selectedSubscriptionId = _subscriptions[0]['id'] as String;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading subscriptions: $e');
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoadingSlots = true);

    final slots = await _slotService.loadAvailableSlots(
      selectedDate: _selectedDate,
      selectedSubscriptionId: _selectedSubscriptionId,
      subscriptions: _subscriptions,
    );

    if (mounted) {
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
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

    if (_subscriptions.length > 1 && _selectedSubscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subscription')),
      );
      return;
    }

    final userId = widget.userSession['id']?.toString();
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _bookingHelper.createLiveBooking(
      context: context,
      userId: userId,
      specialty: _selectedSpecialty!,
      selectedDate: _selectedDate,
      selectedTime: _selectedTime!,
      startTime: _startTime!,
      endTime: _endTime!,
      selectedSubscriptionId: _selectedSubscriptionId,
      subscriptions: _subscriptions,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        widget.onBooked?.call();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    }
  }

  void _handleSlotSelection(String slot) {
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    setState(() {
      _selectedTime = slot;
      _startTime = TimeOfDay(hour: hour, minute: minute);

      // Default 1-hour duration
      final startMins = hour * 60 + minute;
      final endMins = startMins + 60;
      const hardLimitMins = 22 * 60;

      if (endMins > hardLimitMins) {
        _endTime = const TimeOfDay(hour: 22, minute: 0);
      } else {
        _endTime = TimeOfDay(hour: endMins ~/ 60, minute: endMins % 60);
      }
    });
  }

  void _setDuration(double hours) {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time first')),
      );
      return;
    }

    final hasExtendedHours = DurationCalculator.hasAddon(
      selectedSubscriptionId: _selectedSubscriptionId,
      subscriptions: _subscriptions,
      addonCode: 'extended_hours',
    );

    final hasPriorityBooking = DurationCalculator.hasAddon(
      selectedSubscriptionId: _selectedSubscriptionId,
      subscriptions: _subscriptions,
      addonCode: 'priority_booking',
    );

    final endTime = DurationCalculator.calculateEndTime(
      startTime: _startTime!,
      hours: hours,
      selectedDate: _selectedDate,
      hasExtendedHours: hasExtendedHours,
      hasPriorityBooking: hasPriorityBooking,
      context: context,
    );

    if (endTime != null) {
      setState(() => _endTime = endTime);
    }
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
            _buildHeader(),
            const SizedBox(height: 16),
            _buildRemainingHours(),
            const SizedBox(height: 16),

            // Subscription Selector (if multiple subscriptions)
            SubscriptionSelectorWidget(
              subscriptions: _subscriptions,
              selectedSubscriptionId: _selectedSubscriptionId,
              onChanged: _handleSubscriptionChange,
            ),

            _buildDateSelector(),
            const SizedBox(height: 24),

            // Specialty Dropdown
            SpecialtyDropdownWidget(
              selectedSpecialty: _selectedSpecialty,
              selectedSubscriptionId: _selectedSubscriptionId,
              subscriptions: _subscriptions,
              onChanged: (value) => setState(() => _selectedSpecialty = value),
            ),
            const SizedBox(height: 24),

            // Time Slot Grid
            TimeSlotGridWidget(
              availableSlots: _availableSlots,
              selectedTime: _selectedTime,
              isLoading: _isLoadingSlots,
              onSlotSelected: _handleSlotSelection,
            ),

            if (_selectedTime != null) ...[
              const SizedBox(height: 24),
              _buildDurationSelector(),
              const SizedBox(height: 20),
              _buildTimeAdjustment(),
              if (_startTime != null && _endTime != null) ...[
                const SizedBox(height: 16),
                _buildBookingSummary(),
              ],
            ],

            const SizedBox(height: 32),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
    );
  }

  Widget _buildRemainingHours() {
    if (_subscriptions.isEmpty) {
      return Container(
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
      );
    }

    return Text(
      _remainingMinutes > 0
          ? 'Total Remaining: $_remainingHours hours $_remainingMinutes mins'
          : 'Total Remaining Hours: $_remainingHours',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFFFF6B35),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            Expanded(
              child: DurationButtonWidget(
                hours: 1,
                label: '1 Hour',
                startTime: _startTime,
                endTime: _endTime,
                selectedDate: _selectedDate,
                selectedSubscriptionId: _selectedSubscriptionId,
                subscriptions: _subscriptions,
                onPressed: () => _setDuration(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DurationButtonWidget(
                hours: 2,
                label: '2 Hours',
                startTime: _startTime,
                endTime: _endTime,
                selectedDate: _selectedDate,
                selectedSubscriptionId: _selectedSubscriptionId,
                subscriptions: _subscriptions,
                onPressed: () => _setDuration(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DurationButtonWidget(
                hours: 3,
                label: '3 Hours',
                startTime: _startTime,
                endTime: _endTime,
                selectedDate: _selectedDate,
                selectedSubscriptionId: _selectedSubscriptionId,
                subscriptions: _subscriptions,
                onPressed: () => _setDuration(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DurationButtonWidget(
                hours: 4,
                label: '4 Hours',
                startTime: _startTime,
                endTime: _endTime,
                selectedDate: _selectedDate,
                selectedSubscriptionId: _selectedSubscriptionId,
                subscriptions: _subscriptions,
                onPressed: () => _setDuration(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeAdjustment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: _buildTimeDisplay(
                label: 'Start Time',
                time: _startTime,
                subtitle: 'Set by slot selection above',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeDisplay(
                label: 'End Time',
                time: _endTime,
                subtitle: 'Calculated from duration',
              ),
            ),
          ],
        ),
      ],
    );
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

  Widget _buildBookingSummary() {
    final totalMins =
        (_endTime!.hour * 60 + _endTime!.minute) -
        (_startTime!.hour * 60 + _startTime!.minute);
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;

    final hasExtendedHours = DurationCalculator.hasAddon(
      selectedSubscriptionId: _selectedSubscriptionId,
      subscriptions: _subscriptions,
      addonCode: 'extended_hours',
    );

    final deductedMins = hasExtendedHours && totalMins > 30
        ? totalMins - 30
        : totalMins;
    final deductedHours = deductedMins ~/ 60;
    final deductedMinutes = deductedMins % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF006876).withValues(alpha: 0.1),
            const Color(0xFF008C9E).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF006876), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF006876)),
              const SizedBox(width: 8),
              Text(
                'Total: ${hours}h ${mins}m',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
            ],
          ),
          if (hasExtendedHours && totalMins > 30) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 18, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        '🎁 Extended Hours Bonus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You get +30 mins free!\nCharged: ${deductedHours}h ${deductedMinutes}m',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookSlot,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Book Slot',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _handleSubscriptionChange(String? value) {
    setState(() {
      _selectedSubscriptionId = value;
      _selectedSpecialty = null;
      _selectedTime = null;
      _startTime = null;
      _endTime = null;
    });
    _loadAvailableSlots();
  }
}
