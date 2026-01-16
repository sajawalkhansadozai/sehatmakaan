import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workshop_model.dart';
import '../models/workshop_registration_model.dart';

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
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Workshop created: ${workshopRef.id}');
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

      // Create registration
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
            'paymentStatus': 'pending',
            'paymentMethod': 'payfast',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Increment participant count
      await _firestore.collection('workshops').doc(workshopId).update({
        'currentParticipants': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Workshop registration created: ${registrationRef.id}');
      return {
        'success': true,
        'registrationId': registrationRef.id,
        'message': 'Registration submitted successfully',
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
}
