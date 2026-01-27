# 🚨 CRITICAL PAYMENT ISSUES FOUND

---

## **ISSUE #1: WEBHOOK INCONSISTENCY - CRITICAL ⚠️⚠️⚠️**

### **Problem:**
The 3 payment webhooks use **DIFFERENT status field names** for marking payments as confirmed:

| Webhook | Collection | Status Field | Expected Value |
|---------|-----------|--------------|-----------------|
| `handlePayFastWebhook` (Workshop) | `workshop_registrations` | `status` | `'confirmed'` |
| `payfastWebhook` (Booking) | `bookings` | `paymentStatus` | `'COMPLETE'` ❌ INCONSISTENT |
| `payfastWorkshopCreationWebhook` | `workshops` | `isCreationFeePaid` | `true` (boolean) |

### **Code Evidence:**

**Workshop Registration (CORRECT):**
```javascript
// Line 3391 - handlePayFastWebhook
await admin.firestore()
  .collection('workshop_registrations')
  .doc(registrationId)
  .update({
    status: 'confirmed',  // ✅ String 'confirmed'
    paymentStatus: 'paid',
    registrationNumber: registrationNumber,
    paymentId: pf_payment_id,
    confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
```

**Booking Payment (BROKEN):**
```javascript
// Line 385 - payfastWebhook
let newStatus = 'pending';
if (paymentStatus === 'COMPLETE') {
  newStatus = 'completed';  // ❌ Sets to 'completed' not 'confirmed'
} else if (paymentStatus === 'FAILED') {
  newStatus = 'failed';
} else if (paymentStatus === 'CANCELLED') {
  newStatus = 'cancelled';
}

// Updates payment, NOT booking
await admin.firestore().collection('workshop_payments').doc(paymentId).update({
  status: newStatus,  // ❌ Wrong field name for booking
  // ...
});

// Workshop registration update, not booking
await admin.firestore()
  .collection('workshop_registrations')
  .doc(registrationId)
  .update({
    paymentStatus: 'paid',  // ❌ Updates workshop_registrations, not bookings!
  });
```

