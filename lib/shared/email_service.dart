import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Email Service - Helper functions to send emails via Firebase Cloud Functions
///
/// All emails are queued in Firestore and automatically processed by Cloud Functions
class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// ✅ Method 1: Queue Email (Recommended - Automatic)
  ///
  /// Adds email to email_queue collection, Cloud Function automatically sends it
  Future<String> queueEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final docRef = await _firestore.collection('email_queue').add({
        'to': to,
        'subject': subject,
        'htmlContent': htmlContent,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'retryCount': 0,
      });

      debugPrint('✅ Email queued successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error queuing email: $e');
      rethrow;
    }
  }

  /// ✅ Method 2: Send Test Email (Callable Function)
  ///
  /// Calls Cloud Function directly to send test email
  Future<Map<String, dynamic>> sendTestEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendTestEmail');
      final result = await callable.call({
        'to': to,
        'subject': subject,
        'message': message,
      });

      debugPrint('✅ Test email sent: ${result.data}');
      return result.data;
    } catch (e) {
      debugPrint('❌ Error sending test email: $e');
      rethrow;
    }
  }

  /// 📧 Send Workshop Registration Confirmation (Auto-triggered by Cloud Function)
  ///
  /// This is automatically sent when workshop_registrations document is created
  /// No need to call this manually - just create the registration
  // Future<void> sendWorkshopRegistrationEmail() {
  //   // This is handled by onWorkshopRegistration Cloud Function
  //   // No manual call needed
  // }

  /// 📧 Send Custom Email with Template
  ///
  /// Queue a custom email with HTML template
  Future<String> sendCustomEmail({
    required String to,
    required String subject,
    required String title,
    required String body,
    String? buttonText,
    String? buttonUrl,
  }) async {
    final htmlContent =
        '''
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
          .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #14B8A6 0%, #0D9488 100%); color: white; padding: 30px; text-align: center; }
          .header h1 { margin: 0; font-size: 28px; }
          .content { padding: 30px; }
          .button { display: inline-block; background-color: #14B8A6; color: white; padding: 15px 40px; text-decoration: none; border-radius: 5px; margin-top: 20px; font-weight: bold; }
          .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>$title</h1>
          </div>
          <div class="content">
            <p>$body</p>
            ${buttonText != null && buttonUrl != null ? '<p style="text-align: center;"><a href="$buttonUrl" class="button">$buttonText</a></p>' : ''}
          </div>
          <div class="footer">
            <p>Sehat Makaan - Your Health, Our Priority</p>
            <p>📧 support@sehatmakaan.com</p>
          </div>
        </div>
      </body>
      </html>
    ''';

    return queueEmail(to: to, subject: subject, htmlContent: htmlContent);
  }

  /// 📊 Get Email Status
  ///
  /// Check status of queued email
  Future<Map<String, dynamic>?> getEmailStatus(String emailId) async {
    try {
      final doc = await _firestore.collection('email_queue').doc(emailId).get();

      if (!doc.exists) {
        debugPrint('⚠️ Email not found: $emailId');
        return null;
      }

      final data = doc.data()!;
      return {
        'status': data['status'],
        'createdAt': data['createdAt'],
        'sentAt': data['sentAt'],
        'retryCount': data['retryCount'],
        'error': data['error'],
      };
    } catch (e) {
      debugPrint('❌ Error getting email status: $e');
      rethrow;
    }
  }

  /// 📋 Get User's Recent Emails
  ///
  /// Get list of emails sent to specific user
  Stream<List<Map<String, dynamic>>> getUserEmails(
    String userEmail, {
    int limit = 10,
  }) {
    return _firestore
        .collection('email_queue')
        .where('to', isEqualTo: userEmail)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'subject': data['subject'],
              'status': data['status'],
              'createdAt': data['createdAt'],
              'sentAt': data['sentAt'],
            };
          }).toList();
        });
  }

  /// 🔄 Retry Failed Emails (Admin Only)
  ///
  /// Call Cloud Function to retry all failed emails
  Future<Map<String, dynamic>> retryFailedEmails() async {
    try {
      final callable = _functions.httpsCallable('retryFailedEmails');
      final result = await callable.call();

      debugPrint('✅ Retry result: ${result.data}');
      return result.data;
    } catch (e) {
      debugPrint('❌ Error retrying failed emails: $e');
      rethrow;
    }
  }

  /// 💳 Generate PayFast Payment Link
  ///
  /// Generate payment link for workshop registration
  Future<String> generatePaymentLink({
    required String registrationId,
    required String workshopTitle,
    required double amount,
    required String userEmail,
    required String userName,
  }) async {
    try {
      final callable = _functions.httpsCallable('generatePayFastLink');
      final result = await callable.call({
        'registrationId': registrationId,
        'workshopTitle': workshopTitle,
        'amount': amount,
        'userEmail': userEmail,
        'userName': userName,
      });

      final paymentUrl = result.data['paymentUrl'] as String;
      debugPrint('✅ Payment link generated: $paymentUrl');
      return paymentUrl;
    } catch (e) {
      debugPrint('❌ Error generating payment link: $e');
      rethrow;
    }
  }
}

