# 🧪 Creator Command Hub - Testing Guide

## Quick Test Checklist

### 1. **Before Admin Approval** ❌

**Expected UI State:**
- ✅ Book Slot button → Available + Functional
- ✅ View Bookings button → Available + Functional  
- ✅ Create Workshop button → Shows "Request Creator Access"
- ❌ Creator Command Hub → Hidden (stats cards not shown)

**How to Test:**
```
1. Open app with non-creator user
2. Look for 3 action buttons
3. Verify "Request Creator Access" is shown
4. Verify Creator Command Hub is NOT visible
5. Tap "Request Creator Access"
6. Verify request form appears
```

---

### 2. **Request Pending** ⏳

**Expected UI State:**
- ✅ Create Workshop button → Shows "Request Pending" (disabled)
- ❌ Creator Command Hub → Still hidden

**How to Test:**
```
1. Submit creator access request
2. Watch debug logs for: _hasPendingCreatorRequest = true
3. Verify button text changes to "Request Pending"
4. Try tapping button
5. Verify snackbar: "Your workshop creator request is pending admin approval"
```

---

### 3. **After Admin Approval** ✅

**Expected UI State:**
- ✅ Create Workshop button → Shows "Create Workshop" (enabled, green)
- ✅ Creator Command Hub → Appears with 3 stat cards
  - 💰 Total Revenue (Gold card)
  - 📋 Pending Requests (Orange card)
  - ⭐ Platform Score (Teal card)
- ✅ Real-time listeners activated
- ✅ Debug log: "🎉 User is now a workshop creator!"
- ✅ Green snackbar notification

**How to Test:**
```
1. In Firebase Console → Firestore → Add document to workshop_creators
   {
     "userId": "test_user_id",
     "isActive": true,
     "approvedAt": "<timestamp>"
   }

2. Watch app for:
   - Green snackbar notification
   - Creator Command Hub appears
   - Create Workshop button changes to green
   - Debug log: "🎉 User is now a workshop creator!"

3. Verify stats show:
   - Total Revenue: "PKR 0" (if no payouts)
   - Pending Requests: "0" (if no pending)
   - Platform Score: "85%" (base score)
```

---

### 4. **Real-Time Stats Updates** 🔄

#### Test: Revenue Updates

