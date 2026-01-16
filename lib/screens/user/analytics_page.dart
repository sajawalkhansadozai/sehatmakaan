import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/dashboard/dashboard_app_bar.dart';
import '../../widgets/dashboard/dashboard_sidebar.dart';

class AnalyticsPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const AnalyticsPage({super.key, required this.userSession});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _selectedPeriod = 'month'; // 'week', 'month', 'year', 'all'

  // Analytics data
  int _totalBookings = 0;
  int _completedBookings = 0;
  int _cancelledBookings = 0;
  int _activeSubscriptions = 0;
  double _totalRevenue = 0;
  double _averageBookingValue = 0;

  // User data
  Map<String, dynamic>? _currentUserData;
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _activeSubscriptionsList = [];
  int _unreadNotificationCount = 0;

  // Period-specific data
  Map<String, int> _bookingsByMonth = {};
  Map<String, int> _bookingsByWeekday = {};
  Map<String, int> _bookingsBySuite = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAnalytics();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      // Load user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _currentUserData = userDoc.data();
        _currentUserData?['id'] = userId;
      }

      // Load notifications count
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (mounted) {
        setState(() {
          _unreadNotificationCount = notificationsQuery.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      // Calculate date range based on selected period
      DateTime startDate;
      final now = DateTime.now();

      switch (_selectedPeriod) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        case 'all':
        default:
          startDate = DateTime(2020, 1, 1); // Beginning of time
          break;
      }

      // Fetch bookings
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('bookedAt', isGreaterThanOrEqualTo: startDate)
          .get();

      // Fetch subscriptions
      final subscriptionsQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      // Process bookings data
      final bookings = bookingsQuery.docs;
      _totalBookings = bookings.length;
      _completedBookings = bookings
          .where((doc) => doc.data()['status'] == 'completed')
          .length;
      _cancelledBookings = bookings
          .where((doc) => doc.data()['status'] == 'cancelled')
          .length;

      // Calculate revenue
      _totalRevenue = 0;
      _bookingsByMonth = {};
      _bookingsByWeekday = {};
      _bookingsBySuite = {};

      for (var doc in bookings) {
        final data = doc.data();
        final price = (data['totalPrice'] ?? 0.0).toDouble();
        _totalRevenue += price;

        // Group by month
        final date = (data['bookedAt'] as Timestamp).toDate();
        final monthKey = DateFormat('MMM yyyy').format(date);
        _bookingsByMonth[monthKey] = (_bookingsByMonth[monthKey] ?? 0) + 1;

        // Group by weekday
        final weekdayKey = DateFormat('EEEE').format(date);
        _bookingsByWeekday[weekdayKey] =
            (_bookingsByWeekday[weekdayKey] ?? 0) + 1;

        // Group by suite
        final suite = data['suiteName'] ?? 'Unknown';
        _bookingsBySuite[suite] = (_bookingsBySuite[suite] ?? 0) + 1;
      }

      // Store for sidebar
      _allBookings = bookings
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
      _activeSubscriptionsList = subscriptionsQuery.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      _averageBookingValue = _totalBookings > 0
          ? _totalRevenue / _totalBookings
          : 0;

      // Count active subscriptions
      _activeSubscriptions = subscriptionsQuery.docs.length;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        _currentUserData?['fullName']?.toString() ??
        widget.userSession['fullName']?.toString() ??
        'Doctor';

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: DashboardAppBar(
          userName: userName,
          hasNotifications: _unreadNotificationCount > 0,
          notificationCount: _unreadNotificationCount,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationPressed: () =>
              _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ),
      drawer: DashboardSidebar(
        currentUserData: _currentUserData,
        userSession: widget.userSession,
        allBookings: _allBookings,
        activeSubscriptions: _activeSubscriptionsList,
        selectedTab: 'analytics',
        onTabSelected: (tab) {
          Navigator.pop(context);
          if (tab == 'dashboard') {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
              arguments: widget.userSession,
            );
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildBookingsByMonth(),
                    const SizedBox(height: 24),
                    _buildBookingsByWeekday(),
                    const SizedBox(height: 24),
                    _buildBookingsBySuite(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPeriodChip('Week', 'week'),
                _buildPeriodChip('Month', 'month'),
                _buildPeriodChip('Year', 'year'),
                _buildPeriodChip('All Time', 'all'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = value);
          _loadAnalytics();
        }
      },
      selectedColor: const Color(0xFF006876),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF006876),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006876),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Bookings',
              _totalBookings.toString(),
              Icons.calendar_month,
              Colors.blue,
            ),
            _buildStatCard(
              'Completed',
              _completedBookings.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Cancelled',
              _cancelledBookings.toString(),
              Icons.cancel,
              Colors.red,
            ),
            _buildStatCard(
              'Active Plans',
              _activeSubscriptions.toString(),
              Icons.card_membership,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Revenue',
              'Rs ${_totalRevenue.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.purple,
            ),
            _buildStatCard(
              'Avg Booking',
              'Rs ${_averageBookingValue.toStringAsFixed(0)}',
              Icons.trending_up,
              Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsByMonth() {
    if (_bookingsByMonth.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = _bookingsByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bookings by Month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBar(entry.key, entry.value, _totalBookings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsByWeekday() {
    if (_bookingsByWeekday.isEmpty) {
      return const SizedBox.shrink();
    }

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final sortedEntries = weekdays
        .where((day) => _bookingsByWeekday.containsKey(day))
        .map((day) {
          return MapEntry(day, _bookingsByWeekday[day]!);
        })
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bookings by Day of Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBar(entry.key, entry.value, _totalBookings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsBySuite() {
    if (_bookingsBySuite.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = _bookingsBySuite.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Booked Suites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBar(entry.key, entry.value, _totalBookings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, int value, int total) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value (${(percentage * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006876)),
          ),
        ),
      ],
    );
  }
}
