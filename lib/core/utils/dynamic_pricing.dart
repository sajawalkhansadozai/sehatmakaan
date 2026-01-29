import 'package:sehatmakaan/features/admin/models/pricing_config_model.dart';
import 'package:sehatmakaan/features/admin/services/pricing_service.dart';

/// Utility class to load dynamic pricing from Firestore
///
/// Usage:
/// ```dart
/// // Get dental base rate
/// final rate = await DynamicPricing.getDentalBaseRate();
///
/// // Get package price
/// final price = await DynamicPricing.getPackagePrice('dental', 'starter');
///
/// // Get addon price
/// final addonPrice = await DynamicPricing.getAddonPrice('priority_booking');
/// ```
class DynamicPricing {
  static final PricingService _pricingService = PricingService();
  static PricingConfig? _cachedConfig;
  static DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get current pricing configuration (with caching)
  static Future<PricingConfig> _getConfig({bool forceRefresh = false}) async {
    final now = DateTime.now();

    if (forceRefresh ||
        _cachedConfig == null ||
        _lastFetch == null ||
        now.difference(_lastFetch!) > _cacheDuration) {
      _cachedConfig = await _pricingService.getCurrentPricing();
      _lastFetch = now;
    }

    return _cachedConfig!;
  }

  /// Clear cache to force fresh data on next request
  static void clearCache() {
    _cachedConfig = null;
    _lastFetch = null;
  }

  // ============================================================================
  // SUITE BASE RATES
  // ============================================================================

  /// Get dental suite base rate (per hour)
  static Future<double> getDentalBaseRate() async {
    final config = await _getConfig();
    return config.dentalBaseRate;
  }

  /// Get dental suite specialist rate (per hour)
  static Future<double> getDentalSpecialistRate() async {
    final config = await _getConfig();
    return config.dentalSpecialistRate;
  }

  /// Get medical suite base rate (per hour)
  static Future<double> getMedicalBaseRate() async {
    final config = await _getConfig();
    return config.medicalBaseRate;
  }

  /// Get medical suite specialist rate (per hour)
  static Future<double> getMedicalSpecialistRate() async {
    final config = await _getConfig();
    return config.medicalSpecialistRate;
  }

  /// Get aesthetic suite base rate (per hour)
  static Future<double> getAestheticBaseRate() async {
    final config = await _getConfig();
    return config.aestheticBaseRate;
  }

  /// Get aesthetic suite specialist rate (per hour)
  static Future<double> getAestheticSpecialistRate() async {
    final config = await _getConfig();
    return config.aestheticSpecialistRate;
  }

  /// Get suite base rate by suite type and specialty
  static Future<double> getSuiteRate(
    String suiteType, {
    bool isSpecialist = false,
  }) async {
    final config = await _getConfig();

    switch (suiteType.toLowerCase()) {
      case 'dental':
        return isSpecialist
            ? config.dentalSpecialistRate
            : config.dentalBaseRate;
      case 'medical':
        return isSpecialist
            ? config.medicalSpecialistRate
            : config.medicalBaseRate;
      case 'aesthetic':
        return isSpecialist
            ? config.aestheticSpecialistRate
            : config.aestheticBaseRate;
      default:
        return config.dentalBaseRate; // Default fallback
    }
  }

  // ============================================================================
  // MONTHLY PACKAGE PRICES
  // ============================================================================

