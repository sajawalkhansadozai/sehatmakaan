import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/workshop_service.dart';

class WorkshopCheckoutPage extends StatefulWidget {
  const WorkshopCheckoutPage({super.key});

  @override
  State<WorkshopCheckoutPage> createState() => _WorkshopCheckoutPageState();
}

class _WorkshopCheckoutPageState extends State<WorkshopCheckoutPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkshopService _workshopService = WorkshopService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final workshop = args['workshop'] as Map<String, dynamic>;
    final registrationId = args['registrationId'] as String;
    final registrationData = args['registrationData'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(workshop, registrationData),
            const SizedBox(height: 24),
            _buildPaymentInfo(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(workshop, registrationId),
    );
  }

  Widget _buildOrderSummary(
    Map<String, dynamic> workshop,
    Map<String, dynamic> registrationData,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const Divider(height: 24),
            _buildSummaryRow('Workshop', workshop['title'] ?? ''),
            const SizedBox(height: 8),
            _buildSummaryRow('Date', _formatDate(workshop['date'])),
            const SizedBox(height: 8),
            _buildSummaryRow('Time', workshop['time'] ?? ''),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Participant',
              '${registrationData['firstName']} ${registrationData['lastName']}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('Email', registrationData['email'] ?? ''),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
                Text(
                  'PKR ${workshop['price']?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF006876),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    return date.toString();
  }

  Widget _buildPaymentInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.payment,
              'Secure Payment',
              'Your payment is processed securely through PayFast',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.shield,
              'Money Back Guarantee',
              'Full refund available up to 7 days before the workshop',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.confirmation_number,
              'Instant Confirmation',
              'You\'ll receive a confirmation email immediately after payment',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF006876).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF006876), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> workshop, String registrationId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'PKR ${workshop['price']?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _processPayment(workshop, registrationId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006876),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Pay Securely',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Future<void> _processPayment(
    Map<String, dynamic> workshop,
    String registrationId,
  ) async {
    // ============================================================================
    // PHASE 3 SECURITY CHECK: Verify 1-Hour Payment Window
    // ============================================================================
    try {
      final registrationDoc = await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .get();

      if (!registrationDoc.exists) {
        if (mounted) {
          _showErrorDialog(
            'Registration Not Found',
            'This registration could not be found. Please try again.',
          );
        }
        return;
      }

      final registrationData = registrationDoc.data()!;
      final creatorApprovedAt = registrationData['creatorApprovedAt'];

      // Check if approval exists
      if (creatorApprovedAt == null) {
        if (mounted) {
          _showErrorDialog(
            'Approval Pending',
            'This workshop registration has not been approved yet by the instructor.',
          );
        }
        return;
      }

      // Convert Timestamp to DateTime
      DateTime approvedTime;
      if (creatorApprovedAt is Timestamp) {
        approvedTime = creatorApprovedAt.toDate();
      } else if (creatorApprovedAt is DateTime) {
        approvedTime = creatorApprovedAt;
      } else {
        if (mounted) {
          _showErrorDialog(
            'Invalid Data',
            'Unable to verify approval timestamp. Please contact support.',
          );
        }
        return;
      }

      // Check if 1-hour window has expired
      if (_workshopService.hasJoiningPaymentExpired(approvedTime)) {
        if (mounted) {
          _showErrorDialog(
            'Payment Window Expired',
            'Sorry, your 1-hour payment window has expired. Please register again to request a new approval.',
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Verification Failed',
          'Unable to verify registration status: $e',
        );
      }
      return;
    }

    // ============================================================================
    // PROCEED WITH PAYMENT
    // ============================================================================
    setState(() => _isProcessing = true);

    try {
      // ============================================================================
      // PAYMENT GATEWAY - TO BE IMPLEMENTED
      // ============================================================================
      // TODO: Implement PayFast payment integration
      // 1. Create payment record in Firebase
      // 2. Generate PayFast payment link with merchant credentials
      // 3. Redirect user to PayFast payment page
      // 4. Handle payment callback/webhook to confirm payment
      // 5. Update registration status based on payment result
      // ============================================================================

      /* COMMENTED OUT - PayFast Integration (To be added later)
      final paymentRef = await _firestore.collection('workshop_payments').add({
        'registrationId': registrationId,
        'workshopId': workshop['id'],
        'amount': workshop['price'],
        'status': 'pending',
        'paymentMethod': 'payfast',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final paymentUrl = 'https://www.payfast.co.za/eng/process?'
          'merchant_id=YOUR_MERCHANT_ID'
          '&merchant_key=YOUR_MERCHANT_KEY'
          '&amount=${workshop['price']}'
          '&item_name=${Uri.encodeComponent(workshop['title'] ?? '')}'
          '&return_url=${Uri.encodeComponent('YOUR_RETURN_URL')}'
          '&cancel_url=${Uri.encodeComponent('YOUR_CANCEL_URL')}'
          '&notify_url=${Uri.encodeComponent('YOUR_NOTIFY_URL')}';

      await launchUrl(Uri.parse(paymentUrl));
      */

      // ============================================================================
      // TEMPORARY: Auto-confirm for testing (REMOVE IN PRODUCTION)
      // ============================================================================
      if (mounted) {
        // Generate registration number
        final year = DateTime.now().year;
        final registrationNumber =
            'WS-$year-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

        // Update registration with confirmation
        await _updateRegistrationStatus(
          registrationId,
          'confirmed',
          registrationNumber,
        );

        // Increment workshop participants count using TRANSACTION (prevent over-booking)
        final incrementResult =
            await _incrementWorkshopParticipantsWithTransaction(
              workshop['id'],
              workshop['maxParticipants'] ?? 100,
            );

        if (!incrementResult) {
          // Rollback registration if seat not available
          await _updateRegistrationStatus(registrationId, 'failed');
          throw Exception('Workshop is now full. Please try another workshop.');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Registration confirmed! (Payment gateway will be added later)',
            ),
            backgroundColor: Color(0xFF90D26D),
            duration: Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing registration: $e'),
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

  Future<void> _updateRegistrationStatus(
    String registrationId,
    String status, [
    String? registrationNumber,
  ]) async {
    final updates = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (registrationNumber != null) {
      updates['registrationNumber'] = registrationNumber;
      updates['paymentStatus'] = 'paid';
      updates['confirmedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore
        .collection('workshop_registrations')
        .doc(registrationId)
        .update(updates);
  }

  /// Transaction-based seat increment to prevent over-booking
  Future<bool> _incrementWorkshopParticipantsWithTransaction(
    String workshopId,
    int maxParticipants,
  ) async {
    try {
      final workshopRef = _firestore.collection('workshops').doc(workshopId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final workshopSnapshot = await transaction.get(workshopRef);

        if (!workshopSnapshot.exists) {
          throw Exception('Workshop not found');
        }

        final currentParticipants =
            workshopSnapshot.data()?['currentParticipants'] ?? 0;

        // Check if seat still available
        if (currentParticipants >= maxParticipants) {
          return false; // ❌ Workshop full
        }

        // ✅ Increment safely
        transaction.update(workshopRef, {
          'currentParticipants': currentParticipants + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true; // ✅ Seat confirmed
      });
    } catch (e) {
      debugPrint('❌ Transaction error: $e');
      return false;
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
