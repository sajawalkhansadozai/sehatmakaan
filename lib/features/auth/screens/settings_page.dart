import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';
import 'package:sehatmakaan/core/common_widgets/dashboard/dashboard_app_bar.dart';
import 'package:sehatmakaan/core/common_widgets/dashboard/dashboard_sidebar.dart';
import 'package:sehatmakaan/features/auth/services/user_status_service.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const SettingsPage({super.key, required this.userSession});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _currentUserData;
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _activeSubscriptions = [];
  int _unreadNotificationCount = 0;

  // Settings
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _bookingReminders = true;
  bool _marketingEmails = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      // Load user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _currentUserData = userDoc.data();
        _currentUserData?['id'] = userId;

        // Load notification preferences
        _emailNotifications = _currentUserData?['emailNotifications'] ?? true;
        _pushNotifications = _currentUserData?['pushNotifications'] ?? true;
        _bookingReminders = _currentUserData?['bookingReminders'] ?? true;
        _marketingEmails = _currentUserData?['marketingEmails'] ?? false;
      }

      // Load notifications count
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Load bookings and subscriptions for sidebar
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      final subscriptionsQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (mounted) {
        setState(() {
          _unreadNotificationCount = notificationsQuery.docs.length;
          _allBookings = bookingsQuery.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList();
          _activeSubscriptions = subscriptionsQuery.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateNotificationSetting(String field, bool value) async {
    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({field: value});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final user = _auth.currentUser;
                if (user == null) return;

                // Reauthenticate
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPasswordController.text,
                );
                await user.reauthenticateWithCredential(credential);

                // Update password
                await user.updatePassword(newPasswordController.text);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006876),
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final userId = widget.userSession['id']?.toString();
                if (userId == null) return;

                // Delete user data
                await _firestore.collection('users').doc(userId).delete();

                // Delete bookings
                final bookings = await _firestore
                    .collection('bookings')
                    .where('userId', isEqualTo: userId)
                    .get();
                for (var doc in bookings.docs) {
                  await doc.reference.delete();
                }

                // Delete subscriptions
                final subscriptions = await _firestore
                    .collection('subscriptions')
                    .where('userId', isEqualTo: userId)
                    .get();
                for (var doc in subscriptions.docs) {
                  await doc.reference.delete();
                }

                // Delete auth account
                await _auth.currentUser?.delete();

                // Clear local data
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await UserStatusService.stopMonitoring();

                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/landing', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
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
        activeSubscriptions: _activeSubscriptions,
        selectedTab: 'settings',
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
          : ResponsiveContainer(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAccountSection(),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context),
                    ),
                    _buildNotificationSection(),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context),
                    ),
                    _buildSecuritySection(),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context),
                    ),
                    _buildDangerZone(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', _currentUserData?['fullName'] ?? 'N/A'),
            _buildInfoRow('Email', _currentUserData?['email'] ?? 'N/A'),
            _buildInfoRow(
              'PMDC Number',
              _currentUserData?['pmdcNumber'] ?? 'N/A',
            ),
            _buildInfoRow('Specialty', _currentUserData?['specialty'] ?? 'N/A'),
            _buildInfoRow(
              'Experience',
              '${_currentUserData?['yearsOfExperience'] ?? 0} years',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Email Notifications',
              'Receive notifications via email',
              _emailNotifications,
              (value) {
                setState(() => _emailNotifications = value);
                _updateNotificationSetting('emailNotifications', value);
              },
            ),
            _buildSwitchTile(
              'Push Notifications',
              'Receive push notifications',
              _pushNotifications,
              (value) {
                setState(() => _pushNotifications = value);
                _updateNotificationSetting('pushNotifications', value);
              },
            ),
            _buildSwitchTile(
              'Booking Reminders',
              'Get reminders for upcoming bookings',
              _bookingReminders,
              (value) {
                setState(() => _bookingReminders = value);
                _updateNotificationSetting('bookingReminders', value);
              },
            ),
            _buildSwitchTile(
              'Marketing Emails',
              'Receive promotional emails',
              _marketingEmails,
              (value) {
                setState(() => _marketingEmails = value);
                _updateNotificationSetting('marketingEmails', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF006876),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock, color: Color(0xFF006876)),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Permanently delete your account'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
