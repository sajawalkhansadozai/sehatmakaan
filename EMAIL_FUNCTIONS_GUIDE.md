# 📧 Email Functions Guide - Sehat Makaan

## Overview
Complete Firebase Cloud Functions implementation for automated email notifications.

---

## ✅ Deployed Functions

### 1. **sendQueuedEmail** (Firestore Trigger)
- **Trigger:** `email_queue/{emailId}` onCreate
- **Purpose:** Processes all queued emails
- **Features:**
  - ✅ Nodemailer integration with Gmail
  - ✅ Automatic retry mechanism (max 3 retries)
  - ✅ Status tracking (pending → sent/failed)
  - ✅ Demo mode when credentials not configured

---

### 2. **onWorkshopRegistration** (Firestore Trigger)
- **Trigger:** `workshop_registrations/{registrationId}` onCreate
- **Purpose:** Sends confirmation email when user registers for workshop
- **Email Content:**
  - Workshop title, date, time, location
  - Registration fee
  - Status badge
  - Next steps (payment process)
  - Registration ID

---

### 3. **onWorkshopConfirmation** (Firestore Trigger)
- **Trigger:** `workshop_registrations/{registrationId}` onUpdate
- **Purpose:** Sends payment link when admin confirms/rejects registration

#### When Status Changes to "confirmed":
- ✅ Sends approval email with payment link
- 💳 Payment link: `https://sehatmakaan.com/payment/{registrationId}`
- ⏰ 48-hour reservation notice
- 📋 Workshop details and amount due

#### When Status Changes to "rejected":
- ⚠️ Sends rejection email
- 📝 Includes rejection reason (if provided)
- 🔄 Encourages future registration

---

### 4. **onUserApproval** (Firestore Trigger)
- **Trigger:** `users/{userId}` onUpdate
- **Purpose:** Notifies users when account is approved/rejected

#### When Status Changes to "approved":
- 🎉 Welcome email with login credentials
- 📧 Email address
- 👤 Username
- 🔐 Password reset instructions
- 📱 App features overview

#### When Status Changes to "rejected":
- ❌ Rejection notification
- 📝 Rejection reason (if provided)
- 📞 Support contact information

---

### 5. **onBookingCreated** (Firestore Trigger)
- **Trigger:** `bookings/{bookingId}` onCreate
- **Purpose:** Sends booking confirmation email
- **Email Content:**
  - 📅 Booking date and time
  - 💰 Total cost
  - 📋 Selected add-ons
  - 🔲 QR code reference
  - ⚠️ Cancellation policy (24 hours notice)

---

### 6. **onHighPriorityNotification** (Firestore Trigger)
- **Trigger:** `notifications/{notificationId}` onCreate
- **Purpose:** Sends email for high-priority notifications only
- **Filter:** Only `priority === 'high'` notifications
- **Email Content:**
  - 🔔 Notification title
  - 📝 Notification body
  - 📱 App check reminder

---

### 7. **payfastWebhook** (HTTP Request)
- **Endpoint:** `https://us-central1-sehatmakaan-833e2.cloudfunctions.net/payfastWebhook`
- **Purpose:** Handles PayFast payment notifications
- **Process:**
  1. Validates payment status from PayFast
  2. Updates `workshop_payments` collection
  3. Updates `workshop_registrations` with payment status
  4. Sends payment confirmation email

---

### 8. **generatePayFastLink** (Callable Function)
- **Purpose:** Generate PayFast payment link for workshop registration
- **Parameters:**
  - `registrationId`: Workshop registration ID
  - `workshopTitle`: Workshop title
  - `amount`: Payment amount
  - `userEmail`: User email
  - `userName`: User full name
- **Returns:** Payment URL (test or production)

---

### 9. **sendTestEmail** (Callable Function)
- **Purpose:** Test email configuration
- **Parameters:**
  - `to`: Recipient email
  - `subject`: Email subject
  - `message`: Email message
- **Usage:** Testing email service setup

---

### 10. **retryFailedEmails** (Callable Function)
- **Purpose:** Manually retry failed emails
- **Access:** Admin only
- **Features:**
  - Retries emails with status "failed"
  - Max 3 retry attempts
  - Returns success/failure count

---

### 11. **cleanOldEmails** (Scheduled Function)
- **Schedule:** Every 24 hours
- **Purpose:** Delete old email_queue records (30+ days)
- **Cleanup:** Automatic database maintenance

---

## 🔧 Email Configuration

### Setup Gmail Credentials

```bash
# Set Gmail credentials
firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-app-password"

# View current config
firebase functions:config:get

# Deploy after config change
firebase deploy --only functions
```

### Generate Gmail App Password
1. Go to Google Account Settings
2. Security → 2-Step Verification
3. App Passwords → Generate new password
4. Copy the 16-character password
5. Use in Firebase config

---

## 📊 Email Queue Collection Structure

```javascript
{
  "to": "user@example.com",
  "subject": "Email Subject",
  "htmlContent": "<html>...</html>",
  "status": "pending",  // pending | sent | failed | demo_sent
  "createdAt": Timestamp,
  "sentAt": Timestamp,
  "retryCount": 0,
  "error": "Error message if failed",
  "messageId": "SMTP message ID"
}
```

---

## 🎯 Usage from Flutter App

