import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class DoctorDialogs {
  /// Show reject doctor dialog
  static Future<String?> showRejectDialog(
    BuildContext context,
    Map<String, dynamic> doctor,
  ) async {
    final isMobile = ResponsiveHelper.isMobile(context);

    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          _RejectDoctorDialog(doctor: doctor, isMobile: isMobile),
    );

    return result;
  }

  /// Show delete doctor confirmation dialog
  static Future<bool> showDeleteDialog(
    BuildContext context,
    Map<String, dynamic> doctor,
  ) async {
    final isMobile = ResponsiveHelper.isMobile(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Doctor',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.getDialogWidth(context),
          ),
          child: Text(
            'Delete ${doctor['fullName']}? This cannot be undone.',
            style: TextStyle(fontSize: isMobile ? 13 : 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

// ✅ Stateful dialog to properly manage TextEditingController lifecycle
class _RejectDoctorDialog extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final bool isMobile;

  const _RejectDoctorDialog({required this.doctor, required this.isMobile});

  @override
  State<_RejectDoctorDialog> createState() => _RejectDoctorDialogState();
}

class _RejectDoctorDialogState extends State<_RejectDoctorDialog> {
  late TextEditingController reasonController;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize controller in initState - survives dialog rebuild
    reasonController = TextEditingController();
  }

  @override
  void dispose() {
    // ✅ Dispose only when dialog is truly closed
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reject Doctor Application',
        style: TextStyle(fontSize: widget.isMobile ? 16 : 18),
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
              'Rejecting ${widget.doctor['fullName']}\'s application',
              style: TextStyle(fontSize: widget.isMobile ? 13 : 14),
            ),
            SizedBox(height: widget.isMobile ? 12 : 16),
            TextField(
              controller: reasonController,
              maxLines: widget.isMobile ? 3 : 4,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter reason')),
              );
              return;
            }
            // ✅ Pass the reason and close dialog
            Navigator.pop(context, reasonController.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
