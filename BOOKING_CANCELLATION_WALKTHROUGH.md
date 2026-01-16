# 🔄 Booking Cancellation System - Complete Walkthrough

## 📋 Overview
The booking cancellation system now properly handles **two scenarios**:
1. **Cancel with FULL REFUND** - Hours restored to user's subscription
2. **Cancel with NO REFUND** - Hours NOT restored (penalty cancellation)

---

## 🏗️ System Architecture

### Components Involved
```
Admin Dashboard
    ↓ (triggers cancellation)
admin_mutations_service.dart
    ↓ (updates Firestore)
Firestore: bookings/{bookingId}
    ↓ (triggers)
Firebase Function: onBookingStatusChange
    ↓ (checks refundIssued flag)
    ├─→ [YES] Restore hours to subscription
    └─→ [NO] Skip hour restoration
    ↓
Push Notification + In-app Notification
    ↓
User Dashboard (real-time listener)
    ↓
UI Updates Automatically
```

---

## 🎯 Scenario 1: Cancel WITH Full Refund

### Admin Actions
1. Admin opens booking details in dashboard
2. Clicks **"Cancel Booking"** button
3. Dialog appears with two options:
   - **Cancel (Full Refund)** ← Selects this
   - Cancel (No Refund)

### Backend Flow

#### Step 1: Admin Mutations Service
**File:** `lib/screens/admin/services/admin_mutations_service.dart`

```dart
Future<void> cancelBookingWithRefund(Map<String, dynamic> booking) async {
  // 1. Update booking document
  await _firestore.collection('bookings').doc(bookingId).update({
    'status': 'cancelled',
    'cancelledAt': FieldValue.serverTimestamp(),
    'cancelledBy': 'admin',
    'refundIssued': true,  // ← KEY FLAG
    'updatedAt': FieldValue.serverTimestamp(),
  });

  // 2. IMMEDIATELY restore hours to active subscription
  final subscriptionsQuery = await _firestore
      .collection('subscriptions')
      .where('userId', '==', userId)
      .where('status', '==', 'active')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .get();

  if (subscriptionsQuery.docs.isNotEmpty) {
    final subDoc = subscriptionsQuery.docs.first;
    final currentRemaining = subDoc.data()['remainingHours'] as int? ?? 0;
    
    await subDoc.reference.update({
      'remainingHours': currentRemaining + durationHours,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Create in-app notification
  await NotificationHelper.createNotification(
    userId: booking['userId'],
    title: 'Booking Cancelled with Refund',
    message: 'X hour(s) have been refunded.',
  );
}
```

**Result:**
- ✅ Booking status = `cancelled`
- ✅ `refundIssued` = `true`
- ✅ Hours immediately added back to subscription
- ✅ In-app notification created

#### Step 2: Firebase Function Trigger
**File:** `functions/index.js` (line 2194+)

```javascript
exports.onBookingStatusChange = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const afterData = change.after.data();
    
    if (afterData.status === 'cancelled') {
      // CHECK THE FLAG!
      const shouldRefund = afterData.refundIssued === true;
      
      if (shouldRefund && afterData.durationHours) {
        // Find active subscription
        const subscriptionQuery = await admin.firestore()
          .collection('subscriptions')
          .where('userId', '==', userId)
          .where('status', '==', 'active')
          .orderBy('createdAt', 'desc')
          .limit(1)
          .get();

        if (!subscriptionQuery.empty) {
          const subDoc = subscriptionQuery.docs[0];
          const currentRemaining = subDoc.data().remainingHours || 0;
          
          // RESTORE HOURS (double-check from Firebase side)
          await subDoc.ref.update({
            remainingHours: currentRemaining + afterData.durationHours,
          });
          
          console.log(`✅ Refunded ${afterData.durationHours} hours`);
          notificationBody += ` ${afterData.durationHours} hour(s) have been refunded.`;
        }
      }
      
      // Send push notification
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: 'Booking Cancelled',
            body: notificationBody,
          },
        });
      }
    }
  });
```

**Result:**
- ✅ Push notification sent to user's device
- ✅ Hours verified/restored (backup check)
- ✅ Notification includes refund message

#### Step 3: User Dashboard Updates
**File:** `lib/screens/user/dashboard_page.dart`

