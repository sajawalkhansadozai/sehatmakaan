# 🔐 PayFast Sandbox Integration Guide - Sehat Makaan

## 📋 Overview

Your Sehat Makaan test merchant account has been successfully created on PayFast Sandbox. This guide explains how to use the sandbox credentials and test the payment integration.

---

## 🎫 PayFast Sandbox Credentials

```
Business Name: Sehat Makaan
Account Type: MERCHANT
Environment: SANDBOX (Test)

Merchant ID:    14833
Secured Key:    rPcy4T7GQkSCFsHBLdn26s
```

**⚠️ IMPORTANT:** These are test/sandbox credentials. Do NOT use these in production.

---

## ✅ Updated Files

The following files have been updated with your new sandbox credentials:

### 1. **Flutter Payment Service**
**File:** [lib/features/payments/services/payfast_service.dart](lib/features/payments/services/payfast_service.dart#L12-L16)

```dart
static const String merchantId = '14833';
static const String securedKey = 'rPcy4T7GQkSCFsHBLdn26s';
static const bool testMode = true;
```

### 2. **Cloud Functions (Backend)**
**File:** [functions/index.js](functions/index.js#L803-L804)

```javascript
const merchantId = functions.config().payfast?.merchant_id || '14833';
const merchantKey = functions.config().payfast?.merchant_key || 'rPcy4T7GQkSCFsHBLdn26s';
```

### 3. **Workshop Checkout Pages**
- [lib/features/workshops/screens/user/workshop_checkout_page.dart](lib/features/workshops/screens/user/workshop_checkout_page.dart#L343-L344)
- [lib/features/workshops/screens/user/workshop_creation_fee_checkout_page.dart](lib/features/workshops/screens/user/workshop_creation_fee_checkout_page.dart#L402-L403)

---

## 🧪 Testing the Payment Integration

### Step 1: Prepare for Testing
1. Ensure your app is running in **test mode** (`testMode = true`)
2. Launch the app on a device or emulator

### Step 2: Initiate a Test Payment

#### For Workshop Registration:
1. Navigate to a workshop
2. Click "Register for Workshop"
3. Click "Pay Now" button
4. You'll be redirected to PayFast sandbox page

#### For Workshop Creation Fee:
1. Create a new workshop
2. Proceed to payment step
3. Click "Pay Creation Fee" (PKR 10,000)
4. You'll be redirected to PayFast sandbox page

### Step 3: Complete Payment in Sandbox

When you reach the PayFast sandbox page, use these **TEST CARD DETAILS**:

```
Card Type:           VISA / MASTERCARD
Card Number:         4111111111111111
Expiry Date:         Any future date (e.g., 12/25)
CVV:                 Any 3 digits (e.g., 123)
Name on Card:        Any name
```

**DO NOT use your actual card details in sandbox!**

### Step 4: Payment Confirmation

After successful payment:
1. You'll see a success message in the app
2. The booking/registration will be confirmed
3. A confirmation email will be sent
4. Status will update in Firestore

---

## 💾 Payment Flow in Sandbox

```
┌─────────────────────────────────────────┐
│   User Clicks "Pay Now"                 │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   App generates payment URL with:       │
│   - Merchant ID: 14833                  │
│   - Secured Key: rPcy4T7GQkSCFsHBLdn26s│
│   - Amount: PKR (in rupees)             │
│   - Webhook URL: Firebase Cloud Func   │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   Redirect to PayFast Sandbox           │
│   https://sandbox.payfast.co.za/        │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   User enters test card details         │
│   Completes payment (simulator)         │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   PayFast sends webhook to Cloud Func   │
│   POST /payfastWebhook                  │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   Cloud Function verifies:              │
│   ✓ Signature matches                   │
│   ✓ Amount is correct                   │
│   ✓ Payment not duplicated              │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   Update Firestore Collections:         │
│   - booking_payments                    │
│   - bookings                            │
│   - workshop_registrations              │
│   - email_queue                         │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   Success! Booking Confirmed            │
│   User receives confirmation email      │
└─────────────────────────────────────────┘
```

---

## 📊 Test Transactions & Order ID

### For Signup Application

After completing your first successful test transaction:

1. **Look for the Order/Payment ID** returned by PayFast
2. **Format:** Usually something like `TEST-PAYFAST-12345`
3. **Where to find it:**
   - In the success page confirmation
   - In your app's payment status message
   - In Firestore `booking_payments` or `workshop_payments` collection

### Submission to PayFast

When submitting your signup application:
1. Enter the test transaction order ID in the "Test Order ID" field
2. This proves you've successfully integrated and tested the sandbox

---

## 🔒 Security Considerations

### For Sandbox Testing:
✅ **Safe to use in test mode**
- Credentials are for sandbox environment
- No real money transactions
- Webhooks use test data

### Before Production Migration:
⚠️ **CRITICAL STEPS:**

1. **Generate Production Credentials**
   - Contact PayFast support for production merchant account
   - Receive production Merchant ID and Secured Key

2. **Update All Files**
   ```bash
   # Update these with PRODUCTION credentials:
   firebase functions:config:set payfast.merchant_id="YOUR-PROD-ID"
   firebase functions:config:set payfast.merchant_key="YOUR-PROD-KEY"
   ```

3. **Change Test Mode**
   ```dart
   static const bool testMode = false; // Set to false for production
   ```

4. **Update Payment URLs**
   ```dart
   final baseUrl = testMode
       ? 'https://sandbox.payfast.com.pk/api/payfast/pay'  // Sandbox
       : 'https://ipg.payfast.com.pk/api/payfast/pay';     // Production
   ```

---

## 🔗 PayFast Resources

### Sandbox Environment:
- **Sandbox URL:** https://sandbox.payfast.co.za/
- **Documentation:** https://www.payfast.co.za/developer
- **Test Cards:** [PayFast Test Card Numbers](https://www.payfast.co.za/developer/documentation/1.0)

### Support:
- **Email:** support@payfast.co.za
- **Docs:** https://www.payfast.co.za/api-documentation

---

## 📝 Troubleshooting

### Issue: Payment not confirmed
**Solution:**
1. Check internet connection
2. Verify webhook endpoint is accessible
3. Check Firebase Cloud Functions logs
4. Ensure Firestore database is running

### Issue: Signature mismatch error
**Solution:**
1. Verify merchant ID and secured key are correct
2. Check signature generation order (must match PayFast spec)
3. Review Cloud Function logs for errors

### Issue: Webhook not received
**Solution:**
1. Verify webhook URL in payment parameters
2. Check Firebase Cloud Functions deployment
3. Monitor Cloud Function logs in Firebase Console
4. Ensure payment was not already processed

---

## 📋 Next Steps

1. ✅ **Test the integration** - Follow testing steps above
2. ✅ **Document test order ID** - Save for signup submission
3. ✅ **Verify all flows** - Test booking and workshop payments
4. ⏳ **Complete signup** - Submit with test order ID to PayFast
5. ⏳ **Migrate to production** - When approved by PayFast

---

## 💡 Important Notes

- **Test Mode is Active:** All payments in sandbox are simulated
- **No Charges:** Test transactions don't result in real money transfers
- **Webhook Verification:** Always verify PayFast signatures in production
- **Data Consistency:** Test transactions update Firestore like real payments
- **Email Testing:** Confirmation emails may be sent (configure test email addresses)

---

**Last Updated:** February 4, 2026
**Credentials Set:** Merchant ID 14833 | Secured Key rPcy4T7GQkSCFsHBLdn26s
