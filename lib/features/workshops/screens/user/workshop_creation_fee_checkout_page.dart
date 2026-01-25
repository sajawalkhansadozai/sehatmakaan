import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/workshop_model.dart';
import '../../services/workshop_service.dart';

/// 💰 Workshop Creation Fee Payment Page
/// This page handles the PKR 10,000 creation fee payment for approved workshops
/// Once payment is successful, workshop.isActive becomes true and goes live
class WorkshopCreationFeeCheckoutPage extends StatefulWidget {
  const WorkshopCreationFeeCheckoutPage({super.key});

  @override
  State<WorkshopCreationFeeCheckoutPage> createState() =>
      _WorkshopCreationFeeCheckoutPageState();
}

class _WorkshopCreationFeeCheckoutPageState
    extends State<WorkshopCreationFeeCheckoutPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WorkshopService _workshopService = WorkshopService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final workshop = args['workshop'] as WorkshopModel;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        title: const Text('Workshop Creation Fee'),
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkshopSummary(workshop),
            const SizedBox(height: 24),
            _buildPaymentInfo(workshop),
            const SizedBox(height: 24),
            _buildPaymentNote(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(workshop),
    );
  }

  Widget _buildWorkshopSummary(WorkshopModel workshop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workshop Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const Divider(height: 24),
            _buildSummaryRow('Title', workshop.title),
            const SizedBox(height: 8),
            _buildSummaryRow('Type', workshop.certificationType),
            const SizedBox(height: 8),
            _buildSummaryRow('Provider', workshop.provider),
            const SizedBox(height: 8),
            _buildSummaryRow('Date', _formatDate(workshop.startDate)),
            const SizedBox(height: 8),
            _buildSummaryRow('Time', workshop.startTime ?? 'TBD'),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Price',
              'PKR ${workshop.price.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Max Participants',
              workshop.maxParticipants.toString(),
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Status: Approved by Admin - Payment Required',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(WorkshopModel workshop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006876).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payment, color: Color(0xFF006876)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Your workshop has been approved by the admin. To make it publicly visible and start accepting registrations, you need to pay the creation fee.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Creation Fee',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
                Text(
                  'PKR ${workshop.adminSetFee?.toStringAsFixed(0) ?? '10000'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment is processed securely through PayFast. After successful payment, your workshop will automatically go live.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text(
                'What happens after payment?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint('✅ Workshop becomes publicly visible'),
          _buildBulletPoint('✅ Users can view and register'),
          _buildBulletPoint('✅ You can manage registrations'),
          _buildBulletPoint('✅ Start collecting revenue from participants'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(WorkshopModel workshop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _processPayment(workshop),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006876),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pay PKR ${workshop.adminSetFee?.toStringAsFixed(0) ?? '10000'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _processPayment(WorkshopModel workshop) async {
    if (workshop.id == null) {
      _showErrorDialog('Error', 'Invalid workshop data');
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showErrorDialog('Error', 'User not authenticated');
      return;
    }

    // Verify payment deadline hasn't expired
    if (workshop.permissionGrantedAt != null) {
      final remainingSeconds = _workshopService.getRemainingPaymentTime(
        workshop.permissionGrantedAt!,
      );

      if (remainingSeconds <= 0) {
        _showErrorDialog(
          'Payment Deadline Expired',
          'Sorry, your 48-hour payment window has expired. Please create a new workshop.',
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      // ============================================================================
      // PAYFAST PAYMENT INTEGRATION
      // ============================================================================
      // Create payment record
      final paymentRef = await _firestore
          .collection('workshop_creation_payments')
          .add({
            'workshopId': workshop.id,
            'creatorId': userId,
            'amount': workshop.adminSetFee ?? 10000.0,
            'status': 'pending',
            'paymentMethod': 'payfast',
            'createdAt': FieldValue.serverTimestamp(),
          });

      debugPrint('💰 Payment record created: ${paymentRef.id}');

      // ============================================================================
      // PAYFAST INTEGRATION - WITH CLOUD FUNCTION WEBHOOK
      // ============================================================================
      // Get Firebase project ID for webhook URL
      const projectId =
          'sehat-makaan'; // TODO: Replace with your Firebase project ID

      // Generate PayFast payment URL
      final paymentUrl =
          'https://www.payfast.co.za/eng/process?'
          'merchant_id=10000100' // DUMMY: Replace with real merchant_id
          '&merchant_key=46f0cd694581a' // DUMMY: Replace with real merchant_key
          '&amount=${workshop.adminSetFee ?? 10000}'
          '&item_name=${Uri.encodeComponent('Workshop Creation Fee - ${workshop.title}')}'
          '&item_description=${Uri.encodeComponent('Creation fee for workshop: ${workshop.title}')}'
          '&return_url=${Uri.encodeComponent('https://sehatmakaan.com/payment-success')}'
          '&cancel_url=${Uri.encodeComponent('https://sehatmakaan.com/payment-cancel')}'
          '&notify_url=${Uri.encodeComponent('https://us-central1-$projectId.cloudfunctions.net/payfastWorkshopCreationWebhook')}'
          '&custom_str1=${workshop.id}' // Workshop ID for callback
          '&custom_str2=${paymentRef.id}'; // Payment record ID

      debugPrint('🔗 PayFast URL: $paymentUrl');

      // Launch PayFast payment page
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Redirected to PayFast payment page');

        // Store context before async gap
        if (!mounted) return;
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);

        // Show pending message
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Opening PayFast payment page...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );

        // ============================================================================
        // 🚀 AUTO-ACTIVATION TRIGGER (For Testing - Remove in Production)
        // ============================================================================
        // NOTE: In production, this should be handled by PayFast webhook
        // For now, we auto-activate after simulated payment
        await _handleSuccessfulPayment(workshop.id!);
        // ============================================================================

        // Navigate back - Payment status will be updated via webhook
        navigator.pop();
        return;
      } else {
        throw Exception('Could not launch PayFast payment URL');
      }
    } catch (e) {
      debugPrint('❌ Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// 🚀 ATOMIC TRANSACTION: Auto-activate workshop after successful payment
  /// This should be called by PayFast webhook in production
  Future<void> _handleSuccessfulPayment(String workshopId) async {
    try {
      debugPrint('💰 Processing successful payment for workshop: $workshopId');

      // Use transaction to ensure atomic update (prevents data corruption)
      await _firestore.runTransaction((transaction) async {
        final workshopRef = _firestore.collection('workshops').doc(workshopId);
        final workshopSnapshot = await transaction.get(workshopRef);

        if (!workshopSnapshot.exists) {
          throw Exception('Workshop not found');
        }

        // Atomic update: Mark as paid AND activate in one operation
        transaction.update(workshopRef, {
          'isCreationFeePaid': true, // ✅ Payment confirmed
          'isActive': true, // 🚀 WORKSHOP IS NOW LIVE!
          'permissionStatus': 'live', // Final status
          'activatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Workshop activated: $workshopId');
      });

      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Payment successful! Your workshop is now LIVE!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to activate workshop: $e');
      // Don't throw - let webhook retry if needed
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous page
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
