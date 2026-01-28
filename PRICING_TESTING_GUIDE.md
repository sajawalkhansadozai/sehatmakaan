# 🧪 Pricing Management - Quick Testing Guide

## Initial Setup (Do This First)

### Step 1: Initialize Default Pricing

Add this to your app's initialization:

```dart
// In main.dart or any initialization file
import 'package:sehat_makaan_flutter/core/utils/pricing_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize pricing (only needed once)
  await PricingInitializer.initializeDefaultPricing();
  
  runApp(MyApp());
}
```

**OR** run in admin panel after first login:

```dart
// One-time setup button in admin panel
ElevatedButton(
  onPressed: () async {
    await PricingInitializer.initializeDefaultPricing();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Pricing initialized!')),
    );
  },
  child: Text('Initialize Pricing'),
)
```

---

## Testing Steps

### ✅ Test 1: Admin Panel Access

1. Login to admin panel
2. Click on menu (3 dots or hamburger icon)
3. Look for **"Pricing"** option
4. Click on "Pricing"

**Expected:** Pricing management screen opens

---

### ✅ Test 2: View Current Prices

**Expected:** You should see 4 sections:
- 🏥 Suite Hourly Base Rates (6 fields)
- 📦 Monthly Package Prices (9 fields)
- ➕ Monthly Package Add-ons (4 fields)
- ⏱️ Hourly Booking Add-ons (5 fields)

**Total:** 28 price fields

---

### ✅ Test 3: Edit Prices

1. Change dental base rate from 1500 to 2000
2. Change dental starter package from 25000 to 27000
3. Change priority booking addon from 500 to 600
4. Click **"Save All Changes"** button

**Expected:**
- ✅ Green success message appears
- ✅ "Last updated" timestamp updates
- ✅ Page refreshes with new values

---

### ✅ Test 4: Verify Firestore

1. Open Firebase Console
2. Go to Firestore Database
3. Look for collection: `pricing_config`
4. Open document: `current_pricing`

**Expected:** You should see all updated prices

---

### ✅ Test 5: Dynamic Price Loading

Create a test widget:

```dart
import 'package:sehat_makaan_flutter/core/utils/dynamic_pricing.dart';

class PriceTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: DynamicPricing.getDentalBaseRate(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('Dental Rate: PKR ${snapshot.data}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

**Expected:** Shows updated price (2000 instead of 1500)

---

### ✅ Test 6: Mobile Responsiveness

1. Resize browser window or use mobile device
2. Open pricing management tab

**Expected:**
- Layout adjusts for mobile
- Price fields stack vertically
- Save button expands to full width
- All fields remain accessible

---

### ✅ Test 7: Input Validation

1. Try to enter letters in a price field
2. Try to enter negative numbers
3. Try to leave a field empty

**Expected:**
- Only numbers allowed
- No letters accepted
- Save validates all fields

---

### ✅ Test 8: Real-time Updates

Open two browser tabs:
- Tab 1: Admin panel pricing page
- Tab 2: Admin panel pricing page

In Tab 1:
1. Change a price
2. Click save

In Tab 2:
**Expected:** Price updates automatically (if using stream)

---

### ✅ Test 9: Cache Testing

```dart
// Test cache behavior
void testCache() async {
  // First call - fetches from Firestore
  final rate1 = await DynamicPricing.getDentalBaseRate();
  print('First call: $rate1');
  
  // Second call - returns cached value (within 5 mins)
  final rate2 = await DynamicPricing.getDentalBaseRate();
  print('Second call (cached): $rate2');
  
  // Clear cache
  DynamicPricing.clearCache();
  
  // Third call - fetches fresh from Firestore
  final rate3 = await DynamicPricing.getDentalBaseRate();
  print('Third call (fresh): $rate3');
}
```

---

### ✅ Test 10: Error Handling

1. Disconnect from internet
2. Try to load pricing page
3. Try to save changes

**Expected:**
- Shows default prices when offline
- Error message on save failure
- Graceful degradation

---

## Quick Verification Commands

### Display All Prices in Console

```dart
import 'package:sehat_makaan_flutter/core/utils/pricing_initializer.dart';

// Call this to see all current prices in console
await PricingInitializer.displayCurrentPricing();
```

### Check Individual Prices

```dart
import 'package:sehat_makaan_flutter/core/utils/dynamic_pricing.dart';

// Suite rates
print(await DynamicPricing.getDentalBaseRate());
print(await DynamicPricing.getMedicalBaseRate());

// Package prices
print(await DynamicPricing.getPackagePrice('dental', 'starter'));
print(await DynamicPricing.getPackagePrice('medical', 'advanced'));

// Addon prices
print(await DynamicPricing.getAddonPrice('priority_booking'));
print(await DynamicPricing.getAddonPrice('extended_hours'));
```

---

## Common Issues & Solutions

### Issue 1: "No pricing config found"
**Solution:** Run `PricingInitializer.initializeDefaultPricing()`

### Issue 2: Prices not updating
**Solution:** 
- Clear cache: `DynamicPricing.clearCache()`
- Check Firestore security rules
- Verify admin permissions

### Issue 3: Save button not working
**Solution:**
- Check console for errors
- Verify Firebase connection
- Ensure admin is logged in

### Issue 4: Fields showing 0 or NaN
**Solution:**
- Check Firestore document structure
- Verify field names match model
- Initialize default pricing

---

## Performance Benchmarks

### Expected Load Times
- Initial pricing load: < 500ms
- Cached price fetch: < 10ms
- Price save operation: < 1s
- Real-time update: < 2s

### Database Calls
- Without cache: 1 call per price fetch
- With cache: 1 call per 5 minutes
- Bulk operations: 1 call for all prices

---

## Security Checklist

- [ ] Only admins can access pricing tab
- [ ] Only admins can update prices
- [ ] All users can read prices
- [ ] Audit trail tracks changes
- [ ] Input validation prevents invalid data

---

## Success Criteria

✅ All 28 price fields editable  
✅ Changes save to Firestore  
✅ Updates reflect immediately  
✅ Mobile layout works  
✅ No console errors  
✅ Cache improves performance  
✅ Real-time updates work  
✅ Audit trail maintained  

---

## Next Steps After Testing

1. ✅ Test all functionality
2. ✅ Verify database updates
3. ✅ Check mobile responsiveness
4. ✅ Update Firestore security rules
5. ✅ Train admin users
6. ✅ Monitor for errors
7. ✅ Plan future enhancements

---

**Testing Complete?** Move to production deployment! 🚀