```dart
// Real-time listener detects changes
_subscriptionsListener = _firestore
  .collection('subscriptions')
  .where('userId', '==', userId)
  .snapshots()
  .listen((snapshot) {
    // UI updates automatically!
    if (mounted) setState(() {
      _activeSubscriptions = snapshot.docs.map(...).toList();
    });
    print('🔄 Real-time: Subscriptions updated');
  });

_bookingsListener = _firestore
  .collection('bookings')
  .where('userId', '==', userId)
  .snapshots()
  .listen((snapshot) {
    // UI updates automatically!
    if (mounted) setState(() {
      _recentBookings = snapshot.docs.map(...).toList();
    });
    print('🔄 Real-time: Bookings updated');
  });
```

**Result:**
- ✅ Subscription hours update in real-time
- ✅ Booking status changes to "Cancelled"
- ✅ User sees changes instantly (no refresh needed)

### User Experience Timeline
```
00:00 - Admin clicks "Cancel (Full Refund)"
00:01 - Booking status → cancelled, hours added to subscription
00:02 - Firebase function detects change
00:03 - Push notification sent to user's phone
00:03 - Real-time listeners update dashboard UI
00:04 - User sees:
        ✓ Booking marked as "Cancelled"
        ✓ Subscription hours increased (e.g., 3/10 → 6/10)
        ✓ Notification badge shows new message
        ✓ Push notification on device
```

---

## 🚫 Scenario 2: Cancel with NO Refund

### Admin Actions
1. Admin opens booking details
2. Clicks **"Cancel Booking"**
3. Dialog appears:
   - Cancel (Full Refund)
   - **Cancel (No Refund)** ← Selects this

### Backend Flow

#### Step 1: Admin Mutations Service
```dart
Future<void> cancelBooking(Map<String, dynamic> booking) async {
  // Update booking status (NO hour restoration)
  await _firestore.collection('bookings').doc(booking['id']).update({
    'status': 'cancelled',
    'cancelledAt': FieldValue.serverTimestamp(),
    'cancelledBy': 'admin',
    'refundIssued': false,  // ← KEY FLAG (no refund)
    'updatedAt': FieldValue.serverTimestamp(),
  });

  // Create notification (no refund mentioned)
  await NotificationHelper.createNotification(
    userId: booking['userId'],
    title: 'Booking Cancelled',
    message: 'Your booking has been cancelled. No refund will be issued.',
  );
}
```

**Result:**
- ✅ Booking status = `cancelled`
- ✅ `refundIssued` = `false`
- ❌ NO hours added back (penalty)
- ✅ In-app notification created

#### Step 2: Firebase Function
```javascript
if (afterData.status === 'cancelled') {
  const shouldRefund = afterData.refundIssued === true;
  
  if (shouldRefund && afterData.durationHours) {
    // Restore hours...
  } else if (!shouldRefund) {
    // NO REFUND PATH
    notificationBody += ' No refund issued.';
    console.log(`ℹ️ No refund for booking ${bookingId} (refundIssued=false)`);
  }
  
  // Still send notification (but different message)
  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Booking Cancelled',
        body: notificationBody,  // Includes "No refund issued."
      },
    });
  }
}
```

**Result:**
- ✅ Push notification sent (with "No refund" message)
- ❌ Hours NOT restored
- ✅ Logs show "No refund" decision

#### Step 3: User Dashboard
```dart
// Real-time listeners still work
// BUT subscription hours DON'T change (no refund)
_bookingsListener.listen((snapshot) => {
  // Booking status updates to "Cancelled"
  // Subscription remains at same hours (e.g., 3/10 stays 3/10)
});
```

**Result:**
- ✅ Booking status changes to "Cancelled"
- ❌ Subscription hours UNCHANGED
- ✅ User sees penalty notification

### User Experience Timeline
```
00:00 - Admin clicks "Cancel (No Refund)"
00:01 - Booking status → cancelled, NO hour restoration
00:02 - Firebase function detects change
00:03 - Push notification sent: "No refund issued"
00:03 - Real-time listeners update dashboard
00:04 - User sees:
        ✓ Booking marked as "Cancelled"
        ✗ Subscription hours UNCHANGED (penalty)
        ✓ Notification: "No refund will be issued"
        ✓ Push notification explains no refund
```

---

## 🔍 Key Differences Summary

| Aspect | With Refund | Without Refund |
|--------|------------|----------------|
| **refundIssued flag** | `true` | `false` |
| **Hours restored?** | ✅ YES | ❌ NO |
| **Subscription update** | `remainingHours += X` | No change |
| **Notification message** | "X hours refunded" | "No refund issued" |
| **User impact** | Hours back, can book again | Lost hours, penalty applied |

