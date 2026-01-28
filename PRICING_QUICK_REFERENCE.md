# 💰 Pricing Management - Quick Reference Card

## 🎯 Admin Quick Guide

### Access Pricing Management
```
Login → Menu (☰) → Pricing → Edit → Save
```

### All 28 Prices You Can Change

#### 🏥 Suite Hourly Rates (6)
| Suite Type | Rate Type | Default |
|------------|-----------|---------|
| 🦷 Dental | General | PKR 1,500 |
| 🦷 Dental | Specialist | PKR 3,000 |
| 🩺 Medical | General | PKR 2,000 |
| 🩺 Medical | Specialist | PKR 0 |
| ✨ Aesthetic | General | PKR 3,000 |
| ✨ Aesthetic | Specialist | PKR 0 |

#### 📦 Monthly Packages (9)
| Suite | Package | Hours | Default |
|-------|---------|-------|---------|
| 🦷 Dental | Starter | 10h | PKR 25,000 |
| 🦷 Dental | Advanced | 20h | PKR 30,000 |
| 🦷 Dental | Professional | 40h | PKR 35,000 |
| 🩺 Medical | Starter | 10h | PKR 20,000 |
| 🩺 Medical | Advanced | 20h | PKR 25,000 |
| 🩺 Medical | Professional | 40h | PKR 30,000 |
| ✨ Aesthetic | Starter | 10h | PKR 30,000 |
| ✨ Aesthetic | Advanced | 20h | PKR 35,000 |
| ✨ Aesthetic | Professional | 40h | PKR 40,000 |

#### ➕ Monthly Add-ons (4)
| Add-on | Default |
|--------|---------|
| Extra 10 Hour Block | PKR 10,000 |
| Dedicated Locker | PKR 2,000 |
| Clinical Assistant | PKR 5,000 |
| Social Media Highlight | PKR 3,000 |

#### ⏱️ Hourly Add-ons (5)
| Add-on | Default |
|--------|---------|
| Dental Assistant (30 mins) | PKR 500 |
| Medical Nurse (30 mins) | PKR 500 |
| Intraoral X-ray Use | PKR 300 |
| Priority Booking | PKR 500 |
| Extended Hours (+30 mins) | PKR 500 |

---

## 💻 Developer Quick Reference

### Import
```dart
import 'package:sehat_makaan_flutter/core/utils/dynamic_pricing.dart';
```

### Get Suite Rates
```dart
// Specific suite
final dentalRate = await DynamicPricing.getDentalBaseRate();
final medicalRate = await DynamicPricing.getMedicalBaseRate();
final aestheticRate = await DynamicPricing.getAestheticBaseRate();

// Generic by type
final rate = await DynamicPricing.getSuiteRate('dental', isSpecialist: false);
```

### Get Package Prices
```dart
// Specific package
final price = await DynamicPricing.getPackagePrice('dental', 'starter');
final price = await DynamicPricing.getPackagePrice('medical', 'advanced');
final price = await DynamicPricing.getPackagePrice('aesthetic', 'professional');
```

### Get Add-on Prices
```dart
// Specific addon
final price = await DynamicPricing.getAddonPrice('priority_booking');
final price = await DynamicPricing.getAddonPrice('extended_hours');
final price = await DynamicPricing.getAddonPrice('extra_10_hours');
```

### Bulk Operations
```dart
// Get all suite rates
final allRates = await DynamicPricing.getAllSuiteRates();

// Get all package prices
final allPackages = await DynamicPricing.getAllPackagePrices();

// Get all addon prices
final allAddons = await DynamicPricing.getAllAddonPrices();
```

### Real-time Stream
```dart
Stream<PricingConfig> stream = DynamicPricing.getPricingStream();
```

### Cache Control
```dart
DynamicPricing.clearCache(); // Force fresh fetch
```

---

## 🔧 Setup Commands

### One-time Initialization
```dart
import 'package:sehat_makaan_flutter/core/utils/pricing_initializer.dart';

await PricingInitializer.initializeDefaultPricing();
```

### Display Current Prices (Debug)
```dart
await PricingInitializer.displayCurrentPricing();
```

### Check if Initialized
```dart
bool isReady = await PricingInitializer.isPricingInitialized();
```

---

## 📱 UI Components

