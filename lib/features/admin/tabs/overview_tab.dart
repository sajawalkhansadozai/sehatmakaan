import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/stat_card_widget.dart';
import '../utils/admin_styles.dart';
import '../utils/responsive_helper.dart';
import '../services/admin_data_service.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final titleFontSize = ResponsiveHelper.getTitleFontSize(context);

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: AdminStyles.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard,
                  color: AdminStyles.primaryColor,
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  isMobile ? 'Statistics' : 'Platform Statistics',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AdminStyles.primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildRealtimeStats(context),
          SizedBox(height: isMobile ? 24 : 32),
          _buildSystemControls(context),
        ],
      ),
    );
  }

  Widget _buildRealtimeStats(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<List<QuerySnapshot>>(
      stream: _combineStreams([
        firestore
            .collection('users')
            .where('userType', isEqualTo: 'doctor')
            .snapshots(),
        firestore.collection('bookings').snapshots(),
        firestore.collection('subscriptions').snapshots(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: List.generate(6, (index) => _buildLoadingCard()),
          );
        }

        final doctors = snapshot.data![0].docs;
        final bookings = snapshot.data![1].docs;
        final subscriptions = snapshot.data![2].docs;

        // Calculate stats
        final totalDoctors = doctors.length;
        final pendingDoctors = doctors.where((d) {
          final data = d.data() as Map<String, dynamic>?;
          return data?['status'] == 'pending';
        }).length;

        // Today's bookings
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final todayBookings = bookings.where((b) {
          final data = b.data() as Map<String, dynamic>?;
          final bookingDate = (data?['bookingDate'] as Timestamp?)?.toDate();
          return bookingDate != null &&
              bookingDate.isAfter(startOfDay) &&
              bookingDate.isBefore(endOfDay);
        }).length;

        // Active bookings
        final activeBookings = bookings.where((b) {
          final data = b.data() as Map<String, dynamic>?;
          return data?['status'] == 'confirmed';
        }).length;

        // Active subscriptions
        final activeSubscriptions = subscriptions.where((s) {
          final data = s.data() as Map<String, dynamic>?;
          return data?['status'] == 'active';
        }).length;

        // Monthly revenue (calculate from subscriptions and bookings)
        final startOfMonth = DateTime(now.year, now.month, 1);
        double monthlyRevenue = 0;

        // Revenue from active subscriptions this month
        for (var sub in subscriptions) {
          final data = sub.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final isActive = data['status'] == 'active';

          // Include if created this month OR if currently active (for display purposes)
          if (isActive &&
              createdAt != null &&
              createdAt.isAfter(startOfMonth)) {
            final price =
                (data['price'] as num?)?.toDouble() ??
                (data['monthlyPrice'] as num?)?.toDouble() ??
                0;
            monthlyRevenue += price;
          }
        }

        // Revenue from paid bookings this month
        for (var booking in bookings) {
          final data = booking.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final paymentStatus = data['paymentStatus'] as String?;
          final isPaid = paymentStatus == 'paid';

          if (createdAt != null && createdAt.isAfter(startOfMonth) && isPaid) {
            monthlyRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0;
          }
        }

        return GridView.count(
          crossAxisCount: ResponsiveHelper.getStatsColumnCount(context),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: ResponsiveHelper.isMobile(context) ? 12 : 16,
          mainAxisSpacing: ResponsiveHelper.isMobile(context) ? 12 : 16,
          childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.2 : 1.4,
          children: [
            StatCardWidget(
              title: 'Total Doctors',
              value: '$totalDoctors',
              icon: Icons.people,
              color: AdminStyles.primaryColor,
            ),
            StatCardWidget(
              title: 'Pending Approval',
              value: '$pendingDoctors',
              icon: Icons.pending_actions,
              color: AdminStyles.warningColor,
            ),
            StatCardWidget(
              title: 'Today Bookings',
              value: '$todayBookings',
              icon: Icons.calendar_today,
              color: AdminStyles.successColor,
            ),
            StatCardWidget(
              title: 'Active Bookings',
              value: '$activeBookings',
              icon: Icons.event_available,
              color: AdminStyles.primaryColor,
            ),
            StatCardWidget(
              title: 'Active Subscriptions',
              value: '$activeSubscriptions',
              icon: Icons.card_membership,
              color: AdminStyles.warningColor,
            ),
            StatCardWidget(
              title: 'Monthly Revenue',
              value: 'PKR ${monthlyRevenue.toStringAsFixed(0)}',
              icon: Icons.attach_money,
              color: AdminStyles.successColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shadowColor: AdminStyles.primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AdminStyles.primaryColor.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AdminStyles.primaryColor),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  Stream<List<QuerySnapshot>> _combineStreams(
    List<Stream<QuerySnapshot>> streams,
  ) async* {
    // Combine multiple streams by listening to all and emitting when any changes
    final controllers = <StreamController<QuerySnapshot>>[];
    final subscriptions = <StreamSubscription>[];

    try {
      for (var stream in streams) {
        final controller = StreamController<QuerySnapshot>();
        controllers.add(controller);
        subscriptions.add(stream.listen(controller.add));
      }

      // Wait for initial data from all streams
      final initialData = <QuerySnapshot>[];
      for (var controller in controllers) {
        initialData.add(await controller.stream.first);
      }
      yield initialData;

      // Listen for updates
      await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
        final data = <QuerySnapshot>[];
        for (var stream in streams) {
          data.add(await stream.first);
        }
        yield data;
      }
    } finally {
      for (var sub in subscriptions) {
        sub.cancel();
      }
      for (var controller in controllers) {
        controller.close();
      }
    }
  }

  // ============================================================================
  // GOD MODE: SYSTEM CONTROLS
  // ============================================================================

  Widget _buildSystemControls(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final firestore = FirebaseFirestore.instance;
    final dataService = AdminDataService(firestore);

    return StreamBuilder<Map<String, dynamic>>(
      stream: dataService.streamSystemSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Card(
          elevation: 6,
          shadowColor: Colors.red.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.red.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.red.shade700,
                        size: isMobile ? 24 : 28,
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ GOD MODE: System Controls',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          Text(
                            'Ultimate Admin Power - Handle with Care',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
