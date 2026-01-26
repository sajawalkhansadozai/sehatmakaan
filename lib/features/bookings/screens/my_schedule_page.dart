import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';
import '../../workshops/services/workshop_service.dart';

class MySchedulePage extends StatefulWidget {
  final Map<String, dynamic> userSession;
  const MySchedulePage({super.key, required this.userSession});

  @override
  State<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends State<MySchedulePage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkshopService _workshopService = WorkshopService();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late TabController _tabController;
  Map<DateTime, List<Map<String, dynamic>>> _eventsByDate = {};
  List<Map<String, dynamic>> _selectedDayEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScheduleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleData() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      // Get all bookings and workshops for the current month
      final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDayOfMonth = DateTime(
        _focusedDay.year,
        _focusedDay.month + 1,
        0,
        23,
        59,
        59,
      );

      // Fetch both bookings and workshop registrations
      final results = await Future.wait([
        // Bookings
        _firestore
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .where(
              'bookingDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
            )
            .where(
              'bookingDate',
              isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth),
            )
            .orderBy('bookingDate')
            .get(),
        // Workshop registrations
        _firestore
            .collection('workshop_registrations')
            .where('userId', isEqualTo: userId)
            .where('status', whereIn: ['confirmed', 'paid', 'approved'])
            .get(),
      ]);

      Map<DateTime, List<Map<String, dynamic>>> groupedEvents = {};

      // Process bookings
      for (var doc in results[0].docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['eventType'] = 'booking'; // Mark as booking

        final bookingTimestamp = data['bookingDate'] as Timestamp?;
        if (bookingTimestamp != null) {
          final bookingDate = bookingTimestamp.toDate();
          final dateKey = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
          );

          if (groupedEvents[dateKey] == null) {
            groupedEvents[dateKey] = [];
          }
          groupedEvents[dateKey]!.add(data);
        }
      }

      // Process workshop registrations
      for (var doc in results[1].docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['eventType'] = 'workshop'; // Mark as workshop

        // 🔒 PHASE 3 AUTO-EXPIRY CHECK
        // If approved but payment window expired, mark as expired
        final approvalStatus = data['approvalStatus'];
        final creatorApprovedAt = data['creatorApprovedAt'];
        final paymentStatus = data['paymentStatus'];

        if (approvalStatus == 'approved_by_creator' &&
            paymentStatus == 'pending' &&
            creatorApprovedAt != null) {
          DateTime approvedTime;
          if (creatorApprovedAt is Timestamp) {
            approvedTime = creatorApprovedAt.toDate();
          } else if (creatorApprovedAt is DateTime) {
            approvedTime = creatorApprovedAt;
          } else {
            approvedTime = DateTime.now();
          }

          // Check if 1-hour window has expired
          if (_workshopService.hasJoiningPaymentExpired(approvedTime)) {
            // Mark as expired in Firestore
            await _firestore
                .collection('workshop_registrations')
                .doc(doc.id)
                .update({
                  'approvalStatus': 'expired',
                  'updatedAt': FieldValue.serverTimestamp(),
                });

            // Skip adding to events list
            continue;
          }
        }

        // Get workshop details
        final workshopId = data['workshopId'];
        if (workshopId != null) {
          final workshopDoc = await _firestore
              .collection('workshops')
              .doc(workshopId)
              .get();

          if (workshopDoc.exists) {
            final workshopData = workshopDoc.data();
            data['workshopTitle'] = workshopData?['title'];
            data['workshopLocation'] = workshopData?['location'];
            data['workshopPrice'] = workshopData?['price'];
            data['workshopStartTime'] = workshopData?['startTime'];

            // Get workshop date
            final workshopTimestamp = workshopData?['startDate'] as Timestamp?;
            if (workshopTimestamp != null) {
              final workshopDate = workshopTimestamp.toDate();
              final dateKey = DateTime(
                workshopDate.year,
                workshopDate.month,
                workshopDate.day,
              );

              if (groupedEvents[dateKey] == null) {
                groupedEvents[dateKey] = [];
              }
              groupedEvents[dateKey]!.add(data);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _eventsByDate = groupedEvents;
          _updateSelectedDayEvents();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateSelectedDayEvents() {
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    _selectedDayEvents = _eventsByDate[selectedDate] ?? [];
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _eventsByDate[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Schedule',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
          ),
        ),
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.calendar_month),
              text: ResponsiveHelper.isMobile(context)
                  ? 'Calendar'
                  : 'Calendar View',
            ),
            Tab(
              icon: const Icon(Icons.list_rounded),
              text: ResponsiveHelper.isMobile(context)
                  ? 'Upcoming'
                  : 'Upcoming Events',
            ),
            Tab(
              icon: const Icon(Icons.history_rounded),
              text: ResponsiveHelper.isMobile(context) ? 'Past' : 'Past Events',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF006876)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarView(),
                _buildUpcomingBookings(),
                _buildPastBookings(),
              ],
            ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _updateSelectedDayEvents();
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadScheduleData();
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFF006876).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF006876),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Colors.red),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.circle, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMMM d, y').format(_selectedDay),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedDayEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookings for this day',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _selectedDayEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(_selectedDayEvents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUpcomingBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('userId', isEqualTo: widget.userSession['id'])
          // Removed date filter to show ALL bookings (past and future)
          .where(
            'status',
            whereIn: ['confirmed', 'in_progress', 'completed', 'cancelled'],
          )
          .orderBy('bookingDate', descending: true) // Latest first
          .limit(50) // Increased limit to show more bookings
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF006876)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data?.docs ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming bookings',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            data['id'] = bookings[index].id;
            return _buildEventCard(data);
          },
        );
      },
    );
  }

  Widget _buildPastBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('userId', isEqualTo: widget.userSession['id'])
          .where('bookingDate', isLessThan: Timestamp.fromDate(DateTime.now()))
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('bookingDate', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF006876)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data?.docs ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No past bookings',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            data['id'] = bookings[index].id;
            return _buildEventCard(data, isPast: true);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, {bool isPast = false}) {
    final eventType = event['eventType']?.toString() ?? 'booking';

    // Handle workshop events
    if (eventType == 'workshop') {
      return _buildWorkshopCard(event, isPast: isPast);
    }

    // Handle booking events (original logic)
    final suiteType = event['suiteType']?.toString() ?? 'Unknown';
    final timeSlot = event['timeSlot']?.toString() ?? '--:--';
    final status = event['status']?.toString() ?? 'confirmed';
    final durationMins = event['durationMins'] ?? 60;

    final bookingTimestamp = event['bookingDate'] as Timestamp?;
    final bookingDate = bookingTimestamp?.toDate() ?? DateTime.now();

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final suiteIcon = _getSuiteIcon(suiteType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF006876).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  suiteIcon,
                  color: const Color(0xFF006876),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room,
                          size: 14,
                          color: Color(0xFF006876),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BOOKING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${suiteType[0].toUpperCase()}${suiteType.substring(1)} Suite',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeSlot,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $durationMins mins',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(bookingDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkshopCard(
    Map<String, dynamic> workshop, {
    bool isPast = false,
  }) {
    final workshopTitle = workshop['workshopTitle']?.toString() ?? 'Workshop';
    final status = workshop['status']?.toString() ?? 'pending';
    final location = workshop['workshopLocation']?.toString() ?? 'TBA';
    final startTime = workshop['workshopStartTime']?.toString() ?? '--:--';

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showWorkshopDetails(workshop),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFFFF6B35),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.school,
                          size: 14,
                          color: Color(0xFFFF6B35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'WORKSHOP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workshopTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          startTime,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkshopDetails(Map<String, dynamic> workshop) {
    final workshopTitle = workshop['workshopTitle']?.toString() ?? 'Workshop';
    final status = workshop['status']?.toString() ?? 'pending';
    final approvalStatus = workshop['approvalStatus']?.toString();
    final location = workshop['workshopLocation']?.toString() ?? 'TBA';
    final price = (workshop['workshopPrice'] ?? 0).toDouble();
    final startTime = workshop['workshopStartTime']?.toString() ?? '--:--';
    final registrationNumber = workshop['registrationNumber']?.toString();
    final creatorApprovedAt = workshop['creatorApprovedAt'];

    // Check if showing timer for approved registration awaiting payment
    final showPaymentTimer =
        approvalStatus == 'approved_by_creator' &&
        workshop['paymentStatus'] != 'completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WorkshopDetailsSheet(
        workshopTitle: workshopTitle,
        status: status,
        approvalStatus: approvalStatus,
        location: location,
        price: price,
        startTime: startTime,
        registrationNumber: registrationNumber,
        creatorApprovedAt: creatorApprovedAt,
        showPaymentTimer: showPaymentTimer,
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    final suiteType = booking['suiteType']?.toString() ?? 'Unknown';
    final timeSlot = booking['timeSlot']?.toString() ?? '--:--';
    final status = booking['status']?.toString() ?? 'confirmed';
    final durationMins = booking['durationMins'] ?? 60;
    final baseRate = (booking['baseRate'] ?? 0).toDouble();
    final totalAmount = (booking['totalAmount'] ?? 0).toDouble();
    final addons = booking['addons'] as List<dynamic>? ?? [];

    final bookingTimestamp = booking['bookingDate'] as Timestamp?;
    final bookingDate = bookingTimestamp?.toDate() ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006876).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSuiteIcon(suiteType),
                        color: const Color(0xFF006876),
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${suiteType[0].toUpperCase()}${suiteType.substring(1)} Suite',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Date',
                  DateFormat('EEEE, MMMM d, y').format(bookingDate),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.access_time, 'Time Slot', timeSlot),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.timer_outlined,
                  'Duration',
                  '$durationMins minutes',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.info_outline,
                  'Status',
                  status[0].toUpperCase() + status.substring(1),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.attach_money,
                  'Base Rate',
                  'PKR ${baseRate.toStringAsFixed(0)}/hour',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.payment,
                  'Total Amount',
                  'PKR ${totalAmount.toStringAsFixed(0)}',
                ),

                if (addons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Add-ons',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...addons.map(
                    (addon) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF006876),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            addon.toString(),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                if (status == 'confirmed' || status == 'in_progress') ...[
                  // Reschedule Button
                  if (_canReschedule(booking))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRescheduleDialog(booking);
                        },
                        icon: const Icon(Icons.schedule),
                        label: const Text('Reschedule Booking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006876),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (_canReschedule(booking)) const SizedBox(height: 12),
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCancelDialog(booking);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF006876)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    // Calculate if cancellation is within 24 hours
    final bookingDate = (booking['date'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    bool isWithin24Hours = false;
    String refundMessage = '';

    if (bookingDate != null) {
      final difference = bookingDate.difference(now);
      isWithin24Hours = difference.inHours < 24;

      if (isWithin24Hours) {
        refundMessage =
            '⚠️ Cancelling within 24 hours: Hours will NOT be refunded.\n\nTime until booking: ${difference.inHours}h ${difference.inMinutes % 60}m';
      } else {
        refundMessage =
            '✅ Cancelling more than 24 hours in advance: Hours will be refunded.\n\nTime until booking: ${difference.inDays} days ${difference.inHours % 24} hours';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: isWithin24Hours ? Colors.red : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Cancel Booking?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this booking?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isWithin24Hours
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isWithin24Hours
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Text(
                refundMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: isWithin24Hours
                      ? Colors.red.shade900
                      : Colors.green.shade900,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelBooking(booking['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Yes, Cancel Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF006876)),
        ),
      );

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellationType': 'user',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload data
      _loadScheduleData();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return const Color(0xFF006876);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle_filled;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  IconData _getSuiteIcon(String suiteType) {
    switch (suiteType.toLowerCase()) {
      case 'dental':
        return Icons.medical_services;
      case 'medical':
        return Icons.local_hospital;
      case 'aesthetic':
        return Icons.spa;
      default:
        return Icons.meeting_room;
    }
  }

  // ============================================================================
  // RESCHEDULE FUNCTIONALITY
  // ============================================================================

  bool _canReschedule(Map<String, dynamic> booking) {
    // 1. Status Check - Allow confirmed, in_progress only
    final status = booking['status'] as String?;
    if (status != 'confirmed' && status != 'in_progress') {
      return false; // ❌ Only confirmed/in_progress can be rescheduled
    }

    // 2. Date Check (Future booking)
    final bookingTimestamp = booking['bookingDate'] as Timestamp?;
    if (bookingTimestamp == null) return false;

    final bookingDate = bookingTimestamp.toDate();
    if (bookingDate.isBefore(DateTime.now())) {
      return false; // ❌ Past booking nahi ho sakti
    }

    // 3. Minimum Notice Period (4 hours)
    final hoursUntilBooking = bookingDate.difference(DateTime.now()).inHours;
    if (hoursUntilBooking < 4) {
      return false; // ❌ 4 hours se kam time hai
    }

    // 4. Reschedule Limit (max 2 times)
    final rescheduleCount = booking['rescheduleCount'] as int? ?? 0;
    if (rescheduleCount >= 2) {
      return false; // ❌ Already 2 bar reschedule kar chuke
    }

    // ✅ All conditions passed
    return true;
  }

  void _showRescheduleDialog(Map<String, dynamic> booking) {
    final bookingId = booking['id'] as String?;
    if (bookingId == null) return;

    DateTime selectedDate = DateTime.now();
    String? selectedTimeSlot;
    List<String> availableSlots = [];
    bool isLoadingSlots = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Reschedule Booking'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select New Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(hours: 4),
                          ),
                          firstDate: DateTime.now().add(
                            const Duration(hours: 4),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            selectedTimeSlot = null;
                            isLoadingSlots = true;
                          });
                          await _loadAvailableSlotsForReschedule(
                            picked,
                            booking,
                            (slots) {
                              setState(() {
                                availableSlots = slots;
                                isLoadingSlots = false;
                              });
                            },
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF006876)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF006876),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMM dd, yyyy').format(selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isLoadingSlots)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (availableSlots.isEmpty)
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
                                'Please select a date to view available slots',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSlots.map((slot) {
                          final isSelected = selectedTimeSlot == slot;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedTimeSlot = slot;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
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
                                  fontSize: 14,
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
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedTimeSlot == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        _confirmReschedule(
                          bookingId,
                          selectedDate,
                          selectedTimeSlot!,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006876),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Reschedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadAvailableSlotsForReschedule(
    DateTime selectedDate,
    Map<String, dynamic> currentBooking,
    Function(List<String>) onSlotsLoaded,
  ) async {
    try {
      final startOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final bookingsQuery = await _firestore
          .collection('bookings')
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .get();

      // Get booked slots (excluding current booking)
      final currentBookingId = currentBooking['id'] as String?;
      final bookedSlots = <String>{};
      for (final doc in bookingsQuery.docs) {
        if (doc.id != currentBookingId) {
          final data = doc.data();
          final timeSlot = data['timeSlot'] as String?;
          if (timeSlot != null) {
            bookedSlots.add(timeSlot);
          }
        }
      }

      // Import constants to get time slots
      final allSlots = [
        '10:00',
        '11:00',
        '12:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
        '17:00',
        '18:00',
        '19:00',
        '20:00',
        '21:00',
      ];

      final available = allSlots
          .where((slot) => !bookedSlots.contains(slot))
          .toList();

      onSlotsLoaded(available);
    } catch (e) {
      debugPrint('Error loading slots: $e');
      onSlotsLoaded([]);
    }
  }

  Future<void> _confirmReschedule(
    String bookingId,
    DateTime newDate,
    String newTimeSlot,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reschedule'),
        content: Text(
          'Are you sure you want to reschedule this booking to ${DateFormat('MMM dd, yyyy').format(newDate)} at $newTimeSlot?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performReschedule(bookingId, newDate, newTimeSlot);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006876),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Reschedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReschedule(
    String bookingId,
    DateTime newDate,
    String newTimeSlot,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF006876)),
        ),
      );

      // Get current booking to increment reschedule count
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      final currentData = bookingDoc.data();
      final currentRescheduleCount =
          currentData?['rescheduleCount'] as int? ?? 0;

      // Update booking with new date and slot
      await _firestore.collection('bookings').doc(bookingId).update({
        'bookingDate': Timestamp.fromDate(newDate),
        'timeSlot': newTimeSlot,
        'startTime': newTimeSlot,
        'rescheduleCount': currentRescheduleCount + 1,
        'lastRescheduledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking rescheduled to ${DateFormat('MMM dd, yyyy').format(newDate)} at $newTimeSlot',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reload data
      _loadScheduleData();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Separate widget for workshop details with countdown timer
class _WorkshopDetailsSheet extends StatefulWidget {
  final String workshopTitle;
  final String status;
  final String? approvalStatus;
  final String location;
  final double price;
  final String startTime;
  final String? registrationNumber;
  final dynamic creatorApprovedAt;
  final bool showPaymentTimer;

  const _WorkshopDetailsSheet({
    required this.workshopTitle,
    required this.status,
    this.approvalStatus,
    required this.location,
    required this.price,
    required this.startTime,
    this.registrationNumber,
    this.creatorApprovedAt,
    required this.showPaymentTimer,
  });

  @override
  State<_WorkshopDetailsSheet> createState() => _WorkshopDetailsSheetState();
}

class _WorkshopDetailsSheetState extends State<_WorkshopDetailsSheet> {
  final WorkshopService _workshopService = WorkshopService();
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.showPaymentTimer) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    DateTime? approvedAt;
    if (widget.creatorApprovedAt is Timestamp) {
      approvedAt = (widget.creatorApprovedAt as Timestamp).toDate();
    } else if (widget.creatorApprovedAt is DateTime) {
      approvedAt = widget.creatorApprovedAt;
    }

    if (approvedAt != null) {
      _remainingSeconds = _workshopService.getRemainingJoiningTime(approvedAt);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _remainingSeconds = _workshopService.getRemainingJoiningTime(
              approvedAt!,
            );
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Color(0xFFFF6B35),
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Workshop Registration',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.workshopTitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Countdown Timer
              if (widget.showPaymentTimer && _remainingSeconds > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alarm, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Complete Payment Within:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeBox(hours.toString(), 'Hours'),
                          const Text(
                            ' : ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildTimeBox(
                            minutes.toString().padLeft(2, '0'),
                            'Min',
                          ),
                          const Text(
                            ' : ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildTimeBox(
                            seconds.toString().padLeft(2, '0'),
                            'Sec',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to payment
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment gateway for PKR ${widget.price.toStringAsFixed(0)}',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment),
                          label: Text(
                            'Pay PKR ${widget.price.toStringAsFixed(0)} Now',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (widget.showPaymentTimer && _remainingSeconds <= 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Payment deadline expired. Please contact the instructor.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.access_time,
                'Start Time',
                widget.startTime,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on, 'Location', widget.location),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.info_outline,
                'Status',
                widget.status[0].toUpperCase() + widget.status.substring(1),
              ),
              if (widget.approvalStatus != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.check_circle,
                  'Approval Status',
                  widget.approvalStatus![0].toUpperCase() +
                      widget.approvalStatus!.substring(1).replaceAll('_', ' '),
                ),
              ],
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.payment,
                'Fee',
                'PKR ${widget.price.toStringAsFixed(0)}',
              ),
              if (widget.registrationNumber != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.confirmation_number,
                  'Registration No.',
                  widget.registrationNumber!,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.green.shade700),
        ),
      ],
    );
  }
}
