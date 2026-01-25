import 'package:flutter/material.dart';

class DashboardUtils {
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF90D26D);
      case 'pending':
        return const Color(0xFFFF6B35);
      case 'completed':
        return const Color(0xFF006876);
      case 'active':
        return const Color(0xFF90D26D);
      default:
        return Colors.grey;
    }
  }

  static IconData getNotificationIcon(String type) {
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

  static String formatTime(DateTime date) {
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
}
