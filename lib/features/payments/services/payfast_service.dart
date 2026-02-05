import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// PayFast Payment Service - Pakistan Integration
/// Handles PayFast Pakistan (payfast.com.pk) payment integration
class PayFastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ PayFast Pakistan Test Credentials (from official documentation)
  static const String merchantId = '102'; // PayFast UAT Test Merchant ID
  static const String securedKey =
      'zWHjBp2AlttNu1sK'; // PayFast UAT Test Secured Key
  static const bool testMode = true; // Set to false in production

  /// Get Access Token from PayFast API
  /// ✅ FIXED: Must include BASKET_ID, TXNAMT, CURRENCY_CODE (as per PHP example)
  Future<String?> getAccessToken({
    required String basketId,
    required double amount,
  }) async {
    try {
      final tokenUrl = testMode
          ? 'https://ipguat.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken'
          : 'https://ipg1.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken';

      debugPrint('🔑 Requesting access token from PayFast...');

      // ✅ CRITICAL FIX: Send as URL-encoded form data (like PHP example)
      final params = {
        'MERCHANT_ID': merchantId,
        'SECURED_KEY': securedKey,
        'BASKET_ID': basketId,
        'TXNAMT': amount.toStringAsFixed(2),
        'CURRENCY_CODE': 'PKR',
      };

      debugPrint('📝 Token request params: $params');

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: params,
      );

      debugPrint('🔑 Token API Response: ${response.statusCode}');
      debugPrint('🔑 Token API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['ACCESS_TOKEN'] ?? data['token'] ?? data['TOKEN'];

        if (token != null) {
          debugPrint('✅ Access token received: $token');
          return token;
        } else {
          debugPrint('❌ No token in response: ${response.body}');
          return null;
        }
      } else {
        debugPrint('❌ Token request failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting access token: $e');
      return null;
    }
  }

  /// Generate PayFast Pakistan payment parameters
  Map<String, String> generatePaymentParams({
    required String registrationId,
    required String workshopTitle,
    required double amount,
    required String userEmail,
    required String userName,
  }) {
    final params = <String, String>{};

    // ✅ PayFast Pakistan required fields (UPPERCASE as per API documentation)
    params['MERCHANT_ID'] = merchantId;
    params['MERCHANT_NAME'] = 'Sehat Makaan'; // Brand name

    // Transaction details
    // NOTE: TOKEN will be set by getAccessToken() API call
    params['BASKET_ID'] = registrationId; // ✅ MANDATORY: Unique order ID

    // ✅ FIX: ORDER_DATE must be "YYYY-MM-DD HH:MM:SS" format (as per PHP example)
    final now = DateTime.now();
    params['ORDER_DATE'] =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    // ✅ Amount in PKR (no conversion needed for Pakistan)
    params['TXNAMT'] = amount.toStringAsFixed(2);
    params['CURRENCY_CODE'] = 'PKR'; // Pakistani Rupee
    params['PROCCODE'] = '00'; // ✅ MANDATORY: Transaction process code

    // Customer details
    // ⚠️ TEST CREDENTIALS (from PayFast support):
    // Demo Bank: Account 111111111111111111111, CNIC: 1111111111111, OTP: 123456
    // DO NOT use real JazzCash (03123456789) - real money deduction!
    params['CUSTOMER_EMAIL_ADDRESS'] = userEmail.isNotEmpty
        ? userEmail
        : 'customer@sehatmakaan.com';
    params['CUSTOMER_MOBILE_NO'] = '03000000090'; // ✅ PayFast demo number

    // ✅ Sanitize description
    final sanitizedTitle = workshopTitle
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s\-_]'), '')
        .trim();
    params['TXNDESC'] = sanitizedTitle.isNotEmpty
        ? sanitizedTitle
        : 'Sehat Makaan Booking';

    // ✅ MANDATORY: Callback URLs
    params['SUCCESS_URL'] = 'https://sehatmakaan.com/payment/success';
    params['FAILURE_URL'] = 'https://sehatmakaan.com/payment/cancel';
    params['CHECKOUT_URL'] = 'https://sehatmakaan.com/payment/checkout';

    // ✅ MANDATORY: Version (random string as per docs)
    params['VERSION'] = 'SEHATMAKAAN-MOBILE-1.0';

    debugPrint('✅ PayFast Pakistan params generated for $userEmail');

    return params;
  }

  /// Generate random signature for PayFast
  /// ✅ CRITICAL FIX: SIGNATURE is just a random string (not a hash!)
  /// As per PHP example: SIGNATURE = "SOMERANDOM-STRING"
  String generateRandomSignature() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomString = 'SEHATMAKAAN-$timestamp';
    debugPrint('🔑 Random signature: $randomString');
    return randomString;
  }

  /// Generate validation hash for webhook verification
  /// Format: basket_id|secured_key|merchant_id|err_code
  /// Used to verify PayFast's IPN (Instant Payment Notification)
  String generateValidationHash({
    required String basketId,
    required String errorCode,
  }) {
    final hashString = '$basketId|$securedKey|$merchantId|$errorCode';
    final bytes = utf8.encode(hashString);
    final hash = sha256.convert(bytes);
    debugPrint('🔐 Validation hash string: $hashString');
    debugPrint('🔐 Validation hash: $hash');
    return hash.toString();
  }

  /// Generate PayFast Pakistan payment URL
  Future<String> generatePaymentUrl({
    required String registrationId,
    required String workshopTitle,
    required double amount,
    required String userEmail,
    required String userName,
    String? bookingId, // ✅ NEW: For booking payments
    String? paymentType, // ✅ NEW: 'workshop', 'booking', or 'workshop_creation'
  }) async {
    try {
      debugPrint('🔧 Generating payment URL...');

      // Generate parameters first
      final params = generatePaymentParams(
        registrationId: registrationId,
        workshopTitle: workshopTitle,
        amount: amount,
        userEmail: userEmail,
        userName: userName,
      );

      // ✅ CRITICAL FIX: Get access token with BASKET_ID and TXNAMT
      final accessToken = await getAccessToken(
        basketId: registrationId,
        amount: amount,
      );
      if (accessToken == null) {
        throw Exception('Failed to get PayFast access token');
      }

      // ✅ Use PayFast-provided TOKEN
      params['TOKEN'] = accessToken;

      debugPrint(
        '📝 Payment params (before signature): ${params.keys.join(", ")}',
      );

      // ✅ CRITICAL FIX: Use random string for SIGNATURE (not SHA256 hash!)
      final signature = generateRandomSignature();
      params['SIGNATURE'] = signature;

      debugPrint('✅ Random signature generated: $signature');

      // ✅ PayFast Pakistan requires POST request, so we create an HTML form
      // that auto-submits to the PayFast endpoint
      final baseUrl = testMode
          ? 'https://ipguat.apps.net.pk/Ecommerce/api/Transaction/PostTransaction' // Sandbox UAT
          : 'https://ipg1.apps.net.pk/Ecommerce/api/Transaction/PostTransaction'; // Production

      debugPrint('🌐 PayFast URL: $baseUrl');
      debugPrint('📝 Payment params: ${params.keys.join(", ")}');

      // Generate HTML form with auto-submit
      final formFields = params.entries
          .map(
            (e) => '<input type="hidden" name="${e.key}" value="${e.value}">',
          )
          .join('\n');

      final html =
          '''
<!DOCTYPE html>
<html>
<head>
    <title>Redirecting to PayFast...</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #006876 0%, #00a0b0 100%);
        }
        .loader {
            text-align: center;
            color: white;
        }
        .spinner {
            border: 4px solid rgba(255,255,255,0.3);
            border-radius: 50%;
            border-top: 4px solid white;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="loader">
        <div class="spinner"></div>
        <h2>Redirecting to PayFast...</h2>
        <p>Please wait while we redirect you to the payment gateway.</p>
    </div>
    <form id="payfast_form" action="$baseUrl" method="POST">
        $formFields
    </form>
    <script>
        // Add error handling for form submission
        try {
            console.log('Submitting payment form to PayFast...');
            document.getElementById('payfast_form').submit();
        } catch (error) {
            console.error('Error submitting form:', error);
            alert('Error redirecting to payment gateway. Please try again.');
        }
    </script>
</body>
</html>
''';

      // Return data URL with HTML form
      final dataUrl =
          'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';
      debugPrint('✅ Payment URL generated successfully');
      return dataUrl;
    } catch (e) {
      debugPrint('❌ Error generating payment URL: $e');
      // Return error page HTML instead of crashing
      final errorHtml =
          '''
<!DOCTYPE html>
<html>
<head>
    <title>Payment Error</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: #f5f5f5;
            text-align: center;
            padding: 20px;
        }
        .error {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #d32f2f; }
    </style>
</head>
<body>
    <div class="error">
        <h1>⚠️ Payment Error</h1>
        <p>Unable to generate payment request.</p>
        <p>Error: $e</p>
        <p>Please go back and try again.</p>
    </div>
</body>
</html>
''';
      return 'data:text/html;charset=utf-8,${Uri.encodeComponent(errorHtml)}';
    }
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

      // Generate payment URL (now async)
      final paymentUrl = await generatePaymentUrl(
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
  /// ⚠️ NOTE: For webhook verification, use generateValidationHash() instead
  Future<bool> verifyPaymentCallback(Map<String, dynamic> callbackData) async {
    try {
      // Extract validation hash from callback
      final receivedHash = callbackData['validation_hash'];
      final basketId = callbackData['basket_id'];
      final errorCode = callbackData['err_code'] ?? '000';

      if (receivedHash == null || basketId == null) {
        debugPrint('❌ Missing validation_hash or basket_id in callback');
        return false;
      }

      // Generate expected validation hash
      // Format: basket_id|secured_key|merchant_id|err_code
      final expectedHash = generateValidationHash(
        basketId: basketId,
        errorCode: errorCode,
      );

      // Compare hashes
      if (receivedHash != expectedHash) {
        debugPrint('❌ Validation hash mismatch');
        debugPrint('Received: $receivedHash');
        debugPrint('Expected: $expectedHash');
        return false;
      }

      // Verify payment status (if completed)
      final paymentStatus = callbackData['payment_status'];
      if (paymentStatus != null && paymentStatus != 'COMPLETE') {
        debugPrint('⚠️ Payment not complete: $paymentStatus');
        return false;
      }

      debugPrint('✅ Payment callback verified successfully');
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
    String paymentType = 'workshop', // ✅ NEW: Specify collection type
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      // ✅ Use correct collection based on payment type
      final collection = paymentType == 'booking'
          ? 'booking_payments'
          : 'workshop_payments';

      await _firestore.collection(collection).doc(paymentId).update(updateData);

      debugPrint('✅ Payment status updated in $collection: $status');
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
