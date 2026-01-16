import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../helpers/email_helper.dart';
import '../helpers/notification_helper.dart';
import '../../../features/workshops/screens/admin/helpers/workshop_payment_helper.dart';

/// Service class for all Firebase mutation operations in admin dashboard
class AdminMutationsService {
  final FirebaseFirestore _firestore;
  final VoidCallback onLoadingStart;
  final VoidCallback onLoadingEnd;
  final Function(String) showSuccess;
  final Function(String) showError;

  AdminMutationsService({
    required FirebaseFirestore firestore,
    required this.onLoadingStart,
    required this.onLoadingEnd,
    required this.showSuccess,
    required this.showError,
  }) : _firestore = firestore;

  // ============================================================================
  // DOCTOR MUTATIONS
  // ============================================================================

  Future<void> approveDoctor(Map<String, dynamic> doctor) async {
    try {
      onLoadingStart();

      await _firestore.collection('users').doc(doctor['id']).update({
        'status': 'approved',
        'isActive': true,
        'isVerified': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: doctor['id'] ?? '',
        type: 'registration_approved',
        title: 'Registration Approved',
        message: 'Your registration has been approved! You can now login.',
      );

      showSuccess('${doctor['fullName']} approved! Email notification sent.');
    } catch (e) {
      showError('Failed to approve doctor: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> rejectDoctor(Map<String, dynamic> doctor, String reason) async {
    try {
      onLoadingStart();

      await _firestore.collection('users').doc(doctor['id']).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: doctor['id'] ?? '',
        type: 'registration_rejected',
        title: 'Registration Update',
        message: 'Your registration has been reviewed. Reason: $reason',
      );

      showSuccess('Doctor rejected with reason: $reason');
    } catch (e) {
      showError('Failed to reject doctor: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> suspendDoctor(Map<String, dynamic> doctor) async {
    try {
      onLoadingStart();

      await _firestore.collection('users').doc(doctor['id']).update({
        'status': 'suspended',
        'isActive': false,
        'suspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email notification
      final emailHtml =
          '''
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .warning-box { background: #fff3cd; border-left: 4px solid #ff9800; padding: 15px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>⚠️ Account Suspended</h1>
            </div>
            <div class="content">
              <p>Dear ${doctor['fullName']},</p>
              
              <div class="warning-box">
                <h3 style="margin-top: 0; color: #ff9800;">Terms and Conditions Violation</h3>
                <p>Your account has been temporarily suspended due to violation of our Terms and Conditions.</p>
              </div>
              
              <p><strong>What this means:</strong></p>
              <ul>
                <li>Your account access has been suspended</li>
                <li>All activities and features are paused</li>
                <li>You cannot login until the suspension is removed</li>
                <li>Active bookings and subscriptions are on hold</li>
              </ul>
              
              <p><strong>Next Steps:</strong></p>
              <p>Please contact our admin team for more details about the suspension and steps to resolve this issue.</p>
              
              <p>Email: admin@sehatmakaan.com<br>
              Phone: +92 XXX XXXXXXX</p>
              
              <p>Best regards,<br>
              <strong>Sehat Makaan Team</strong></p>
            </div>
            <div class="footer">
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
        </html>
      ''';

      await EmailQueueHelper.queueEmail(
        firestore: _firestore,
        to: doctor['email'] ?? '',
        subject: '⚠️ Account Suspended - Sehat Makaan',
        htmlContent: emailHtml,
        userId: doctor['id'],
        data: {
          'type': 'account_suspended',
          'userId': doctor['id'],
          'suspendedAt': DateTime.now().toIso8601String(),
        },
      );

      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: doctor['id'] ?? '',
        type: 'account_suspended',
        title: 'Account Suspended',
        message:
            'Your account has been temporarily suspended. Contact admin for details.',
      );

      showSuccess('${doctor['fullName']} has been suspended.');
    } catch (e) {
      showError('Failed to suspend doctor: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> unsuspendDoctor(Map<String, dynamic> doctor) async {
    try {
      onLoadingStart();

      await _firestore.collection('users').doc(doctor['id']).update({
        'status': 'approved',
        'isActive': true,
        'suspendedAt': FieldValue.delete(),
        'unsuspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email notification
      final emailHtml =
          '''
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .success-box { background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>✅ Account Reactivated</h1>
            </div>
            <div class="content">
              <p>Dear ${doctor['fullName']},</p>
              
              <div class="success-box">
                <h3 style="margin-top: 0; color: #28a745;">Good News!</h3>
                <p>Your account suspension has been removed and your account is now active.</p>
              </div>
              
              <p><strong>What's restored:</strong></p>
              <ul>
                <li>Full account access</li>
                <li>All features and activities enabled</li>
                <li>Login privileges restored</li>
                <li>Active bookings and subscriptions resumed</li>
              </ul>
              
              <p>You can now login to your account and continue using all Sehat Makaan services.</p>
              
              <p>Please ensure you follow our Terms and Conditions to avoid future suspensions.</p>
              
              <p>Best regards,<br>
              <strong>Sehat Makaan Team</strong></p>
            </div>
            <div class="footer">
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
        </html>
      ''';

      await EmailQueueHelper.queueEmail(
        firestore: _firestore,
        to: doctor['email'] ?? '',
        subject: '✅ Account Reactivated - Sehat Makaan',
        htmlContent: emailHtml,
        userId: doctor['id'],
        data: {
          'type': 'account_reactivated',
          'userId': doctor['id'],
          'reactivatedAt': DateTime.now().toIso8601String(),
        },
      );

      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: doctor['id'] ?? '',
        type: 'account_reactivated',
        title: 'Account Reactivated',
        message: 'Your account has been reactivated. You can now login.',
      );

      showSuccess('${doctor['fullName']} has been unsuspended.');
    } catch (e) {
      showError('Failed to unsuspend doctor: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> deleteDoctor(Map<String, dynamic> doctor) async {
    try {
      onLoadingStart();

      final doctorId = doctor['id'] as String;
      final batch = _firestore.batch();

      // Send final email notification before deletion
      final emailHtml =
          '''
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #f85032 0%, #e73827 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .danger-box { background: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>⛔ Account Permanently Deleted</h1>
            </div>
            <div class="content">
              <p>Dear ${doctor['fullName']},</p>
              
              <div class="danger-box">
                <h3 style="margin-top: 0; color: #dc3545;">Account Termination Notice</h3>
                <p>Your account has been permanently deleted from Sehat Makaan due to serious violation of our Terms and Conditions.</p>
              </div>
              
              <p><strong>What this means:</strong></p>
              <ul>
                <li>Your account has been completely removed from our system</li>
                <li>All your data has been permanently deleted</li>
                <li>You can no longer access any Sehat Makaan services</li>
                <li>All active bookings and subscriptions are cancelled</li>
                <li>This action is permanent and cannot be reversed</li>
              </ul>
              
              <p><strong>If you believe this is an error:</strong></p>
              <p>Please contact our admin team immediately at:<br>
              Email: admin@sehatmakaan.com<br>
              Phone: +92 XXX XXXXXXX</p>
              
              <p>This is a final notice. After account deletion, you will not receive any further communications from Sehat Makaan.</p>
              
              <p>Best regards,<br>
              <strong>Sehat Makaan Team</strong></p>
            </div>
            <div class="footer">
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
        </html>
      ''';

      await EmailQueueHelper.queueEmail(
        firestore: _firestore,
        to: doctor['email'] ?? '',
        subject: '⛔ Account Permanently Deleted - Sehat Makaan',
        htmlContent: emailHtml,
        userId: doctorId,
        data: {
          'type': 'account_deleted',
          'userId': doctorId,
          'deletedAt': DateTime.now().toIso8601String(),
        },
      );

      // Delete user document
      batch.delete(_firestore.collection('users').doc(doctorId));

      // Delete all user's bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: doctorId)
          .get();
      for (var doc in bookingsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all user's subscriptions
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: doctorId)
          .get();
      for (var doc in subscriptionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all user's notifications
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: doctorId)
          .get();
      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit all deletions
      await batch.commit();

      showSuccess(
        '${doctor['fullName']} has been permanently deleted. All data removed.',
      );
    } catch (e) {
      showError('Failed to delete doctor: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  // ============================================================================
  // BOOKING MUTATIONS
  // ============================================================================

  Future<void> cancelBookingWithRefund(Map<String, dynamic> booking) async {
    try {
      onLoadingStart();

      // Get booking subscription to refund hours
      final bookingId = booking['id'];
      final userId = booking['userId'];
      final durationHours = booking['durationHours'] as int? ?? 1;

      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'admin_cancellation',
        'refundIssued': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // RESTORE HOURS: Find user's active subscription and add hours back
      if (userId != null && durationHours > 0) {
        final subscriptionsQuery = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (subscriptionsQuery.docs.isNotEmpty) {
          final subDoc = subscriptionsQuery.docs.first;
          final currentRemaining = subDoc.data()['remainingHours'] as int? ?? 0;

          await subDoc.reference.update({
            'remainingHours': currentRemaining + durationHours,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint(
            '✅ Refunded $durationHours hours to subscription ${subDoc.id}',
          );
        } else {
          debugPrint('⚠️ No active subscription found for user $userId');
        }
      }

      // Cloud function will handle notification creation

      showSuccess('Booking cancelled with $durationHours hour(s) refunded');
    } catch (e) {
      showError('Failed to cancel booking: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> cancelBooking(Map<String, dynamic> booking) async {
    try {
      onLoadingStart();

      await _firestore.collection('bookings').doc(booking['id']).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'admin_cancellation',
        'refundIssued': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cloud function will handle notification creation

      showSuccess('Booking cancelled without refund');
    } catch (e) {
      showError('Failed to cancel booking: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  // ============================================================================
  // WORKSHOP MUTATIONS
  // ============================================================================

  Future<void> createWorkshop(Map<String, dynamic> data) async {
    try {
      onLoadingStart();

      await _firestore.collection('workshops').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'currentParticipants': 0,
        'isActive': true,
      });

      showSuccess('Workshop created successfully');
    } catch (e) {
      showError('Failed to create workshop: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> updateWorkshop(
    String workshopId,
    Map<String, dynamic> data,
  ) async {
    try {
      onLoadingStart();

      await _firestore.collection('workshops').doc(workshopId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      showSuccess('Workshop updated successfully');
    } catch (e) {
      showError('Failed to update workshop: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> deleteWorkshop(Map<String, dynamic> workshop) async {
    try {
      onLoadingStart();

      await _firestore.collection('workshops').doc(workshop['id']).delete();

      showSuccess('${workshop['title']} has been deleted');
    } catch (e) {
      showError('Failed to delete workshop: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> confirmRegistration(Map<String, dynamic> registration) async {
    try {
      onLoadingStart();

      final workshopDoc = await _firestore
          .collection('workshops')
          .doc(registration['workshopId'])
          .get();

      if (!workshopDoc.exists) {
        throw Exception('Workshop not found');
      }

      final workshop = workshopDoc.data()!;

      await _firestore
          .collection('workshop_registrations')
          .doc(registration['id'])
          .update({
            'status': 'confirmed',
            'confirmedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      final paymentLink = WorkshopPaymentHelper.generatePaymentLink(
        registrationId: registration['id'],
        registrationNumber: registration['registrationNumber'] ?? 'N/A',
        amount: (workshop['price'] as num?)?.toDouble() ?? 0.0,
      );

      final emailHtml =
          WorkshopPaymentHelper.generateWorkshopConfirmationEmailHtml(
            name: registration['name'] ?? 'Participant',
            workshopTitle: workshop['title'] ?? 'Workshop',
            registrationNumber: registration['registrationNumber'] ?? 'N/A',
            amount: (workshop['price'] as num?)?.toDouble() ?? 0.0,
            paymentLink: paymentLink,
            workshopSchedule: workshop['schedule'] ?? 'TBD',
          );

      await EmailQueueHelper.queueEmail(
        firestore: _firestore,
        to: registration['email'] ?? '',
        subject: 'Workshop Registration Confirmed - ${workshop['title']}',
        htmlContent: emailHtml,
        userId: registration['userId'],
        data: {
          'type': 'workshop_confirmation',
          'registrationId': registration['id'],
          'workshopId': registration['workshopId'],
          'paymentLink': paymentLink,
        },
      );

      if (registration['userId'] != null) {
        await NotificationHelper.createNotification(
          firestore: _firestore,
          userId: registration['userId'],
          type: 'workshop_confirmed',
          title: 'Workshop Registration Confirmed',
          message:
              'Your registration for ${workshop['title']} is confirmed. Check email for payment details.',
        );
      }

      showSuccess('Registration confirmed! Payment email queued.');
    } catch (e) {
      showError('Failed to confirm registration: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> rejectRegistration(Map<String, dynamic> registration) async {
    try {
      onLoadingStart();

      await _firestore
          .collection('workshop_registrations')
          .doc(registration['id'])
          .update({
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (registration['userId'] != null) {
        await NotificationHelper.createNotification(
          firestore: _firestore,
          userId: registration['userId'],
          type: 'workshop_rejected',
          title: 'Workshop Registration Rejected',
          message:
              'Your workshop registration could not be approved at this time.',
        );
      }

      showSuccess('Registration rejected');
    } catch (e) {
      showError('Failed to reject registration: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> deleteRegistration(Map<String, dynamic> registration) async {
    try {
      onLoadingStart();

      final batch = _firestore.batch();

      batch.delete(
        _firestore.collection('workshop_registrations').doc(registration['id']),
      );

      if (registration['status'] == 'confirmed') {
        batch.update(
          _firestore.collection('workshops').doc(registration['workshopId']),
          {'currentParticipants': FieldValue.increment(-1)},
        );
      }

      await batch.commit();

      showSuccess('Registration deleted');
    } catch (e) {
      showError('Failed to delete registration: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }
}
