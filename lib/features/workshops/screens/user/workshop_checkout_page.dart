import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkshopCheckoutPage extends StatefulWidget {
  const WorkshopCheckoutPage({super.key});

  @override
  State<WorkshopCheckoutPage> createState() => _WorkshopCheckoutPageState();
}

class _WorkshopCheckoutPageState extends State<WorkshopCheckoutPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isProcessing = false;
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workshop Checkout')),
        body: const Center(
          child: Text('Missing checkout data. Please restart the flow.'),
        ),
      );
    }

    final workshop = args['workshop'] as Map<String, dynamic>?;
    final userSession = args['userSession'] as Map<String, dynamic>?;

    if (workshop == null || userSession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workshop Checkout')),
        body: const Center(
          child: Text('Incomplete checkout data. Please restart the flow.'),
        ),
      );
    }

    // 🚀 Auto-create registration data from userSession
    final registrationData = {
      'firstName':
          userSession['firstName'] ??
          userSession['name']?.toString().split(' ').first ??
          'User',
      'lastName':
          userSession['lastName'] ??
          userSession['name']?.toString().split(' ').skip(1).join(' ') ??
          '',
      'email': userSession['email'] ?? '',
      'cnic': userSession['cnic'] ?? '',
      'phone': userSession['phone'] ?? '',
      'institution': userSession['institution'] ?? '',
      'specialty': userSession['specialty'] ?? '',
    };

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
            _buildTermsCheckbox(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(
        workshop,
        userSession,
        registrationData,
      ),
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

  Widget _buildTermsCheckbox() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _termsAccepted,
              onChanged: (value) {
                setState(() => _termsAccepted = value ?? false);
              },
              title: const Text(
                'I agree to the workshop terms and conditions',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF006876),
              contentPadding: EdgeInsets.zero,
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

  Widget _buildBottomBar(
    Map<String, dynamic> workshop,
    Map<String, dynamic> userSession,
    Map<String, dynamic> registrationData,
  ) {
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (!_termsAccepted || _isProcessing)
                    ? null
                    : () => _processPayment(
                        workshop,
                        userSession,
                        registrationData,
                      ),
                icon: const Icon(Icons.payment),
                label: const Text('Proceed to Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006876),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Show loading state only if processing
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 12),
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(
    Map<String, dynamic> workshop,
    Map<String, dynamic> userSession,
    Map<String, dynamic> registrationData,
  ) async {
    try {
      setState(() => _isProcessing = true);

      // 🚀 Auto-create registration record in Firestore
      final registrationRef = await _firestore
          .collection('workshop_registrations')
          .add({
            'userId': userSession['id'],
            'workshopId': workshop['id'],
            'firstName': registrationData['firstName'],
            'lastName': registrationData['lastName'],
            'email': registrationData['email'],
            'cnic': registrationData['cnic'],
            'phone': registrationData['phone'],
            'institution': registrationData['institution'],
            'specialty': registrationData['specialty'],
            'status': 'pending', // Will become 'confirmed' after payment
            'paymentStatus': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      final registrationId = registrationRef.id;

      // Create payment record in Firestore
      final paymentRef = await _firestore.collection('workshop_payments').add({
        'registrationId': registrationId,
        'workshopId': workshop['id'],
        'userId': userSession['id'],
        'amount': workshop['price'],
        'status': 'pending',
        'paymentMethod': 'payfast',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final paymentId = paymentRef.id;
      final workshopTitle = Uri.encodeComponent(workshop['title'] ?? '');
      final userEmail = Uri.encodeComponent(registrationData['email'] ?? '');
      final amount = (workshop['price'] as num?)?.toStringAsFixed(2) ?? '0.00';

      // Build PayFast payment URL with proper parameters
      final payfastUrl =
          'https://www.payfast.co.za/eng/process?'
          'merchant_id=10029646'
          '&merchant_key=qzffl86tqx6qk'
          '&amount=$amount'
          '&item_name=Workshop%20Registration%3A%20$workshopTitle'
          '&item_description=Payment%20for%20workshop%20registration'
          '&email_address=$userEmail'
          '&custom_str1=$registrationId'
          '&custom_str2=$paymentId'
          '&custom_str3=workshop'
          '&return_url=https://sehatmakaan.vercel.app/payment-success'
          '&cancel_url=https://sehatmakaan.vercel.app/payment-cancel'
          '&notify_url=https://us-central1-sehatmakaan-833e2.cloudfunctions.net/handlePayFastWebhook';

      debugPrint('💳 Opening PayFast payment page: $payfastUrl');

      // Launch PayFast payment page
      if (await canLaunchUrl(Uri.parse(payfastUrl))) {
        await launchUrl(
          Uri.parse(payfastUrl),
          mode: LaunchMode.externalApplication,
        );

        // Show message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '💳 Opening PayFast payment gateway. Please complete your payment.',
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Wait for payment callback (webhook will update registration status)
        // For now, show a dialog asking user to confirm
        if (mounted) {
          _showPaymentPendingDialog(registrationId, paymentId);
        }
      } else {
        throw 'Could not launch PayFast payment page';
      }
    } catch (e) {
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

  void _showPaymentPendingDialog(String registrationId, String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.blue),
            SizedBox(width: 12),
            Text('Payment Processing'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your payment is being processed. Please wait for confirmation.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              'You will be redirected once payment is confirmed.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
