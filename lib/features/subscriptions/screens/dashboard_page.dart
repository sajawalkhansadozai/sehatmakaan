import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/shared/notification_model.dart';
import 'package:sehat_makaan_flutter/core/common_widgets/dashboard/dashboard_app_bar.dart';
import 'package:sehat_makaan_flutter/core/common_widgets/dashboard/dashboard_sidebar.dart';
import 'package:sehat_makaan_flutter/core/common_widgets/dashboard/notifications_drawer.dart';
import 'package:sehat_makaan_flutter/core/common_widgets/dashboard/subscription_card.dart';
import 'package:sehat_makaan_flutter/features/bookings/widgets/booking_card.dart';
import 'package:sehat_makaan_flutter/core/utils/dashboard_utils.dart';
import 'package:sehat_makaan_flutter/shared/fcm_service.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const DashboardPage({super.key, required this.userSession});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
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
  StreamSubscription<QuerySnapshot>? _creatorStatusListener;
  StreamSubscription<QuerySnapshot>? _creatorRequestListener;

  bool _isLoading = true;
  String _selectedTab = 'dashboard';
  bool _isWorkshopCreator = false;
  bool _hasPendingCreatorRequest = false;
  Map<String, dynamic>? _currentUserData;

  // God-Level UI: Animation & Workshop Stats
  late AnimationController _staggerController;
  Map<String, dynamic> _workshopStats = {
    'totalRevenue': 0.0,
    'pendingRequests': 0,
    'platformScore': 85,
  };

  @override
  void initState() {
    super.initState();
    debugPrint('🔷 Dashboard initState - userSession: ${widget.userSession}');
    debugPrint('🔷 Dashboard initState - userId: ${widget.userSession['id']}');

    // God-Level UI: Initialize animation controller
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _initializeFCM();
    _loadUserDataRealtime();
    _setupRealtimeListeners();
    _checkWorkshopCreatorStatus();
    _loadWorkshopStats();
  }

  @override
  void dispose() {
    _subscriptionsListener?.cancel();
    _bookingsListener?.cancel();
    _notificationsListener?.cancel();
    _creatorStatusListener?.cancel();
    _creatorRequestListener?.cancel();
    _staggerController.dispose();
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

  /// God-Level UI: Load workshop statistics for Creator Insight Hub
  Future<void> _loadWorkshopStats() async {
    if (!_isWorkshopCreator) return;
    final userId = widget.userSession['id']?.toString();
    if (userId == null) return;

    try {
      // Calculate total revenue from completed workshops
      final completedWorkshops = await _firestore
          .collection('workshops')
          .where('createdBy', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      for (final doc in completedWorkshops.docs) {
        final price = doc.data()['price'] as num? ?? 0;
        final registrations = await _firestore
            .collection('workshop_registrations')
            .where('workshopId', isEqualTo: doc.id)
            .where('paymentStatus', isEqualTo: 'completed')
            .get();
        totalRevenue += (price * registrations.docs.length);
      }

      // Count pending join requests - get all creator's workshops first
      final creatorWorkshops = await _firestore
          .collection('workshops')
          .where('createdBy', isEqualTo: userId)
          .get();

      int pendingCount = 0;
      for (final workshop in creatorWorkshops.docs) {
        final pendingRegistrations = await _firestore
            .collection('workshop_registrations')
            .where('workshopId', isEqualTo: workshop.id)
            .where('approvalStatus', isEqualTo: 'pending_creator')
            .get();
        pendingCount += pendingRegistrations.docs.length;
      }

      if (mounted) {
        setState(() {
          _workshopStats = {
            'totalRevenue': totalRevenue,
            'pendingRequests': pendingCount,
            'platformScore': 85 + (completedWorkshops.docs.length * 2),
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading workshop stats: $e');
    }
  }

  /// Setup real-time listener for workshop creator status
  void _checkWorkshopCreatorStatus() {
    final userId = widget.userSession['id']?.toString();
    if (userId == null) return;

    // Listen for creator status changes
    _creatorStatusListener = _firestore
        .collection('workshop_creators')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            final wasCreator = _isWorkshopCreator;
            setState(() {
              _isWorkshopCreator = snapshot.docs.isNotEmpty;
            });

            // Show notification when approved
            if (!wasCreator && _isWorkshopCreator) {
              debugPrint('🎉 User is now a workshop creator!');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '🎉 Congratulations! Your workshop creator request has been approved!',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 5),
                ),
              );
              _loadWorkshopStats();
            }
          }
        });

    // Listen for pending request changes
    _creatorRequestListener = _firestore
        .collection('workshop_creator_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _hasPendingCreatorRequest = snapshot.docs.isNotEmpty;
            });
            debugPrint(
              '🔄 Pending creator request status: ${snapshot.docs.isNotEmpty}',
            );
          }
        });
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
    return ResponsiveContainer(
      child: CustomScrollView(
        slivers: [
          // 🎯 God-Level: Creator Command Hub (Only for workshop creators)
          if (_isWorkshopCreator)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildCreatorInsightHub(),
              ),
            ),

          // Main content
          SliverPadding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_activeSubscriptions.isNotEmpty) ...[
                  _buildActiveSubscriptionsSection(),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context),
                  ),
                ],
                _buildQuickActionsSection(),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context),
                ),
                _buildUpcomingBookingsSection(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 💎 God-Level: Creator Insight Hub with Glassmorphism
  Widget _buildCreatorInsightHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Creator Command Hub',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Card 1: Total Revenue (Gold Gradient)
              _buildInsightCard(
                title: 'Total Revenue',
                value:
                    'PKR ${_workshopStats['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                icon: Icons.attach_money,
                gradientColors: [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFA500),
                ],
                shadowColor: const Color(0xFFFFD700),
              ),

              // Card 2: Pending Requests (Pulsing Amber)
              _buildInsightCard(
                title: 'Pending Requests',
                value: '${_workshopStats['pendingRequests'] ?? 0}',
                icon: Icons.pending_actions,
                gradientColors: [
                  const Color(0xFFFF6B35),
                  const Color(0xFFFF8C42),
                ],
                shadowColor: const Color(0xFFFF6B35),
                isPulsing: (_workshopStats['pendingRequests'] ?? 0) > 0,
              ),

              // Card 3: Platform Score (Teal Circular Progress)
              _buildInsightCard(
                title: 'Platform Score',
                value: '${_workshopStats['platformScore'] ?? 85}%',
                icon: Icons.star,
                gradientColors: [
                  const Color(0xFF006876),
                  const Color(0xFF004D57),
                ],
                shadowColor: const Color(0xFF006876),
                showProgress: true,
                progressValue: (_workshopStats['platformScore'] ?? 85) / 100,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    bool isPulsing = false,
    bool showProgress = false,
    double progressValue = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Glassmorphic overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: Colors.white, size: 20),
                            ),
                            if (isPulsing)
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.5, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                                builder: (context, opacity, child) {
                                  return Opacity(
                                    opacity: opacity,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                onEnd: () {
                                  // Restart animation
                                },
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showProgress)
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  value: progressValue,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.3,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Subscriptions',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006876),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
        ResponsiveBuilder(
          builder: (context, constraints) {
            final isMobile = ResponsiveHelper.isMobile(context);

            if (isMobile) {
              // On mobile, show cards in a column
              return Column(
                children: _activeSubscriptions
                    .map(
                      (sub) => SubscriptionCard(
                        subscription: sub,
                        capitalizeFirst: DashboardUtils.capitalizeFirst,
                        formatDate: DashboardUtils.formatDate,
                      ),
                    )
                    .toList(),
              );
            } else {
              // On tablet/desktop, show cards in a responsive grid
              final crossAxisCount = ResponsiveHelper.getGridColumns(context);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: _activeSubscriptions.length,
                itemBuilder: (context, index) => SubscriptionCard(
                  subscription: _activeSubscriptions[index],
                  capitalizeFirst: DashboardUtils.capitalizeFirst,
                  formatDate: DashboardUtils.formatDate,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'title': 'Book Slot',
        'icon': Icons.calendar_today,
        'primaryColor': const Color(0xFF006876),
        'secondaryColor': const Color(0xFF004D57),
        'route': '/live-slot-booking',
      },
      {
        'title': 'View Bookings',
        'icon': Icons.event_note,
        'primaryColor': const Color(0xFFFF6B35),
        'secondaryColor': const Color(0xFFFF8C42),
        'route': '/my-schedule',
      },
      {
        'title': 'Booking',
        'icon': Icons.add_circle_outline,
        'primaryColor': const Color(0xFF90D26D),
        'secondaryColor': const Color(0xFF70B24D),
        'route': '/booking-workflow',
      },
      {
        'title': 'Workshops',
        'icon': Icons.school,
        'primaryColor': const Color(0xFF006876),
        'secondaryColor': const Color(0xFF004D57),
        'route': '/workshops',
      },
      if (_isWorkshopCreator)
        {
          'title': 'Create Workshop',
          'icon': Icons.add_box,
          'primaryColor': const Color(0xFF90D26D),
          'secondaryColor': const Color(0xFF70B24D),
          'route': '/create-workshop',
        }
      else if (_hasPendingCreatorRequest)
        {
          'title': 'Request Pending',
          'icon': Icons.pending,
          'primaryColor': Colors.orange,
          'secondaryColor': Colors.deepOrange,
          'isPending': true,
        }
      else
        {
          'title': 'Request Creator Access',
          'icon': Icons.person_add,
          'primaryColor': const Color(0xFFFF6B35),
          'secondaryColor': const Color(0xFFFF8C42),
          'isCreatorRequest': true,
        },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006876),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),

        // 🎭 God-Level: Staggered Grid with Dual-Tone Cards
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.isMobile(context)
                ? 2
                : ResponsiveHelper.getGridColumns(context),
            crossAxisSpacing:
                ResponsiveHelper.getResponsiveSpacing(context) * 0.5,
            mainAxisSpacing:
                ResponsiveHelper.getResponsiveSpacing(context) * 0.5,
            childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.2 : 1.3,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final delay = index * 100; // Stagger delay

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + delay),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: _buildDualToneActionCard(
                title: action['title'] as String,
                icon: action['icon'] as IconData,
                primaryColor: action['primaryColor'] as Color,
                secondaryColor: action['secondaryColor'] as Color,
                onTap: () {
                  HapticFeedback.lightImpact();

                  if (action['isPending'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Your workshop creator request is pending admin approval',
                        ),
                      ),
                    );
                  } else if (action['isCreatorRequest'] == true) {
                    _showRequestCreatorBottomSheet();
                  } else {
                    Navigator.pushNamed(
                      context,
                      action['route'] as String,
                      arguments: widget.userSession,
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// 💎 God-Level: Dual-Tone Action Card with Bounce Animation
  Widget _buildDualToneActionCard({
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle pattern overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
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

  Widget _buildUpcomingBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Upcoming Bookings',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF006876),
                ),
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
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),

        if (_recentBookings.isEmpty)
          Card(
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Center(
                child: Text(
                  'No upcoming bookings',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      14,
                    ),
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),

        // ⏰ God-Level: Timeline View with Time Dots
        if (_recentBookings.isNotEmpty)
          Column(
            children: List.generate(
              _recentBookings.length > 3 ? 3 : _recentBookings.length,
              (index) {
                final booking = _recentBookings[index];
                final bookingDate = (booking['bookingDate'] as Timestamp?)
                    ?.toDate();
                final now = DateTime.now();
                final hoursUntil = bookingDate != null
                    ? bookingDate.difference(now).inHours
                    : 0;

                // Determine time dot color based on urgency
                Color timeDotColor;
                if (hoursUntil <= 24) {
                  timeDotColor = const Color(0xFFFF6B35); // Urgent (< 24 hours)
                } else if (hoursUntil <= 72) {
                  timeDotColor = const Color(0xFFFFA500); // Soon (< 3 days)
                } else {
                  timeDotColor = const Color(0xFF90D26D); // Scheduled
                }

                return _buildTimelineBookingCard(
                  booking: booking,
                  isLast:
                      index ==
                      (_recentBookings.length > 3
                          ? 2
                          : _recentBookings.length - 1),
                  timeDotColor: timeDotColor,
                  hoursUntil: hoursUntil,
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

  /// ⏰ God-Level: Timeline Booking Card with Time Dot
  Widget _buildTimelineBookingCard({
    required Map<String, dynamic> booking,
    required bool isLast,
    required Color timeDotColor,
    required int hoursUntil,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column with Time Dot
          Column(
            children: [
              // Pulsing Time Dot
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.2),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: timeDotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: timeDotColor.withValues(alpha: 0.3),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: timeDotColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Vertical Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          timeDotColor.withValues(alpha: 0.6),
                          timeDotColor.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Booking Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: timeDotColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: timeDotColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking['suiteName']?.toString() ?? 'Booking',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006876),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: timeDotColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hoursUntil <= 24
                                  ? '${hoursUntil}h'
                                  : '${(hoursUntil / 24).ceil()}d',
                              style: TextStyle(
                                color: timeDotColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: const Color(
                              0xFF006876,
                            ).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DashboardUtils.formatDate(
                              (booking['bookingDate'] as Timestamp).toDate(),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(
                                0xFF006876,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: const Color(
                              0xFF006876,
                            ).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${booking['startTime'] ?? ''} - ${booking['endTime'] ?? ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(
                                0xFF006876,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsHistory() {
    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Bookings',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF006876),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
            if (_allBookings.isEmpty)
              Card(
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: Center(
                    child: Text(
                      'No bookings found',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          14,
                        ),
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
      ),
    );
  }

  Widget _buildPurchasesHistory() {
    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Subscriptions & Packages',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF006876),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
            if (_allSubscriptions.isEmpty)
              Card(
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: Center(
                    child: Text(
                      'No purchases found',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          14,
                        ),
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

  /// ⚡ God-Level: Draggable Bottom Sheet for Creator Request
  Future<void> _showRequestCreatorBottomSheet() async {
    HapticFeedback.mediumImpact();

    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _CreatorRequestBottomSheet(),
    );

    if (result != null && mounted) {
      await _submitCreatorRequest(result);
    }
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
            content: Text(
              'Workshop creator request submitted successfully! Admin will review and approve.',
            ),
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

/// Stateful Widget for Creator Request Bottom Sheet
class _CreatorRequestBottomSheet extends StatefulWidget {
  @override
  State<_CreatorRequestBottomSheet> createState() =>
      _CreatorRequestBottomSheetState();
}

class _CreatorRequestBottomSheetState
    extends State<_CreatorRequestBottomSheet> {
  final workshopTypeController = TextEditingController();
  final workshopTopicController = TextEditingController();
  final workshopDescriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    workshopTypeController.dispose();
    workshopTopicController.dispose();
    workshopDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // 🎯 Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006876), Color(0xFF004D57)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF006876,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workshop Creator Request',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006876),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fill out this form to get started',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          label: 'Workshop Type *',
                          controller: workshopTypeController,
                          icon: Icons.category,
                          hint: 'e.g., Medical Training, Clinical Skills',
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
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Workshop Topic *',
                          controller: workshopTopicController,
                          icon: Icons.topic,
                          hint: 'e.g., Advanced Suturing Techniques',
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
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Workshop Description *',
                          controller: workshopDescriptionController,
                          icon: Icons.description,
                          hint: 'Describe what you will teach in this workshop',
                          maxLines: 4,
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
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),

              // Submit Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'workshopType': workshopTypeController.text.trim(),
                            'workshopTopic': workshopTopicController.text
                                .trim(),
                            'workshopDescription': workshopDescriptionController
                                .text
                                .trim(),
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006876),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF006876),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Icon(icon, color: const Color(0xFF006876)),
          ),
          validator: validator,
        ),
      ],
    );
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