// ==========================================
// 📖 USAGE EXAMPLES
// ==========================================

/// Example 1: Send Test Email
void exampleSendTestEmail() async {
  final emailService = EmailService();

  try {
    final result = await emailService.sendTestEmail(
      to: 'doctor@example.com',
      subject: 'Welcome to Sehat Makaan',
      message: 'Thank you for joining us!',
    );

    debugPrint('Email ID: ${result['emailId']}');
  } catch (e) {
    debugPrint('Error: $e');
  }
}

/// Example 2: Send Custom Email
void exampleSendCustomEmail() async {
  final emailService = EmailService();

  try {
    final emailId = await emailService.sendCustomEmail(
      to: 'doctor@example.com',
      subject: 'New Workshop Available',
      title: '🎓 New Workshop Alert',
      body:
          'A new workshop on Mental Health is now available for registration. Join us to learn more!',
      buttonText: 'Register Now',
      buttonUrl: 'https://sehatmakaan.com/workshops/123',
    );

    debugPrint('Email queued: $emailId');
  } catch (e) {
    debugPrint('Error: $e');
  }
}

/// Example 3: Check Email Status
void exampleCheckEmailStatus(String emailId) async {
  final emailService = EmailService();

  try {
    final status = await emailService.getEmailStatus(emailId);

    if (status != null) {
      debugPrint('Status: ${status['status']}');
      debugPrint('Retry Count: ${status['retryCount']}');
      if (status['error'] != null) {
        debugPrint('Error: ${status['error']}');
      }
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}

/// Example 4: Listen to User's Emails
void exampleListenToUserEmails(String userEmail) {
  final emailService = EmailService();

  emailService.getUserEmails(userEmail, limit: 5).listen((emails) {
    debugPrint('Found ${emails.length} emails:');
    for (var email in emails) {
      debugPrint('- ${email['subject']}: ${email['status']}');
    }
  });
}

/// Example 5: Generate Payment Link
void exampleGeneratePaymentLink() async {
  final emailService = EmailService();

  try {
    final paymentUrl = await emailService.generatePaymentLink(
      registrationId: 'reg_12345',
      workshopTitle: 'Mental Health Workshop',
      amount: 250.00,
      userEmail: 'doctor@example.com',
      userName: 'Dr. John Smith',
    );

    debugPrint('Payment URL: $paymentUrl');
  } catch (e) {
    debugPrint('Error: $e');
  }
}

/// Example 6: Retry Failed Emails (Admin Only)
void exampleRetryFailedEmails() async {
  final emailService = EmailService();

  try {
    final result = await emailService.retryFailedEmails();

    debugPrint('Total: ${result['total']}');
    debugPrint('Successful: ${result['successful']}');
    debugPrint('Failed: ${result['failed']}');
  } catch (e) {
    debugPrint('Error: $e');
  }
}

// ==========================================
// 🚀 AUTOMATIC EMAIL TRIGGERS
// ==========================================

/// These emails are sent automatically by Cloud Functions
/// No manual intervention needed - just create the documents

/// ✅ Workshop Registration Email
/// Triggered when: workshop_registrations/{id} is created
/// Automatically sent to user

/// ✅ Workshop Confirmation Email
/// Triggered when: workshop_registrations/{id} status → 'confirmed'
/// Sends payment link to user

/// ✅ Workshop Rejection Email
/// Triggered when: workshop_registrations/{id} status → 'rejected'
/// Sends rejection notice to user

/// ✅ User Approval Email
/// Triggered when: users/{id} status → 'approved'
/// Sends welcome email with credentials

/// ✅ User Rejection Email
/// Triggered when: users/{id} status → 'rejected'
/// Sends rejection notice

/// ✅ Booking Confirmation Email
/// Triggered when: bookings/{id} is created
/// Sends booking details with QR code

/// ✅ High Priority Notification Email
/// Triggered when: notifications/{id} is created with priority='high'
/// Sends urgent notification email

/// ✅ Payment Confirmation Email
/// Triggered when: PayFast webhook confirms payment
/// Sends payment receipt
