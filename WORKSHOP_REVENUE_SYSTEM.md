# Workshop Revenue Release System

## 🎯 Overview

Complete automated revenue management system where workshop registration payments are collected by admin and automatically released to workshop creators 1 hour after workshop ends.

---

## 💰 Payment Flow

### 1. **Registration Payment (User → Admin)**
```
User pays workshop fee → PayFast → Admin account
```
- Payment goes to admin first (NOT directly to creator)
- Stored in `workshop_payments` collection
- Status tracked in real-time

### 2. **Revenue Collection Period**
```
Workshop starts → Workshop runs → Workshop ends
```
- All participant payments held by admin
- Creator cannot access funds during workshop

### 3. **Automatic Release (Admin → Creator)**
```
Workshop ends + 1 hour → Auto-release → Creator receives net amount
```
- System automatically releases revenue
- PayFast fees deducted from creator's amount
- Both admin and creator receive email notifications

---

## 📊 Fee Structure

### PayFast Transaction Fees
- **Percentage Fee**: 2.9% of transaction amount
- **Fixed Fee**: PKR 3 per transaction
- **Who Pays**: Workshop creator (deducted from their revenue)

### Example Calculation
```
Workshop Fee: PKR 1,000
Participants: 10 people
Total Revenue: PKR 10,000

PayFast Fees:
- Per transaction: (1,000 × 2.9%) + 3 = 29 + 3 = PKR 32
- Total fees (10 transactions): PKR 320

Net Amount to Creator: PKR 10,000 - 320 = PKR 9,680
```

---

## 🔧 Technical Implementation

### New Cloud Functions

#### 1. **autoReleaseWorkshopRevenue** (Scheduled)
- **Trigger**: Runs every 60 minutes
- **Purpose**: Auto-release revenues 1 hour after workshop end
- **Process**:
  1. Find workshops that ended ≥1 hour ago
  2. Check `revenueReleased = false` and `paymentHold = false`
  3. Calculate total revenue and fees
  4. Create payout record
  5. Update workshop status
  6. Send emails to creator and admin

#### 2. **adminControlWorkshopPayout** (HTTPS Callable)
- **Security**: Admin authentication required
- **Actions**:
  - `hold`: Admin blocks payment release
  - `release`: Admin manually releases payment
- **Use Cases**:
  - Dispute resolution
  - Quality issues
  - Terms violation

#### 3. **getPayoutHistory** (HTTPS Callable)
- **Security**: Admin or creator authentication required
- **Purpose**: View payout history
- **Filters**: By workshopId or creatorId

---

## 📁 Database Collections

### 1. **workshops** (Updated Fields)
```javascript
{
  // Existing fields...
  
  // NEW Revenue Tracking Fields:
  revenueReleased: false,           // Has revenue been released?
  revenueReleasedAt: timestamp,     // When was it released?
  totalRevenue: 10000,              // Total collected (PKR)
  totalFees: 320,                   // PayFast fees (PKR)
  netRevenue: 9680,                 // Amount released to creator (PKR)
  payoutId: "payout_abc123",        // Reference to payout record
  
  // Admin Controls:
  paymentHold: false,               // Admin hold status
  paymentHoldAt: timestamp,         // When was hold applied?
  paymentHoldBy: "admin_uid",       // Which admin applied hold?
  paymentHoldReason: "text",        // Why was payment held?
}
```

### 2. **workshop_payouts** (New Collection)
```javascript
{
  payoutId: "auto_generated_id",
  workshopId: "workshop_id",
  creatorId: "creator_uid",
  creatorEmail: "creator@example.com",
  workshopTitle: "Workshop Name",
  
  // Financial Details:
  totalRevenue: 10000,              // Total collected
  totalTransactions: 10,            // Number of participants
  totalFees: 320,                   // PayFast fees
  netAmount: 9680,                  // Amount released to creator
  
  // Release Info:
  status: "released",               // released / pending / held
  releaseType: "automatic",         // automatic / manual
  releasedAt: timestamp,
  releasedBy: "system" or "admin_uid",
  notes: "Auto-released 1 hour after workshop end",
  
  createdAt: timestamp,
}
```

### 3. **admin_actions** (New Collection)
```javascript
{
  actionType: "payment_hold" or "payment_release",
  workshopId: "workshop_id",
  workshopTitle: "Workshop Name",
  performedBy: "admin_uid",
  performedAt: timestamp,
  amount: 9680,                     // (for releases)
  payoutId: "payout_id",           // (for releases)
  reason: "Admin notes",
  notes: "Additional info",
}
```

---

## 📧 Email Notifications

### 1. **Creator Revenue Release Email**
**Subject**: 💰 Revenue Released - [Workshop Title]

**Content**:
- ✅ Success message
- Workshop details
- Participant count
- Payment breakdown:
  - Total revenue collected
  - PayFast fees deducted
  - Net amount released
- Payout ID for reference
- Expected bank transfer timeline (3-5 days)

### 2. **Admin Notification Email**
**Subject**: 🔔 Revenue Released - [Workshop Title]

**Content**:
- Automatic release notification
- Workshop information
- Creator details
- Financial summary
- Payout ID
- Action status: "No action required"

### 3. **Payment Hold Email** (if admin holds payment)
**Subject**: ⚠️ Payment on Hold - [Workshop Title]

**Content**:
- Payment hold notice
- Workshop details
- Hold reason
- Contact support instructions

---

## 🛡️ Security Features

### 1. **Authentication**
- All admin functions require Firebase Authentication
- User type verification (admin vs regular user)
- Permission-based access control

