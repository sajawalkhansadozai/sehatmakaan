import 'package:flutter/material.dart';
import 'package:sehatmakaan/features/admin/utils/admin_styles.dart';
import '../utils/responsive_helper.dart';

enum CancelBookingAction { withRefund, withoutRefund, cancel }

class BookingDialogs {
  /// Show cancel booking dialog with refund options
  static Future<CancelBookingAction> showCancelBookingDialog(
    BuildContext context,
    Map<String, dynamic> booking,
  ) async {
    final isMobile = ResponsiveHelper.isMobile(context);
    final result = await showDialog<CancelBookingAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.getDialogWidth(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose cancellation option:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Full Refund: Cancel booking and refund the full amount to the user.',
                style: TextStyle(fontSize: isMobile ? 13 : 14),
              ),
              const SizedBox(height: 8),
              Text(
                'No Refund: Cancel booking without refunding.',
                style: TextStyle(fontSize: isMobile ? 13 : 14),
              ),
            ],
          ),
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
