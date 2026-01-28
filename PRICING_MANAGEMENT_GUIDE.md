# 💰 Pricing Management System - Complete Guide

## Overview

Admin panel mein ek naya **Pricing Management** tab add kiya gaya hai jahan se admin saari prices ko ek jagah se change kar sakta hai:

✅ **Suite Hourly Rates** - Dental, Medical, Aesthetic (General & Specialist)  
✅ **Monthly Package Prices** - Starter, Advanced, Professional (har suite ke liye)  
✅ **Monthly Add-ons** - Extra hours, locker, assistant, social media  
✅ **Hourly Add-ons** - Dental assistant, nurse, x-ray, priority booking, extended hours  

---

## 🎯 Key Features

### 1. **Centralized Price Management**
- Saari prices ek screen par
- Real-time updates
- Easy to use interface
- Mobile responsive design

### 2. **Dynamic Pricing**
- Prices Firestore database mein store hoti hain
- Admin panel se change karne par automatically update ho jati hain
- Caching system for better performance
- No app restart needed

### 3. **Comprehensive Coverage**
```
📊 Total Price Points: 28
├── Suite Base Rates: 6 (3 suites × 2 rates each)
├── Monthly Packages: 9 (3 suites × 3 packages each)
├── Monthly Add-ons: 4
└── Hourly Add-ons: 5
```

---

## 📁 Files Created

### 1. **Models**
```
lib/features/admin/models/pricing_config_model.dart
```
- `PricingConfig` class with all pricing fields
- Firestore serialization/deserialization
- Default pricing configuration

### 2. **Services**
```
lib/features/admin/services/pricing_service.dart
```
- `getCurrentPricing()` - Fetch current prices
- `updatePricing()` - Update all prices
- `initializeDefaultPricing()` - Setup initial prices
- `pricingStream()` - Real-time price updates

### 3. **UI Components**
```
lib/features/admin/tabs/pricing_management_tab.dart
```
- Complete pricing management interface
- Organized sections for different price types
- Input validation
- Save/update functionality

### 4. **Utilities**
```
lib/core/utils/dynamic_pricing.dart
```
- Helper class for fetching prices
- Caching mechanism (5-minute cache)
- Convenient methods for price lookup

---

## 🚀 How to Use

### **Admin Panel Access**

1. Admin dashboard mein login karein
2. Menu se **"Pricing"** tab select karein
3. Saari prices edit karein
4. **"Save All Changes"** button press karein
5. Success message confirm karega

### **Price Updates Take Effect Immediately**
- No app restart needed
- Existing bookings NOT affected
- New bookings use updated prices

---

## 💻 Developer Guide

### **Fetching Dynamic Prices in Code**

#### Method 1: Simple Price Lookup
```dart
import 'package:sehat_makaan_flutter/core/utils/dynamic_pricing.dart';

// Get dental base rate
final dentalRate = await DynamicPricing.getDentalBaseRate();

// Get package price
final starterPrice = await DynamicPricing.getPackagePrice('dental', 'starter');

// Get addon price
final priorityPrice = await DynamicPricing.getAddonPrice('priority_booking');
```

#### Method 2: Suite Rate with Specialist Check
```dart
// Get rate based on suite type and specialty
final rate = await DynamicPricing.getSuiteRate(
  'dental',
  isSpecialist: true, // true for specialist rate
);
```

#### Method 3: Bulk Operations
```dart
// Get all suite rates at once
final allRates = await DynamicPricing.getAllSuiteRates();
print(allRates['dental']['base']); // Dental base rate
print(allRates['medical']['specialist']); // Medical specialist rate

// Get all package prices
final packages = await DynamicPricing.getAllPackagePrices();
print(packages['aesthetic']['professional']); // Aesthetic professional price

// Get all addon prices
final addons = await DynamicPricing.getAllAddonPrices();
print(addons['priority_booking']); // Priority booking price
```