### 2. **Authorization**
- Admins can hold/release any workshop payment
- Creators can only view their own payout history
- Regular users cannot access payout functions

### 3. **Validation**
- Amount validation (expected vs received)
- Signature verification (PayFast webhooks)
- Duplicate payment prevention
- Transaction-safe database updates

### 4. **Audit Trail**
- All admin actions logged in `admin_actions` collection
- Payout records immutable once created
- Timestamp tracking for all operations

---

## 🎛️ Admin Controls

### Hold Payment
```javascript
// Call from Flutter admin panel
final result = await FirebaseFunctions.instance
  .httpsCallable('adminControlWorkshopPayout')
  .call({
    'workshopId': 'workshop_xyz',
    'action': 'hold',
    'reason': 'Quality issues reported'
  });
```

**Result**:
- Payment blocked from auto-release
- Creator notified via email
- Can be released manually later

### Release Payment Manually
```javascript
// Call from Flutter admin panel
final result = await FirebaseFunctions.instance
  .httpsCallable('adminControlWorkshopPayout')
  .call({
    'workshopId': 'workshop_xyz',
    'action': 'release',
    'reason': 'Issues resolved'
  });
```

**Result**:
- Payment immediately released to creator
- Same email notifications sent
- Payout record created with `releaseType: 'manual'`

### View Payout History
```javascript
// Admin can view all payouts for a workshop
final result = await FirebaseFunctions.instance
  .httpsCallable('getPayoutHistory')
  .call({
    'workshopId': 'workshop_xyz'
  });

// Creator can view their own payouts
final result = await FirebaseFunctions.instance
  .httpsCallable('getPayoutHistory')
  .call({
    'creatorId': currentUserId
  });
```

---

## ⏱️ Timeline

### Automatic Release Schedule

```
Workshop End Time: 3:00 PM
+1 hour → 4:00 PM: Auto-release eligible
Next scheduled run: 4:00 PM - 5:00 PM
Actual release: Within this window
```

**Scheduled Function**: Runs every 60 minutes

**Example**:
- Workshop ends at 3:15 PM
- Becomes eligible at 4:15 PM
- Next cron run at 5:00 PM
- Released between 4:15 PM - 5:00 PM

---

## 🔍 Monitoring & Logs

### Check Auto-Release Logs
```bash
firebase functions:log --only autoReleaseWorkshopRevenue
```

### Check Admin Action Logs
```bash
firebase functions:log --only adminControlWorkshopPayout
```

### View Payout Records
```javascript
// Firestore query
const payouts = await FirebaseFirestore.instance
  .collection('workshop_payouts')
  .orderBy('releasedAt', descending: true)
  .limit(50)
  .get();
```

---

## 🚀 Deployment

### Deploy All Functions
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Deploy Specific Functions
```bash
# Deploy scheduled function
firebase deploy --only functions:autoReleaseWorkshopRevenue

# Deploy admin control function
firebase deploy --only functions:adminControlWorkshopPayout

# Deploy payout history function
firebase deploy --only functions:getPayoutHistory

# Re-deploy updated registration webhook
firebase deploy --only functions:handlePayFastWebhook
```

---

## ✅ Testing Checklist

### 1. **Test Auto-Release**
- [ ] Create test workshop
- [ ] Add test participants with payments
- [ ] Set workshop end time to 2 hours ago
- [ ] Wait for next cron run
- [ ] Verify payout record created
- [ ] Verify workshop updated
- [ ] Verify emails sent

### 2. **Test Admin Hold**
- [ ] Call `adminControlWorkshopPayout` with `action: 'hold'`
- [ ] Verify `paymentHold = true` in workshop
- [ ] Verify creator email sent
- [ ] Verify auto-release skips this workshop

### 3. **Test Manual Release**
- [ ] Call `adminControlWorkshopPayout` with `action: 'release'`
- [ ] Verify payout created with `releaseType: 'manual'`
- [ ] Verify emails sent to creator and admin
- [ ] Verify `revenueReleased = true`

### 4. **Test Payout History**
- [ ] Call `getPayoutHistory` as admin
- [ ] Call `getPayoutHistory` as creator
- [ ] Call `getPayoutHistory` as unauthorized user (should fail)
- [ ] Verify correct data returned

---

## 🔧 Configuration Required

### Firebase Functions Config
```bash
# Already configured (Gmail for emails)
firebase functions:config:get gmail.email
firebase functions:config:get gmail.password
```

### Firestore Indexes
No additional indexes required for this feature.

### Firestore Rules
Update rules to allow admin access to payouts:
```javascript
match /workshop_payouts/{payoutId} {
  allow read: if request.auth != null && 
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin' ||
     resource.data.creatorId == request.auth.uid);
  allow write: if false; // Only Cloud Functions can write
}

match /admin_actions/{actionId} {
  allow read: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
  allow write: if false; // Only Cloud Functions can write
}
```

---

## 📞 Support

**Admin Email**: sehatmakaan@gmail.com

**Issue Resolution**:
1. Creator disputes payment → Admin holds payment → Investigate → Release or refund
2. Workshop quality issues → Admin holds payment → Review → Decision
3. Terms violation → Admin holds payment indefinitely → Account action

---

## 🎉 Summary

✅ **Payments go to admin first** (not directly to creator)
✅ **Auto-release after 1 hour** (no manual intervention needed)
✅ **PayFast fees deducted from creator** (not admin)
✅ **Admin can hold/release** payments anytime
✅ **Email notifications** to both parties
✅ **Complete audit trail** of all transactions
✅ **Secure and fraud-proof** implementation

**Status**: ✅ Ready for deployment
**Last Updated**: January 27, 2026
