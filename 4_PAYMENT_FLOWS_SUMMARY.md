# 4 Payment Flows - Step by Step

## 1️⃣ PAYMENT: BOOKING (Patient → PayFast → App)

**Who Pays**: Patient/User  
**Amount**: PKR 500-2,000 (doctor consultation)  
**Who Receives**: Doctor (creator of booking)  
**Status**: Direct payment (no admin involvement)

### Step-by-Step Flow:

```
1. Patient clicks "Book Appointment" with Doctor
   ↓
2. Enters payment amount (PKR 500-2000)
   ↓
3. Clicks "Pay Now" button
   ↓
4. Redirected to PayFast checkout page
   ↓
5. PayFast processes payment (card/bank transfer)
   ↓
6. PayFast sends webhook to Firebase:
   POST /payfastWebhook
   
7. Firebase Verifies:
   ✅ MD5 signature matches
   ✅ Amount matches booking (not tampered)
   ✅ Payment ID is new (no duplicates)
   ✅ Status is "00" (success)
   ↓
8. Database Updates:
   Collection: booking_payments
   Document: {paymentId}
   {
     amount_gross: "1000",
     amountReceived: "1000",
     paymentId: "12345-payfast",
     status: "paid",
     paidAt: timestamp,
     bookingId: "booking_123",
     userId: "patient_456"
   }
   
   Collection: bookings
   Document: booking_123
   {
     status: "paid",  // Changed from "pending" to "paid"
     paymentId: "12345-payfast",
     isPaid: true
   }
   ↓
9. Email Sent to Patient:
   Subject: "Appointment Booked!"
   Body: "Your appointment is confirmed. Doctor will see you soon."
   ↓
10. DONE ✅
    Patient can see booking in "My Bookings"
    Doctor can see patient in "Upcoming Appointments"
```

### Database Records Created:
```javascript
// booking_payments collection
{
  amount_gross: 1000,
  amountReceived: 1000,
  paymentId: "12345-payfast",
  status: "paid",
  paidAt: Timestamp(2026, 1, 27),
  bookingId: "booking_123",
  userId: "patient_456"
}

// bookings collection (updated)
{
  id: "booking_123",
  doctorId: "doctor_789",
  userId: "patient_456",
  status: "paid",  // ← Updated
  isPaid: true,    // ← Updated
  appointmentDate: "2026-02-15",
  slot: "10:00 AM",
  paymentId: "12345-payfast",
  amount: 1000
}
```

---

## 2️⃣ PAYMENT: WORKSHOP CREATION (Creator → PayFast → App)

**Who Pays**: Doctor/Creator  
**Amount**: PKR 10,000 (fixed activation fee)  
**Who Receives**: Sehat Makaan (platform)  
**Status**: Workshop gets activated after payment

### Step-by-Step Flow:

```
1. Doctor fills workshop form:
   - Title, description, date, time, price
   - Clicks "Create & Activate Workshop"
   ↓
2. System shows payment prompt:
   "Activation Fee: PKR 10,000"
   ↓
3. Doctor clicks "Pay Activation Fee"
   ↓
4. Redirected to PayFast checkout page
   ↓
5. PayFast processes payment
   ↓
6. PayFast sends webhook to Firebase:
   POST /payfastWorkshopCreationWebhook
   
7. Firebase Verifies:
   ✅ MD5 signature matches
   ✅ Amount is exactly 10,000 (not less/more)
   ✅ Payment ID is new (not duplicate)
   ✅ Status is "00" (success)
   ↓
8. Database Updates:
   Collection: workshop_creation_payments
   Document: {paymentId}
   {
     amount_gross: "10000",
     amountReceived: "10000",
     paymentId: "67890-payfast",
     status: "paid",
     paidAt: timestamp,
     workshopId: "workshop_xyz",
     creatorId: "doctor_789"
   }
   
   Collection: workshops
   Document: workshop_xyz
   {
     status: "active",        // Changed from "draft" to "active"
     isActive: true,
     paymentId: "67890-payfast",
     activatedAt: timestamp
   }
   ↓
9. Email Sent to Creator:
   Subject: "Workshop Activated!"
   Body: "Your workshop is now live. Participants can register now."
   ↓
10. DONE ✅
    Workshop appears in "Available Workshops"
    Participants can register and pay
```