#### Method 4: Real-time Updates
```dart
// Listen to price changes
StreamBuilder<PricingConfig>(
  stream: DynamicPricing.getPricingStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final config = snapshot.data!;
      return Text('Dental Rate: PKR ${config.dentalBaseRate}');
    }
    return CircularProgressIndicator();
  },
)
```

### **Cache Management**

```dart
// Clear cache to force fresh data
DynamicPricing.clearCache();

// Next call will fetch from Firestore
final freshRate = await DynamicPricing.getDentalBaseRate();
```

---

## 🗄️ Database Structure

### **Firestore Collection: `pricing_config`**

```javascript
pricing_config/current_pricing
{
  // Suite Hourly Rates
  dentalBaseRate: 1500,
  dentalSpecialistRate: 3000,
  medicalBaseRate: 2000,
  medicalSpecialistRate: 0,
  aestheticBaseRate: 3000,
  aestheticSpecialistRate: 0,
  
  // Dental Packages
  dentalStarterPrice: 25000,
  dentalAdvancedPrice: 30000,
  dentalProfessionalPrice: 35000,
  
  // Medical Packages
  medicalStarterPrice: 20000,
  medicalAdvancedPrice: 25000,
  medicalProfessionalPrice: 30000,
  
  // Aesthetic Packages
  aestheticStarterPrice: 30000,
  aestheticAdvancedPrice: 35000,
  aestheticProfessionalPrice: 40000,
  
  // Monthly Add-ons
  extra10HoursPrice: 10000,
  dedicatedLockerPrice: 2000,
  clinicalAssistantPrice: 5000,
  socialMediaHighlightPrice: 3000,
  
  // Hourly Add-ons
  dentalAssistantPrice: 500,
  medicalNursePrice: 500,
  intraoralXrayPrice: 300,
  priorityBookingPrice: 500,
  extendedHoursPrice: 500,
  
  // Metadata
  updatedAt: Timestamp,
  updatedBy: "admin_user_id"
}
```

---

## 🔧 Setup Instructions

### **1. Initialize Default Pricing (One-time)**

Run this once to create the pricing configuration in Firestore:

```dart
import 'package:sehat_makaan_flutter/features/admin/services/pricing_service.dart';

void initializePricing() async {
  final pricingService = PricingService();
  await pricingService.initializeDefaultPricing();
  print('✅ Default pricing initialized');
}
```

### **2. Firestore Security Rules**

Add to your `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Pricing configuration - read by all, write by admin only
    match /pricing_config/{document=**} {
      allow read: if true; // Everyone can read prices
      allow write: if request.auth != null && 
                   get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### **3. Admin Navigation Update**

Already implemented! Admin dashboard mein:
- ✅ Import added
- ✅ Menu item added
- ✅ Route handler added

---

## 📊 Price Categories Detail

### **Suite Hourly Base Rates**
```
🦷 Dental Suite
   ├── General Rate: PKR 1,500/hour
   └── Specialist Rate: PKR 3,000/hour

🩺 Medical Suite
   ├── General Rate: PKR 2,000/hour
   └── Specialist Rate: PKR 0/hour (not applicable)

✨ Aesthetic Suite
   ├── General Rate: PKR 3,000/hour
   └── Specialist Rate: PKR 0/hour (not applicable)
```

### **Monthly Packages**
```
📦 Dental Packages
   ├── Starter (10 hours): PKR 25,000
   ├── Advanced (20 hours): PKR 30,000
   └── Professional (40 hours): PKR 35,000

📦 Medical Packages
   ├── Starter (10 hours): PKR 20,000
   ├── Advanced (20 hours): PKR 25,000
   └── Professional (40 hours): PKR 30,000

📦 Aesthetic Packages
   ├── Starter (10 hours): PKR 30,000
   ├── Advanced (20 hours): PKR 35,000
   └── Professional (40 hours): PKR 40,000
```

### **Add-ons**
```
➕ Monthly Add-ons
   ├── Extra 10 Hour Block: PKR 10,000
   ├── Dedicated Locker: PKR 2,000
   ├── Clinical Assistant: PKR 5,000
   └── Social Media Highlight: PKR 3,000

