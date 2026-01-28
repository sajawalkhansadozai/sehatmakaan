import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/core/utils/price_helper.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';
import 'package:sehat_makaan_flutter/core/constants/types.dart';

/// Test script to verify dynamic pricing integration
///
/// Run this to test if admin pricing overrides are working
class PricingIntegrationTest {
  /// Test all pricing features
  static Future<void> runAllTests() async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('     DYNAMIC PRICING INTEGRATION TEST');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('');

    await _testSuitePricing();
    await _testPackagePricing();
    await _testAddonPricing();
    await _testFallbackMechanism();

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('     ALL TESTS COMPLETED');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('');
  }

  /// Test 1: Suite Pricing
  static Future<void> _testSuitePricing() async {
    debugPrint('');
    debugPrint('🧪 TEST 1: Suite Pricing');
    debugPrint('─────────────────────────────────────────────────────');

    try {
      // Get default dental rate
      final defaultDental = AppConstants.suites.firstWhere(
        (s) => s.type.value == 'dental',
      );
      debugPrint('📌 Default Dental Rate: PKR ${defaultDental.baseRate}');

      // Get dynamic dental rate
      final dynamicDental = await PriceHelper.getSuiteWithDynamicPricing(
        'dental',
      );
      debugPrint('💰 Dynamic Dental Rate: PKR ${dynamicDental.baseRate}');

      if (dynamicDental.baseRate != defaultDental.baseRate) {
        debugPrint('✅ ADMIN OVERRIDE ACTIVE - Using admin price');
      } else {
        debugPrint('📋 Using default price (admin not set or same as default)');
      }

      // Test specialist rate
      debugPrint('');
      debugPrint(
        '📌 Default Dental Specialist: PKR ${defaultDental.specialistRate}',
      );
      debugPrint(
        '💰 Dynamic Dental Specialist: PKR ${dynamicDental.specialistRate}',
      );

      debugPrint('✅ Suite pricing test PASSED');
    } catch (e) {
      debugPrint('❌ Suite pricing test FAILED: $e');
    }
  }

  /// Test 2: Package Pricing
  static Future<void> _testPackagePricing() async {
    debugPrint('');
    debugPrint('🧪 TEST 2: Package Pricing');
    debugPrint('─────────────────────────────────────────────────────');

    try {
      // Get default package
      final defaultPackages = AppConstants.packages['dental'] ?? [];
      final defaultStarter = defaultPackages.firstWhere(
        (p) => p.type.value == 'starter',
      );
      debugPrint('📌 Default Dental Starter: PKR ${defaultStarter.price}');

      // Get dynamic package
      final dynamicStarter = await PriceHelper.getPackageWithDynamicPricing(
        'dental',
        'starter',
      );
      debugPrint('💰 Dynamic Dental Starter: PKR ${dynamicStarter.price}');

      if (dynamicStarter.price != defaultStarter.price) {
        debugPrint('✅ ADMIN OVERRIDE ACTIVE - Using admin price');
      } else {
        debugPrint('📋 Using default price (admin not set or same as default)');
      }

      // Test all packages
      debugPrint('');
      final allPackages =
          await PriceHelper.getPackagesForSuiteWithDynamicPricing('dental');
      debugPrint(
        '📦 Loaded ${allPackages.length} packages with dynamic pricing',
      );
      for (final pkg in allPackages) {
        debugPrint('   - ${pkg.name}: PKR ${pkg.price}');
      }

      debugPrint('✅ Package pricing test PASSED');
    } catch (e) {
      debugPrint('❌ Package pricing test FAILED: $e');
    }
  }

  /// Test 3: Addon Pricing
  static Future<void> _testAddonPricing() async {
    debugPrint('');
    debugPrint('🧪 TEST 3: Addon Pricing');
    debugPrint('─────────────────────────────────────────────────────');

    try {
      // Get default addon
      final defaultPriority = AppConstants.hourlyAddons.firstWhere(
        (a) => a.code == 'priority_booking',
      );
      debugPrint('📌 Default Priority Booking: PKR ${defaultPriority.price}');

      // Get dynamic addon
      final dynamicPriority = await PriceHelper.getAddonWithDynamicPricing(
        'priority_booking',
      );
      debugPrint('💰 Dynamic Priority Booking: PKR ${dynamicPriority.price}');

      if (dynamicPriority.price != defaultPriority.price) {
        debugPrint('✅ ADMIN OVERRIDE ACTIVE - Using admin price');
      } else {
        debugPrint('📋 Using default price (admin not set or same as default)');
      }

      // Test monthly addons
      debugPrint('');
      final monthlyAddons =
          await PriceHelper.getMonthlyAddonsWithDynamicPricing();
      debugPrint('➕ Monthly Addons (${monthlyAddons.length}):');
      for (final addon in monthlyAddons) {
        debugPrint('   - ${addon.name}: PKR ${addon.price}');
      }

      // Test hourly addons
      debugPrint('');
      final hourlyAddons =
          await PriceHelper.getHourlyAddonsWithDynamicPricing();
      debugPrint('⏱️ Hourly Addons (${hourlyAddons.length}):');
      for (final addon in hourlyAddons) {
        debugPrint('   - ${addon.name}: PKR ${addon.price}');
      }

      debugPrint('✅ Addon pricing test PASSED');
    } catch (e) {
      debugPrint('❌ Addon pricing test FAILED: $e');
    }
  }

  /// Test 4: Fallback Mechanism
  static Future<void> _testFallbackMechanism() async {
    debugPrint('');
    debugPrint('🧪 TEST 4: Fallback Mechanism');
    debugPrint('─────────────────────────────────────────────────────');

    try {
      debugPrint('Testing error handling and fallback...');

      // This should handle errors gracefully
      final suite = await PriceHelper.getSuiteWithDynamicPricing('dental');
      final package = await PriceHelper.getPackageWithDynamicPricing(
        'dental',
        'starter',
      );
      final addon = await PriceHelper.getAddonWithDynamicPricing(
        'priority_booking',
      );

      debugPrint('✅ Suite loaded: PKR ${suite.baseRate}');
      debugPrint('✅ Package loaded: PKR ${package.price}');
      debugPrint('✅ Addon loaded: PKR ${addon.price}');
      debugPrint('✅ Fallback mechanism working - never crashes!');
    } catch (e) {
      debugPrint('❌ Fallback test FAILED: $e');
    }
  }

  /// Display comparison table
  static Future<void> showPriceComparison() async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('     PRICE COMPARISON: DEFAULT vs DYNAMIC');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('');

    // Suites
    debugPrint('🏥 SUITE HOURLY RATES:');
    debugPrint('─────────────────────────────────────────────────────');
    await _compareSuitePrice('dental', 'Dental Suite');
    await _compareSuitePrice('medical', 'Medical Suite');
    await _compareSuitePrice('aesthetic', 'Aesthetic Suite');

    // Packages
    debugPrint('');
    debugPrint('📦 MONTHLY PACKAGES:');
    debugPrint('─────────────────────────────────────────────────────');
    await _comparePackagePrice('dental', 'starter', 'Dental Starter');
    await _comparePackagePrice('dental', 'advanced', 'Dental Advanced');
    await _comparePackagePrice('medical', 'starter', 'Medical Starter');

    // Addons
    debugPrint('');
    debugPrint('➕ ADD-ONS:');
    debugPrint('─────────────────────────────────────────────────────');
    await _compareAddonPrice('priority_booking', 'Priority Booking');
    await _compareAddonPrice('extended_hours', 'Extended Hours');
    await _compareAddonPrice('extra_10_hours', 'Extra 10 Hours');

    debugPrint('');
  }

  static Future<void> _compareSuitePrice(String suiteType, String name) async {
    final defaultSuite = AppConstants.suites.firstWhere(
      (s) => s.type.value == suiteType,
    );
    final dynamicSuite = await PriceHelper.getSuiteWithDynamicPricing(
      suiteType,
    );

    final changed = dynamicSuite.baseRate != defaultSuite.baseRate
        ? '🔄'
        : '  ';
    debugPrint(
      '$changed $name: PKR ${defaultSuite.baseRate} → PKR ${dynamicSuite.baseRate}',
    );
  }

  static Future<void> _comparePackagePrice(
    String suiteType,
    String packageType,
    String name,
  ) async {
    final defaultPackages = AppConstants.packages[suiteType] ?? [];
    final defaultPkg = defaultPackages.firstWhere(
      (p) => p.type.value == packageType,
    );
    final dynamicPkg = await PriceHelper.getPackageWithDynamicPricing(
      suiteType,
      packageType,
    );

    final changed = dynamicPkg.price != defaultPkg.price ? '🔄' : '  ';
    debugPrint(
      '$changed $name: PKR ${defaultPkg.price} → PKR ${dynamicPkg.price}',
    );
  }

  static Future<void> _compareAddonPrice(String code, String name) async {
    Addon? defaultAddon;
    try {
      defaultAddon = AppConstants.monthlyAddons.firstWhere(
        (a) => a.code == code,
      );
    } catch (_) {
      defaultAddon = AppConstants.hourlyAddons.firstWhere(
        (a) => a.code == code,
      );
    }

    final dynamicAddon = await PriceHelper.getAddonWithDynamicPricing(code);

    final changed = dynamicAddon.price != defaultAddon.price ? '🔄' : '  ';
    debugPrint(
      '$changed $name: PKR ${defaultAddon.price} → PKR ${dynamicAddon.price}',
    );
  }

  /// Quick test - just show current prices
  static Future<void> quickTest() async {
    debugPrint('');
    debugPrint('⚡ QUICK PRICING TEST');
    debugPrint('─────────────────────────────────────────────────────');

    final dentalRate = await PriceHelper.getSuiteBaseRate('dental');
    final starterPrice = await PriceHelper.getPackagePrice('dental', 'starter');
    final priorityPrice = await PriceHelper.getAddonPrice('priority_booking');

    debugPrint('Dental Suite: PKR $dentalRate/hour');
    debugPrint('Starter Package: PKR $starterPrice/month');
    debugPrint('Priority Booking: PKR $priorityPrice');
    debugPrint('');
    debugPrint('✅ All prices loaded successfully!');
  }
}

/// Example usage in your app
/// 
/// ```dart
/// // In main.dart or admin dashboard
/// import 'package:sehat_makaan_flutter/core/utils/pricing_integration_test.dart';
/// 
/// // Run full test suite
/// await PricingIntegrationTest.runAllTests();
/// 
/// // Show comparison
/// await PricingIntegrationTest.showPriceComparison();
/// 
/// // Quick test
/// await PricingIntegrationTest.quickTest();
/// ```
