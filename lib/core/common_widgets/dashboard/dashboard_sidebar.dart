import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sehatmakaan/features/auth/services/user_status_service.dart';
import 'drawer_item_widget.dart';

class DashboardSidebar extends StatelessWidget {
  final Map<String, dynamic>? currentUserData;
  final Map<String, dynamic> userSession;
  final List<Map<String, dynamic>> allBookings;
  final List<Map<String, dynamic>> activeSubscriptions;
  final String selectedTab;
  final Function(String) onTabSelected;

  const DashboardSidebar({
    super.key,
    required this.currentUserData,
    required this.userSession,
    required this.allBookings,
    required this.activeSubscriptions,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final userName =
        currentUserData?['fullName']?.toString() ??
        userSession['fullName']?.toString() ??
        'Doctor';
    final userEmail =
        currentUserData?['email']?.toString() ??
        userSession['email']?.toString() ??
        '';
    final specialty = currentUserData?['specialty']?.toString() ?? 'General';
    final pmdcNumber = currentUserData?['pmdcNumber']?.toString() ?? '';
    final yearsOfExperience =
        currentUserData?['yearsOfExperience']?.toString() ?? '0';
    final isActive = currentUserData?['isActive'] ?? false;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(
            userName,
            userEmail,
            specialty,
            pmdcNumber,
            yearsOfExperience,
            isActive,
          ),
          _buildMenuItems(context),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String userName,
    String userEmail,
    String specialty,
    String pmdcNumber,
    String yearsOfExperience,
    bool isActive,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006876), Color(0xFF004D57)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 12),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006876),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. $userName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            specialty,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (pmdcNumber.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'PMDC: $pmdcNumber',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.work_history_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$yearsOfExperience Years Experience',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          // Main Navigation
          DrawerItemWidget(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            isSelected: selectedTab == 'dashboard',
            onTap: () {
              onTabSelected('dashboard');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 4),
          DrawerItemWidget(
            icon: Icons.history_rounded,
            title: 'Booking History',
            isSelected: selectedTab == 'bookings',
            onTap: () {
              onTabSelected('bookings');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 4),
          DrawerItemWidget(
            icon: Icons.shopping_bag_rounded,
            title: 'Past Purchases',
            isSelected: selectedTab == 'purchases',
            onTap: () {
              onTabSelected('purchases');
              Navigator.pop(context);
            },
          ),

          // Professional Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Professional',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),
          DrawerItemWidget(
            icon: Icons.calendar_today_rounded,
            title: 'My Schedule',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/my-schedule',
                arguments: userSession,
              );
            },
          ),
          const SizedBox(height: 4),
          DrawerItemWidget(
            icon: Icons.bar_chart_rounded,
            title: 'Analytics',
            isSelected: selectedTab == 'analytics',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/analytics',
                arguments: userSession,
              );
            },
          ),

          // Account Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),
          DrawerItemWidget(
            icon: Icons.settings_rounded,
            title: 'Settings',
            isSelected: selectedTab == 'settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings', arguments: userSession);
            },
          ),

          // Support Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Support',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),
          DrawerItemWidget(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/help-support',
                arguments: userSession,
              );
            },
          ),
          const SizedBox(height: 4),
          DrawerItemWidget(
            icon: Icons.info_outline_rounded,
            title: 'About App',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          const SizedBox(height: 4),
          DrawerItemWidget(
            icon: Icons.share_rounded,
            title: 'Share App',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // App Version
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Version 1.0.0 • Last sync: Just now',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                // Stop status monitoring
                await UserStatusService.stopMonitoring();

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/landing',
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.medical_services, color: Color(0xFF006876)),
            SizedBox(width: 12),
            Text('About Sehat Makaan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sehat Makaan is a comprehensive healthcare management platform connecting doctors with modern medical facilities.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'support@sehatmakaan.com',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.web, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'www.sehatmakaan.com',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