### Database Records Created:
```javascript
// workshop_creation_payments collection
{
  amount_gross: 10000,
  amountReceived: 10000,
  paymentId: "67890-payfast",
  status: "paid",
  paidAt: Timestamp(2026, 1, 27),
  workshopId: "workshop_xyz",
  creatorId: "doctor_789"
}

// workshops collection (updated)
{
  id: "workshop_xyz",
  creatorId: "doctor_789",
  title: "Diabetes Management Workshop",
  description: "Learn to manage diabetes...",
  registrationFee: 1000,
  participantsLimit: 50,
  status: "active",      // ← Updated
  isActive: true,        // ← Updated
  paymentId: "67890-payfast",
  activatedAt: Timestamp(2026, 1, 27),
  creationFeeAmount: 10000,
  scheduledDate: "2026-02-20",
  startTime: "2:00 PM"
}
```

---

## 3️⃣ PAYMENT: WORKSHOP REGISTRATION (Participant → PayFast → App)

**Who Pays**: Participant/User  
**Amount**: PKR 500-5,000 (workshop registration fee)  
**Who Receives**: Doctor/Creator (initially held by admin, released after workshop)  
**Status**: Participant gets enrolled, payment held by admin

### Step-by-Step Flow:

```
1. User browses available workshops
   ↓
2. Clicks workshop → sees "Register Now" button
   ↓
3. Clicks "Register & Pay" (amount: PKR 1,000)
   ↓
4. Redirected to PayFast checkout page
   ↓
5. PayFast processes payment
   ↓
6. PayFast sends webhook to Firebase:
   POST /handlePayFastWebhook
   
7. Firebase Verifies:
   ✅ MD5 signature matches
   ✅ Amount matches workshop fee (PKR 1,000)
   ✅ Payment ID is new (no duplicate registrations)
   ✅ Status is "00" (success)
   ↓
8. Database Updates:
   Collection: workshop_payments
   Document: {paymentId}
   {
     amount_gross: "1000",           // ← CRITICAL: Amount saved here
     amountReceived: "1000",
     paymentId: "11111-payfast",
     status: "paid",
     paidAt: timestamp,
     workshopId: "workshop_xyz",
     userId: "participant_111"
   }
   
   Collection: workshop_registrations
   Document: {registrationId}
   {
     workshopId: "workshop_xyz",
     userId: "participant_111",
     registrationDate: timestamp,
     status: "registered",
     paymentId: "11111-payfast",
     amountPaid: 1000
   }
   
   Collection: workshops
   Document: workshop_xyz
   {
     totalParticipants: 5,            // Incremented
     registeredCount: 5,              // Incremented
     revenueReleased: false,          // ← NEW: Will be true after release
     paymentHold: false,              // ← NEW: Admin can set to true
     creatorEmail: "doctor@example",  // ← NEW: Stored for emails
     creatorName: "Dr. Ahmed"         // ← NEW: Stored for emails
   }
   ↓
9. Email Sent to Participant:
   Subject: "Registration Confirmed!"
   Body: "You are registered for 'Diabetes Management Workshop' on 2026-02-20"
   ↓
10. DONE ✅
    User can see workshop in "My Registrations"
    Payment held securely in admin account
    Waiting for auto-release after workshop ends
```

### Database Records Created:
```javascript
// workshop_payments collection
{
  amount_gross: 1000,           // ← Saved for revenue calculation
  amountReceived: 1000,
  paymentId: "11111-payfast",
  status: "paid",
  paidAt: Timestamp(2026, 1, 27),
  workshopId: "workshop_xyz",
  userId: "participant_111"
}

// workshop_registrations collection
{
  id: "reg_222",
  workshopId: "workshop_xyz",
  userId: "participant_111",
  registrationDate: Timestamp(2026, 1, 27),
  status: "registered",
  paymentId: "11111-payfast",
  amountPaid: 1000
}

// workshops collection (updated)
{
  id: "workshop_xyz",
  creatorId: "doctor_789",
  // ... other fields ...
  totalParticipants: 5,          // ← Incremented
  registeredCount: 5,            // ← Incremented
  revenueReleased: false,        // ← New field
  paymentHold: false,            // ← New field
  creatorEmail: "doctor@example",// ← New field
  creatorName: "Dr. Ahmed"       // ← New field
}
```

---

## 4️⃣ PAYMENT: REVENUE RELEASE (Admin Account → Creator Account)

**Who Pays**: Admin (holds all payments)  
**Amount**: Sum of all registrations - PayFast fees  
**Who Receives**: Doctor/Creator  
**Status**: Automatic 1 hour after workshop ends OR manual release by admin