**Setup:**
- Creator user approved (from test #3)
- Creator has made at least 1 payout

**Expected Behavior:**
1. Add new document to `workshop_payouts` collection:
```json
{
  "creatorId": "<creator_user_id>",
  "status": "released",
  "netAmount": 1500,
  "createdAt": "<timestamp>"
}
```

2. **Immediate Update Expected:**
   - Total Revenue card updates instantly
   - Debug log: "💰 Real-time: Payouts changed"
   - Debug log: "✅ Creator stats updated successfully!"

**How to Test:**
```
1. Open app on creator account (approved)
2. Verify initial Total Revenue (e.g., "PKR 0")
3. Open Firebase Console
4. Add new payout document with status "released"
5. Watch app - Total Revenue should update within 1 second
6. Check logs for "💰 Real-time: Payouts changed"
```

---

#### Test: Pending Requests Updates

**Setup:**
- Creator user approved
- Creator has created at least 1 workshop

**Expected Behavior:**
1. Add new document to `workshop_registrations`:
```json
{
  "workshopId": "<workshop_id>",
  "userId": "<participant_user_id>",
  "approvalStatus": "pending_creator",
  "createdAt": "<timestamp>"
}
```

2. **Immediate Updates Expected:**
   - Pending Requests count increases
   - Card starts pulsing (if count > 0)
   - Debug log: "📋 Real-time: Workshop registrations changed"
   - Debug log: "✅ Creator stats updated successfully!"
   - Platform Score increases (+5 bonus for having registrations)

**How to Test:**
```
1. Open app on creator account
2. Verify initial Pending Requests: "0"
3. Verify Platform Score (base should be 85)
4. Open Firebase Console
5. Add new workshop_registrations doc with approvalStatus: "pending_creator"
6. Watch app - Pending Requests count should increase within 1 second
7. Watch Platform Score - should increase by 5
8. Verify card pulses
9. Check logs for "📋 Real-time: Workshop registrations changed"
```

---

### 5. **Button Navigation** 🔘

#### Button 1: Book Slot
```
Tap "Book Slot" button
Expected: Navigate to `/live-slot-booking`
```

#### Button 2: View Bookings  
```
Tap "View Bookings" button
Expected: Navigate to `/my-schedule`
```

#### Button 3: Create Workshop
```
Tap "Create Workshop" button (only if approved)
Expected: Navigate to `/create-workshop`
With arguments: userSession data passed
```

**How to Test:**
```
1. Tap each button
2. Verify correct navigation
3. Verify userSession passed correctly
4. Tap back to return to dashboard
```

---

### 6. **Platform Score Calculation** ⭐

**Scoring System:**
```
Base: 85 points

+ Completed Workshops:
  - 2 points each (max +10)
  - Need 0-5 completed workshops

+ Total Registrations:
  - +5 if > 0 registrations

+ Revenue Thresholds:
  - > 100k: +5 points
  - > 50k: +3 points  
  - > 10k: +1 point

Final: Clamped to 85-100
```

**Test Cases:**

**Case 1: Base Creator (No Activity)**
```
Setup: Just approved, no activity
Expected: 85% (base score)
Verify: Debug log shows "Platform Score: 85"
```

**Case 2: With Registrations**
```
Setup: 2+ registrations
Expected: 85 + 5 = 90%
Verify: Debug log shows "+5 for registrations"
```

**Case 3: With Completed Workshops**
```
Setup: 3 completed workshops
Expected: 85 + (3*2) = 91%
Verify: Debug log shows "+6 for workshops"
```

**Case 4: With High Revenue**
```
Setup: 150,000 PKR revenue
Expected: 85 + 5 (revenue) + 5 (registrations) + X (workshops)
Verify: Debug log shows "+5 for revenue > 100k"
```

**Case 5: Maximum Score**
```
Setup: 5+ completed workshops, registrations, 100k+ revenue
Expected: 100% (capped)
Verify: Score never exceeds 100
```

---

### 7. **Error Cases** ⚠️

#### No Payouts Yet
```
Creator approved but no payouts
Expected: Total Revenue = "PKR 0"
Verify: No errors in logs, stats update when first payout released
```

#### No Active Workshops
```
Creator approved but no workshops created
Expected: Pending Requests = "0"
Verify: Stats load without errors
```

#### Multiple Workshops with Pending Requests
```
Setup: Creator has 3 active workshops with:
  - Workshop 1: 2 pending requests
  - Workshop 2: 3 pending requests
  - Workshop 3: 0 pending requests
Expected: Pending Requests = "5"
Verify: Sum counts from all workshops
```

#### Listener Cleanup (Memory Leaks)
```
1. Approve as creator (listeners start)
2. Unapprove/Remove from workshop_creators
3. Navigate away from dashboard
4. Return to dashboard
Expected: 
  - Old listeners cancelled
  - New listeners created
  - No duplicate listeners
Verify: 
  - Check logs for listener setup/cleanup
  - Monitor memory in Android Studio
```

---

### 8. **UI/UX Tests** 🎨

#### Animation
```
Open dashboard → Creator is approved
Expected: 
- Stats cards fade in smoothly
- Staggered animation (each card slightly delayed)
- Duration: ~600ms total

Verify: Smooth, not jarring
```

#### Responsiveness
```
Open dashboard on different screen sizes:
- Mobile (small)
- Tablet (medium)
- Desktop (large)

Expected:
- Stats cards scroll horizontally on mobile
- Grid layout adjusts on tablet/desktop
- All buttons readable and tappable
```

#### Loading States
```
Open app as creator for first time
Expected:
- Brief loading state
- Stats appear after Firestore queries complete
- No blank cards

Verify: Smooth loading experience
```

---

## 🔍 Debug Logs to Monitor

When testing, watch for these logs in `flutter logs`:

### Successful State Transitions:
```
🔷 Dashboard initState - userId: user123
💎 Loading Creator Stats for user: user123
💰 Found 2 released payouts
💰 Total Revenue: PKR 3500
📚 Creator has 2 active workshops  
📋 Total Pending Requests: 1
⭐ Platform Score: 91 (completed: 1, registrations: 1, revenue: PKR3500)
✅ Creator stats updated successfully!
```

### Real-Time Listener Activations:
```
💎 Setting up creator stats real-time listeners...
💰 Real-time: Payouts changed (2 released payouts)
📋 Real-time: Workshop registrations changed (4 total)
```

### Approval Event:
```
🎉 User is now a workshop creator!
```

---

## 📋 Test Matrix

| Feature | Test | Status |
|---------|------|--------|
| Not Approved State | Shows "Request Access" | ✅ |
| Pending State | Shows "Request Pending" | ✅ |
| Approved State | Shows "Create Workshop" | ✅ |
| Creator Command Hub | Appears when approved | ✅ |
| Total Revenue | Calculates from payouts | ✅ |
| Pending Requests | Counts from registrations | ✅ |
| Platform Score | Multi-factor calculation | ✅ |
| Revenue Real-time | Updates on payout change | ✅ |
| Pending Real-time | Updates on registration change | ✅ |
| Score Real-time | Updates when stats change | ✅ |
| Button Navigation | All 3 buttons navigate | ✅ |
| Error Handling | No crashes on empty data | ✅ |
| Memory Cleanup | Listeners cancelled on dispose | ✅ |

---

## 🎯 Quick Test Commands

**Check for compilation errors:**
```bash
flutter analyze lib/features/subscriptions/screens/dashboard_page.dart
```

**Run the app:**
```bash
flutter run
```

**View logs:**
```bash
flutter logs
```

**Format code:**
```bash
dart format lib/features/subscriptions/screens/dashboard_page.dart
```

---

**All tests should pass for production deployment** ✅
