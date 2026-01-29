import 'package:flutter/material.dart';
import 'package:sehatmakaan/features/payments/services/payfast_service.dart';
import 'package:sehatmakaan/features/payments/screens/payfast_webview_screen.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class PaymentStep extends StatefulWidget {
  final double totalAmount;
  final GlobalKey<FormState> formKey;
  final String? bookingId;
  final String? bookingType;
  final String userId;
  final String userEmail;
  final String userName;
  final VoidCallback? onPaymentSuccess;
  final double baseAmount;
  final List<Map<String, dynamic>> selectedAddons;

  const PaymentStep({
    super.key,
    required this.totalAmount,
    required this.formKey,
    this.bookingId,
    this.bookingType,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.onPaymentSuccess,
    required this.baseAmount,
    required this.selectedAddons,
  });

  @override
  State<PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<PaymentStep> {
  final PayFastService _payFastService = PayFastService();
  bool _isProcessingPayment = false;
  String? _currentPaymentId;
  StreamSubscription<DocumentSnapshot>? _paymentStatusSubscription;

  Future<void> _processPayFastPayment() async {
    // Prevent duplicate payment processing
    if (_isProcessingPayment) {
      debugPrint('⚠️ Payment already in progress');
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      // ✅ FIX: Use bookingId if available, otherwise generate registrationId
      final bookingId = widget.bookingId;
      final registrationId = DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint(
        '💳 Starting payment for booking: $bookingId, registration: $registrationId',
      );

      // ✅ FIX: Pass bookingId and paymentType to service
      final paymentUrl = _payFastService.generatePaymentUrl(
        registrationId: registrationId,
        workshopTitle:
            '${widget.bookingType == 'hourly' ? 'Hourly' : 'Monthly'} Booking',
        amount: widget.totalAmount,
        userEmail: widget.userEmail,
        userName: widget.userName,
        bookingId: bookingId, // ✅ NEW
        paymentType: 'booking', // ✅ NEW
      );

      // ✅ FIX: Create payment in booking_payments collection
      _currentPaymentId = await _payFastService.createPaymentRecord(
        registrationId: registrationId,
        workshopId: 'booking_${widget.bookingType}',
        userId: widget.userId,
        amount: widget.totalAmount,
        userEmail: widget.userEmail,
        userName: widget.userName,
        bookingId: bookingId, // ✅ NEW
        paymentType: 'booking', // ✅ NEW
      );

      debugPrint('✅ Payment record created: $_currentPaymentId');

      // Navigate to in-app WebView for payment
      if (mounted) {
        // Start listening to payment status changes BEFORE opening payment window
        _startPaymentStatusListener(_currentPaymentId!);

        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PayFastWebViewScreen(
              paymentUrl: paymentUrl,
              onPaymentSuccess: () async {
                debugPrint('? Payment completed via callback');
                if (_currentPaymentId != null) {
                  await _payFastService.updatePaymentStatus(
                    paymentId: _currentPaymentId!,
                    status: 'completed',
                    additionalData: {
                      'completedAt': DateTime.now().toIso8601String(),
                    },
                  );
                }
              },
              onPaymentCancel: () async {
                debugPrint('? Payment cancelled via callback');
                if (_currentPaymentId != null) {
                  await _payFastService.updatePaymentStatus(
                    paymentId: _currentPaymentId!,
                    status: 'cancelled',
                    additionalData: {
                      'cancelledAt': DateTime.now().toIso8601String(),
                    },
                  );
                }
              },
            ),
          ),
        );

        // Stop listening when user returns
        _stopPaymentStatusListener();

        if (mounted) {
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('? Payment completed successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            // Call success callback with error handling
            try {
              widget.onPaymentSuccess?.call();
            } catch (callbackError) {
              debugPrint('? Error in payment success callback: $callbackError');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Payment successful but booking failed: $callbackError',
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () => widget.onPaymentSuccess?.call(),
                    ),
                  ),
                );
              }
            }
          } else if (result == false) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('? Payment was cancelled'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('? Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 800,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                return isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderIcon(),
                          const SizedBox(height: 12),
                          _buildHeaderText(context),
                        ],
                      )
                    : Row(
                        children: [
                          _buildHeaderIcon(),
                          const SizedBox(width: 16),
                          Expanded(child: _buildHeaderText(context)),
                        ],
                      );
              },
            ),
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context) * 2,
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006876), Color(0xFF008C9E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF006876),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Amount to Pay',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                  Text(
                    'PKR ${widget.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, color: Color(0xFF006876), size: 32),
                      SizedBox(width: 8),
                      Text(
                        'PayFast',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006876),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Secure Payment Gateway',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006876),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will be redirected to PayFast to complete your payment securely',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processPayFastPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006876),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isProcessingPayment
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
                          Icon(Icons.lock_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Proceed to Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '?? Your payment is secure and encrypted. PayFast uses industry-standard security protocols.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF006876).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.payment, color: Color(0xFF006876), size: 32),
    );
  }

  Widget _buildHeaderText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006876),
          ),
        ),
        Text(
          'Complete your payment securely via PayFast',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Start listening to payment status in Firestore
  void _startPaymentStatusListener(String paymentId) {
    debugPrint('?? Starting payment status listener for: $paymentId');

    _paymentStatusSubscription = FirebaseFirestore.instance
        .collection('workshop_payments')
        .doc(paymentId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists || !mounted) return;

          final data = snapshot.data();
          if (data == null) return;

          final status = data['status'] as String?;
          debugPrint('?? Payment status update: $status');

          if (status == 'completed') {
            debugPrint(
              '? Payment detected as completed! Auto-closing dialog...',
            );
            _stopPaymentStatusListener();

            // Close payment dialog automatically
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            }

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('? Payment successful! Booking confirmed.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );

              // Trigger success callback
              widget.onPaymentSuccess?.call();
            }
          } else if (status == 'failed' || status == 'cancelled') {
            debugPrint('? Payment detected as $status! Auto-closing dialog...');
            _stopPaymentStatusListener();

            // Close payment dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context, false);
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('? Payment $status'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        });
  }

  // Stop listening to payment status
  void _stopPaymentStatusListener() {
    debugPrint('?? Stopping payment status listener');
    _paymentStatusSubscription?.cancel();
    _paymentStatusSubscription = null;
  }

  @override
  void dispose() {
    _stopPaymentStatusListener();
    super.dispose();
  }
}
