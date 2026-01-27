import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/email_helper.dart';
import '../helpers/notification_helper.dart';
import 'package:sehat_makaan_flutter/features/admin/helpers/workshop_payment_helper.dart';

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
  // AUDIT LOGGING
  // ============================================================================

  /// Centralized admin action logging for audit trail
  Future<void> _logAdminAction(
    String adminId,
    String actionType,
    String targetId,
    Map<String, dynamic> details,
  ) async {
    try {
      await _firestore.collection('admin_audit_log').add({
        'adminId': adminId,
        'action': actionType,
        'targetId': targetId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Admin action logged: $actionType on $targetId');
    } catch (e) {
      debugPrint('❌ Failed to log admin action: $e');
      // Don't throw - logging should not break the main operation
    }
  }

  // ============================================================================
  // DOCTOR MUTATIONS
  // ============================================================================

  Future<void> approveDoctor(
    Map<String, dynamic> doctor, [
    String? adminId,
  ]) async {
    try {
      onLoadingStart();

      final doctorId = doctor['id'] as String;
      await _firestore.collection('users').doc(doctorId).update({
        'status': 'approved',
        'isActive': true,
        'isVerified': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: doctorId,
        type: 'registration_approved',
        title: 'Registration Approved',
        message: 'Your registration has been approved! You can now login.',
      );

      // Log admin action
      if (adminId != null) {
        await _logAdminAction(adminId, 'doctor_approved', doctorId, {
          'doctorName': doctor['fullName'],
          'email': doctor['email'],
        });
      }

      showSuccess('${doctor['fullName']} approved! Email notification sent.');
    } catch (e) {
      showError('Failed to approve doctor: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> rejectDoctor(
    Map<String, dynamic> doctor,
    String reason, [
    String? adminId,
  ]) async {
    try {
      onLoadingStart();

      final doctorId = doctor['id'] as String;

      // ✅ Debug: Log the reason being sent
      debugPrint('🔴 REJECTING DOCTOR: $doctorId');
      debugPrint('📝 REASON: $reason');
      debugPrint('✉️ EMAIL: ${doctor['email']}');

      await _firestore.collection('users').doc(doctorId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: doctorId,
        type: 'registration_rejected',
        title: 'Registration Update',
        message: 'Your registration has been reviewed. Reason: $reason',
      );

      // Log admin action
      if (adminId != null) {
        await _logAdminAction(adminId, 'doctor_rejected', doctorId, {
          'doctorName': doctor['fullName'],
          'email': doctor['email'],
          'reason': reason,
        });
      }

      showSuccess('Doctor rejected with reason: $reason');
    } catch (e) {
      showError('Failed to reject doctor: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  Future<void> suspendDoctor(
    Map<String, dynamic> doctor, [
    String? adminId,
  ]) async {
    try {
      onLoadingStart();

      final doctorId = doctor['id'] as String;

      // ✅ Step 1: Update status to suspended
      await _firestore.collection('users').doc(doctorId).update({
        'status': 'suspended',
        'isActive': false,
        'suspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Step 2: Pause all active workshops/features
      debugPrint('⏸️ PAUSING ALL WORKSHOPS FOR DOCTOR: $doctorId');
      final workshopsQuery = await _firestore
          .collection('workshops')
          .where('createdBy', isEqualTo: doctorId)
          .where('status', isNotEqualTo: 'archived')
          .get();

      for (var doc in workshopsQuery.docs) {
        await _firestore.collection('workshops').doc(doc.id).update({
          'status': 'paused',
          'pausedAt': FieldValue.serverTimestamp(),
          'pauseReason': 'Account suspended - Doctor features paused',
        });
        debugPrint('✅ Workshop paused: ${doc.id}');
      }

      // ✅ Step 3: Put all active bookings on hold
      debugPrint('⏸️ PUTTING BOOKINGS ON HOLD FOR DOCTOR: $doctorId');
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      for (var doc in bookingsQuery.docs) {
        // ✅ IMPORTANT: Save original status before putting on hold
        final originalStatus = doc['status'] as String?;
        await _firestore.collection('bookings').doc(doc.id).update({
          'status': 'on_hold',
          'holdReason': 'Doctor account suspended',
          'originalStatus': originalStatus, // ✅ Save for restoration
          'holdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Booking on hold (original: $originalStatus): ${doc.id}');
      }

      // ✅ Step 3A: Pause all active monthly subscriptions
      debugPrint('⏸️ PAUSING MONTHLY SUBSCRIPTIONS FOR DOCTOR: $doctorId');
      final subscriptionsQuery = await _firestore
          .collection('subscriptions')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in subscriptionsQuery.docs) {
        final originalStatus = doc['status'] as String?;
        await _firestore.collection('subscriptions').doc(doc.id).update({
          'status': 'paused',
          'pauseReason': 'Doctor account suspended',
          'originalStatus': originalStatus,
          'pausedAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
          '✅ Subscription paused (original: $originalStatus): ${doc.id}',
        );
      }

      // ✅ Step 3B: Handle future hourly bookings (upcoming slots)
      debugPrint('⏸️ HANDLING FUTURE HOURLY BOOKINGS FOR DOCTOR: $doctorId');
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final futureBookingsQuery = await _firestore
          .collection('bookings')
          .where('doctorId', isEqualTo: doctorId)
          .where('bookingDate', isGreaterThanOrEqualTo: todayStr)
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var doc in futureBookingsQuery.docs) {
        final originalStatus = doc['status'] as String?;
        await _firestore.collection('bookings').doc(doc.id).update({
          'status': 'on_hold',
          'holdReason': 'Doctor suspended - Future booking',
          'originalStatus': originalStatus,
          'holdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Future hourly booking on hold: ${doc.id}');
      }

      // ✅ Step 3C: Handle workshop registrations with payments
      debugPrint('⏸️ HANDLING WORKSHOP REGISTRATIONS FOR DOCTOR: $doctorId');
      final doctorWorkshops = workshopsQuery.docs.map((d) => d.id).toList();

      int workshopRegistrationsCount = 0;
      if (doctorWorkshops.isNotEmpty) {
        final registrationsQuery = await _firestore
            .collection('workshop_registrations')
            .where('workshopId', whereIn: doctorWorkshops)
            .where('paymentStatus', isEqualTo: 'paid')
            .where('status', whereIn: ['confirmed', 'pending'])
            .get();

        workshopRegistrationsCount = registrationsQuery.docs.length;

        for (var doc in registrationsQuery.docs) {
          final originalStatus = doc['status'] as String?;
          await _firestore
              .collection('workshop_registrations')
              .doc(doc.id)
              .update({
                'status': 'on_hold',
                'holdReason': 'Workshop creator account suspended',
                'originalStatus': originalStatus,
                'holdAt': FieldValue.serverTimestamp(),
                'refundEligible': true, // Mark for potential refund
              });
          debugPrint('✅ Workshop registration on hold: ${doc.id}');
        }
      }

      // ✅ Step 4: Check if suspended doctor is currently logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == doctorId) {
        // ✅ Step 5: Auto-logout if current user is the suspended doctor
        debugPrint('🚪 AUTO-LOGOUT: Suspended doctor is currently logged in');
        await _performAutoLogout();
      }

      // Log admin action
      if (adminId != null) {
        await _logAdminAction(adminId, 'doctor_suspended', doctorId, {
          'doctorName': doctor['fullName'],
          'email': doctor['email'],
          'workshopsPaused': workshopsQuery.docs.length,
          'bookingsOnHold': bookingsQuery.docs.length,
          'subscriptionsPaused': subscriptionsQuery.docs.length,
          'futureBookingsOnHold': futureBookingsQuery.docs.length,
          'workshopRegistrationsOnHold': workshopRegistrationsCount,
        });
      }

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
                <li>✅ Your account access has been suspended</li>
                <li>⏸️ All your workshops and features are paused</li>
                <li>🚫 You cannot login until the suspension is removed</li>
                <li>⏸️ Active bookings are on hold</li>
                <li>⏸️ Monthly subscriptions are paused</li>
                <li>⏸️ Future hourly bookings are on hold</li>
                <li>⏸️ Workshop registrations with payments are on hold</li>
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
            'Your account has been temporarily suspended. All features and bookings are paused.',
      );

      showSuccess(
        '${doctor['fullName']} has been suspended. All features and bookings paused.',
      );
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

      final doctorId = doctor['id'] as String;

      // ✅ Step 1: Update status to approved
      await _firestore.collection('users').doc(doctorId).update({
        'status': 'approved',
        'isActive': true,
        'suspendedAt': FieldValue.delete(),
        'unsuspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Step 2: Resume all paused workshops
      debugPrint('▶️ RESUMING ALL WORKSHOPS FOR DOCTOR: $doctorId');
      final workshopsQuery = await _firestore
          .collection('workshops')
          .where('createdBy', isEqualTo: doctorId)
          .where('status', isEqualTo: 'paused')
          .get();

      for (var doc in workshopsQuery.docs) {
        // Resume to previous active status
        await _firestore.collection('workshops').doc(doc.id).update({
          'status': 'active',
          'pausedAt': FieldValue.delete(),
          'pauseReason': FieldValue.delete(),
          'resumedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Workshop resumed: ${doc.id}');
      }

      // ✅ Step 3: Resume all bookings from hold
      debugPrint('▶️ RESUMING BOOKINGS FOR DOCTOR: $doctorId');
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'on_hold')
          .get();

      for (var doc in bookingsQuery.docs) {
        // ✅ IMPORTANT: Restore original status from when it was put on hold
        final originalStatus = doc['originalStatus'] as String? ?? 'confirmed';
        await _firestore.collection('bookings').doc(doc.id).update({
          'status': originalStatus, // ✅ Restore to original status
          'holdReason': FieldValue.delete(),
          'originalStatus': FieldValue.delete(), // ✅ Clean up
          'holdAt': FieldValue.delete(),
          'resumedAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
          '✅ Booking resumed (restored to: $originalStatus): ${doc.id}',
        );
      }

      // ✅ Step 3A: Resume monthly subscriptions
      debugPrint('▶️ RESUMING MONTHLY SUBSCRIPTIONS FOR DOCTOR: $doctorId');
      final subscriptionsQuery = await _firestore
          .collection('subscriptions')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'paused')
          .get();

      for (var doc in subscriptionsQuery.docs) {
        final originalStatus = doc['originalStatus'] as String? ?? 'active';
        await _firestore.collection('subscriptions').doc(doc.id).update({
          'status': originalStatus,
          'pauseReason': FieldValue.delete(),
          'originalStatus': FieldValue.delete(),
          'pausedAt': FieldValue.delete(),
          'resumedAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
          '✅ Subscription resumed (restored to: $originalStatus): ${doc.id}',
        );
      }

      // ✅ Step 3B: Resume future hourly bookings
      debugPrint('▶️ RESUMING FUTURE HOURLY BOOKINGS FOR DOCTOR: $doctorId');
      // Query for all on-hold bookings (includes future bookings)
      final futureBookingsQuery = await _firestore
          .collection('bookings')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'on_hold')
          .get();

      for (var doc in futureBookingsQuery.docs) {
        final originalStatus = doc['originalStatus'] as String? ?? 'confirmed';
        await _firestore.collection('bookings').doc(doc.id).update({
          'status': originalStatus,
          'holdReason': FieldValue.delete(),
          'originalStatus': FieldValue.delete(),
          'holdAt': FieldValue.serverTimestamp(),
          'resumedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Future hourly booking resumed: ${doc.id}');
      }

      // ✅ Step 3C: Resume workshop registrations
      debugPrint('▶️ RESUMING WORKSHOP REGISTRATIONS FOR DOCTOR: $doctorId');
      final doctorWorkshops = workshopsQuery.docs.map((d) => d.id).toList();

      if (doctorWorkshops.isNotEmpty) {
        final registrationsQuery = await _firestore
            .collection('workshop_registrations')
            .where('workshopId', whereIn: doctorWorkshops)
            .where('status', isEqualTo: 'on_hold')
            .get();

        for (var doc in registrationsQuery.docs) {
          final originalStatus =
              doc['originalStatus'] as String? ?? 'confirmed';
          await _firestore
              .collection('workshop_registrations')
              .doc(doc.id)
              .update({
                'status': originalStatus,
                'holdReason': FieldValue.delete(),
                'originalStatus': FieldValue.delete(),
                'holdAt': FieldValue.delete(),
                'refundEligible': FieldValue.delete(),
                'resumedAt': FieldValue.serverTimestamp(),
              });
          debugPrint('✅ Workshop registration resumed: ${doc.id}');
        }
      }

      // Send email notification
      final emailHtml =
          '''
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #28a745 0%, #20c997 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .success-box { background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>✅ Account Restored</h1>
            </div>
            <div class="content">
              <p>Dear ${doctor['fullName']},</p>
              
              <div class="success-box">
                <h3 style="margin-top: 0; color: #28a745;">Suspension Removed</h3>
                <p>Your account suspension has been removed. Your account is now fully restored.</p>
              </div>
              
              <p><strong>Your account status:</strong></p>
              <ul>
                <li>✅ Full account access restored</li>
                <li>▶️ All workshops and features are now active</li>
                <li>✅ You can login normally</li>
                <li>▶️ All bookings have been resumed</li>
                <li>▶️ Monthly subscriptions are active again</li>
                <li>▶️ Future hourly bookings are confirmed</li>
                <li>▶️ Workshop registrations are restored</li>
              </ul>
              
              <p>You can now login and continue your activities on Sehat Makaan.</p>
              
              <p>Best regards,<br>
              <strong>Sehat Makaan Team</strong></p>
            </div>
            <div class="footer">
              <p>Sehat Makaan - Your Health, Our Priority</p>
            </div>
          </div>
        </body>
        </html>
      ''';

      await EmailQueueHelper.queueEmail(
        firestore: _firestore,
        to: doctor['email'] ?? '',
        subject: '✅ Account Restored - Sehat Makaan',
        htmlContent: emailHtml,
        userId: doctor['id'],
        data: {
          'type': 'account_restored',
          'userId': doctor['id'],
          'unsuspendedAt': DateTime.now().toIso8601String(),
        },
      );

      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: doctor['id'] ?? '',
        type: 'account_restored',
        title: 'Account Restored',
        message:
            'Your account suspension has been removed. You can now login and use all features.',
      );

      showSuccess(
        '${doctor['fullName']} has been unsuspended. All features and bookings restored.',
      );
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

  /// PHASE 2: Set workshop fee and approve (Unified function)
  /// Admin reviews doctor's proposal and sets the platform fee in one operation
  Future<void> setWorkshopFeeAndApprove({
    required String workshopId,
    required double feeAmount,
    required String adminId,
  }) async {
    try {
      onLoadingStart();

      await _firestore.collection('workshops').doc(workshopId).update({
        'permissionStatus': 'approved_by_admin',
        'adminSetFee': feeAmount,
        'permissionGrantedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log admin action
      await _logAdminAction(adminId, 'approve_workshop_with_fee', workshopId, {
        'feeAmount': feeAmount,
      });

      // Get workshop details for notification
      final workshopDoc = await _firestore
          .collection('workshops')
          .doc(workshopId)
          .get();

      if (workshopDoc.exists) {
        final workshopData = workshopDoc.data()!;
        final creatorId = workshopData['createdBy'] as String?;

        if (creatorId != null) {
          await NotificationHelper.createNotification(
            firestore: _firestore,
            userId: creatorId,
            type: 'workshop_approved',
            title: 'Workshop Proposal Approved! ⏰',
            message:
                'Your workshop "${workshopData['title']}" has been approved. '
                'Platform fee: PKR ${feeAmount.toStringAsFixed(0)}. '
                'You have 48 hours to complete payment and go live!',
          );
        }
      }

      showSuccess(
        'Workshop approved! Fee set: PKR ${feeAmount.toStringAsFixed(0)}. '
        'Creator has 48 hours to pay.',
      );
    } catch (e) {
      showError('Failed to approve workshop: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  /// PHASE 2: Grant workshop permission and set admin fee (Legacy - kept for backward compatibility)
  /// Admin reviews doctor's proposal and sets the platform fee
  Future<void> grantWorkshopPermission({
    required String workshopId,
    required double adminSetFee,
  }) async {
    try {
      onLoadingStart();

      await _firestore.collection('workshops').doc(workshopId).update({
        'permissionStatus':
            'approved', // Changed to 'approved' to trigger email function
        'adminSetFee': adminSetFee,
        'approvalTime':
            FieldValue.serverTimestamp(), // For email deadline calculation
        'permissionGrantedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get workshop details for notification
      final workshopDoc = await _firestore
          .collection('workshops')
          .doc(workshopId)
          .get();

      if (workshopDoc.exists) {
        final workshopData = workshopDoc.data()!;
        final creatorId = workshopData['createdBy'] as String?;

        if (creatorId != null) {
          await NotificationHelper.createNotification(
            firestore: _firestore,
            userId: creatorId,
            type: 'workshop_approved',
            title: 'Workshop Proposal Approved! ⏰',
            message:
                'Your workshop "${workshopData['title']}" has been approved. '
                'Platform fee: PKR ${adminSetFee.toStringAsFixed(0)}. '
                'You have 2 hours to complete payment and go live!',
          );
        }
      }

      showSuccess(
        'Workshop approved! Fee set: PKR ${adminSetFee.toStringAsFixed(0)}. '
        'Doctor has 2 hours to pay. Email notification sent!',
      );
    } catch (e) {
      showError('Failed to grant permission: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  /// Reject workshop proposal
  Future<void> rejectWorkshopProposal({
    required String workshopId,
    required String reason,
  }) async {
    try {
      onLoadingStart();

      await _firestore.collection('workshops').doc(workshopId).update({
        'permissionStatus': 'rejected',
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final workshopDoc = await _firestore
          .collection('workshops')
          .doc(workshopId)
          .get();

      if (workshopDoc.exists) {
        final workshopData = workshopDoc.data()!;
        final creatorId = workshopData['createdBy'] as String?;

        if (creatorId != null) {
          await NotificationHelper.createNotification(
            firestore: _firestore,
            userId: creatorId,
            type: 'workshop_rejected',
            title: 'Workshop Proposal Update',
            message:
                'Your workshop "${workshopData['title']}" was not approved. Reason: $reason',
          );
        }
      }

      showSuccess('Workshop proposal rejected.');
    } catch (e) {
      showError('Failed to reject proposal: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

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

  // ============================================================================
  // PHASE 4: WORKSHOP PAYOUT SYSTEM
  // ============================================================================

  /// Release workshop payout with audit logging (Admin action)
  Future<void> releaseWorkshopPayout(
    Map<String, dynamic> workshop,
    String adminId,
  ) async {
    try {
      onLoadingStart();

      final workshopId = workshop['id'] as String;

      // 🛡️ SECURITY: Verify payout hasn't been released already (Idempotency)
      if (workshop['payoutStatus'] == 'released') {
        showError('Payout already released for this workshop');
        return;
      }

      // Verify payout is requested
      if (workshop['payoutStatus'] != 'requested') {
        showError('Workshop payout has not been requested yet');
        return;
      }

      // Get calculated amounts
      final totalRevenue = (workshop['totalRevenue'] ?? 0.0).toDouble();
      final adminCommission = (workshop['adminCommission'] ?? 0.0).toDouble();
      final doctorPayout = (workshop['doctorPayout'] ?? 0.0).toDouble();
      final createdBy = workshop['createdBy'] as String?;

      if (createdBy == null) {
        showError('Workshop creator not found');
        return;
      }

      // 🔒 Use Firestore Batch for atomic operation
      final batch = _firestore.batch();

      // 1. Update workshop status
      batch.update(_firestore.collection('workshops').doc(workshopId), {
        'payoutStatus': 'released',
        'payoutReleasedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Create payout audit log
      final payoutLogRef = _firestore.collection('payout_logs').doc();
      batch.set(payoutLogRef, {
        'workshopId': workshopId,
        'workshopTitle': workshop['title'] ?? 'Unknown Workshop',
        'doctorId': createdBy,
        'adminId': adminId,
        'totalRevenue': totalRevenue,
        'adminCommission': adminCommission,
        'doctorPayout': doctorPayout,
        'status': 'completed',
        'releasedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

      // 3. Send push notification to doctor
      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: createdBy,
        type: 'payout_released',
        title: '💰 Payout Released!',
        message:
            'Your payout of PKR ${doctorPayout.toStringAsFixed(0)} for "${workshop['title']}" has been released.',
      );

      debugPrint('✅ Payout released: $workshopId → PKR $doctorPayout');
      showSuccess(
        'Payout of PKR ${doctorPayout.toStringAsFixed(0)} released successfully!',
      );
    } catch (e) {
      showError('Failed to release payout: $e');
      debugPrint('❌ Release payout error: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  // ============================================================================
  // GOD MODE: SYSTEM SETTINGS
  // ============================================================================

  /// Update global system settings (God Mode Control)
  Future<void> updateSystemSettings({
    required String adminId,

    int? bookingNoticePeriod,
    int? minBookingDuration,
    int? maxBookingDuration,
  }) async {
    try {
      onLoadingStart();

      final updateData = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': adminId,
      };

      if (bookingNoticePeriod != null) {
        updateData['bookingNoticePeriod'] = bookingNoticePeriod;
      }
      if (minBookingDuration != null) {
        updateData['minBookingDuration'] = minBookingDuration;
      }
      if (maxBookingDuration != null) {
        updateData['maxBookingDuration'] = maxBookingDuration;
      }

      await _firestore
          .collection('app_settings')
          .doc('system_config')
          .set(updateData, SetOptions(merge: true));

      // Log system settings change
      await _firestore.collection('admin_audit_log').add({
        'adminId': adminId,
        'action': 'system_settings_updated',
        'changes': updateData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      showSuccess('System settings updated successfully!');
    } catch (e) {
      showError('Failed to update system settings: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  // ============================================================================
  // GOD MODE: MANUAL OVERRIDES
  // ============================================================================

  /// Force-release a suite (bypass normal booking rules)
  Future<void> forceReleaseSuite({
    required String adminId,
    required String bookingId,
    required String reason,
  }) async {
    try {
      onLoadingStart();

      final batch = _firestore.batch();

      // Cancel booking
      batch.update(_firestore.collection('bookings').doc(bookingId), {
        'status': 'force_cancelled',
        'cancelledBy': 'admin',
        'cancelReason': 'Admin Force Release: $reason',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log admin action
      batch.set(_firestore.collection('admin_audit_log').doc(), {
        'adminId': adminId,
        'action': 'force_release_suite',
        'bookingId': bookingId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      showSuccess('Suite force-released successfully!');
    } catch (e) {
      showError('Failed to force-release suite: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  /// Shadow payout - manually trigger workshop payout before end date
  Future<void> shadowPayoutWorkshop({
    required String adminId,
    required String workshopId,
    required String reason,
  }) async {
    try {
      onLoadingStart();

      // Get workshop data
      final workshopDoc = await _firestore
          .collection('workshops')
          .doc(workshopId)
          .get();
      if (!workshopDoc.exists) {
        showError('Workshop not found');
        return;
      }

      final workshop = workshopDoc.data()!;
      final createdBy = workshop['createdBy'] as String?;

      if (createdBy == null) {
        showError('Workshop creator not found');
        return;
      }

      // Get calculated amounts from existing workshop data
      final totalRevenue = (workshop['totalRevenue'] ?? 0.0).toDouble();
      final adminCommission = (workshop['adminCommission'] ?? 0.0).toDouble();
      final doctorPayout = (workshop['doctorPayout'] ?? 0.0).toDouble();

      final batch = _firestore.batch();

      // Update workshop payout status
      batch.update(_firestore.collection('workshops').doc(workshopId), {
        'payoutStatus': 'shadow_released',
        'shadowPayoutReason': reason,
        'payoutReleasedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create payout log
      batch.set(_firestore.collection('payout_logs').doc(), {
        'workshopId': workshopId,
        'workshopTitle': workshop['title'] ?? 'Unknown',
        'doctorId': createdBy,
        'adminId': adminId,
        'totalRevenue': totalRevenue,
        'adminCommission': adminCommission,
        'doctorPayout': doctorPayout,
        'status': 'shadow_payout',
        'reason': reason,
        'releasedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log admin action
      batch.set(_firestore.collection('admin_audit_log').doc(), {
        'adminId': adminId,
        'action': 'shadow_payout',
        'workshopId': workshopId,
        'amount': doctorPayout,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Notify doctor
      await NotificationHelper.createNotification(
        firestore: _firestore,
        userId: createdBy,
        type: 'shadow_payout',
        title: '💰 Early Payout Released!',
        message:
            'Admin released early payout of PKR ${doctorPayout.toStringAsFixed(0)} for "${workshop['title']}".',
      );

      showSuccess(
        'Shadow payout of PKR ${doctorPayout.toStringAsFixed(0)} released!',
      );
    } catch (e) {
      showError('Failed to process shadow payout: $e');
      rethrow;
    } finally {
      onLoadingEnd();
    }
  }

  // ✅ Auto-logout helper method
  Future<void> _performAutoLogout() async {
    try {
      debugPrint('🚪 PERFORMING AUTO-LOGOUT');

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ SharedPreferences cleared');

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      debugPrint('✅ Firebase signOut completed');

      showSuccess('Your account has been suspended. You have been logged out.');
    } catch (e) {
      debugPrint('❌ Error during auto-logout: $e');
    }
  }
}