### FutureBuilder Pattern
```dart
FutureBuilder<double>(
  future: DynamicPricing.getDentalBaseRate(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('PKR ${snapshot.data}');
    }
    return CircularProgressIndicator();
  },
)
```

### StreamBuilder Pattern
```dart
StreamBuilder<PricingConfig>(
  stream: DynamicPricing.getPricingStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final config = snapshot.data!;
      return Text('PKR ${config.dentalBaseRate}');
    }
    return CircularProgressIndicator();
  },
)
```

---

## 🗄️ Firestore Path

```
Collection: pricing_config
Document: current_pricing
```

### Read from Firestore
```dart
final doc = await FirebaseFirestore.instance
    .collection('pricing_config')
    .doc('current_pricing')
    .get();
```

---

## 🔒 Security Rules

```javascript
match /pricing_config/{document=**} {
  allow read: if true;
  allow write: if request.auth != null && 
               get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
}
```

---

## ⚡ Performance

| Operation | Time |
|-----------|------|
| Cached fetch | ~10ms |
| Fresh fetch | ~500ms |
| Save operation | ~1s |
| Real-time update | ~2s |

**Cache Duration:** 5 minutes

---

## 🎨 Admin UI Sections

```
1. Suite Hourly Base Rates (🏥)
   - 6 editable fields
   
2. Monthly Package Prices (📦)
   - 3 subsections (Dental, Medical, Aesthetic)
   - 9 editable fields total
   
3. Monthly Package Add-ons (➕)
   - 4 editable fields
   
4. Hourly Booking Add-ons (⏱️)
   - 5 editable fields

[Save All Changes Button]
```

---

## ✅ Testing Checklist

- [ ] Initialize default pricing
- [ ] Access pricing tab
- [ ] Edit a price
- [ ] Save changes
- [ ] Verify in Firestore
- [ ] Test dynamic fetch
- [ ] Test cache
- [ ] Test mobile view
- [ ] Test permissions
- [ ] Test real-time updates

---

## 🚨 Common Commands

### Quick Test
```dart
// Test price fetch
print(await DynamicPricing.getDentalBaseRate());

// Test cache clear
DynamicPricing.clearCache();

// Display all prices
await PricingInitializer.displayCurrentPricing();
```

### Emergency Reset
```dart
// Reinitialize to defaults
await PricingInitializer.initializeDefaultPricing();
```

---

## 📊 File Locations

```
Models:
lib/features/admin/models/pricing_config_model.dart

Services:
lib/features/admin/services/pricing_service.dart

UI:
lib/features/admin/tabs/pricing_management_tab.dart

Utils:
lib/core/utils/dynamic_pricing.dart
lib/core/utils/pricing_initializer.dart

Docs:
PRICING_MANAGEMENT_GUIDE.md
PRICING_TESTING_GUIDE.md
PRICING_IMPLEMENTATION_SUMMARY.md
```

---

## 🎯 Quick Examples

### Example 1: Calculate Booking Cost
```dart
final suiteRate = await DynamicPricing.getSuiteRate('dental');
final hours = 3;
final addonPrice = await DynamicPricing.getAddonPrice('priority_booking');

final total = (suiteRate * hours) + addonPrice;
print('Total: PKR $total');
```

### Example 2: Display Package Options
```dart
final starter = await DynamicPricing.getPackagePrice('dental', 'starter');
final advanced = await DynamicPricing.getPackagePrice('dental', 'advanced');
final pro = await DynamicPricing.getPackagePrice('dental', 'professional');

print('Starter: PKR $starter');
print('Advanced: PKR $advanced');
print('Professional: PKR $pro');
```

### Example 3: Admin Price Update
```dart
// In admin panel, user edits field and clicks save
// Service automatically updates Firestore
// All apps see new price within 5 minutes (or immediately if using stream)
```

---

## 📞 Quick Help

**Can't access pricing tab?**
→ Check if logged in as admin

**Prices showing as 0?**
→ Run `PricingInitializer.initializeDefaultPricing()`

**Changes not saving?**
→ Check Firebase connection and admin permissions

**Need fresh prices?**
→ Call `DynamicPricing.clearCache()`

---

**Print This Card & Keep Handy! 📋**

**Last Updated:** January 28, 2026  
**Version:** 1.0.0