### Method 1: Direct Email Queue (Recommended)
```dart
// Add to email_queue collection
await FirebaseFirestore.instance.collection('email_queue').add({
  'to': 'user@example.com',
  'subject': 'Custom Email Subject',
  'htmlContent': '<div><h1>Hello!</h1><p>Your content here</p></div>',
  'status': 'pending',
  'createdAt': FieldValue.serverTimestamp(),
  'retryCount': 0,
});

// Function automatically triggers and sends email
```

### Method 2: Call Callable Function
```dart
// Send test email
final callable = FirebaseFunctions.instance.httpsCallable('sendTestEmail');
final result = await callable.call({
  'to': 'user@example.com',
  'subject': 'Test Email',
  'message': 'This is a test message',
});
print(result.data['emailId']);
```

---

## 📧 Email Templates Included

### 1. Workshop Registration Confirmation
- ✅ Beautiful HTML template
- 📅 Workshop details card
- 🎨 Gradient header (Teal theme)
- 📋 Next steps guide
- 📧 Footer with contact info

### 2. Workshop Approval + Payment Link
- 🎊 Celebration theme
- 💳 Payment button (CTA)
- 💰 Amount highlight
- ⏰ 48-hour reservation notice
- 📋 Important notes list

### 3. Workshop Rejection
- ⚠️ Professional rejection notice
- 📝 Rejection reason display
- 🔄 Encouragement for future registration

### 4. User Account Approval
- 🎉 Welcome message
- 📧 Login credentials display
- 🔐 Password reset instructions
- 📱 App features overview
- ✅ Green theme (success)

### 5. User Account Rejection
- ❌ Professional rejection notice
- 📝 Rejection reason
- 📞 Support contact info
- 🔴 Red theme (rejection)

### 6. Booking Confirmation
- ✅ Booking confirmed badge
- 📅 Date/time details
- 💰 Total cost
- 🔲 QR code reference
- ⚠️ Important notes

### 7. Payment Confirmation
- 💳 Payment success message
- 💰 Amount paid
- 🆔 Payment ID
- ✅ Status confirmation
- 📋 Workshop details

### 8. High Priority Notification
- 🔔 Urgent notification banner
- 📝 Notification content
- ⚠️ Orange theme (warning)
- 📱 App check reminder

---

## 🔒 Security Rules

```javascript
// Firestore Security Rules for email_queue
match /email_queue/{emailId} {
  // Only Cloud Functions can write
  allow read: if request.auth != null && request.auth.token.admin == true;
  allow write: if false;
}
```

---

## 📈 Monitoring

### View Function Logs
```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only sendQueuedEmail

# Live tail
firebase functions:log --tail
```

### View Failed Emails
```javascript
// Query in Firestore Console
collection: email_queue
where: status == 'failed'
orderBy: createdAt desc
```

---

## 🧪 Testing

### Test Email Sending
```bash
# From Flutter app
final callable = FirebaseFunctions.instance.httpsCallable('sendTestEmail');
await callable.call({
  'to': 'your-email@gmail.com',
  'subject': 'Test Email',
  'message': 'Testing email service!',
});
```

### Check Email Queue Status
```dart
// Listen to email queue
FirebaseFirestore.instance
  .collection('email_queue')
  .where('to', isEqualTo: 'user@example.com')
  .orderBy('createdAt', descending: true)
  .limit(10)
  .snapshots()
  .listen((snapshot) {
    for (var doc in snapshot.docs) {
      print('Email status: ${doc['status']}');
    }
  });
```

---

## ⚠️ Important Notes

### Demo Mode
- If Gmail credentials NOT configured:
  - Emails are logged to console only
  - Status marked as "demo_sent"
  - No actual emails sent
  - Perfect for development/testing

### Production Setup
1. ✅ Configure Gmail credentials
2. ✅ Enable billing on Firebase project
3. ✅ Set up PayFast webhook URL
4. ✅ Update return/cancel URLs
5. ✅ Test all email templates
6. ✅ Monitor function logs regularly

### Retry Logic
- Emails automatically retry up to 3 times
- Failed emails remain in queue
- Admin can manually retry via `retryFailedEmails` function

### Cost Considerations
- Firebase Functions: Free tier = 125K invocations/month
- Cloud Firestore: Free tier = 20K writes/day
- Storage: Free tier = 1GB
- Outbound data: Free tier = 10GB/month

---

## 🚀 Deployment Commands

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendQueuedEmail

# View deployed functions
firebase functions:list

# Delete old function
firebase functions:delete FUNCTION_NAME
```

---

## 📞 Support

If emails not sending:
1. Check Gmail credentials: `firebase functions:config:get`
2. Check function logs: `firebase functions:log --tail`
3. Verify email_queue collection has pending emails
4. Check Firestore security rules
5. Verify Firebase billing enabled

---

## 🎉 Summary

### ✅ What's Working:
- 11 Cloud Functions deployed
- 8 beautiful email templates
- Automatic email queue processing
- Workshop registration flow
- User approval flow
- Booking confirmations
- Payment webhooks
- Notification emails
- Retry mechanism
- Auto cleanup

### 🔥 Ready for Production!
All email functionality is now deployed and ready to use. Simply configure Gmail credentials and test with your email addresses.

---

**Created:** 2026-01-03  
**Project:** Sehat Makaan - Flutter Firebase  
**Functions Count:** 11  
**Templates Count:** 8  
**Status:** ✅ DEPLOYED
