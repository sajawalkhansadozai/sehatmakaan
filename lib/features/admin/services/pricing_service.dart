import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pricing_config_model.dart';

/// Service for managing pricing configuration
class PricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'pricing_config';
  static const String _configDocId = 'current_pricing';

  /// Get current pricing configuration
  Future<PricingConfig> getCurrentPricing() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .get();

      if (doc.exists) {
        return PricingConfig.fromFirestore(doc);
      } else {
        // Return default pricing if no config exists
        debugPrint('⚠️ No pricing config found, returning defaults');
        return PricingConfig.createDefault();
      }
    } catch (e) {
      debugPrint('❌ Error fetching pricing: $e');
      return PricingConfig.createDefault();
    }
  }

  /// Update pricing configuration
  Future<Map<String, dynamic>> updatePricing({
    required PricingConfig config,
    required String adminId,
  }) async {
    try {
      final updatedConfig = PricingConfig(
        id: config.id,
        dentalBaseRate: config.dentalBaseRate,
        dentalSpecialistRate: config.dentalSpecialistRate,
        medicalBaseRate: config.medicalBaseRate,
        medicalSpecialistRate: config.medicalSpecialistRate,
        aestheticBaseRate: config.aestheticBaseRate,
        aestheticSpecialistRate: config.aestheticSpecialistRate,
        dentalStarterPrice: config.dentalStarterPrice,
        dentalAdvancedPrice: config.dentalAdvancedPrice,
        dentalProfessionalPrice: config.dentalProfessionalPrice,
        medicalStarterPrice: config.medicalStarterPrice,
        medicalAdvancedPrice: config.medicalAdvancedPrice,
        medicalProfessionalPrice: config.medicalProfessionalPrice,
        aestheticStarterPrice: config.aestheticStarterPrice,
        aestheticAdvancedPrice: config.aestheticAdvancedPrice,
        aestheticProfessionalPrice: config.aestheticProfessionalPrice,
        extra10HoursPrice: config.extra10HoursPrice,
        dedicatedLockerPrice: config.dedicatedLockerPrice,
        clinicalAssistantPrice: config.clinicalAssistantPrice,
        socialMediaHighlightPrice: config.socialMediaHighlightPrice,
        dentalAssistantPrice: config.dentalAssistantPrice,
        medicalNursePrice: config.medicalNursePrice,
        intraoralXrayPrice: config.intraoralXrayPrice,
        priorityBookingPrice: config.priorityBookingPrice,
        extendedHoursPrice: config.extendedHoursPrice,
        updatedBy: adminId,
      );

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(updatedConfig.toFirestore(), SetOptions(merge: true));

      debugPrint('✅ Pricing configuration updated successfully');

      return {'success': true, 'message': 'Pricing updated successfully'};
    } catch (e) {
      debugPrint('❌ Error updating pricing: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Initialize default pricing (call this once during app setup)
  Future<void> initializeDefaultPricing() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .get();

      if (!doc.exists) {
        final defaultConfig = PricingConfig.createDefault();
        await _firestore
            .collection(_collectionName)
            .doc(_configDocId)
            .set(defaultConfig.toFirestore());
        debugPrint('✅ Default pricing configuration initialized');
      }
    } catch (e) {
      debugPrint('❌ Error initializing pricing: $e');
    }
  }

  /// Stream pricing configuration for real-time updates
  Stream<PricingConfig> pricingStream() {
    return _firestore
        .collection(_collectionName)
        .doc(_configDocId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return PricingConfig.fromFirestore(snapshot);
          }
          return PricingConfig.createDefault();
        });
  }
}