  /// Get monthly package price
  ///
  /// [suiteType] - 'dental', 'medical', or 'aesthetic'
  /// [packageType] - 'starter', 'advanced', or 'professional'
  static Future<double> getPackagePrice(
    String suiteType,
    String packageType,
  ) async {
    final config = await _getConfig();

    switch (suiteType.toLowerCase()) {
      case 'dental':
        switch (packageType.toLowerCase()) {
          case 'starter':
            return config.dentalStarterPrice;
          case 'advanced':
            return config.dentalAdvancedPrice;
          case 'professional':
            return config.dentalProfessionalPrice;
          default:
            return config.dentalStarterPrice;
        }
      case 'medical':
        switch (packageType.toLowerCase()) {
          case 'starter':
            return config.medicalStarterPrice;
          case 'advanced':
            return config.medicalAdvancedPrice;
          case 'professional':
            return config.medicalProfessionalPrice;
          default:
            return config.medicalStarterPrice;
        }
      case 'aesthetic':
        switch (packageType.toLowerCase()) {
          case 'starter':
            return config.aestheticStarterPrice;
          case 'advanced':
            return config.aestheticAdvancedPrice;
          case 'professional':
            return config.aestheticProfessionalPrice;
          default:
            return config.aestheticStarterPrice;
        }
      default:
        return config.dentalStarterPrice;
    }
  }

  // ============================================================================
  // ADD-ON PRICES
  // ============================================================================

  /// Get addon price by code
  static Future<double> getAddonPrice(String addonCode) async {
    final config = await _getConfig();

    switch (addonCode.toLowerCase()) {
      // Monthly add-ons
      case 'extra_10_hours':
        return config.extra10HoursPrice;
      case 'dedicated_locker':
        return config.dedicatedLockerPrice;
      case 'clinical_assistant':
        return config.clinicalAssistantPrice;
      case 'social_media_highlight':
        return config.socialMediaHighlightPrice;

      // Hourly add-ons
      case 'dental_assistant':
        return config.dentalAssistantPrice;
      case 'medical_nurse':
        return config.medicalNursePrice;
      case 'intraoral_xray':
        return config.intraoralXrayPrice;
      case 'priority_booking':
        return config.priorityBookingPrice;
      case 'extended_hours':
        return config.extendedHoursPrice;

      default:
        return 0.0;
    }
  }

  // ============================================================================
  // BULK OPERATIONS
  // ============================================================================

  /// Get all suite rates as a map
  static Future<Map<String, Map<String, double>>> getAllSuiteRates() async {
    final config = await _getConfig();

    return {
      'dental': {
        'base': config.dentalBaseRate,
        'specialist': config.dentalSpecialistRate,
      },
      'medical': {
        'base': config.medicalBaseRate,
        'specialist': config.medicalSpecialistRate,
      },
      'aesthetic': {
        'base': config.aestheticBaseRate,
        'specialist': config.aestheticSpecialistRate,
      },
    };
  }

  /// Get all package prices as a map
  static Future<Map<String, Map<String, double>>> getAllPackagePrices() async {
    final config = await _getConfig();

    return {
      'dental': {
        'starter': config.dentalStarterPrice,
        'advanced': config.dentalAdvancedPrice,
        'professional': config.dentalProfessionalPrice,
      },
      'medical': {
        'starter': config.medicalStarterPrice,
        'advanced': config.medicalAdvancedPrice,
        'professional': config.medicalProfessionalPrice,
      },
      'aesthetic': {
        'starter': config.aestheticStarterPrice,
        'advanced': config.aestheticAdvancedPrice,
        'professional': config.aestheticProfessionalPrice,
      },
    };
  }

  /// Get all addon prices as a map
  static Future<Map<String, double>> getAllAddonPrices() async {
    final config = await _getConfig();

    return {
      'extra_10_hours': config.extra10HoursPrice,
      'dedicated_locker': config.dedicatedLockerPrice,
      'clinical_assistant': config.clinicalAssistantPrice,
      'social_media_highlight': config.socialMediaHighlightPrice,
      'dental_assistant': config.dentalAssistantPrice,
      'medical_nurse': config.medicalNursePrice,
      'intraoral_xray': config.intraoralXrayPrice,
      'priority_booking': config.priorityBookingPrice,
      'extended_hours': config.extendedHoursPrice,
    };
  }

  // ============================================================================
  // REAL-TIME UPDATES
  // ============================================================================

  /// Listen to pricing changes in real-time
  static Stream<PricingConfig> getPricingStream() {
    return _pricingService.pricingStream();
  }
}
