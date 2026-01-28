import 'package:flutter/foundation.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';
import 'package:sehat_makaan_flutter/core/constants/types.dart';
import 'package:sehat_makaan_flutter/core/utils/dynamic_pricing.dart';

/// Helper class to get prices with admin overrides
///
/// This class provides prices that:
/// 1. First checks for admin-set prices from Firestore
/// 2. Falls back to hardcoded defaults if Firestore unavailable
///
/// Usage:
/// ```dart
/// // Get suite with dynamic pricing
/// final suite = await PriceHelper.getSuiteWithDynamicPricing('dental');
/// print(suite.baseRate); // Shows admin price or default
///
/// // Get package with dynamic pricing
/// final package = await PriceHelper.getPackageWithDynamicPricing('dental', 'starter');
///
/// // Get addon with dynamic pricing
/// final addon = await PriceHelper.getAddonWithDynamicPricing('priority_booking');
/// ```
class PriceHelper {
  /// Get suite with dynamic pricing (admin prices override defaults)
  static Future<Suite> getSuiteWithDynamicPricing(String suiteTypeStr) async {
    try {
      final suiteType = SuiteType.fromString(suiteTypeStr);
      final defaultSuite = AppConstants.suites.firstWhere(
        (s) => s.type == suiteType,
      );

      // Try to get dynamic pricing
      final dynamicBaseRate = await DynamicPricing.getSuiteRate(
        suiteTypeStr,
        isSpecialist: false,
      );

      final dynamicSpecialistRate = await DynamicPricing.getSuiteRate(
        suiteTypeStr,
        isSpecialist: true,
      );

      // Return suite with dynamic prices
      return Suite(
        type: defaultSuite.type,
        name: defaultSuite.name,
        baseRate: dynamicBaseRate,
        specialistRate: dynamicSpecialistRate > 0
            ? dynamicSpecialistRate
            : null,
        description: defaultSuite.description,
        features: defaultSuite.features,
        icon: defaultSuite.icon,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading dynamic suite pricing, using defaults: $e');
      // Fallback to hardcoded default
      final suiteType = SuiteType.fromString(suiteTypeStr);
      return AppConstants.suites.firstWhere((s) => s.type == suiteType);
    }
  }

  /// Get all suites with dynamic pricing
  static Future<List<Suite>> getAllSuitesWithDynamicPricing() async {
    try {
      final suites = <Suite>[];
      for (final suite in AppConstants.suites) {
        final dynamicSuite = await getSuiteWithDynamicPricing(suite.type.value);
        suites.add(dynamicSuite);
      }
      return suites;
    } catch (e) {
      debugPrint('⚠️ Error loading dynamic suites, using defaults: $e');
      return AppConstants.suites;
    }
  }

  /// Get package with dynamic pricing (admin prices override defaults)
  static Future<Package> getPackageWithDynamicPricing(
    String suiteType,
    String packageTypeStr,
  ) async {
    try {
      final packageType = PackageType.fromString(packageTypeStr);
      final packages = AppConstants.packages[suiteType] ?? [];
      final defaultPackage = packages.firstWhere((p) => p.type == packageType);

      // Try to get dynamic pricing
      final dynamicPrice = await DynamicPricing.getPackagePrice(
        suiteType,
        packageTypeStr,
      );

      // Return package with dynamic price
      return Package(
        type: defaultPackage.type,
        name: defaultPackage.name,
        price: dynamicPrice,
        hours: defaultPackage.hours,
        features: defaultPackage.features,
        popular: defaultPackage.popular,
      );
    } catch (e) {
      debugPrint(
        '⚠️ Error loading dynamic package pricing, using defaults: $e',
      );
      // Fallback to hardcoded default
      final packageType = PackageType.fromString(packageTypeStr);
      final packages = AppConstants.packages[suiteType] ?? [];
      return packages.firstWhere((p) => p.type == packageType);
    }
  }

  /// Get all packages for a suite with dynamic pricing
  static Future<List<Package>> getPackagesForSuiteWithDynamicPricing(
    String suiteType,
  ) async {
    try {
      final defaultPackages = AppConstants.packages[suiteType] ?? [];
      final dynamicPackages = <Package>[];

      for (final pkg in defaultPackages) {
        final dynamicPackage = await getPackageWithDynamicPricing(
          suiteType,
          pkg.type.value,
        );
        dynamicPackages.add(dynamicPackage);
      }

      return dynamicPackages;
    } catch (e) {
      debugPrint('⚠️ Error loading dynamic packages, using defaults: $e');
      return AppConstants.packages[suiteType] ?? [];
    }
  }

  /// Get addon with dynamic pricing (admin prices override defaults)
  static Future<Addon> getAddonWithDynamicPricing(String addonCode) async {
    try {
      // Find addon in both monthly and hourly lists
      Addon? defaultAddon;

      try {
        defaultAddon = AppConstants.monthlyAddons.firstWhere(
          (a) => a.code == addonCode,
        );
      } catch (_) {
        defaultAddon = AppConstants.hourlyAddons.firstWhere(
          (a) => a.code == addonCode,
        );
      }

      // Try to get dynamic pricing
      final dynamicPrice = await DynamicPricing.getAddonPrice(addonCode);

      // Return addon with dynamic price
      return Addon(
        name: defaultAddon.name,
        price: dynamicPrice > 0 ? dynamicPrice : defaultAddon.price,
        code: defaultAddon.code,
        applicableFor: defaultAddon.applicableFor,
        minPackage: defaultAddon.minPackage,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading dynamic addon pricing, using defaults: $e');
      // Fallback to hardcoded default
      try {
        return AppConstants.monthlyAddons.firstWhere(
          (a) => a.code == addonCode,
        );
      } catch (_) {
        return AppConstants.hourlyAddons.firstWhere((a) => a.code == addonCode);
      }
    }
  }

  /// Get all monthly addons with dynamic pricing
  static Future<List<Addon>> getMonthlyAddonsWithDynamicPricing() async {
    try {
      final dynamicAddons = <Addon>[];
      for (final addon in AppConstants.monthlyAddons) {
        final dynamicAddon = await getAddonWithDynamicPricing(addon.code);
        dynamicAddons.add(dynamicAddon);
      }
      return dynamicAddons;
    } catch (e) {
      debugPrint('⚠️ Error loading dynamic monthly addons, using defaults: $e');
      return AppConstants.monthlyAddons;
    }
  }

  /// Get all hourly addons with dynamic pricing
  static Future<List<Addon>> getHourlyAddonsWithDynamicPricing() async {
    try {
      final dynamicAddons = <Addon>[];
      for (final addon in AppConstants.hourlyAddons) {
        final dynamicAddon = await getAddonWithDynamicPricing(addon.code);
        dynamicAddons.add(dynamicAddon);
      }
      return dynamicAddons;
    } catch (e) {
      debugPrint('⚠️ Error loading dynamic hourly addons, using defaults: $e');
      return AppConstants.hourlyAddons;
    }
  }

  /// Get addon price by code (convenience method)
  static Future<double> getAddonPrice(String addonCode) async {
    try {
      final addon = await getAddonWithDynamicPricing(addonCode);
      return addon.price;
    } catch (e) {
      debugPrint('⚠️ Error getting addon price, using 0: $e');
      return 0.0;
    }
  }

  /// Get suite base rate (convenience method)
  static Future<double> getSuiteBaseRate(String suiteType) async {
    try {
      final suite = await getSuiteWithDynamicPricing(suiteType);
      return suite.baseRate;
    } catch (e) {
      debugPrint('⚠️ Error getting suite rate, using default: $e');
      final defaultSuite = AppConstants.suites.firstWhere(
        (s) => s.type.value == suiteType,
      );
      return defaultSuite.baseRate;
    }
  }

  /// Get suite specialist rate (convenience method)
  static Future<double?> getSuiteSpecialistRate(String suiteType) async {
    try {
      final suite = await getSuiteWithDynamicPricing(suiteType);
      return suite.specialistRate;
    } catch (e) {
      debugPrint('⚠️ Error getting specialist rate, using default: $e');
      final defaultSuite = AppConstants.suites.firstWhere(
        (s) => s.type.value == suiteType,
      );
      return defaultSuite.specialistRate;
    }
  }

  /// Get package price (convenience method)
  static Future<double> getPackagePrice(
    String suiteType,
    String packageType,
  ) async {
    try {
      final package = await getPackageWithDynamicPricing(
        suiteType,
        packageType,
      );
      return package.price;
    } catch (e) {
      debugPrint('⚠️ Error getting package price, using default: $e');
      final packages = AppConstants.packages[suiteType] ?? [];
      final defaultPackage = packages.firstWhere(
        (p) => p.type.value == packageType,
      );
      return defaultPackage.price;
    }
  }

  // ============================================================================
  // REAL-TIME STREAMS (for live pricing updates)
  // ============================================================================

  /// Get suite prices as a stream (real-time updates)
  static Stream<Suite> getSuiteStream(String suiteTypeStr) {
    return DynamicPricing.getPricingStream().map((pricing) {
      try {
        final suiteType = SuiteType.fromString(suiteTypeStr);
        final defaultSuite = AppConstants.suites.firstWhere(
          (s) => s.type == suiteType,
        );

        // Map pricing config to suite rates based on type
        double baseRate;
        double? specialistRate;

        switch (suiteTypeStr.toLowerCase()) {
          case 'dental':
            baseRate = pricing.dentalBaseRate;
            specialistRate = pricing.dentalSpecialistRate;
            break;
          case 'medical':
            baseRate = pricing.medicalBaseRate;
            specialistRate = pricing.medicalSpecialistRate;
            break;
          case 'aesthetic':
            baseRate = pricing.aestheticBaseRate;
            specialistRate = pricing.aestheticSpecialistRate;
            break;
          default:
            baseRate = defaultSuite.baseRate;
            specialistRate = defaultSuite.specialistRate;
        }

        return Suite(
          type: defaultSuite.type,
          name: defaultSuite.name,
          baseRate: baseRate,
          specialistRate: specialistRate,
          description: defaultSuite.description,
          features: defaultSuite.features,
          icon: defaultSuite.icon,
        );
      } catch (e) {
        debugPrint('⚠️ Error in suite stream, using default: $e');
        final suiteType = SuiteType.fromString(suiteTypeStr);
        return AppConstants.suites.firstWhere((s) => s.type == suiteType);
      }
    });
  }

  /// Get package as a stream (real-time updates)
  static Stream<Package> getPackageStream(
    String suiteType,
    String packageTypeStr,
  ) {
    return DynamicPricing.getPricingStream().map((pricing) {
      try {
        final packageType = PackageType.fromString(packageTypeStr);
        final packages = AppConstants.packages[suiteType] ?? [];
        final defaultPackage = packages.firstWhere(
          (p) => p.type == packageType,
        );

        // Map pricing config to package price
        double price;

        switch (suiteType.toLowerCase()) {
          case 'dental':
            if (packageTypeStr == 'starter') {
              price = pricing.dentalStarterPrice;
            } else if (packageTypeStr == 'advanced') {
              price = pricing.dentalAdvancedPrice;
            } else {
              price = pricing.dentalProfessionalPrice;
            }
            break;
          case 'medical':
            if (packageTypeStr == 'starter') {
              price = pricing.medicalStarterPrice;
            } else if (packageTypeStr == 'advanced') {
              price = pricing.medicalAdvancedPrice;
            } else {
              price = pricing.medicalProfessionalPrice;
            }
            break;
          case 'aesthetic':
            if (packageTypeStr == 'starter') {
              price = pricing.aestheticStarterPrice;
            } else if (packageTypeStr == 'advanced') {
              price = pricing.aestheticAdvancedPrice;
            } else {
              price = pricing.aestheticProfessionalPrice;
            }
            break;
          default:
            price = defaultPackage.price;
        }

        return Package(
          type: defaultPackage.type,
          name: defaultPackage.name,
          price: price,
          hours: defaultPackage.hours,
          features: defaultPackage.features,
          popular: defaultPackage.popular,
        );
      } catch (e) {
        debugPrint('⚠️ Error in package stream, using default: $e');
        final packageType = PackageType.fromString(packageTypeStr);
        final packages = AppConstants.packages[suiteType] ?? [];
        return packages.firstWhere((p) => p.type == packageType);
      }
    });
  }

  /// Get all packages for a suite as a stream (real-time updates)
  static Stream<List<Package>> getPackagesForSuiteStream(String suiteType) {
    return DynamicPricing.getPricingStream().map((pricing) {
      try {
        final defaultPackages = AppConstants.packages[suiteType] ?? [];
        final livePackages = <Package>[];

        for (final pkg in defaultPackages) {
          double price;

          switch (suiteType.toLowerCase()) {
            case 'dental':
              if (pkg.type == PackageType.starter) {
                price = pricing.dentalStarterPrice;
              } else if (pkg.type == PackageType.advanced) {
                price = pricing.dentalAdvancedPrice;
              } else {
                price = pricing.dentalProfessionalPrice;
              }
              break;
            case 'medical':
              if (pkg.type == PackageType.starter) {
                price = pricing.medicalStarterPrice;
              } else if (pkg.type == PackageType.advanced) {
                price = pricing.medicalAdvancedPrice;
              } else {
                price = pricing.medicalProfessionalPrice;
              }
              break;
            case 'aesthetic':
              if (pkg.type == PackageType.starter) {
                price = pricing.aestheticStarterPrice;
              } else if (pkg.type == PackageType.advanced) {
                price = pricing.aestheticAdvancedPrice;
              } else {
                price = pricing.aestheticProfessionalPrice;
              }
              break;
            default:
              price = pkg.price;
          }

          livePackages.add(
            Package(
              type: pkg.type,
              name: pkg.name,
              price: price,
              hours: pkg.hours,
              features: pkg.features,
              popular: pkg.popular,
            ),
          );
        }

        return livePackages;
      } catch (e) {
        debugPrint('⚠️ Error in packages stream, using defaults: $e');
        return AppConstants.packages[suiteType] ?? [];
      }
    });
  }

  /// Get addon as a stream (real-time updates)
  static Stream<Addon> getAddonStream(String addonCode) {
    return DynamicPricing.getPricingStream().map((pricing) {
      try {
        // Find addon in both monthly and hourly lists
        Addon? defaultAddon;

        try {
          defaultAddon = AppConstants.monthlyAddons.firstWhere(
            (a) => a.code == addonCode,
          );
        } catch (_) {
          defaultAddon = AppConstants.hourlyAddons.firstWhere(
            (a) => a.code == addonCode,
          );
        }

        // Map pricing config to addon price
        double price;

        switch (addonCode) {
          // Monthly add-ons
          case 'extra_10_hours':
            price = pricing.extra10HoursPrice;
            break;
          case 'dedicated_locker':
            price = pricing.dedicatedLockerPrice;
            break;
          case 'clinical_assistant':
            price = pricing.clinicalAssistantPrice;
            break;
          case 'social_media':
            price = pricing.socialMediaHighlightPrice;
            break;
          // Hourly add-ons
          case 'dental_assistant':
            price = pricing.dentalAssistantPrice;
            break;
          case 'medical_nurse':
            price = pricing.medicalNursePrice;
            break;
          case 'intraoral_xray':
            price = pricing.intraoralXrayPrice;
            break;
          case 'priority_booking':
            price = pricing.priorityBookingPrice;
            break;
          case 'extended_hours':
            price = pricing.extendedHoursPrice;
            break;
          default:
            price = defaultAddon.price;
        }

        return Addon(
          name: defaultAddon.name,
          description: defaultAddon.description,
          price: price,
          code: defaultAddon.code,
        );
      } catch (e) {
        debugPrint('⚠️ Error in addon stream, using default: $e');
        Addon? defaultAddon;
        try {
          defaultAddon = AppConstants.monthlyAddons.firstWhere(
            (a) => a.code == addonCode,
          );
        } catch (_) {
          defaultAddon = AppConstants.hourlyAddons.firstWhere(
            (a) => a.code == addonCode,
          );
        }
        return defaultAddon;
      }
    });
  }

  /// Get all monthly addons as a stream (real-time updates)
  static Stream<List<Addon>> getMonthlyAddonsStream() {
    return DynamicPricing.getPricingStream().map((pricing) {
      try {
        return AppConstants.monthlyAddons.map((addon) {
          double price;

          switch (addon.code) {
            case 'extra_10_hours':
              price = pricing.extra10HoursPrice;
              break;
            case 'dedicated_locker':
              price = pricing.dedicatedLockerPrice;
              break;
            case 'clinical_assistant':
              price = pricing.clinicalAssistantPrice;
              break;
            case 'social_media':
              price = pricing.socialMediaHighlightPrice;
              break;
            default:
              price = addon.price;
          }

          return Addon(
            name: addon.name,
            description: addon.description,
            price: price,
            code: addon.code,
          );
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Error in monthly addons stream, using defaults: $e');
        return AppConstants.monthlyAddons;
      }
    });
  }

  /// Get all hourly addons as a stream (real-time updates)
  static Stream<List<Addon>> getHourlyAddonsStream() {
    return DynamicPricing.getPricingStream().map((pricing) {
      try {
        return AppConstants.hourlyAddons.map((addon) {
          double price;

          switch (addon.code) {
            case 'dental_assistant':
              price = pricing.dentalAssistantPrice;
              break;
            case 'medical_nurse':
              price = pricing.medicalNursePrice;
              break;
            case 'intraoral_xray':
              price = pricing.intraoralXrayPrice;
              break;
            case 'priority_booking':
              price = pricing.priorityBookingPrice;
              break;
            case 'extended_hours':
              price = pricing.extendedHoursPrice;
              break;
            default:
              price = addon.price;
          }

          return Addon(
            name: addon.name,
            description: addon.description,
            price: price,
            code: addon.code,
          );
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Error in hourly addons stream, using defaults: $e');
        return AppConstants.hourlyAddons;
      }
    });
  }
}
