import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workshop_creator_model.dart';

class WorkshopCreatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new workshop creator (Admin only)
  Future<String> addWorkshopCreator({
    required String userId,
    required String fullName,
    required String email,
    String? specialty,
    required String adminId,
  }) async {
    try {
      // Check if user is already a workshop creator
      final existing = await _firestore
          .collection('workshop_creators')
          .where('userId', isEqualTo: userId)
          .get();

      if (existing.docs.isNotEmpty) {
        final existingDoc = existing.docs.first;
        final isActive = existingDoc.data()['isActive'] ?? false;

        if (isActive) {
          throw Exception('User is already an active workshop creator');
        } else {
          // Reactivate existing creator
          await _firestore
              .collection('workshop_creators')
              .doc(existingDoc.id)
              .update({'isActive': true});
          return existingDoc.id;
        }
      }

      // Create new workshop creator
      final creator = WorkshopCreatorModel(
        userId: userId,
        fullName: fullName,
        email: email,
        specialty: specialty,
        createdBy: adminId,
      );

      final docRef = await _firestore
          .collection('workshop_creators')
          .add(creator.toJson());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add workshop creator: $e');
    }
  }

  /// Remove/Deactivate workshop creator (Admin only)
  Future<void> removeWorkshopCreator(String creatorId) async {
    try {
      await _firestore.collection('workshop_creators').doc(creatorId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to remove workshop creator: $e');
    }
  }

  /// Reactivate workshop creator (Admin only)
  Future<void> reactivateWorkshopCreator(String creatorId) async {
    try {
      await _firestore.collection('workshop_creators').doc(creatorId).update({
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Failed to reactivate workshop creator: $e');
    }
  }

  /// Check if a user is an active workshop creator
  Future<bool> isUserWorkshopCreator(String userId) async {
    try {
      final query = await _firestore
          .collection('workshop_creators')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get workshop creator by user ID
  Future<WorkshopCreatorModel?> getCreatorByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection('workshop_creators')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return WorkshopCreatorModel.fromFirestore(query.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Get all workshop creators (Admin only)
  Future<List<WorkshopCreatorModel>> getAllWorkshopCreators() async {
    try {
      final query = await _firestore
          .collection('workshop_creators')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => WorkshopCreatorModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load workshop creators: $e');
    }
  }

  /// Get workshops created by a specific creator
  Future<List<Map<String, dynamic>>> getCreatorWorkshops(
    String creatorId,
  ) async {
    try {
      final query = await _firestore
          .collection('workshops')
          .where('createdBy', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load creator workshops: $e');
    }
  }

  /// Get workshop count for a creator
  Future<int> getCreatorWorkshopCount(String userId) async {
    try {
      // First get creator ID
      final creator = await getCreatorByUserId(userId);
      if (creator?.id == null) return 0;

      final query = await _firestore
          .collection('workshops')
          .where('createdBy', isEqualTo: creator!.id)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Stream of workshop creators for real-time updates (Admin only)
  Stream<List<WorkshopCreatorModel>> streamWorkshopCreators() {
    return _firestore
        .collection('workshop_creators')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkshopCreatorModel.fromFirestore(doc))
              .toList(),
        );
  }
}
