import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// PayFast Payment Service - Pakistan Integration
/// Handles PayFast Pakistan (payfast.com.pk) payment integration
class PayFastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ PayFast Pakistan Configuration (use environment variables in production)
  static const String merchantId = '10000100'; // Replace with your merchant ID
  static const String securedKey =
      '46f0cd694581a'; // Replace with your secured key
  static const bool testMode = true; // Set to false in production

  /// Generate PayFast Pakistan payment parameters
  Map<String, String> generatePaymentParams({
    required String registrationId,
    required String workshopTitle,
    required double amount,
    required String userEmail,
    required String userName,
  }) {
    final params = <String, String>{};

    // ✅ PayFast Pakistan required fields
    params['MERCHANT_ID'] = merchantId;
    params['SECURED_KEY'] = securedKey;

    // Transaction details
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    params['TOKEN'] = '$registrationId-$timestamp'; // Unique transaction token

    // ✅ Amount in PKR (no conversion needed for Pakistan)
    params['TXNAMT'] = amount.toStringAsFixed(2);
    params['CURRENCY_CODE'] = 'PKR'; // Pakistani Rupee

    // Customer details
    params['CUSTOMER_EMAIL_ADDRESS'] = userEmail;
    params['CUSTOMER_MOBILE_NO'] = ''; // Optional

    // ✅ Sanitize description
    final sanitizedTitle = workshopTitle
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s\-_]'), '')
        .trim();
    params['TXNDESC'] = sanitizedTitle.isNotEmpty
        ? sanitizedTitle
        : 'Workshop Registration';

    // Callback URLs
    params['SUCCESS_URL'] = 'https://sehatmakaan.com/payment/success';
    params['FAILURE_URL'] = 'https://sehatmakaan.com/payment/cancel';
    params['CHECKOUT_URL'] = 'https://sehatmakaan.com/payment/checkout';

    debugPrint('✅ PayFast Pakistan params generated for $userEmail');

    return params;
  }

  /// Generate PayFast Pakistan signature
  /// ✅ Specific order: MERCHANT_ID + SECURED_KEY + TOKEN + TXNAMT + CUSTOMER_EMAIL_ADDRESS
  String generateSignature(Map<String, String> params) {
    // ✅ PayFast Pakistan signature order (NOT alphabetical)
    final signatureString =
        '${params['MERCHANT_ID']}'
        '${params['SECURED_KEY']}'
        '${params['TOKEN']}'
        '${params['TXNAMT']}'
        '${params['CUSTOMER_EMAIL_ADDRESS']}';

    debugPrint('🔐 Signature string: $signatureString');

    // Generate SHA-256 hash
    final bytes = utf8.encode(signatureString);
    final digest = sha256.convert(bytes);

    final signature = digest.toString();
    debugPrint('🔑 Generated signature: $signature');

    return signature;
  }

  /// Generate PayFast Pakistan payment URL
  String generatePaymentUrl({
    required String registrationId,
    required String workshopTitle,
    required double amount,
    required String userEmail,
    required String userName,
    String? bookingId, // ✅ NEW: For booking payments
    String? paymentType, // ✅ NEW: 'workshop', 'booking', or 'workshop_creation'
  }) {
    // Generate parameters
    final params = generatePaymentParams(
      registrationId: registrationId,
      workshopTitle: workshopTitle,
      amount: amount,
      userEmail: userEmail,
      userName: userName,
    );

    // Generate signature
    final signature = generateSignature(params);
    params['SIGNATURE'] = signature;

    // ✅ PayFast Pakistan API endpoint
    final baseUrl = testMode
        ? 'https://ipg.payfast.com.pk/api/payfast/pay' // Sandbox/Test
        : 'https://ipg.payfast.com.pk/api/payfast/pay'; // Production

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryString';
  }

  /// Create payment record in Firestore
  /// ✅ FIXED: Uses correct collection based on payment type
  Future<String> createPaymentRecord({
    required String registrationId,
    required String workshopId,
    required String userId,
    required double amount,
    required String userEmail,
    required String userName,
    String? bookingId, // ✅ NEW: For booking payments
    String paymentType = 'workshop', // ✅ NEW: 'workshop' or 'booking'
  }) async {
    try {
      // ✅ Use correct collection based on payment type
      final collection = paymentType == 'booking'
          ? 'booking_payments'
          : 'workshop_payments';

      final paymentData = {
        'userId': userId,
        'amount': amount,
        'currency': 'PKR', // ✅ Pakistani Rupee
        'status': 'pending',
        'paymentMethod': 'payfast-pakistan',
        'userEmail': userEmail,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add type-specific fields
      if (paymentType == 'booking' && bookingId != null) {
        paymentData['bookingId'] = bookingId;
      } else {
        paymentData['registrationId'] = registrationId;
        paymentData['workshopId'] = workshopId;
      }

      final paymentDoc = await _firestore
          .collection(collection)
          .add(paymentData);

      debugPrint('✅ Payment record created in $collection: ${paymentDoc.id}');
      return paymentDoc.id;
    } catch (e) {
      debugPrint('❌ Error creating payment record: $e');
      rethrow;
    }
  }

  /// Process workshop payment
  Future<Map<String, dynamic>> processWorkshopPayment({
    required String registrationId,
    required String workshopId,
    required String workshopTitle,
    required double amount,
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    try {
      // Create payment record
      final paymentId = await createPaymentRecord(
        registrationId: registrationId,
        workshopId: workshopId,
        userId: userId,
        amount: amount,
        userEmail: userEmail,
        userName: userName,
      );

      // Generate payment URL
      final paymentUrl = generatePaymentUrl(
        registrationId: registrationId,
        workshopTitle: workshopTitle,
        amount: amount,
        userEmail: userEmail,
        userName: userName,
      );

      return {
        'success': true,
        'paymentId': paymentId,
        'paymentUrl': paymentUrl,
        'message': 'Payment link generated successfully',
      };
    } catch (e) {
      debugPrint('❌ Error processing payment: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to process payment',
      };
    }
  }

  /// Verify PayFast payment callback
  Future<bool> verifyPaymentCallback(Map<String, dynamic> callbackData) async {
    try {
      // Extract signature from callback
      final receivedSignature = callbackData['signature'];
      if (receivedSignature == null) {
        debugPrint('❌ No signature in callback data');
        return false;
      }

      // Remove signature from data for verification
      final dataToVerify = Map<String, String>.from(callbackData);
      dataToVerify.remove('signature');

      // Generate expected signature
      final expectedSignature = generateSignature(dataToVerify);

      // Compare signatures
      if (receivedSignature != expectedSignature) {
        debugPrint('❌ Signature mismatch');
        debugPrint('Received: $receivedSignature');
        debugPrint('Expected: $expectedSignature');
        return false;
      }

      // Verify payment status
      final paymentStatus = callbackData['payment_status'];
      if (paymentStatus != 'COMPLETE') {
        debugPrint('⚠️ Payment not complete: $paymentStatus');
        return false;
      }

      debugPrint('✅ Payment verified successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');
      return false;
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await _firestore
          .collection('workshop_payments')
          .doc(paymentId)
          .update(updateData);

      debugPrint('✅ Payment status updated: $status');
    } catch (e) {
      debugPrint('❌ Error updating payment status: $e');
      rethrow;
    }
  }

  /// Handle payment notification (webhook)
  /// This should be called by a Cloud Function
  Future<void> handlePaymentNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      // Verify payment
      final isValid = await verifyPaymentCallback(notificationData);
      if (!isValid) {
        debugPrint('❌ Invalid payment notification');
        return;
      }

      // Extract payment details
      final registrationId = notificationData['m_payment_id'];
      final paymentStatus = notificationData['payment_status'];
      final amountGross = notificationData['amount_gross'];

      // Find payment record
      final paymentQuery = await _firestore
          .collection('workshop_payments')
          .where('registrationId', isEqualTo: registrationId)
          .limit(1)
          .get();

      if (paymentQuery.docs.isEmpty) {
        debugPrint(
          '❌ Payment record not found for registration: $registrationId',
        );
        return;
      }

      final paymentDoc = paymentQuery.docs.first;

      // Update payment status
      await updatePaymentStatus(
        paymentId: paymentDoc.id,
        status: paymentStatus == 'COMPLETE' ? 'completed' : 'failed',
        additionalData: {
          'payfastData': notificationData,
          'amountReceived': amountGross,
          'completedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update booking/subscription/workshop status based on type
      if (paymentStatus == 'COMPLETE') {
        final workshopId = paymentDoc.data()['workshopId']?.toString() ?? '';
        String collection;

        // Determine collection based on workshop/booking type
        if (workshopId.contains('booking_hourly')) {
          collection = 'bookings';
        } else if (workshopId.contains('booking_monthly')) {
          collection = 'subscriptions';
        } else {
          collection = 'workshop_registrations';
        }

        try {
          // Query to find the booking/subscription by registrationId
          final bookingQuery = await _firestore
              .collection(collection)
              .where('registrationId', isEqualTo: registrationId)
              .limit(1)
              .get();

          if (bookingQuery.docs.isNotEmpty) {
            await bookingQuery.docs.first.reference.update({
              'paymentStatus': 'paid',
              'paymentCompletedAt': FieldValue.serverTimestamp(),
            });
            debugPrint('✅ $collection payment completed for $registrationId');
          } else {
            debugPrint(
              '⚠️ No $collection found for registration: $registrationId',
            );
          }
        } catch (e) {
          debugPrint('❌ Error updating $collection status: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling payment notification: $e');
      rethrow;
    }
  }

  /// Get payment status
  Future<String?> getPaymentStatus(String paymentId) async {
    try {
      final doc = await _firestore
          .collection('workshop_payments')
          .doc(paymentId)
          .get();
      return doc.data()?['status'];
    } catch (e) {
      debugPrint('❌ Error getting payment status: $e');
      return null;
    }
  }

  /// Cancel payment
  Future<void> cancelPayment(String paymentId) async {
    try {
      await updatePaymentStatus(
        paymentId: paymentId,
        status: 'cancelled',
        additionalData: {'cancelledAt': FieldValue.serverTimestamp()},
      );
      debugPrint('✅ Payment cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling payment: $e');
      rethrow;
    }
  }
}
