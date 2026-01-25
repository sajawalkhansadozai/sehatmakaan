import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';

class MonthlyDashboardPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const MonthlyDashboardPage({super.key, required this.userSession});

  @override
  State<MonthlyDashboardPage> createState() => _MonthlyDashboardPageState();
}

class _MonthlyDashboardPageState extends State<MonthlyDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  String? _selectedSlot;
  bool _isLoading = true;
  final List<Map<String, dynamic>> _subscriptions = [];
  final List<Map<String, dynamic>> _purchasedAddons = [];
  List<TimeSlotModel> _slots = [];
  String _currentTab = 'booking';
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
    _loadPurchasedAddons();
    _loadSlotsForDate();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      final query = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .where('type', isEqualTo: 'monthly')
          .get();

      final subs = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _subscriptions.clear();
          _subscriptions.addAll(subs);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscriptions: $e')),
        );
      }
    }
  }

  Future<void> _loadPurchasedAddons() async {
    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      final query = await _firestore
          .collection('purchased_addons')
          .where('userId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .get();

      final addons = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _purchasedAddons.clear();
          _purchasedAddons.addAll(addons);
        });
      }
    } catch (e) {
      debugPrint('Error loading addons: $e');
    }
  }

  Future<void> _loadSlotsForDate() async {
    try {
      // Get current subscription's suite type for filtering
      final subscription = _subscriptions.firstOrNull;
      final suiteType = subscription?['suiteType'] as String?;

      // Load existing bookings for the selected date
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Build query with suite type filter if available
      var bookingsQuery = _firestore
          .collection('bookings')
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['confirmed', 'in_progress']);

      // Filter by suite type to show only conflicts within same suite
      if (suiteType != null) {
        bookingsQuery = bookingsQuery.where('suiteType', isEqualTo: suiteType);
      }

      final bookingsSnapshot = await bookingsQuery.get();

      // Get booked time ranges (considering start and end times)
      final bookedSlots = <String>{};
      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();

        // Get start and end time for the booking
        final startTimeStr = data['startTime'] as String?;
        final endTimeStr = data['endTime'] as String?;

        if (startTimeStr != null && endTimeStr != null) {
          // Parse start and end times
          final startParts = startTimeStr.split(':');
          final endParts = endTimeStr.split(':');
          final startMins =
              int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

          // Mark all affected time slots as booked
          for (final slot in AppConstants.timeSlots) {
            final slotParts = slot.split(':');
            final slotMins =
                int.parse(slotParts[0]) * 60 + int.parse(slotParts[1]);

            // Check if this slot falls within the booked range
            if (slotMins >= startMins && slotMins < endMins) {
              bookedSlots.add(slot);
            }
          }
        } else {
          // Fallback: Old format with just timeSlot field
          final timeSlot = data['timeSlot'] as String?;
          if (timeSlot != null) {
            bookedSlots.add(timeSlot);
          }
        }
      }

      // Check if selected date is today
      final now = DateTime.now();
      final isToday =
          _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;

      // Generate time slots with booking status
      final slots = AppConstants.timeSlots.map((time) {
        bool isAvailable = !bookedSlots.contains(time);

        // For today, hide past time slots with grace period
        if (isToday && isAvailable) {
          final parts = time.split(':');
          final slotHour = int.parse(parts[0]);
          final slotMinute = int.parse(parts[1]);
          final slotMinutes = slotHour * 60 + slotMinute;
          final currentMinutes = now.hour * 60 + now.minute;

          const gracePeriodMins = 30;
          if (slotMinutes + gracePeriodMins < currentMinutes) {
            isAvailable = false;
          }
        }

        return TimeSlotModel(time: time, isBooked: !isAvailable);
      }).toList();

      if (mounted) {
        setState(() {
          _slots = slots;
        });
      }
    } catch (e) {
      debugPrint('Error loading slots: $e');
    }
  }

  Future<void> _bookSlot() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    if (_remainingHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No remaining hours available')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      final subscription = _subscriptions.firstOrNull;
      if (subscription == null) return;

      // Create booking
      await _firestore.collection('bookings').add({
        'userId': userId,
        'subscriptionId': subscription['id'],
        'suiteType': subscription['suiteType'],
        'packageType': subscription['packageType'],
        'bookingDate': Timestamp.fromDate(_selectedDate),
        'timeSlot': _selectedSlot,
        'hours': 1,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update subscription hours
      final remainingHours = (subscription['remainingHours'] as int? ?? 0) - 1;
      final hoursUsed = (subscription['hoursUsed'] as int? ?? 0) + 1;

      await _firestore
          .collection('subscriptions')
          .doc(subscription['id'])
          .update({
            'remainingHours': remainingHours,
            'hoursUsed': hoursUsed,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot booked successfully!'),
            backgroundColor: Color(0xFF90D26D),
          ),
        );
        setState(() {
          _selectedSlot = null;
        });
        _loadSubscriptions();
        _loadSlotsForDate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error booking slot: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  int get _totalHours {
    return _subscriptions.fold<int>(
      0,
      (total, sub) => total + (sub['hoursIncluded'] as int? ?? 0),
    );
  }

  int get _remainingHours {
    return _subscriptions.fold<int>(
      0,
      (total, sub) => total + (sub['remainingHours'] as int? ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_subscriptions.isEmpty && !_isLoading) {
      return _buildNoSubscriptionView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 1200,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006876), Color(0xFF004D57)],
        ),
      ),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Dr. ${widget.userSession['fullName']?.toString().split(' ').first ?? 'Doctor'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            20,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveSpacing(context) *
                            0.2,
                      ),
                      Text(
                        'Monthly Dashboard',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/dashboard',
                          arguments: widget.userSession,
                        );
                      },
                      icon: const Icon(Icons.dashboard, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context) * 0.8,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    'Total Hours',
                    '$_totalHours',
                    Icons.schedule,
                    const Color(0xFFFF6B35),
                  ),
                ),
                SizedBox(
                  width: ResponsiveHelper.getResponsiveSpacing(context) * 0.6,
                ),
                Expanded(
                  child: _buildStatsCard(
                    'Remaining',
                    '$_remainingHours',
                    Icons.timelapse,
                    const Color(0xFF90D26D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.getResponsiveSpacing(context) * 0.6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12,
                    ),
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) * 0.2,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      24,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tabs
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildTab('booking', 'Book Slots', Icons.calendar_today),
              ),
              Expanded(
                child: _buildTab(
                  'purchase',
                  'Purchase Add-ons',
                  Icons.shopping_bag,
                ),
              ),
              Expanded(
                child: _buildTab('my-addons', 'My Add-ons', Icons.inventory_2),
              ),
            ],
          ),
        ),
        Expanded(
          child: _currentTab == 'booking'
              ? _buildBookingTab()
              : _currentTab == 'purchase'
              ? _buildPurchaseAddonsTab()
              : _buildMyAddonsTab(),
        ),
      ],
    );
  }

  Widget _buildTab(String tabId, String label, IconData icon) {
    final isSelected = _currentTab == tabId;
    return InkWell(
      onTap: () => setState(() => _currentTab = tabId),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context) * 0.8,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF006876) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF006876) : Colors.grey,
              size: 20,
            ),
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context) * 0.2,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF006876) : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubscriptionInfo(),
          const SizedBox(height: 24),
          _buildCalendar(),
          const SizedBox(height: 24),
          _buildTimeSlots(),
        ],
      ),
    );
  }

  Widget _buildPurchaseAddonsTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Add-ons',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006876),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context) * 0.8,
          ),
          _buildAddonCard(
            'Extra 10 Hour Block',
            'Add 10 additional hours to your package',
            15000,
            'extra_10_hours',
          ),
          const SizedBox(height: 12),
          _buildAddonCard(
            'Priority Booking',
            'Get priority access to time slots',
            5000,
            'priority_booking',
          ),
          const SizedBox(height: 12),
          _buildAddonCard(
            'Extended Hours',
            'Book slots beyond regular hours',
            8000,
            'extended_hours',
          ),
        ],
      ),
    );
  }

  Widget _buildAddonCard(
    String title,
    String description,
    double price,
    String addonCode,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF006876).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PKR ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _purchaseAddon(title, addonCode, price),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006876),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Purchase'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseAddon(
    String addonName,
    String addonCode,
    double price,
  ) async {
    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      final subscription = _subscriptions.firstOrNull;
      if (subscription == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found')),
        );
        return;
      }

      await _firestore.collection('purchased_addons').add({
        'userId': userId,
        'subscriptionId': subscription['id'],
        'addonName': addonName,
        'addonCode': addonCode,
        'price': price,
        'suiteType': subscription['suiteType'],
        'isUsed': false,
        'purchasedAt': FieldValue.serverTimestamp(),
      });

      // If it's extra hours, update subscription
      if (addonCode == 'extra_10_hours') {
        final remainingHours =
            (subscription['remainingHours'] as int? ?? 0) + 10;
        final hoursIncluded = (subscription['hoursIncluded'] as int? ?? 0) + 10;

        await _firestore
            .collection('subscriptions')
            .doc(subscription['id'])
            .update({
              'remainingHours': remainingHours,
              'hoursIncluded': hoursIncluded,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add-on purchased successfully!'),
            backgroundColor: Color(0xFF90D26D),
          ),
        );
        _loadPurchasedAddons();
        _loadSubscriptions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error purchasing add-on: $e')));
      }
    }
  }

  Widget _buildMyAddonsTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Purchased Add-ons',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006876),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context) * 0.8,
          ),
          if (_purchasedAddons.isEmpty)
            Card(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Center(
                  child: Text(
                    'No add-ons purchased yet',
                    style: TextStyle(
                      color: const Color(0xFF006876).withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            )
          else
            ..._purchasedAddons.map((addon) => _buildMyAddonCard(addon)),
        ],
      ),
    );
  }

  Widget _buildMyAddonCard(Map<String, dynamic> addon) {
    final isUsed = addon['isUsed'] as bool? ?? false;
    final purchasedAt = addon['purchasedAt'] as Timestamp?;

    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveSpacing(context) * 0.6,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isUsed
                    ? Colors.grey.withValues(alpha: 0.2)
                    : const Color(0xFF006876).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isUsed ? Icons.check_circle : Icons.inventory_2,
                color: isUsed ? Colors.grey : const Color(0xFF006876),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addon['addonName'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006876),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${(addon['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  if (purchasedAt != null)
                    Text(
                      'Purchased: ${_formatDate(purchasedAt.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF006876).withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isUsed ? Colors.grey : const Color(0xFF90D26D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isUsed ? 'Used' : 'Available',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSubscriptionInfo() {
    final subscription = _subscriptions.isNotEmpty
        ? _subscriptions.first
        : null;
    if (subscription == null) return const SizedBox.shrink();

    final hoursIncluded = subscription['hoursIncluded'] as int? ?? 0;
    final remainingHours = subscription['remainingHours'] as int? ?? 0;
    final progress = hoursIncluded > 0
        ? (hoursIncluded - remainingHours) / hoursIncluded
        : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_capitalizeFirst(subscription['suiteType'] as String? ?? '')} Suite',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006876),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF90D26D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _capitalizeFirst(
                      subscription['packageType'] as String? ?? 'Active',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hours Used: ${hoursIncluded - remainingHours} / $hoursIncluded',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  'Valid until ${_formatDate(subscription['endDate'] as DateTime? ?? DateTime.now())}',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE6F7F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF006876),
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _currentTab = 'purchase');
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Purchase Add-ons'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006876),
                      side: const BorderSide(color: Color(0xFF006876)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/packages');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Buy More Hours'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 12),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDate = focusedDay;
                  _selectedSlot = null;
                });
                _loadSlotsForDate();
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF006876),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF006876).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                todayTextStyle: const TextStyle(color: Colors.white),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Time Slots - ${_formatDate(_selectedDate)}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF006876),
              ),
            ),
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context) * 0.8,
            ),
            if (_slots.isEmpty)
              Center(
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: Text('Select a date to view available slots'),
                ),
              ),
            if (_slots.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _slots.length,
                itemBuilder: (context, index) {
                  final slot = _slots[index];
                  return _buildSlotButton(slot);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotButton(TimeSlotModel slot) {
    final isSelected = _selectedSlot == slot.time;
    final isAvailable = !slot.isBooked;

    return Material(
      color: isSelected
          ? const Color(0xFF006876)
          : (isAvailable ? Colors.white : Colors.grey.shade200),
      borderRadius: BorderRadius.circular(8),
      elevation: isAvailable ? 2 : 0,
      child: InkWell(
        onTap: isAvailable ? () => _handleSlotSelect(slot.time) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF006876)
                  : (isAvailable
                        ? const Color(0xFF006876).withValues(alpha: 0.3)
                        : Colors.grey),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAvailable ? Icons.access_time : Icons.block,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : (isAvailable ? const Color(0xFF006876) : Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  slot.time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isAvailable ? const Color(0xFF006876) : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSlotSelect(String time) {
    if (_remainingHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hours remaining. Please purchase more hours.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedSlot = time;
    });
    _showBookingConfirmDialog();
  }

  void _showBookingConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(_selectedDate)}'),
            Text('Time: $_selectedSlot'),
            const SizedBox(height: 16),
            Text(
              'This will use 1 hour from your subscription.',
              style: TextStyle(
                color: const Color(0xFF006876).withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isBooking ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isBooking
                ? null
                : () {
                    Navigator.pop(context);
                    _confirmBooking();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006876),
            ),
            child: _isBooking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) return;

    await _bookSlot();
  }

  Widget _buildNoSubscriptionView() {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 1200,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Card(
                    margin: ResponsiveHelper.getResponsivePadding(context),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.getResponsiveSpacing(context) * 1.6,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Color(0xFF006876),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                              context,
                            ),
                          ),
                          Text(
                            'No Active Subscription',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                24,
                              ),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF006876),
                            ),
                          ),
                          SizedBox(
                            height:
                                ResponsiveHelper.getResponsiveSpacing(context) *
                                0.6,
                          ),
                          Text(
                            'Choose a monthly package to start booking slots',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                16,
                              ),
                              color: const Color(
                                0xFF006876,
                              ).withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height:
                                ResponsiveHelper.getResponsiveSpacing(context) *
                                1.6,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/packages');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Choose Package',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class TimeSlotModel {
  final String time;
  final bool isBooked;
  final int? bookingId;

  TimeSlotModel({required this.time, required this.isBooked, this.bookingId});
}
