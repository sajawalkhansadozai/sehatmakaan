import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/stat_card_widget.dart';
import '../utils/admin_styles.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminStyles.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: AdminStyles.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Platform Statistics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AdminStyles.primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRealtimeStats(),
        ],
      ),
    );
  }

  Widget _buildRealtimeStats() {
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
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
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
}
