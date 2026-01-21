import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/models/notification_model.dart';
import 'package:sehat_makaan_flutter/widgets/dashboard/dashboard_app_bar.dart';
import 'package:sehat_makaan_flutter/widgets/dashboard/dashboard_sidebar.dart';
import 'package:sehat_makaan_flutter/widgets/dashboard/notifications_drawer.dart';
import 'package:sehat_makaan_flutter/widgets/dashboard/subscription_card.dart';
import 'package:sehat_makaan_flutter/features/bookings/widgets/booking_card.dart';
import 'package:sehat_makaan_flutter/widgets/dashboard/quick_action_card.dart';
import 'package:sehat_makaan_flutter/utils/dashboard_utils.dart';
import 'package:sehat_makaan_flutter/services/fcm_service.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const DashboardPage({super.key, required this.userSession});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _activeSubscriptions = [];
  final List<Map<String, dynamic>> _allSubscriptions = [];
  final List<Map<String, dynamic>> _recentBookings = [];
  final List<Map<String, dynamic>> _allBookings = [];
  final List<NotificationModel> _notifications = [];

  // Stream subscriptions for real-time updates
  StreamSubscription<QuerySnapshot>? _subscriptionsListener;
  StreamSubscription<QuerySnapshot>? _bookingsListener;
  StreamSubscription<QuerySnapshot>? _notificationsListener;

  bool _isLoading = true;
  String _selectedTab = 'dashboard';
  bool _isWorkshopCreator = false;
  bool _hasPendingCreatorRequest = false;
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    debugPrint('🔷 Dashboard initState - userSession: ${widget.userSession}');
    debugPrint('🔷 Dashboard initState - userId: ${widget.userSession['id']}');
    _initializeFCM();
    _loadUserDataRealtime();
    _setupRealtimeListeners();
    _checkWorkshopCreatorStatus();
  }

  @override
  void dispose() {
    _subscriptionsListener?.cancel();
    _bookingsListener?.cancel();
    _notificationsListener?.cancel();
    super.dispose();
  }

  /// Initialize FCM for push notifications
  void _initializeFCM() {
    final userId = widget.userSession['id']?.toString();
    if (userId != null) {
      final fcmService = FCMService();
      fcmService.initialize(userId);

      // Subscribe to general notifications topic
      fcmService.subscribeToTopic('all_users');

      // Subscribe to doctor-specific topics
      fcmService.subscribeToTopic('doctors');
    }
  }

  void _loadUserDataRealtime() {
    final userId = widget.userSession['id']?.toString();
    if (userId == null) return;

    _firestore.collection('users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _currentUserData = snapshot.data();
          _currentUserData?['id'] = userId;
        });
        debugPrint(
          '🔄 Real-time user data updated: ${_currentUserData?['fullName']}',
        );
      }
    });
  }

  Future<void> _checkWorkshopCreatorStatus() async {
    final userId = widget.userSession['id']?.toString();
    if (userId == null) return;

    try {
      final creatorQuery = await _firestore
          .collection('workshop_creators')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      final requestQuery = await _firestore
          .collection('workshop_creator_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isWorkshopCreator = creatorQuery.docs.isNotEmpty;
          _hasPendingCreatorRequest = requestQuery.docs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error checking workshop creator status: $e');
    }
  }

  /// Setup real-time listeners for dashboard data
  void _setupRealtimeListeners() {
    final userId = widget.userSession['id']?.toString();
    if (userId == null) return;

    setState(() => _isLoading = true);

    // Real-time listener for subscriptions
    _subscriptionsListener = _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
          if (mounted) {
            setState(() {
              _allSubscriptions.clear();
              _allSubscriptions.addAll(
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return data;
                }),
              );

              // Filter active subscriptions
              _activeSubscriptions.clear();
              _activeSubscriptions.addAll(
                _allSubscriptions.where(
                  (sub) =>
                      sub['status'] == 'active' && (sub['isActive'] == true),
                ),
              );

              debugPrint(
                '🔄 Real-time: Subscriptions updated (${_allSubscriptions.length} total, ${_activeSubscriptions.length} active)',
              );
            });

            // Check for expiring subscriptions and create notifications
            await _checkExpiringSubscriptions();
          }
        });

    // Real-time listener for bookings
    _bookingsListener = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              final now = DateTime.now();

              _allBookings.clear();
              _allBookings.addAll(
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return data;
                }),
              );

              // Filter upcoming bookings (pending/confirmed + future date/time only)
              _recentBookings.clear();
              final upcomingBookings = _allBookings.where((booking) {
                final status = booking['status'] as String?;

                debugPrint(
                  '📋 Checking booking: status=$status, date=${booking['bookingDate']}, time=${booking['timeSlot']}',
                );

                if (status != 'confirmed' && status != 'in_progress') {
                  debugPrint('  ❌ Rejected: status not confirmed/in_progress');
                  return false;
                }

                // Parse booking date and time
                final bookingDateField = booking['bookingDate'];
                DateTime? bookingDateTime;

                if (bookingDateField is String) {
                  try {
                    final parts = bookingDateField.split('/');
                    if (parts.length == 3) {
                      final month = int.parse(parts[0]);
                      final day = int.parse(parts[1]);
                      final year = int.parse(parts[2]);

                      bookingDateTime = DateTime(year, month, day);

                      // Add time slot
                      final timeSlot = booking['timeSlot'] as String?;
                      if (timeSlot != null) {
                        final timeParts = timeSlot.split(':');
                        if (timeParts.length >= 2) {
                          final hour = int.tryParse(timeParts[0]) ?? 0;
                          final minute = int.tryParse(timeParts[1]) ?? 0;
                          bookingDateTime = DateTime(
                            year,
                            month,
                            day,
                            hour,
                            minute,
                          );
                        }
                      }

                      debugPrint('  📅 Parsed date: $bookingDateTime');
                      debugPrint('  🕐 Current time: $now');
                      debugPrint(
                        '  ⏰ Is future: ${bookingDateTime.isAfter(now)}',
                      );
                    }
                  } catch (e) {
                    debugPrint(
                      '  ⚠️ Error parsing booking date: $bookingDateField - $e',
                    );
                  }
                } else if (bookingDateField is Timestamp) {
                  bookingDateTime = bookingDateField.toDate();
                  debugPrint('  📅 Timestamp date: $bookingDateTime');
                }

                // Only show bookings in the future
                final isFuture =
                    bookingDateTime != null && bookingDateTime.isAfter(now);
                debugPrint('  ✅ Final decision: ${isFuture ? "SHOW" : "HIDE"}');
                return isFuture;
              }).toList();

              // Sort by date (ascending - soonest first)
              upcomingBookings.sort((a, b) {
                DateTime? dateA;
                DateTime? dateB;

                // Parse date A
                final dateFieldA = a['bookingDate'];
                if (dateFieldA is String) {
                  try {
                    final parts = dateFieldA.split('/');
                    if (parts.length == 3) {
                      dateA = DateTime(
                        int.parse(parts[2]),
                        int.parse(parts[0]),
                        int.parse(parts[1]),
                      );
                      final timeSlot = a['timeSlot'] as String?;
                      if (timeSlot != null) {
                        final timeParts = timeSlot.split(':');
                        if (timeParts.length >= 2) {
                          dateA = DateTime(
                            dateA.year,
                            dateA.month,
                            dateA.day,
                            int.tryParse(timeParts[0]) ?? 0,
                            int.tryParse(timeParts[1]) ?? 0,
                          );
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Error parsing date A for sorting');
                  }
                } else if (dateFieldA is Timestamp) {
                  dateA = dateFieldA.toDate();
                }

                // Parse date B
                final dateFieldB = b['bookingDate'];
                if (dateFieldB is String) {
                  try {
                    final parts = dateFieldB.split('/');
                    if (parts.length == 3) {
                      dateB = DateTime(
                        int.parse(parts[2]),
                        int.parse(parts[0]),
                        int.parse(parts[1]),
                      );
                      final timeSlot = b['timeSlot'] as String?;
                      if (timeSlot != null) {
                        final timeParts = timeSlot.split(':');
                        if (timeParts.length >= 2) {
                          dateB = DateTime(
                            dateB.year,
                            dateB.month,
                            dateB.day,
                            int.tryParse(timeParts[0]) ?? 0,
                            int.tryParse(timeParts[1]) ?? 0,
                          );
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Error parsing date B for sorting');
                  }
                } else if (dateFieldB is Timestamp) {
                  dateB = dateFieldB.toDate();
                }

                if (dateA == null || dateB == null) return 0;
                return dateA.compareTo(dateB);
              });

              _recentBookings.addAll(upcomingBookings.take(5));

              debugPrint(
                '🔄 Real-time: Bookings updated (${_allBookings.length} total, ${_recentBookings.length} upcoming)',
              );
            });
          }
        });

    // Real-time listener for notifications
    _notificationsListener = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _notifications.clear();
              _notifications.addAll(
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  return NotificationModel(
                    id: doc.id,
                    userId: data['userId'] ?? '',
                    type: data['type'] ?? 'info',
                    title: data['title'] ?? '',
                    message: data['message'] ?? '',
                    isRead: data['isRead'] ?? false,
                    createdAt:
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                    relatedBookingId: data['relatedBookingId'],
                  );
                }),
              );

              final unreadCount = _notifications.where((n) => !n.isRead).length;
              debugPrint(
                '🔄 Real-time: Notifications updated (${_notifications.length} total, $unreadCount unread)',
              );
            });
          }
        });

    // Set loading to false after initial data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      final batch = _firestore.batch();
      for (final notification in _notifications) {
        final notificationId = notification.id;
        if (notificationId != null && notificationId.isNotEmpty) {
          batch.update(
            _firestore.collection('notifications').doc(notificationId),
            {'isRead': true},
          );
        }
      }
      await batch.commit();
      setState(() {
        _notifications.clear();
      });
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Check active subscriptions for expiry warnings and create notifications
  Future<void> _checkExpiringSubscriptions() async {
    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      for (final subscription in _activeSubscriptions) {
        final endDate = (subscription['endDate'] as Timestamp?)?.toDate();
        if (endDate == null) continue;

        final daysRemaining = endDate.difference(DateTime.now()).inDays;
        final subscriptionId = subscription['id'] as String?;
        if (subscriptionId == null) continue;

        // Check if we should create an expiry warning notification
        // Create notification for: 7 days, 3 days, and 1 day remaining
        if (daysRemaining == 7 || daysRemaining == 3 || daysRemaining == 1) {
          // Check if notification already exists for this subscription and day count
          final existingNotification = await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('type', isEqualTo: 'subscription_expiry_warning')
              .where('relatedSubscriptionId', isEqualTo: subscriptionId)
              .where('daysRemaining', isEqualTo: daysRemaining)
              .limit(1)
              .get();

          if (existingNotification.docs.isEmpty) {
            // Create new expiry warning notification
            final suiteType = subscription['suiteType'] as String? ?? 'Unknown';
            final packageType =
                subscription['packageType'] as String? ?? 'package';
            final remainingHours = subscription['remainingHours'] as int? ?? 0;

            String title;
            String message;
            if (daysRemaining == 1) {
              title = '⚠️ Subscription Expiring Tomorrow!';
              message =
                  'Your $suiteType Suite ($packageType) will expire tomorrow. You have $remainingHours hours remaining. Renew now to avoid losing your hours!';
            } else {
              title = '⏰ Subscription Expiring Soon';
              message =
                  'Your $suiteType Suite ($packageType) will expire in $daysRemaining days. You have $remainingHours hours remaining. Consider renewing to continue using your benefits.';
            }

            await _firestore.collection('notifications').add({
              'userId': userId,
              'type': 'subscription_expiry_warning',
              'title': title,
              'message': message,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
              'relatedSubscriptionId': subscriptionId,
              'daysRemaining': daysRemaining,
            });

            debugPrint(
              '📢 Created expiry warning: $title (Subscription: $subscriptionId, Days: $daysRemaining)',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking expiring subscriptions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        _currentUserData?['fullName']?.toString() ??
        widget.userSession['fullName']?.toString() ??
        'User';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE6F7F9),
      drawer: DashboardSidebar(
        currentUserData: _currentUserData,
        userSession: widget.userSession,
        allBookings: _allBookings,
        activeSubscriptions: _activeSubscriptions,
        selectedTab: _selectedTab,
        onTabSelected: (tab) => setState(() => _selectedTab = tab),
      ),
      endDrawer: NotificationsDrawer(
        notifications: _notifications,
        onMarkAsRead: _markNotificationAsRead,
        onMarkAllAsRead: _markAllNotificationsAsRead,
      ),
      body: SafeArea(
        child: Column(
          children: [
            DashboardAppBar(
              userName: userName,
              hasNotifications: _notifications.isNotEmpty,
              notificationCount: _notifications.length,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              onNotificationPressed: () {
                debugPrint('🔔 Notification button pressed');
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'dashboard'
                  ? _buildDashboardContent()
                  : _selectedTab == 'bookings'
                  ? _buildBookingsHistory()
                  : _buildPurchasesHistory(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeSubscriptions.isNotEmpty) ...[
            _buildActiveSubscriptionsSection(),
            const SizedBox(height: 24),
          ],
          _buildQuickActionsSection(),
          const SizedBox(height: 24),
          _buildUpcomingBookingsSection(),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Subscriptions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006876),
          ),
        ),
        const SizedBox(height: 12),
        ..._activeSubscriptions.map(
          (sub) => SubscriptionCard(
            subscription: sub,
            capitalizeFirst: DashboardUtils.capitalizeFirst,
            formatDate: DashboardUtils.formatDate,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006876),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            QuickActionCard(
              title: 'Book Slot',
              icon: Icons.calendar_today,
              color: const Color(0xFF006876),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/live-slot-booking',
                  arguments: widget.userSession,
                );
              },
            ),
            QuickActionCard(
              title: 'View Bookings',
              icon: Icons.event_note,
              color: const Color(0xFFFF6B35),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/my-schedule',
                  arguments: widget.userSession,
                );
              },
            ),
            QuickActionCard(
              title: 'Booking',
              icon: Icons.add_circle_outline,
              color: const Color(0xFF90D26D),
              onTap: () {
                debugPrint('🔍 Dashboard userSession: ${widget.userSession}');
                Navigator.pushNamed(
                  context,
                  '/booking-workflow',
                  arguments: widget.userSession,
                );
              },
            ),
            QuickActionCard(
              title: 'Workshops',
              icon: Icons.school,
              color: const Color(0xFF006876),
              onTap: () => Navigator.pushNamed(
                context,
                '/workshops',
                arguments: widget.userSession,
              ),
            ),
            if (_isWorkshopCreator)
              QuickActionCard(
                title: 'Create Workshop',
                icon: Icons.add_box,
                color: const Color(0xFF90D26D),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/create-workshop',
                  arguments: widget.userSession,
                ),
              )
            else if (_hasPendingCreatorRequest)
              QuickActionCard(
                title: 'Request Pending',
                icon: Icons.pending,
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your workshop creator request is pending admin approval',
                      ),
                    ),
                  );
                },
              )
            else
              QuickActionCard(
                title: 'Request Creator Access',
                icon: Icons.person_add,
                color: const Color(0xFFFF6B35),
                onTap: _showRequestCreatorDialog,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllBookingsPage(
                      bookings: _recentBookings,
                      userSession: widget.userSession,
                    ),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentBookings.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No upcoming bookings',
                  style: TextStyle(
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        if (_recentBookings.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _recentBookings.length > 3
                  ? 3
                  : _recentBookings.length,
              itemBuilder: (context, index) {
                final booking = _recentBookings[index];
                return BookingCard(
                  booking: booking,
                  capitalizeFirst: DashboardUtils.capitalizeFirst,
                  formatDate: DashboardUtils.formatDate,
                  getStatusColor: DashboardUtils.getStatusColor,
                );
              },
            ),
          ),
        if (_recentBookings.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllBookingsPage(
                        bookings: _recentBookings,
                        userSession: widget.userSession,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  'View ${_recentBookings.length - 3} more bookings',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingsHistory() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Bookings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 16),
          if (_allBookings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No bookings found',
                    style: TextStyle(
                      color: const Color(0xFF006876).withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            )
          else
            ..._allBookings.map(
              (booking) => BookingCard(
                booking: booking,
                capitalizeFirst: DashboardUtils.capitalizeFirst,
                formatDate: DashboardUtils.formatDate,
                getStatusColor: DashboardUtils.getStatusColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchasesHistory() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Subscriptions & Packages',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 16),
          if (_allSubscriptions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No purchases found',
                    style: TextStyle(
                      color: const Color(0xFF006876).withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            )
          else
            ..._allSubscriptions.map((sub) => _buildPurchaseCard(sub)),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> subscription) {
    final packageType = subscription['packageType']?.toString() ?? 'Package';
    final suiteType = subscription['suiteType']?.toString() ?? '';
    final price =
        subscription['price']?.toString() ??
        subscription['monthlyPrice']?.toString() ??
        '0';
    final createdAt = subscription['createdAt'] as Timestamp?;
    final status = subscription['status']?.toString() ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF006876).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, color: Color(0xFF006876)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DashboardUtils.capitalizeFirst(suiteType)} Suite - ${DashboardUtils.capitalizeFirst(packageType)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006876),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PKR $price',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      'Purchased: ${DashboardUtils.formatDate(createdAt.toDate())}',
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
                color: DashboardUtils.getStatusColor(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DashboardUtils.capitalizeFirst(status),
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

  Future<void> _showRequestCreatorDialog() async {
    final workshopTypeController = TextEditingController();
    final workshopTopicController = TextEditingController();
    final workshopDescriptionController = TextEditingController();
    final expectedParticipantsController = TextEditingController();
    final experienceController = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        String selectedDuration = '1-2 hours';

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Workshop Creator Request Form'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fill out this form to request workshop creator access. All fields are required.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Workshop Type
                      const Text(
                        'Workshop Type *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: workshopTypeController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'e.g., Medical Training, Clinical Skills, etc.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Workshop type is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Type must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Workshop Topic
                      const Text(
                        'Workshop Topic *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: workshopTopicController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Advanced Suturing Techniques',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Workshop topic is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Topic must be at least 5 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Workshop Description
                      const Text(
                        'Workshop Description *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: workshopDescriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'Describe what you will teach in this workshop',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Workshop description is required';
                          }
                          if (value.trim().length < 20) {
                            return 'Description must be at least 20 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Expected Duration
                      const Text(
                        'Expected Duration *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDuration,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select duration',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '1-2 hours',
                            child: Text('1-2 hours'),
                          ),
                          DropdownMenuItem(
                            value: '2-4 hours',
                            child: Text('2-4 hours'),
                          ),
                          DropdownMenuItem(
                            value: 'Half day (4-6 hours)',
                            child: Text('Half day (4-6 hours)'),
                          ),
                          DropdownMenuItem(
                            value: 'Full day (6-8 hours)',
                            child: Text('Full day (6-8 hours)'),
                          ),
                          DropdownMenuItem(
                            value: 'Multiple days',
                            child: Text('Multiple days'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedDuration = value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Expected Participants
                      const Text(
                        'Expected Number of Participants *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: expectedParticipantsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 20',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Expected participants is required';
                          }
                          final number = int.tryParse(value.trim());
                          if (number == null || number <= 0) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Experience/Qualifications
                      const Text(
                        'Your Teaching Experience & Qualifications *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: experienceController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'Describe your teaching experience and relevant qualifications',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Teaching experience is required';
                          }
                          if (value.trim().length < 20) {
                            return 'Please provide more details (min 20 characters)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'workshopType': workshopTypeController.text.trim(),
                      'workshopTopic': workshopTopicController.text.trim(),
                      'workshopDescription': workshopDescriptionController.text
                          .trim(),
                      'expectedDuration': selectedDuration,
                      'expectedParticipants': expectedParticipantsController
                          .text
                          .trim(),
                      'teachingExperience': experienceController.text.trim(),
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006876),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit Request'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      await _submitCreatorRequest(result);
    }

    // Dispose controllers
    workshopTypeController.dispose();
    workshopTopicController.dispose();
    workshopDescriptionController.dispose();
    expectedParticipantsController.dispose();
    experienceController.dispose();
  }

  Future<void> _submitCreatorRequest(Map<String, String> formData) async {
    try {
      final userId = widget.userSession['id']?.toString();
      final fullName = widget.userSession['fullName']?.toString() ?? '';
      final email = widget.userSession['email']?.toString() ?? '';
      final specialty = widget.userSession['specialty']?.toString();

      if (userId == null) return;

      await _firestore.collection('workshop_creator_requests').add({
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'specialty': specialty,
        'workshopType': formData['workshopType'],
        'workshopTopic': formData['workshopTopic'],
        'workshopDescription': formData['workshopDescription'],
        'expectedDuration': formData['expectedDuration'],
        'expectedParticipants': formData['expectedParticipants'],
        'teachingExperience': formData['teachingExperience'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Note: Cloud function will handle admin notifications automatically

      if (mounted) {
        setState(() {
          _hasPendingCreatorRequest = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent successfully! Admin will review it.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
      }
    }
  }
}

/// All Bookings Page - Shows all upcoming bookings with full details
class AllBookingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final Map<String, dynamic> userSession;

  const AllBookingsPage({
    super.key,
    required this.bookings,
    required this.userSession,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        title: const Text('All Upcoming Bookings'),
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: const Color(0xFF006876).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Upcoming Bookings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF006876).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your upcoming bookings will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF006876).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return BookingCard(
                  booking: booking,
                  capitalizeFirst: DashboardUtils.capitalizeFirst,
                  formatDate: DashboardUtils.formatDate,
                  getStatusColor: DashboardUtils.getStatusColor,
                );
              },
            ),
    );
  }
}
