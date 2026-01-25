import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/stat_card_widget.dart';
import '../utils/admin_styles.dart';
import '../utils/responsive_helper.dart';
import '../services/admin_data_service.dart';
import '../services/admin_mutations_service.dart';

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

        final settings = snapshot.data!;
        final isMaintenanceMode = settings['isMaintenanceMode'] ?? false;
        final globalCommission = settings['globalCommission'] ?? 20.0;
        final turnoverBuffer = settings['turnoverBuffer'] ?? 60;

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
                SizedBox(height: isMobile ? 16 : 20),

                // Maintenance Mode Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMaintenanceMode
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMaintenanceMode
                          ? Colors.red.shade300
                          : Colors.green.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMaintenanceMode ? Icons.warning : Icons.check_circle,
                        color: isMaintenanceMode ? Colors.red : Colors.green,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maintenance Mode',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: isMaintenanceMode
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                            Text(
                              isMaintenanceMode
                                  ? 'App is OFFLINE for all users'
                                  : 'App is LIVE and accessible',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isMaintenanceMode,
                        activeTrackColor: Colors.red,
                        onChanged: (value) =>
                            _toggleMaintenanceMode(context, value),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // System Settings Grid
                ResponsiveHelper.buildAdaptiveRowColumn(
                  context: context,
                  children: [
                    _buildSystemSetting(
                      context,
                      icon: Icons.attach_money,
                      label: 'Global Commission',
                      value: '${globalCommission.toStringAsFixed(0)}%',
                      color: Colors.orange,
                      onTap: () => _editCommission(context, globalCommission),
                    ),
                    SizedBox(
                      width: isMobile ? 0 : 12,
                      height: isMobile ? 12 : 0,
                    ),
                    _buildSystemSetting(
                      context,
                      icon: Icons.schedule,
                      label: 'Turnover Buffer',
                      value: '$turnoverBuffer mins',
                      color: Colors.blue,
                      onTap: () => _editTurnoverBuffer(context, turnoverBuffer),
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

  Widget _buildSystemSetting(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: isMobile ? 18 : 20),
                  const Spacer(),
                  Icon(
                    Icons.edit,
                    color: color.withValues(alpha: 0.6),
                    size: isMobile ? 14 : 16,
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleMaintenanceMode(BuildContext context, bool value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              value ? Icons.warning : Icons.check_circle,
              color: value ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(value ? 'Enable Maintenance?' : 'Disable Maintenance?'),
          ],
        ),
        content: Text(
          value
              ? 'This will LOCK OUT all users from the app. Only proceed if you need to perform critical maintenance.'
              : 'This will restore normal app access for all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: value ? Colors.red : Colors.green,
            ),
            child: Text(value ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final mutationsService = AdminMutationsService(
        firestore: FirebaseFirestore.instance,
        onLoadingStart: () {},
        onLoadingEnd: () {},
        showSuccess: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
          );
        },
        showError: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        },
      );

      await mutationsService.updateSystemSettings(
        adminId: adminId,
        isMaintenanceMode: value,
      );
    }
  }

  void _editCommission(BuildContext context, double currentValue) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(0),
    );

    final newValue = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Global Commission'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Commission Rate (%)',
            border: OutlineInputBorder(),
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null && context.mounted) {
      final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final mutationsService = AdminMutationsService(
        firestore: FirebaseFirestore.instance,
        onLoadingStart: () {},
        onLoadingEnd: () {},
        showSuccess: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
          );
        },
        showError: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        },
      );

      await mutationsService.updateSystemSettings(
        adminId: adminId,
        globalCommission: newValue,
      );
    }

    controller.dispose();
  }

  void _editTurnoverBuffer(BuildContext context, int currentValue) async {
    final controller = TextEditingController(text: currentValue.toString());

    final newValue = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Turnover Buffer'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Buffer Time (minutes)',
            border: OutlineInputBorder(),
            suffixText: 'mins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null && context.mounted) {
      final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final mutationsService = AdminMutationsService(
        firestore: FirebaseFirestore.instance,
        onLoadingStart: () {},
        onLoadingEnd: () {},
        showSuccess: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
          );
        },
        showError: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        },
      );

      await mutationsService.updateSystemSettings(
        adminId: adminId,
        turnoverBuffer: newValue,
      );
    }

    controller.dispose();
  }
}
