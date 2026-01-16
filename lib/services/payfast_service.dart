import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// PayFast Payment Service
/// Handles PayFast payment integration for workshop bookings
class PayFastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PayFast Configuration (use environment variables in production)
  static const String merchantId = '10000100'; // Demo merchant ID
  static const String merchantKey = '46f0cd694581a'; // Demo merchant key
  static const String passphrase = 'jt7NOE43FZPn'; // Demo passphrase
  static const bool testMode = true; // Set to false in production

  /// Generate PayFast payment parameters
  Map<String, String> generatePaymentParams({
    required String registrationId,
    required String workshopTitle,
    required double amount,
    required String userEmail,
    required String userName,
  }) {
    // Base parameters
    final params = {
      'merchant_id': merchantId,
      'merchant_key': merchantKey,
      'return_url': 'https://sehatmakaan.com/payment/success',
      'cancel_url': 'https://sehatmakaan.com/payment/cancel',
      'notify_url': 'https://sehatmakaan.com/api/payfast/notify',
      'm_payment_id': registrationId,
      'amount': amount.toStringAsFixed(2),
      'item_name': 'Workshop: $workshopTitle',
      'item_description': 'Registration for $workshopTitle workshop',
      'email_address': userEmail,
      'name_first': userName.split(' ').first,
      'name_last': userName.split(' ').length > 1
          ? userName.split(' ').last
          : '',
    };

    // Add passphrase if in production
    if (!testMode && passphrase.isNotEmpty) {
      params['passphrase'] = passphrase;
    }

    return params;
  }

  /// Generate PayFast signature
  String generateSignature(Map<String, String> params) {
    // Remove signature if present
    final paramsToSign = Map<String, String>.from(params);
    paramsToSign.remove('signature');

    // Sort parameters alphabetically
    final sortedKeys = paramsToSign.keys.toList()..sort();

    // Build parameter string
    final paramString = sortedKeys
        .map((key) => '$key=${Uri.encodeComponent(paramsToSign[key]!)}')
        .join('&');

    // Add passphrase if not in test mode
    final stringToHash = !testMode && passphrase.isNotEmpty
        ? '$paramString&passphrase=${Uri.encodeComponent(passphrase)}'
        : paramString;

    // Generate MD5 hash
    final bytes = utf8.encode(stringToHash);
    final digest = md5.convert(bytes);

    return digest.toString();
  }

  /// Generate PayFast payment URL
  String generatePaymentUrl({
    required String registrationId,
    required String workshopTitle,
    required double amount,
    required String userEmail,
    required String userName,
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
    params['signature'] = signature;

    // Build URL
    final baseUrl = testMode
        ? 'https://sandbox.payfast.co.za/eng/process'
        : 'https://www.payfast.co.za/eng/process';

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryString';
  }

  /// Create payment record in Firestore
  Future<String> createPaymentRecord({
    required String registrationId,
    required String workshopId,
    required String userId,
    required double amount,
    required String userEmail,
    required String userName,
  }) async {
    try {
      final paymentDoc = await _firestore.collection('workshop_payments').add({
        'registrationId': registrationId,
        'workshopId': workshopId,
        'userId': userId,
        'amount': amount,
        'currency': 'ZAR',
        'status': 'pending',
        'paymentMethod': 'payfast',
        'userEmail': userEmail,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Payment record created: ${paymentDoc.id}');
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

      // Update workshop registration status
      if (paymentStatus == 'COMPLETE') {
        await _firestore
            .collection('workshop_registrations')
            .doc(registrationId)
            .update({
              'paymentStatus': 'paid',
              'paymentCompletedAt': FieldValue.serverTimestamp(),
            });
        debugPrint('✅ Workshop registration payment completed');
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
