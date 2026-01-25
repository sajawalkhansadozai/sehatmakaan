import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget {
  final String userName;
  final bool hasNotifications;
  final int notificationCount;
  final VoidCallback onMenuPressed;
  final VoidCallback onNotificationPressed;

  const DashboardAppBar({
    super.key,
    required this.userName,
    required this.hasNotifications,
    required this.notificationCount,
    required this.onMenuPressed,
    required this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = 'Dr. $userName';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006876), Color(0xFF004D57)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome, $displayName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your Practice Dashboard',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: onNotificationPressed,
                  icon: Icon(
                    hasNotifications
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                ),
                if (hasNotifications)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
}
