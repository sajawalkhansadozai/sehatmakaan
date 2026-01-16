import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/models/notification_model.dart';

class NotificationsDrawer extends StatelessWidget {
  final List<NotificationModel> notifications;
  final Function(String) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;

  const NotificationsDrawer({
    super.key,
    required this.notifications,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006876), Color(0xFF004D57)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: onMarkAllAsRead,
                    child: const Text(
                      'Mark All',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('No new notifications'))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final notificationId = notification.id ?? '';
                      if (notificationId.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Dismissible(
                        key: Key(notificationId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          onMarkAsRead(notificationId);
                        },
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        child: ListTile(
                          leading: Icon(
                            _getNotificationIcon(notification.type),
                            color: const Color(0xFF006876),
                          ),
                          title: Text(notification.title),
                          subtitle: Text(notification.message),
                          trailing: Text(
                            _formatTime(notification.createdAt),
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            onMarkAsRead(notificationId);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.calendar_today;
      case 'reminder':
        return Icons.alarm;
      case 'update':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}
