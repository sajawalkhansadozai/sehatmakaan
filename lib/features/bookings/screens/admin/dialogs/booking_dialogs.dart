import 'package:flutter/material.dart';
import '../../../../../../screens/admin/utils/admin_styles.dart';

enum CancelBookingAction { withRefund, withoutRefund, cancel }

class BookingDialogs {
  /// Show cancel booking dialog with refund options
  static Future<CancelBookingAction> showCancelBookingDialog(
    BuildContext context,
    Map<String, dynamic> booking,
  ) async {
    final result = await showDialog<CancelBookingAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose cancellation option:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Full Refund: Cancel booking and refund the full amount to the user.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'No Refund: Cancel booking without refunding.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, CancelBookingAction.cancel),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, CancelBookingAction.withoutRefund),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminStyles.warningColor,
            ),
            child: const Text('Cancel (No Refund)'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, CancelBookingAction.withRefund),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminStyles.successColor,
            ),
            child: const Text('Cancel (Full Refund)'),
          ),
        ],
      ),
    );

    return result ?? CancelBookingAction.cancel;
  }
}