### Step-by-Step Flow:

```
🔄 AUTOMATIC RELEASE (Every 60 minutes):

1. Scheduled function runs hourly in Firebase
   `autoReleaseWorkshopRevenue()`
   ↓
2. Checks ALL workshops where:
   ✅ Workshop endDateTime ≤ 1 hour ago
   ✅ revenueReleased == false
   ✅ paymentHold == false
   ↓
3. Example Workshop:
   - Title: "Diabetes Management"
   - Ended: Jan 27, 2:30 PM
   - Current time: Jan 27, 3:45 PM
   - Status: READY FOR RELEASE ✅
   ↓
4. Revenue Calculation:
   
   Participants & Payments:
   - Participant 1: PKR 1,000
   - Participant 2: PKR 1,000
   - Participant 3: PKR 1,000
   - Participant 4: PKR 1,000
   - Participant 5: PKR 1,000
   ─────────────────────────
   Total Collected: PKR 5,000
   
   PayFast Fees (per payment):
   - Per transaction: 2.9% + PKR 3
   - 5 transactions: (5,000 × 2.9%) + (5 × 3)
   - = PKR 145 + 15 = PKR 160
   ─────────────────────────
   Net to Creator: PKR 4,840 ✅
   ↓
5. Database Updates:
   Collection: workshop_payouts
   Document: {payoutId}
   {
     payoutId: "payout_333",
     workshopId: "workshop_xyz",
     creatorId: "doctor_789",
     creatorEmail: "doctor@example.com",
     creatorName: "Dr. Ahmed",
     totalRevenue: 5000,
     totalTransactions: 5,
     totalFees: 160,
     netAmount: 4840,
     status: "released",
     releasedAt: Timestamp(2026, 1, 27, 3, 45),
     releasedBy: "system",
     feeBreakdown: {
       percentage: 145,      // 2.9% of 5000
       flatFee: 15           // 5 × 3
     }
   }
   
   Collection: workshops
   Document: workshop_xyz
   {
     revenueReleased: true,      // ← Changed from false
     totalRevenue: 5000,
     totalFees: 160,
     netRevenue: 4840,
     payoutId: "payout_333",
     releasedAt: Timestamp(...)
   }
   
   Collection: admin_actions (audit log)
   {
     action: "revenue_released",
     workshopId: "workshop_xyz",
     creatorId: "doctor_789",
     amount: 4840,
     timestamp: Timestamp(...),
     triggeredBy: "system_auto_release"
   }
   ↓
6. Emails Sent:
   
   TO CREATOR:
   ───────────
   Subject: "Revenue Released - Diabetes Management Workshop"
   Body:
   "Your workshop revenue has been released!
   
   Total Collected: PKR 5,000
   PayFast Fees: PKR 160
   Net Amount: PKR 4,840
   
   Participants: 5
   Released On: Jan 27, 2026 at 3:45 PM
   
   The amount will appear in your linked bank account within 2-3 business days."
   
   TO ADMIN:
   ─────────
   Subject: "Workshop Revenue Released"
   Body:
   "Workshop revenue has been automatically released.
   
   Workshop: Diabetes Management
   Creator: Dr. Ahmed
   Email: doctor@example.com
   Net Amount Released: PKR 4,840
   Participants: 5
   
   Payout ID: payout_333
   Time: Jan 27, 3:45 PM"
   ↓
7. DONE ✅
    Creator sees payout in "Revenue History"
    Admin gets notification
    Creator receives amount in bank account (2-3 days)
```

### OR MANUAL RELEASE (Admin Control):

```
1. Admin opens "Manage Workshop Payouts"
   ↓
2. Sees workshop with pending revenue:
   "Diabetes Management - PKR 5,000 - Status: Pending"
   ↓
3. Can Click:
   ❌ HOLD - Prevent automatic release (if issue found)
   ✅ RELEASE - Manual release even before 1 hour
   🔄 REPROCESS - Recalculate fees (if changes)
   ↓
4. Admin clicks "RELEASE"
   ↓
5. Same database updates as automatic release
   (Same payout record created)
   ↓
6. But releasedBy = "admin" (not "system")
   ↓
7. Emails sent to both creator and admin
   ↓
8. DONE ✅
```

### Database Records Created:

