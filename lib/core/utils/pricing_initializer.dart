import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/features/admin/services/pricing_service.dart';

/// One-time initialization script for default pricing
///
/// HOW TO USE:
/// 1. Import this file in your main.dart or admin dashboard
/// 2. Call initializeDefaultPricing() once
/// 3. This will create the pricing_config collection in Firestore
///
/// Example:
/// ```dart
/// import 'package:sehat_makaan_flutter/core/utils/pricing_initializer.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///
///   // Initialize pricing (first time only)
///   await PricingInitializer.initializeDefaultPricing();
///
///   runApp(MyApp());
/// }
/// ```

class PricingInitializer {
  static final PricingService _pricingService = PricingService();

  /// Initialize default pricing configuration in Firestore
  /// This should be called once during initial app setup
  static Future<void> initializeDefaultPricing() async {
    try {
      debugPrint('🚀 Initializing default pricing...');
      await _pricingService.initializeDefaultPricing();
      debugPrint('✅ Default pricing initialized successfully!');
      debugPrint('');
      debugPrint('📊 Default Prices Set:');
      debugPrint('   Suite Rates:');
      debugPrint('   - Dental Base: PKR 1,500/hour');
      debugPrint('   - Dental Specialist: PKR 3,000/hour');
      debugPrint('   - Medical Base: PKR 2,000/hour');
      debugPrint('   - Aesthetic Base: PKR 3,000/hour');
      debugPrint('');
      debugPrint('   Monthly Packages:');
      debugPrint('   - Dental Starter: PKR 25,000');
      debugPrint('   - Medical Starter: PKR 20,000');
      debugPrint('   - Aesthetic Starter: PKR 30,000');
      debugPrint('');
      debugPrint('   Add-ons:');
      debugPrint('   - Priority Booking: PKR 500');
      debugPrint('   - Extended Hours: PKR 500');
      debugPrint('   - Extra 10 Hours: PKR 10,000');
      debugPrint('');
      debugPrint('✨ You can now manage prices from Admin Panel > Pricing tab');
    } catch (e) {
      debugPrint('❌ Error initializing pricing: $e');
      debugPrint('⚠️  Make sure Firebase is initialized before calling this');
    }
  }

  /// Check if pricing is already initialized
  static Future<bool> isPricingInitialized() async {
    try {
      final config = await _pricingService.getCurrentPricing();
      return config.id != null;
    } catch (e) {
      return false;
    }
  }

  /// Display current pricing in console (for debugging)
  static Future<void> displayCurrentPricing() async {
    try {
      final config = await _pricingService.getCurrentPricing();

      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('            CURRENT PRICING CONFIGURATION');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');
      debugPrint('🏥 SUITE HOURLY RATES:');
      debugPrint('   Dental:');
      debugPrint(
        '      Base Rate: PKR ${config.dentalBaseRate.toStringAsFixed(0)}/hour',
      );
      debugPrint(
        '      Specialist Rate: PKR ${config.dentalSpecialistRate.toStringAsFixed(0)}/hour',
      );
      debugPrint('   Medical:');
      debugPrint(
        '      Base Rate: PKR ${config.medicalBaseRate.toStringAsFixed(0)}/hour',
      );
      debugPrint(
        '      Specialist Rate: PKR ${config.medicalSpecialistRate.toStringAsFixed(0)}/hour',
      );
      debugPrint('   Aesthetic:');
      debugPrint(
        '      Base Rate: PKR ${config.aestheticBaseRate.toStringAsFixed(0)}/hour',
      );
      debugPrint(
        '      Specialist Rate: PKR ${config.aestheticSpecialistRate.toStringAsFixed(0)}/hour',
      );
      debugPrint('');
      debugPrint('📦 MONTHLY PACKAGES:');
      debugPrint('   Dental:');
      debugPrint(
        '      Starter: PKR ${config.dentalStarterPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Advanced: PKR ${config.dentalAdvancedPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Professional: PKR ${config.dentalProfessionalPrice.toStringAsFixed(0)}',
      );
      debugPrint('   Medical:');
      debugPrint(
        '      Starter: PKR ${config.medicalStarterPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Advanced: PKR ${config.medicalAdvancedPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Professional: PKR ${config.medicalProfessionalPrice.toStringAsFixed(0)}',
      );
      debugPrint('   Aesthetic:');
      debugPrint(
        '      Starter: PKR ${config.aestheticStarterPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Advanced: PKR ${config.aestheticAdvancedPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Professional: PKR ${config.aestheticProfessionalPrice.toStringAsFixed(0)}',
      );
      debugPrint('');
      debugPrint('➕ ADD-ONS:');
      debugPrint('   Monthly:');
      debugPrint(
        '      Extra 10 Hours: PKR ${config.extra10HoursPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Dedicated Locker: PKR ${config.dedicatedLockerPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Clinical Assistant: PKR ${config.clinicalAssistantPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Social Media Highlight: PKR ${config.socialMediaHighlightPrice.toStringAsFixed(0)}',
      );
      debugPrint('   Hourly:');
      debugPrint(
        '      Dental Assistant: PKR ${config.dentalAssistantPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Medical Nurse: PKR ${config.medicalNursePrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Intraoral X-ray: PKR ${config.intraoralXrayPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Priority Booking: PKR ${config.priorityBookingPrice.toStringAsFixed(0)}',
      );
      debugPrint(
        '      Extended Hours: PKR ${config.extendedHoursPrice.toStringAsFixed(0)}',
      );
      debugPrint('');
      if (config.updatedAt != null) {
        debugPrint('📅 Last Updated: ${config.updatedAt}');
        if (config.updatedBy != null) {
          debugPrint('👤 Updated By: ${config.updatedBy}');
        }
      }
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error displaying pricing: $e');
    }
  }
}
