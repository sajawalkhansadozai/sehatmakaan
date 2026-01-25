import 'package:flutter/material.dart';

class AdminStyles {
  static const Color primaryColor = Color(0xFF006876);
  static const Color secondaryColor = Color(0xFF004D57);
  static const Color successColor = Color(0xFF90D26D);
  static const Color warningColor = Color(0xFFFF6B35);
  static const Color errorColor = Colors.red;
  static const Color backgroundColor = Color(0xFFF5F5F5);

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'confirmed':
      case 'active':
        return successColor;
      case 'pending':
        return warningColor;
      case 'rejected':
      case 'cancelled':
        return errorColor;
      default:
        return Colors.grey;
    }
  }

  static LinearGradient get primaryGradient =>
      const LinearGradient(colors: [primaryColor, secondaryColor]);
}