```javascript
// workshop_payouts collection (NEW)
{
  payoutId: "payout_333",
  workshopId: "workshop_xyz",
  creatorId: "doctor_789",
  creatorEmail: "doctor@example.com",
  creatorName: "Dr. Ahmed",
  totalRevenue: 5000,
  totalTransactions: 5,
  totalFees: 160,
  netAmount: 4840,
  status: "released",
  releasedAt: Timestamp(2026, 1, 27, 3, 45),
  releasedBy: "system",
  feeBreakdown: {
    percentage: 145,
    flatFee: 15
  }
}

// admin_actions collection (NEW - Audit Trail)
{
  action: "revenue_released",
  workshopId: "workshop_xyz",
  creatorId: "doctor_789",
  amount: 4840,
  timestamp: Timestamp(2026, 1, 27, 3, 45),
  triggeredBy: "system_auto_release",
  payoutId: "payout_333"
}

// workshops collection (updated)
{
  id: "workshop_xyz",
  // ... all previous fields ...
  revenueReleased: true,      // ← Changed from false
  totalRevenue: 5000,
  totalFees: 160,
  netRevenue: 4840,
  payoutId: "payout_333",
  releasedAt: Timestamp(2026, 1, 27, 3, 45),
  endDateTime: Timestamp(2026, 1, 27, 2, 30)
}
```

---

## 📊 PAYMENT FLOW DIAGRAM

```
Payment Flow Summary:
════════════════════════════════════════════════════════════════════

1️⃣ BOOKING PAYMENT (Patient directly to Doctor):
   Patient (PKR 500-2000) 
   → PayFast 
   → Firebase webhook 
   → booking_payments + bookings updated 
   → Email to Patient
   → Doctor sees booking

2️⃣ WORKSHOP CREATION (Creator to Platform):
   Creator (PKR 10,000)
   → PayFast
   → Firebase webhook
   → workshop_creation_payments + workshops updated
   → Email to Creator
   → Workshop goes LIVE

3️⃣ WORKSHOP REGISTRATION (Participant to Admin):
   Participant (PKR 500-5000)
   → PayFast
   → Firebase webhook
   → workshop_payments + workshop_registrations + workshops updated
   → Email to Participant
   → Payment HELD by Admin
   → Participant enrolled

4️⃣ REVENUE RELEASE (Admin to Creator):
   ⏰ 1 hour after workshop ends
   OR
   🔐 Manual release by Admin
   
   → Calculate total from all registrations
   → Deduct PayFast fees (2.9% + PKR 3)
   → Create payout record
   → Mark workshop as revenueReleased
   → Send emails to Creator + Admin
   → Creator receives amount in bank (2-3 days)
   → Audit trail logged

════════════════════════════════════════════════════════════════════
```

---

## ✅ KEY SECURITY CHECKS (All 4 Payments)

```
Before any payment is accepted:

✅ MD5 Signature Verification
   (Confirms PayFast actually sent this, not hacker)
   
✅ Amount Validation
   (Confirms amount matches what customer agreed to)
   
✅ Duplicate Prevention
   (Ensures same payment can't be processed twice)
   
✅ Status Code Check
   (Confirms payment status is "00" = success)
   
✅ Firestore Transactions
   (All-or-nothing: Either everything updates or nothing)
   
✅ Error Logging
   (Every payment logged for debugging)
```

---

## 🔍 CRITICAL FIXES APPLIED

**Issue**: Amount wasn't being saved when participant registered  
**Impact**: Revenue would calculate as PKR 0  
**Fix**: Added `amount_gross` field to payment record  
**Status**: ✅ DEPLOYED

**Issue**: No fallback if amount field was missing  
**Impact**: Revenue calculation would fail  
**Fix**: Added 3-level fallback logic  
**Status**: ✅ DEPLOYED

**Issue**: Creator email not stored  
**Impact**: Release emails couldn't be sent  
**Fix**: Auto-fetch creator email on first payment  
**Status**: ✅ DEPLOYED

---

## 📝 SUMMARY TABLE

| # | Payment Type | Payer | Receiver | Amount | Timing | Status |
|---|---|---|---|---|---|---|
| 1️⃣ | Booking | Patient | Platform | PKR 500-2,000 | Immediate | ✅ Paid |
| 2️⃣ | Workshop Creation | Creator | Platform | PKR 10,000 | Fixed | ✅ Paid |
| 3️⃣ | Workshop Registration | Participant | Admin (held) | PKR 500-5,000 | Per person | ✅ Held |
| 4️⃣ | Revenue Release | Admin → Creator | Creator | Net Amount | 1hr after | ✅ Released |

**All 4 payments secured, verified, and deployed to production.** ✅