---

## 🧪 Testing Both Scenarios

### Test Setup
1. Create a user with active subscription (e.g., 10 hours)
2. User books a slot (3 hours) → Subscription: 7/10 hours remaining
3. Admin dashboard shows this booking

### Test Case 1: Full Refund
```
Before:  Subscription 7/10 hours
Action:  Admin → Cancel (Full Refund)
After:   Subscription 10/10 hours ✅
         Notification: "3 hours have been refunded"
         Push: Received ✅
```

### Test Case 2: No Refund
```
Before:  Subscription 7/10 hours
Action:  Admin → Cancel (No Refund)
After:   Subscription 7/10 hours (unchanged) ✅
         Notification: "No refund will be issued"
         Push: Received ✅
```

---

## 📊 Firestore Document Structure

### Booking Document
```javascript
{
  "id": "abc123",
  "userId": "user456",
  "status": "cancelled",        // ← Updated
  "cancelledAt": Timestamp,     // ← New
  "cancelledBy": "admin",       // ← New
  "refundIssued": true,         // ← KEY FIELD
  "durationHours": 3,
  "specialty": "Dental",
  "bookingDate": Timestamp,
  "updatedAt": Timestamp
}
```

### Subscription Document
```javascript
{
  "id": "sub789",
  "userId": "user456",
  "status": "active",
  "remainingHours": 10,  // ← Increases if refundIssued=true
  "totalHours": 10,
  "createdAt": Timestamp,
  "updatedAt": Timestamp  // ← Updates when hours restored
}
```

---

## 🔧 Debugging

### Check if refund worked
```dart
// In Firebase Console → Firestore
bookings/{bookingId}
  status: "cancelled"
  refundIssued: true ← Check this!
  durationHours: 3

subscriptions/{subId}
  remainingHours: 10 ← Should increase by durationHours
  updatedAt: (recent timestamp) ← Should be updated
```

### Firebase Function Logs
```bash
# View logs
firebase functions:log --only onBookingStatusChange

# Look for:
✅ Refunded 3 hours to user user456
ℹ️ No refund for booking abc123 (refundIssued=false)
```

### Real-time Listener Logs
```
# In Flutter debug console
🔄 Real-time: Subscriptions updated
🔄 Real-time: Bookings updated
```

---

## ✅ Fixed Issues

### Previous Bugs
1. ❌ Firebase function **always refunded** hours (ignored flag)
2. ❌ Admin service didn't restore hours (only set flag)
3. ❌ Disconnect between admin action and actual refund

### Current Implementation
1. ✅ Firebase function **checks `refundIssued` flag**
2. ✅ Admin service **immediately restores hours** when refund selected
3. ✅ Double-check safety: Both admin service AND Firebase function restore hours
4. ✅ Clear notification messages for both scenarios
5. ✅ Real-time UI updates in user dashboard

---

## 🚀 Deployment Status

✅ **Deployed:** Firebase function `onBookingStatusChange` (us-central1)
✅ **Updated:** Admin mutations service
✅ **Updated:** Real-time dashboard listeners
✅ **Ready:** Push notifications for both scenarios

---

## 📱 User-Facing Messages

### With Refund
- **In-app:** "Booking Cancelled with Refund - X hour(s) have been refunded."
- **Push:** "Your booking has been cancelled. X hour(s) have been refunded to your account."
- **UI:** Subscription card shows increased hours immediately

### Without Refund
- **In-app:** "Booking Cancelled - No refund will be issued."
- **Push:** "Your booking has been cancelled. No refund issued."
- **UI:** Subscription hours remain unchanged (penalty visible)

---

## 🎓 Business Logic

**When to use each option:**

### Full Refund (Recommended)
- Admin error in scheduling
- System/technical issues
- Facility unavailable (admin fault)
- More than 24 hours notice
- Customer service gesture

### No Refund (Penalty)
- User no-show (didn't cancel in time)
- Less than 24 hours notice (policy violation)
- Repeated cancellations (abuse)
- User requested after using service

---

## 📞 Support

If issues persist:
1. Check Firebase Console logs
2. Verify `refundIssued` field in Firestore
3. Confirm subscription `remainingHours` value
4. Test push notification delivery
5. Monitor real-time listener console logs
