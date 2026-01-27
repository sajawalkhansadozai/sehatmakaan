import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workshop_model.dart';
import '../models/workshop_registration_model.dart';
import '../../admin/helpers/notification_helper.dart';

/// Workshop Service for Firebase Firestore
/// Handles workshop CRUD and registration operations
class WorkshopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create new workshop (Admin only)
  Future<Map<String, dynamic>> createWorkshop({
    required String title,
    required String description,
    required String provider,
    required String certificationType,
    required int duration,
    required double price,
    required int maxParticipants,
    required String location,
    required String schedule,
    String? instructor,
    String? prerequisites,
    String? materials,
    String? bannerImage,
    String? syllabusPdf,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final workshopRef = await _firestore.collection('workshops').add({
        'title': title,
        'description': description,
        'provider': provider,
        'certificationType': certificationType,
        'duration': duration,
        'price': price,
        'maxParticipants': maxParticipants,
        'currentParticipants': 0,
        'location': location,
        'schedule': schedule,
        'instructor': instructor,
        'prerequisites': prerequisites,
        'materials': materials,
        'bannerImage': bannerImage,
        'syllabusPdf': syllabusPdf,
        'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'startTime': startTime,
        'endTime': endTime,
        'isActive': false, // ❌ Not live until admin approves and creator pays
        'permissionStatus': 'pending_admin', // 🟡 Awaiting admin review
        'isCreationFeePaid': false, // 💰 Creator must pay after admin approval
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Workshop proposal created: ${workshopRef.id}');
      return {
        'success': true,
        'workshopId': workshopRef.id,
        'message': 'Workshop created successfully',
      };
    } catch (e) {
      debugPrint('❌ Create workshop error: $e');
      return {
        'success': false,
        'error': 'Failed to create workshop. Please try again.',
      };
    }
  }

  /// Get all active workshops
  Stream<List<WorkshopModel>> getActiveWorkshops() {
    return _firestore
        .collection('workshops')
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkshopModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all workshops (Admin)
  Stream<List<WorkshopModel>> getAllWorkshops() {
    return _firestore
        .collection('workshops')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkshopModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get workshop by ID
  Future<WorkshopModel?> getWorkshopById(String workshopId) async {
    try {
      final doc = await _firestore
          .collection('workshops')
          .doc(workshopId)
          .get();
      if (doc.exists) {
        return WorkshopModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get workshop error: $e');
      return null;
    }
  }

  /// Update workshop
  Future<Map<String, dynamic>> updateWorkshop({
    required String workshopId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('workshops').doc(workshopId).update(updates);

      debugPrint('✅ Workshop updated: $workshopId');
      return {'success': true, 'message': 'Workshop updated successfully'};
    } catch (e) {
      debugPrint('❌ Update workshop error: $e');
      return {'success': false, 'error': 'Failed to update workshop.'};
    }
  }

  /// Delete workshop
  Future<Map<String, dynamic>> deleteWorkshop(String workshopId) async {
    try {
      await _firestore.collection('workshops').doc(workshopId).delete();
      debugPrint('✅ Workshop deleted: $workshopId');
      return {'success': true, 'message': 'Workshop deleted successfully'};
    } catch (e) {
      debugPrint('❌ Delete workshop error: $e');
      return {'success': false, 'error': 'Failed to delete workshop.'};
    }
  }

  /// Deactivate workshop
  Future<Map<String, dynamic>> deactivateWorkshop(String workshopId) async {
    try {
      await _firestore.collection('workshops').doc(workshopId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Workshop deactivated: $workshopId');
      return {'success': true, 'message': 'Workshop deactivated'};
    } catch (e) {
      debugPrint('❌ Deactivate workshop error: $e');
      return {'success': false, 'error': 'Failed to deactivate workshop.'};
    }
  }

  /// Register for workshop
  Future<Map<String, dynamic>> registerForWorkshop({
    required String userId,
    required String workshopId,
    required String name,
    required String email,
    required String cnicNumber,
    required String phoneNumber,
    required String profession,
    required String address,
    String? notes,
  }) async {
    try {
      // Check if workshop is full
      final workshop = await getWorkshopById(workshopId);
      if (workshop == null) {
        return {'success': false, 'error': 'Workshop not found'};
      }

      if (workshop.currentParticipants >= workshop.maxParticipants) {
        return {'success': false, 'error': 'Workshop is full'};
      }

      // Check if already registered
      final existingReg = await _firestore
          .collection('workshop_registrations')
          .where('userId', isEqualTo: userId)
          .where('workshopId', isEqualTo: workshopId)
          .limit(1)
          .get();

      if (existingReg.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Already registered for this workshop',
        };
      }

      // Create registration with pending_creator status
      final registrationRef = await _firestore
          .collection('workshop_registrations')
          .add({
            'userId': userId,
            'workshopId': workshopId,
            'name': name,
            'email': email,
            'cnicNumber': cnicNumber,
            'phoneNumber': phoneNumber,
            'profession': profession,
            'address': address,
            'notes': notes,
            'registrationNumber': 'WS${DateTime.now().millisecondsSinceEpoch}',
            'status': 'pending',
            'approvalStatus': 'pending_creator', // Wait for creator approval
            'paymentStatus': 'pending',
            'paymentMethod': 'payfast',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // NOTE: currentParticipants will only increment after successful payment
      // This prevents seat blocking by unapproved/unpaid registrations

      debugPrint('✅ Workshop registration created: ${registrationRef.id}');
      return {
        'success': true,
        'registrationId': registrationRef.id,
        'message': 'Request sent! Please wait for instructor approval.',
      };
    } catch (e) {
      debugPrint('❌ Register workshop error: $e');
      return {
        'success': false,
        'error': 'Failed to register. Please try again.',
      };
    }
  }

  /// Get user's workshop registrations
  Stream<List<WorkshopRegistrationModel>> getUserRegistrations(String userId) {
    return _firestore
        .collection('workshop_registrations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkshopRegistrationModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all workshop registrations (Admin)
  Stream<List<WorkshopRegistrationModel>> getAllRegistrations() {
    return _firestore
        .collection('workshop_registrations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkshopRegistrationModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Confirm workshop registration (Admin)
  Future<Map<String, dynamic>> confirmRegistration(
    String registrationId,
  ) async {
    try {
      await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .update({
            'status': 'confirmed',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Registration confirmed: $registrationId');
      return {'success': true, 'message': 'Registration confirmed'};
    } catch (e) {
      debugPrint('❌ Confirm registration error: $e');
      return {'success': false, 'error': 'Failed to confirm registration.'};
    }
  }

  /// Reject workshop registration (Admin)
  Future<Map<String, dynamic>> rejectRegistration(
    String registrationId,
    String workshopId,
  ) async {
    try {
      await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .update({
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Decrement participant count
      await _firestore.collection('workshops').doc(workshopId).update({
        'currentParticipants': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Registration rejected: $registrationId');
      return {'success': true, 'message': 'Registration rejected'};
    } catch (e) {
      debugPrint('❌ Reject registration error: $e');
      return {'success': false, 'error': 'Failed to reject registration.'};
    }
  }

  /// Update registration payment status
  Future<Map<String, dynamic>> updateRegistrationPayment({
    required String registrationId,
    required String paymentStatus,
    String? paymentId,
  }) async {
    try {
      final updates = {
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (paymentId != null) {
        updates['paymentId'] = paymentId;
      }

      await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .update(updates);

      debugPrint('✅ Registration payment updated: $registrationId');
      return {'success': true, 'message': 'Payment status updated'};
    } catch (e) {
      debugPrint('❌ Update registration payment error: $e');
      return {'success': false, 'error': 'Failed to update payment status.'};
    }
  }

  /// Get registration by ID (for checkout page)
  Future<WorkshopRegistrationModel?> getRegistrationById(
    String registrationId,
  ) async {
    try {
      final doc = await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .get();

      if (doc.exists) {
        return WorkshopRegistrationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get registration error: $e');
      return null;
    }
  }

  /// Process workshop payment
  Future<Map<String, dynamic>> processWorkshopPayment({
    required String registrationId,
    required double amount,
    required String paymentMethod,
    String? paymentId,
  }) async {
    try {
      // Get registration to find workshop ID
      final registrationDoc = await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .get();

      if (!registrationDoc.exists) {
        return {'success': false, 'error': 'Registration not found'};
      }

      final registrationData = registrationDoc.data()!;
      final workshopId = registrationData['workshopId'] as String;

      // Update registration payment status
      await registrationDoc.reference.update({
        'paymentStatus': 'paid',
        'paymentMethod': paymentMethod,
        'paymentId': paymentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Increment workshop participant count
      await _firestore.collection('workshops').doc(workshopId).update({
        'currentParticipants': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for user
      final userId = registrationData['userId'] as String?;
      if (userId != null) {
        final workshopDoc = await _firestore
            .collection('workshops')
            .doc(workshopId)
            .get();
        final workshopTitle = workshopDoc.exists
            ? (workshopDoc.data()!['title'] ?? 'Workshop')
            : 'Workshop';

        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'workshop_payment',
          'title': 'Workshop Payment Confirmed',
          'message':
              'Your payment for $workshopTitle has been confirmed. You are now registered!',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Workshop payment processed successfully: $registrationId');
      return {'success': true, 'message': 'Payment processed successfully'};
    } catch (e) {
      debugPrint('❌ Process workshop payment error: $e');
      return {
        'success': false,
        'error': 'Failed to process payment. Please try again.',
      };
    }
  }

  /// Delete workshop registration (Admin)
  Future<Map<String, dynamic>> deleteRegistration(String registrationId) async {
    try {
      final registrationDoc = await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .get();

      if (!registrationDoc.exists) {
        return {'success': false, 'error': 'Registration not found'};
      }

      // Delete the registration
      await registrationDoc.reference.delete();

      debugPrint('✅ Registration deleted: $registrationId');
      return {'success': true, 'message': 'Registration deleted successfully'};
    } catch (e) {
      debugPrint('❌ Delete registration error: $e');
      return {'success': false, 'error': 'Failed to delete registration.'};
    }
  }

  /// Check for duplicate workshop
  Future<bool> isDuplicateWorkshop({
    required String title,
    required DateTime startDate,
    String? excludeWorkshopId,
  }) async {
    try {
      final query = await _firestore
          .collection('workshops')
          .where('title', isEqualTo: title)
          .where('startDate', isEqualTo: Timestamp.fromDate(startDate))
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;

      // If excluding a workshop (for updates), check if found workshop is not the excluded one
      if (excludeWorkshopId != null) {
        return query.docs.first.id != excludeWorkshopId;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Check duplicate workshop error: $e');
      return false;
    }
  }

  /// Check workshop capacity and notify if near full
  Future<Map<String, dynamic>> checkCapacityAndNotify(String workshopId) async {
    try {
      final workshop = await getWorkshopById(workshopId);
      if (workshop == null) {
        return {'success': false, 'error': 'Workshop not found'};
      }

      final capacityPercent =
          (workshop.currentParticipants / workshop.maxParticipants) * 100;

      if (capacityPercent >= 80 && capacityPercent < 100) {
        // Notify creator workshop is 80% full
        if (workshop.createdBy.isNotEmpty) {
          await _firestore.collection('notifications').add({
            'userId': workshop.createdBy,
            'type': 'workshop_capacity',
            'title': 'Workshop Almost Full',
            'message':
                '${workshop.title} is now ${capacityPercent.toStringAsFixed(0)}% full (${workshop.currentParticipants}/${workshop.maxParticipants} seats)',
            'isRead': false,
            'workshopId': workshopId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        return {
          'success': true,
          'message': 'Capacity notification sent',
          'capacityPercent': capacityPercent,
        };
      } else if (capacityPercent >= 100) {
        // Workshop is full
        await _firestore.collection('workshops').doc(workshopId).update({
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (workshop.createdBy.isNotEmpty) {
          await _firestore.collection('notifications').add({
            'userId': workshop.createdBy,
            'type': 'workshop_full',
            'title': 'Workshop Full',
            'message':
                '${workshop.title} has reached maximum capacity and has been automatically deactivated.',
            'isRead': false,
            'workshopId': workshopId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        return {'success': true, 'message': 'Workshop is full', 'isFull': true};
      }

      return {'success': true, 'capacityPercent': capacityPercent};
    } catch (e) {
      debugPrint('❌ Check capacity error: $e');
      return {'success': false, 'error': 'Failed to check capacity'};
    }
  }

  /// Get workshop analytics
  Future<Map<String, dynamic>> getWorkshopAnalytics() async {
    try {
      // Get all workshops
      final workshopsSnapshot = await _firestore.collection('workshops').get();
      final totalWorkshops = workshopsSnapshot.docs.length;
      final activeWorkshops = workshopsSnapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;

      // Get all registrations
      final registrationsSnapshot = await _firestore
          .collection('workshop_registrations')
          .get();
      final totalRegistrations = registrationsSnapshot.docs.length;
      final confirmedRegistrations = registrationsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'confirmed')
          .length;
      final paidRegistrations = registrationsSnapshot.docs
          .where((doc) => doc.data()['paymentStatus'] == 'paid')
          .length;

      // Calculate revenue
      double totalRevenue = 0;
      for (final regDoc in registrationsSnapshot.docs) {
        final regData = regDoc.data();
        if (regData['paymentStatus'] == 'paid') {
          final workshopId = regData['workshopId'] as String;
          final workshopDoc = await _firestore
              .collection('workshops')
              .doc(workshopId)
              .get();
          if (workshopDoc.exists) {
            final price = (workshopDoc.data()!['price'] ?? 0.0) as num;
            totalRevenue += price.toDouble();
          }
        }
      }

      // Get most popular workshops
      final workshopRegistrationCounts = <String, int>{};
      for (final regDoc in registrationsSnapshot.docs) {
        final workshopId = regDoc.data()['workshopId'] as String;
        workshopRegistrationCounts[workshopId] =
            (workshopRegistrationCounts[workshopId] ?? 0) + 1;
      }

      // Sort by registration count
      final sortedWorkshops = workshopRegistrationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topWorkshops = <Map<String, dynamic>>[];
      for (
        int i = 0;
        i < (sortedWorkshops.length < 5 ? sortedWorkshops.length : 5);
        i++
      ) {
        final workshopId = sortedWorkshops[i].key;
        final workshopDoc = await _firestore
            .collection('workshops')
            .doc(workshopId)
            .get();
        if (workshopDoc.exists) {
          topWorkshops.add({
            'id': workshopId,
            'title': workshopDoc.data()!['title'],
            'registrations': sortedWorkshops[i].value,
          });
        }
      }

      return {
        'success': true,
        'analytics': {
          'totalWorkshops': totalWorkshops,
          'activeWorkshops': activeWorkshops,
          'totalRegistrations': totalRegistrations,
          'confirmedRegistrations': confirmedRegistrations,
          'paidRegistrations': paidRegistrations,
          'totalRevenue': totalRevenue,
          'topWorkshops': topWorkshops,
          'averageRevenuePerWorkshop': totalWorkshops > 0
              ? totalRevenue / totalWorkshops
              : 0,
        },
      };
    } catch (e) {
      debugPrint('❌ Get workshop analytics error: $e');
      return {'success': false, 'error': 'Failed to get analytics'};
    }
  }

  /// Search workshops
  Future<List<WorkshopModel>> searchWorkshops({
    String? searchQuery,
    String? provider,
    double? minPrice,
    double? maxPrice,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('workshops')
          .where('isActive', isEqualTo: true);

      if (provider != null && provider.isNotEmpty) {
        query = query.where('provider', isEqualTo: provider);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      if (startDate != null) {
        query = query.where(
          'startDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'startDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot = await query.get();
      var workshops = snapshot.docs
          .map((doc) => WorkshopModel.fromFirestore(doc))
          .toList();

      // Filter by price range
      if (minPrice != null) {
        workshops = workshops.where((w) => w.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        workshops = workshops.where((w) => w.price <= maxPrice).toList();
      }

      // Filter by search query (title or description)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        workshops = workshops.where((w) {
          return w.title.toLowerCase().contains(lowerQuery) ||
              w.description.toLowerCase().contains(lowerQuery) ||
              (w.certificationType.toLowerCase().contains(lowerQuery));
        }).toList();
      }

      return workshops;
    } catch (e) {
      debugPrint('❌ Search workshops error: $e');
      return [];
    }
  }

  // ============================================================================
  // PHASE 2: DOCTOR PROPOSAL SYSTEM
  // ============================================================================

  /// Submit workshop proposal (Doctor → Admin)
  /// Doctor creates workshop request that needs admin approval
  Future<Map<String, dynamic>> submitWorkshopProposal({
    required String createdBy,
    required String title,
    required String description,
    required String provider,
    required String certificationType,
    required int duration,
    required double price,
    required int maxParticipants,
    required String location,
    required String schedule,
    String? instructor,
    String? prerequisites,
    String? materials,
    String? bannerImage,
    String? syllabusPdf,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final proposalRef = await _firestore.collection('workshops').add({
        'title': title,
        'description': description,
        'provider': provider,
        'certificationType': certificationType,
        'duration': duration,
        'price': price, // Doctor's suggested price
        'maxParticipants': maxParticipants,
        'currentParticipants': 0,
        'location': location,
        'schedule': schedule,
        'instructor': instructor,
        'prerequisites': prerequisites,
        'materials': materials,
        'bannerImage': bannerImage,
        'syllabusPdf': syllabusPdf,
        'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'startTime': startTime,
        'endTime': endTime,
        'isActive': false, // ❌ Not live until admin approves
        'createdBy': createdBy,
        'permissionStatus': 'pending_admin', // 🟡 Awaiting admin review
        'isCreationFeePaid': false, // 💰 Creator must pay after admin approval
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📝 Workshop proposal submitted: ${proposalRef.id}');
      return {
        'success': true,
        'proposalId': proposalRef.id,
        'message': 'Proposal submitted. Awaiting admin approval.',
      };
    } catch (e) {
      debugPrint('❌ Submit proposal error: $e');
      return {
        'success': false,
        'error': 'Failed to submit proposal. Please try again.',
      };
    }
  }

  /// Check if workshop payment deadline has expired (2 hours)
  bool hasPaymentExpired(DateTime? permissionGrantedAt) {
    if (permissionGrantedAt == null) return false;

    final deadline = permissionGrantedAt.add(const Duration(hours: 2));
    return DateTime.now().isAfter(deadline);
  }

  /// Get remaining time for payment (in seconds)
  int getRemainingPaymentTime(DateTime? permissionGrantedAt) {
    if (permissionGrantedAt == null) return 0;

    final deadline = permissionGrantedAt.add(const Duration(hours: 2));
    final remaining = deadline.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Get workshops pending admin approval
  Stream<List<WorkshopModel>> getPendingProposals() {
    return _firestore
        .collection('workshops')
        .where('permissionStatus', isEqualTo: 'pending_admin')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkshopModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get workshops by creator with permission status
  Stream<List<WorkshopModel>> getWorkshopsByCreator(String creatorId) {
    return _firestore
        .collection('workshops')
        .where('createdBy', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkshopModel.fromFirestore(doc))
              .toList();
        });
  }

  // ============================================================================
  // PHASE 3: JOINING PERMISSION (Creator Gatekeeper)
  // ============================================================================

  /// Get pending join requests for creator's workshop
  Stream<List<WorkshopRegistrationModel>> getPendingJoinRequests(
    String workshopId,
  ) {
    return _firestore
        .collection('workshop_registrations')
        .where('workshopId', isEqualTo: workshopId)
        .where('approvalStatus', isEqualTo: 'pending_creator')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkshopRegistrationModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Approve a join request (Creator action)
  Future<Map<String, dynamic>> approveJoinRequest({
    required String registrationId,
    required String workshopId,
  }) async {
    try {
      await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .update({
            'approvalStatus': 'approved_by_creator',
            'creatorApprovedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Get registration details for notification
      final regDoc = await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .get();

      if (regDoc.exists) {
        final regData = regDoc.data()!;
        final userId = regData['userId'] as String?;
        final workshopTitle = regData['workshopTitle'] ?? 'Workshop';

        if (userId != null) {
          await NotificationHelper.createNotification(
            firestore: _firestore,
            userId: userId,
            type: 'workshop_approved',
            title: 'Join Request Approved! ⏰',
            message:
                'Good news! You are approved for "$workshopTitle". '
                'Please pay within 1 hour to secure your seat.',
          );
        }
      }

      debugPrint('✅ Join request approved: $registrationId');
      return {
        'success': true,
        'message': 'Join request approved! Participant has 1 hour to pay.',
      };
    } catch (e) {
      debugPrint('❌ Approve join request error: $e');
      return {'success': false, 'error': 'Failed to approve request.'};
    }
  }

  /// Reject a join request (Creator action)
  Future<Map<String, dynamic>> rejectJoinRequest({
    required String registrationId,
    required String reason,
  }) async {
    try {
      await _firestore
          .collection('workshop_registrations')
          .doc(registrationId)
          .update({
            'approvalStatus': 'rejected',
            'rejectionReason': reason,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Join request rejected: $registrationId');
      return {'success': true, 'message': 'Join request rejected.'};
    } catch (e) {
      debugPrint('❌ Reject join request error: $e');
      return {'success': false, 'error': 'Failed to reject request.'};
    }
  }

  /// Check if 1-hour payment window has expired
  bool hasJoiningPaymentExpired(DateTime? creatorApprovedAt) {
    if (creatorApprovedAt == null) return false;

    final deadline = creatorApprovedAt.add(const Duration(hours: 1));
    return DateTime.now().isAfter(deadline);
  }

  /// Get remaining time for joining payment (in seconds)
  int getRemainingJoiningTime(DateTime? creatorApprovedAt) {
    if (creatorApprovedAt == null) return 0;

    final deadline = creatorApprovedAt.add(const Duration(hours: 1));
    final remaining = deadline.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // ============================================================================
  // PHASE 4: WORKSHOP PAYOUT SYSTEM
  // ============================================================================

  /// Calculate workshop revenue (only from PAID registrations)
  Future<Map<String, dynamic>> calculateWorkshopRevenue(
    String workshopId,
  ) async {
    try {
      final workshop = await getWorkshopById(workshopId);
      if (workshop == null) {
        return {'success': false, 'error': 'Workshop not found'};
      }

      // Get only PAID registrations
      final paidRegsQuery = await _firestore
          .collection('workshop_registrations')
          .where('workshopId', isEqualTo: workshopId)
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      final paidCount = paidRegsQuery.docs.length;
      final totalRevenue = paidCount * workshop.price;
      final adminCommissionRate = 0.20; // 20% commission
      final adminCommission = totalRevenue * adminCommissionRate;
      final doctorPayout = totalRevenue - adminCommission;

      return {
        'success': true,
        'paidParticipants': paidCount,
        'totalRevenue': totalRevenue,
        'adminCommission': adminCommission,
        'doctorPayout': doctorPayout,
      };
    } catch (e) {
      debugPrint('❌ Calculate revenue error: $e');
      return {'success': false, 'error': 'Failed to calculate revenue'};
    }
  }

  /// Request workshop payout (Doctor action)
  Future<Map<String, dynamic>> requestWorkshopPayout(String workshopId) async {
    try {
      final workshop = await getWorkshopById(workshopId);
      if (workshop == null) {
        return {'success': false, 'error': 'Workshop not found'};
      }

      // 🛡️ SECURITY: Verify workshop has ended
      if (workshop.endDate == null) {
        return {'success': false, 'error': 'Workshop end date not set'};
      }

      if (DateTime.now().isBefore(workshop.endDate!)) {
        return {
          'success': false,
          'error': 'Cannot request payout until workshop ends',
        };
      }

      // Check if already requested
      if (workshop.isPayoutRequested) {
        return {'success': false, 'error': 'Payout already requested'};
      }

      // Calculate revenue
      final revenueResult = await calculateWorkshopRevenue(workshopId);
      if (!revenueResult['success']) {
        return revenueResult;
      }

      // Update workshop with payout request
      await _firestore.collection('workshops').doc(workshopId).update({
        'payoutStatus': 'requested',
        'isPayoutRequested': true,
        'payoutRequestedAt': FieldValue.serverTimestamp(),
        'totalRevenue': revenueResult['totalRevenue'],
        'adminCommission': revenueResult['adminCommission'],
        'doctorPayout': revenueResult['doctorPayout'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Payout requested for workshop: $workshopId');
      return {
        'success': true,
        'message': 'Payout request submitted successfully',
        'doctorPayout': revenueResult['doctorPayout'],
      };
    } catch (e) {
      debugPrint('❌ Request payout error: $e');
      return {'success': false, 'error': 'Failed to request payout'};
    }
  }

  /// Phase 5: Get comprehensive financial snapshot for a workshop
  /// Returns: Creation fee status, participant payments summary, and financial metrics
  Future<Map<String, dynamic>> getWorkshopFinancialSnapshot(
    String workshopId,
  ) async {
    try {
      // Fetch workshop data
      final workshopDoc = await _firestore
          .collection('workshops')
          .doc(workshopId)
          .get();
      if (!workshopDoc.exists) {
        return {'success': false, 'error': 'Workshop not found'};
      }

      final workshopData = workshopDoc.data()!;
      final workshopPrice = (workshopData['price'] ?? 0.0).toDouble();
      final isCreationFeePaid = workshopData['isCreationFeePaid'] ?? false;
      final adminSetFee = (workshopData['adminSetFee'] ?? 0.0).toDouble();

      // Fetch all paid registrations
      final registrationsSnapshot = await _firestore
          .collection('workshop_registrations')
          .where('workshopId', isEqualTo: workshopId)
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      final participantPayments = registrationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userName': data['userName'] ?? 'Unknown',
          'cnic': data['cnic'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'paidAt': data['paidAt'],
          'amountPaid': (data['amountPaid'] ?? workshopPrice).toDouble(),
        };
      }).toList();

      // Calculate financial metrics
      final totalParticipants = participantPayments.length;
      final totalRevenue = totalParticipants * workshopPrice;

      // Use fixed 20% commission (no longer dynamic)
      const double globalCommissionRate = 0.20;

      final adminCommission = totalRevenue * globalCommissionRate;
      final doctorPayout = totalRevenue * (1.0 - globalCommissionRate);

      // Escrow liability (money not yet released to doctor)
      final payoutStatus = workshopData['payoutStatus'] ?? 'none';
      final escrowLiability = payoutStatus == 'released' ? 0.0 : doctorPayout;

      // Net profit for admin (creation fees + commission from all workshops)
      final netProfit =
          (isCreationFeePaid ? adminSetFee : 0.0) + adminCommission;

      return {
        'success': true,
        'workshopId': workshopId,
        'workshopTitle': workshopData['title'] ?? 'Untitled',
        // 1. Creation Fee Ledger
        'creationFeePaid': isCreationFeePaid,
        'creationFeeAmount': adminSetFee,
        // 2. Liquidity Tracking
        'totalParticipantsPaid': totalParticipants,
        'totalCashIn': totalRevenue,
        // 3. Escrow Liability
        'escrowLiability': escrowLiability,
        'payoutStatus': payoutStatus,
        // 4. Net Profit
        'netProfit': netProfit,
        'adminCommission': adminCommission,
        // Additional metrics
        'workshopPrice': workshopPrice,
        'doctorPayout': doctorPayout,
        'totalRevenue': totalRevenue,
        // Participant details
        'participantPayments': participantPayments,
        // High-value flag
        'isHighValue': totalRevenue >= 100000,
      };
    } catch (e) {
      debugPrint('❌ Get financial snapshot error: $e');
      return {'success': false, 'error': 'Failed to fetch financial snapshot'};
    }
  }
}