⏱️ Hourly Add-ons
   ├── Dental Assistant (30 mins): PKR 500
   ├── Medical Nurse (30 mins): PKR 500
   ├── Intraoral X-ray Use: PKR 300
   ├── Priority Booking: PKR 500
   └── Extended Hours (+30 mins): PKR 500
```

---

## 🎨 UI Features

### **Organized Sections**
- Color-coded categories
- Icon indicators
- Clear labels
- Easy navigation

### **Input Validation**
- Number-only input
- PKR currency prefix
- No decimal points (whole numbers)
- Required field validation

### **Responsive Design**
- Mobile-friendly layout
- Tablet optimization
- Desktop full-screen experience

### **Save Functionality**
- Single save button for all changes
- Loading state during save
- Success/error notifications
- Last updated timestamp

---

## ⚠️ Important Notes

### **Backward Compatibility**
- Existing hardcoded prices in `AppConstants` still work
- Gradual migration recommended
- Use `DynamicPricing` for new features

### **Performance**
- 5-minute caching reduces database calls
- Stream subscriptions for real-time needs
- Efficient bulk operations available

### **Error Handling**
- Returns default prices if Firestore unavailable
- Graceful fallbacks
- User-friendly error messages

### **Security**
- Only admins can update prices
- All users can read prices
- Audit trail with `updatedBy` field

---

## 🔄 Migration Guide

### **Updating Existing Code**

**Before:**
```dart
final suite = AppConstants.suites.firstWhere((s) => s.type == suiteType);
final price = suite.baseRate;
```

**After:**
```dart
final price = await DynamicPricing.getSuiteRate(suiteType);
```

**Before:**
```dart
final pkg = AppConstants.packages['dental']!
    .firstWhere((p) => p.type == PackageType.starter);
final price = pkg.price;
```

**After:**
```dart
final price = await DynamicPricing.getPackagePrice('dental', 'starter');
```

---

## 📝 Testing Checklist

- [ ] Admin can access Pricing tab
- [ ] All 28 price fields are editable
- [ ] Save button updates Firestore
- [ ] Success message displays on save
- [ ] Prices persist after reload
- [ ] Last updated timestamp shows
- [ ] Mobile layout works correctly
- [ ] Input validation prevents invalid data
- [ ] Cache clears after save
- [ ] Real-time stream receives updates

---

## 🎯 Future Enhancements

1. **Price History**
   - Track price changes over time
   - Audit log for compliance
   - Rollback to previous prices

2. **Bulk Import/Export**
   - CSV upload for bulk updates
   - Export current pricing
   - Template downloads

3. **Scheduled Price Changes**
   - Set future price changes
   - Seasonal pricing
   - Promotional rates

4. **Price Rules**
   - Minimum/maximum bounds
   - Percentage-based adjustments
   - Tiered pricing logic

5. **Analytics**
   - Price change impact analysis
   - Revenue projections
   - Popular package insights

---

## ✅ Summary

Pricing Management system fully implemented aur ready hai!

**What You Can Do:**
- ✅ Change all prices from admin panel
- ✅ View last update time
- ✅ Real-time price synchronization
- ✅ Easy-to-use interface
- ✅ Mobile responsive

**Files Modified:**
- ✅ Admin dashboard navigation updated
- ✅ New pricing tab added
- ✅ Services and models created
- ✅ Utility helper implemented

**Next Steps:**
1. Test the pricing tab in admin panel
2. Initialize default pricing in Firestore
3. Update Firestore security rules
4. Gradually migrate existing code to use DynamicPricing

---

## 📞 Support

Agar koi issue ho ya questions hain toh:
1. Check error messages in console
2. Verify Firestore connection
3. Ensure admin permissions
4. Check this documentation

---

**Created:** January 28, 2026  
**Status:** ✅ Complete and Ready to Use  
**Version:** 1.0.0