**Workshop Creation Fee (ALSO BROKEN):**
```javascript
// Line 530-537 - payfastWorkshopCreationWebhook
transaction.update(workshopRef, {
  isCreationFeePaid: true,  // ❌ Boolean, not string status
  isActive: true,
  permissionStatus: 'live',  // ❌ Uses different field name
  activatedAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

### **Impact:**
❌ **CRITICAL**: Real-time listeners won't detect payment confirmation because:
- Workshop app listeners watch for `status: 'confirmed'` 
- Booking webhook sets different field names
- Workshop creation fee uses boolean instead of string
- Listeners are looking at wrong collections/fields

### **The Real Issue:**
The webhook for booking payment (`payfastWebhook`) at line 385-410:
1. ❌ Updates `workshop_payments` collection instead of `bookings`
2. ❌ Updates `workshop_registrations` instead of the actual booking document
3. ❌ Sets `paymentStatus: 'paid'` on wrong document

**This webhook was copy-pasted from workshop webhook and NEVER updated for booking flow!**

### **Fix Required:**
```javascript
// SHOULD BE:
if (paymentStatus === 'COMPLETE') {
  // Update the actual booking document
  await admin.firestore()
    .collection('bookings')
    .doc(bookingId)  // NOT registrationId
    .update({
      status: 'confirmed',      // ✅ Match workshop webhook
      paymentStatus: 'paid',
      paymentId: pf_payment_id,
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  
  // Update booking payment record
  await admin.firestore()
    .collection('booking_payments')
    .doc(paymentId)
    .update({
      status: 'paid',
      paymentId: pf_payment_id,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
```

---

## **ISSUE #2: NO WEBHOOK VERIFICATION - SECURITY RISK ⚠️⚠️**

### **Problem:**
None of the 3 webhooks verify that the request actually came from PayFast.

### **Current Code (INSECURE):**
```javascript
// handlePayFastWebhook - Line 3343
exports.handlePayFastWebhook = functions.https.onRequest(async (req, res) => {
  try {
    // ❌ NO VERIFICATION - just checks method
    if (req.method !== 'POST') {
      return res.status(400).json({ error: 'Only POST requests allowed' });
    }
    
    // ❌ ANYONE can POST to this URL and:
    // - Confirm fake workshop registrations
    // - Create fake bookings
    // - Activate workshops without payment
```

### **Attack Scenario:**
```bash
# Hacker can do this:
curl -X POST https://us-central1-sehatmakaan-833e2.cloudfunctions.net/handlePayFastWebhook \
  -H "Content-Type: application/json" \
  -d '{
    "payment_status": "COMPLETE",
    "custom_str1": "registration_id",
    "custom_str2": "payment_id",
    "custom_str3": "workshop",
    "amount_gross": "100000"
  }'

# Result:
# ✅ Workshop registration marked as 'confirmed' 
# ✅ Payment marked as 'paid'
# ✅ Participant count incremented
# ✅ Email sent to victim
# ✅ All WITHOUT ACTUAL PAYMENT! 💰
```

### **PayFast Provides Signature Verification:**
PayFast sends webhook with signature field. Need to verify:
```javascript
// SHOULD BE in webhook:
const { signature, ...paymentData } = req.body;
const calculatedSignature = md5(paymentData); // Hash all fields
if (signature !== calculatedSignature) {
  return res.status(401).json({ error: 'Invalid signature' });
}
```

### **Fix Required:**
Implement PayFast signature verification in all 3 webhooks.

---

## **ISSUE #3: AMOUNT VALIDATION MISSING ⚠️⚠️**

### **Problem:**
No validation that amount paid matches amount expected. Hacker can pay PKR 1 for PKR 10,000 workshop.

### **Current Code (VULNERABLE):**
```javascript
// handlePayFastWebhook - Line 3357
const {
  m_payment_id,
  pf_payment_id,
  payment_status,
  amount_gross,  // ❌ NO VALIDATION
  custom_str1,
  // ...
} = req.body;

// Line 3387 - Just accepts any amount
await admin.firestore()
  .collection('workshop_payments')
  .doc(paymentId)
  .update({
    status: 'paid',
    amount: amount_gross,  // ❌ Saves whatever PayFast sent (could be 0 or negative)
  });
```

### **Fix Required:**
```javascript
// Get original payment record to verify amount
const paymentDoc = await admin.firestore()
  .collection('workshop_payments')
  .doc(paymentId)
  .get();

const originalAmount = paymentDoc.data().amount;

// Verify amount matches
if (Math.abs(parseFloat(amount_gross) - originalAmount) > 1) {  // 1 PKR tolerance
  console.error(`❌ Amount mismatch! Expected: ${originalAmount}, Got: ${amount_gross}`);
  return res.status(400).json({ error: 'Amount mismatch' });
}
```

---

## **ISSUE #4: DUPLICATE PAYMENT PROCESSING RISK ⚠️**

### **Problem:**
If PayFast sends webhook twice (network timeout/retry), payment gets confirmed twice:
- Registration count incremented twice
- Emails sent twice
- Booking created twice

### **Current Code (VULNERABLE):**
```javascript
// handlePayFastWebhook - Line 3370
// NO check if payment already processed!
await admin.firestore()
  .collection('workshop_payments')
  .doc(paymentId)
  .update({
    status: 'paid',
    // ...
  });

// Always increments
await admin.firestore().runTransaction(async (transaction) => {
  // ...
  transaction.update(workshopRef, {
    currentParticipants: currentParticipants + 1,  // ❌ Can be +2, +3 if called multiple times
  });
});
```

### **Fix Required:**
```javascript
// Check if already processed
if (paymentDoc.data().status === 'paid') {
  console.log('Payment already processed, skipping');
  return res.status(200).json({ message: 'Already processed' });
}

// Use transaction-safe idempotency
await admin.firestore().runTransaction(async (transaction) => {
  const latestPayment = await transaction.get(paymentRef);
  if (latestPayment.data().status === 'paid') {
    throw new Error('Already processed in parallel request');
  }
  // Update only if not already paid
  transaction.update(paymentRef, { status: 'paid' });
});
```

---

## **ISSUE #5: MISSING BOOKING ID IN WEBHOOK ⚠️**

### **Problem:**
`payfastWebhook` uses `registrationId` but booking payment doesn't have registrationId concept. It uses `bookingId`.

### **Code Evidence:**
```javascript
// payfastWebhook - Line 362
const {
  m_payment_id: registrationId,  // ❌ WRONG - bookings use bookingId
  // ...
} = paymentData;

// Line 392 - Tries to update workshop_registrations
await admin.firestore()
  .collection('workshop_registrations')
  .doc(registrationId)  // ❌ This document doesn't exist for booking payments!
  .update({
    paymentStatus: 'paid',
  });
```

### **Missing Step:**
Booking payment URL in `payment_step.dart` line 60-66:
```dart
final paymentUrl = _payFastService.generatePaymentUrl(
  registrationId: registrationId,  // ❌ Uses registrationId
  workshopTitle: '${widget.bookingType == 'hourly' ? 'Hourly' : 'Monthly'} Booking',
  amount: widget.totalAmount,
  // ...
);
```

Should be:
```dart
final paymentUrl = _payFastService.generatePaymentUrl(
  bookingId: widget.bookingId,  // ✅ Use actual booking ID
  registrationId: registrationId,  // Keep for tracking
  // ...
);
```

---

## **ISSUE #6: TRANSACTION RACE CONDITION ⚠️**

### **Problem:**
When 2 users join same workshop simultaneously:
- Both read `currentParticipants: 50`
- Both increment to `51`
- Both write back `51`
- Result: Only 1 person registered but count shows 2

### **Current Code (VULNERABLE):**
```javascript
// handlePayFastWebhook - Line 3414-3424
await admin.firestore().runTransaction(async (transaction) => {
  const workshopDoc = await transaction.get(workshopRef);
  const currentParticipants = workshopDoc.data().currentParticipants || 0;

  if (currentParticipants < maxParticipants) {
    // ❌ If 2 calls happen simultaneously:
    // Both read currentParticipants = 50
    // Both see 50 < 100 (max)
    // Both increment to 51
    // Real result: should be 52
    transaction.update(workshopRef, {
      currentParticipants: currentParticipants + 1,
    });
  }
});
```

### **This is Actually OK:**
⚠️ **Actually, Firestore transactions DO handle this correctly** because:
1. Transaction reads value atomically
2. If 2nd transaction reads before 1st writes, it will still see old value
3. When 1st transaction commits, 2nd will retry with new value
4. Final result: Both increments are applied correctly

**But issue remains:** Code relies on this behavior without comment explaining it.

---

## **ISSUE #7: NO PROPER ERROR HANDLING ⚠️**

### **Problem:**
Webhooks return 500 errors but don't indicate if retryable or not.

### **Current Code:**
```javascript
// Line 3543
} catch (error) {
  console.error('❌ Error handling PayFast webhook:', error);
  return res.status(500).json({
    success: false,
    error: error.message,
  });
}
```

### **Problem:**
- PayFast sees 500 = "Failed, please retry"
- If error is "Registration not found", retrying won't help
- Webhook keeps retrying forever, polluting logs

### **Fix Required:**
```javascript
if (error.message === 'Registration not found') {
  return res.status(404).json({ error: 'Not found, do not retry' });
} else if (error.message.includes('Firestore')) {
  return res.status(500).json({ error: 'Temporary error, retry later' });
}
```

---

## **SUMMARY: CRITICAL ISSUES**

| # | Issue | Severity | Impact | Status |
|---|-------|----------|--------|--------|
| 1 | Webhook field name mismatch | 🔴 CRITICAL | Bookings payment broken, confirmation fails | ❌ BROKEN |
| 2 | No webhook signature verification | 🔴 CRITICAL | Fraud: anyone can confirm payment | ❌ VULNERABLE |
| 3 | No amount validation | 🟠 HIGH | Underpayment accepted (PKR 1 for 10,000) | ❌ VULNERABLE |
| 4 | Duplicate webhook processing | 🟠 HIGH | Participant count wrong, emails duplicated | ❌ VULNERABLE |
| 5 | Missing bookingId in webhook | 🔴 CRITICAL | Booking payment webhook broken | ❌ BROKEN |
| 6 | Transaction race condition | 🟢 OK | (Actually handled by Firestore) | ✅ OK |
| 7 | Poor error handling | 🟡 MEDIUM | Misleading retry behavior | ⚠️ NEEDS FIX |

---

## **IMMEDIATE FIXES NEEDED:**

### **Priority 1 (Do Immediately):**
1. ✅ Fix webhook field names to use consistent status field
2. ✅ Add PayFast signature verification 
3. ✅ Add amount validation
4. ✅ Add duplicate payment check
5. ✅ Fix booking payment webhook (currently broken)

### **Priority 2 (Do Soon):**
6. ✅ Add proper error handling with status codes
7. ✅ Add idempotency keys to prevent duplicate processing
8. ✅ Add logging/monitoring for failed payments

### **Priority 3 (Do Later):**
9. ✅ Move hardcoded PayFast credentials to environment variables
10. ✅ Add webhook rate limiting
11. ✅ Encrypt sensitive data in Firestore

---

Generated: 27-Jan-2026
Analysis Time: ~5 minutes
Files Analyzed: 4 (3 webhooks + 2 payment pages)
