# Account Suspension & Deletion Flow

## Overview
Complete implementation of account suspension, unsuspension, and deletion with proper activity blocking, email notifications, and terms violation messaging.

---

## 1. SUSPEND ACCOUNT FLOW

### Admin Action: Suspend Doctor
**Location:** Admin Dashboard → Doctors Tab → Suspend Button

**Process:**
1. Admin clicks "Suspend Doctor" button
2. Confirmation dialog appears
3. On confirmation:
   - User status changed to `'suspended'`
   - `isActive` set to `false`
   - `suspendedAt` timestamp added
   - In-app notification created
   - **Email sent with Terms Violation notice**

### Database Changes (Firestore)
```dart
users/{userId}
  status: 'suspended'
  isActive: false
  suspendedAt: [timestamp]
  updatedAt: [timestamp]
```

### Email Sent
**Subject:** ⚠️ Account Suspended - Sehat Makaan

**Content:**
- **Header:** Account Suspended warning
- **Message:** Terms and Conditions violation notice
- **Impact:** All activities paused, login blocked
- **Next Steps:** Contact admin for resolution
- **Contact:** admin@sehatmakaan.com

### In-App Notification
```dart
{
  type: 'account_suspended',
  title: 'Account Suspended',
  message: 'Your account has been temporarily suspended. Contact admin for details.'
}
```

### Login Behavior (BLOCKED)
When suspended user tries to login:
```
❌ Login Failed

Account Suspended

Your account has been temporarily suspended due to 
violation of our Terms and Conditions. All activities 
are paused. Please contact admin for details.
```

**Result:** User is immediately logged out, cannot access any features.

---

## 2. UNSUSPEND ACCOUNT FLOW

### Admin Action: Remove Suspension
**Location:** Admin Dashboard → Doctors Tab → Remove Suspension Button

**Process:**
1. Admin clicks "Remove Suspension" button (appears when status is suspended)
2. Confirmation dialog appears
3. On confirmation:
   - User status changed to `'approved'`
   - `isActive` set to `true`
   - `suspendedAt` field deleted
   - `unsuspendedAt` timestamp added
   - In-app notification created
   - **Email sent with reactivation notice**

### Database Changes (Firestore)
```dart
users/{userId}
  status: 'approved'
  isActive: true
  suspendedAt: [DELETED]
  unsuspendedAt: [timestamp]
  updatedAt: [timestamp]
```

### Email Sent
**Subject:** ✅ Account Reactivated - Sehat Makaan

**Content:**
- **Header:** Account Reactivated (success message)
- **Message:** Suspension removed, account restored
- **Restored Features:** Full access, all activities enabled
- **Reminder:** Follow Terms and Conditions
- **Action:** Can login immediately

### In-App Notification
```dart
{
  type: 'account_reactivated',
  title: 'Account Reactivated',
  message: 'Your account has been reactivated. You can now login.'
}
```

### Login Behavior (ALLOWED)
User can now login normally with full access to all features.

---

## 3. DELETE ACCOUNT FLOW (PERMANENT)

### Admin Action: Delete Doctor
**Location:** Admin Dashboard → Doctors Tab → Delete Button

**Process:**
1. Admin clicks "Delete" button (red button)
2. Confirmation dialog with permanent deletion warning
3. On confirmation:
   - **Email sent FIRST** (before deletion)
   - User document deleted
   - All user's bookings deleted
   - All user's subscriptions deleted
   - All user's notifications deleted
   - Complete data removal (permanent)

### Database Changes (Firestore)
```dart
✅ DELETED:
  - users/{userId}
  - bookings (where userId == deleted user)
  - subscriptions (where userId == deleted user)
  - notifications (where userId == deleted user)
```

### Email Sent (BEFORE DELETION)
**Subject:** ⛔ Account Permanently Deleted - Sehat Makaan

**Content:**
- **Header:** Account Permanently Deleted warning
- **Message:** Serious Terms violation, permanent termination
- **Impact:** 
  - Account completely removed
  - All data permanently deleted
  - Cannot access any services
  - All bookings/subscriptions cancelled
  - **Action is irreversible**
- **Final Notice:** No further communications
- **Contact:** If error, contact admin immediately

### In-App Notification
None (user deleted before notification can be created)

### Login Behavior (BLOCKED PERMANENTLY)
When deleted user tries to login:
```
❌ Login Failed

User data not found. Please contact support.
```

**Result:** User cannot login, all data permanently erased.

---

## Login Security Check (auth_service.dart)

### Authentication Flow
```dart
1. User enters email/password
2. Firebase authenticates credentials
3. Fetch user data from Firestore
4. CHECK STATUS:
   
   IF status == 'suspended':
     ❌ Logout immediately
     Show: "Account Suspended - Terms Violation"
     Block: All access
   
   ELSE IF status == 'rejected':
     ❌ Logout immediately
     Show: "Account Rejected - {reason}"
     Block: All access
   
   ELSE IF status != 'approved':
     ❌ Logout immediately
     Show: "Account Pending Approval"
     Block: All access
   
   ELSE IF isActive == false:
     ❌ Logout immediately
     Show: "Account Inactive"
     Block: All access
   
   ELSE:
     ✅ Allow login
     Save session
     Grant full access
```

---

## Email Queue System

All emails are queued in Firestore and processed by Cloud Functions:

### Email Queue Document
```dart
email_queue/{emailId}
  to: "doctor@example.com"
  subject: "⚠️ Account Suspended - Sehat Makaan"
  html: "<html>...</html>"
  data: {
    type: 'account_suspended',
    userId: 'xyz123',
    suspendedAt: '2025-01-07T...'
  }
  status: 'pending'
  attempts: 0
  createdAt: [timestamp]
```

### Email Processing
- Cloud Function monitors `email_queue` collection
- Sends emails via configured email service (SendGrid/SMTP)
- Updates status: `pending` → `sent` / `failed`
- Retries on failure (up to 3 attempts)

---

## Complete Flow Examples

### Example 1: Suspend → Unsuspend
```
1. Doctor logs in successfully (status: approved)
2. Admin suspends doctor
   → Email sent: "Account Suspended - Terms Violation"
   → Notification: "Account Suspended"
   → Status: suspended, isActive: false
3. Doctor tries to login
   → ❌ BLOCKED: "Account Suspended..."
4. Admin removes suspension
   → Email sent: "Account Reactivated"
   → Notification: "Account Reactivated"
   → Status: approved, isActive: true
5. Doctor can login successfully again
```

### Example 2: Suspend → Delete
```
1. Doctor logs in successfully (status: approved)
2. Admin suspends doctor
   → Email sent: "Account Suspended"
   → Doctor cannot login
3. Admin deletes doctor permanently
   → Email sent: "Account Permanently Deleted"
   → User document deleted
   → All bookings deleted
   → All subscriptions deleted
   → All notifications deleted
4. Doctor tries to login
   → ❌ BLOCKED: "User data not found"
   → No recovery possible (permanent)
```

### Example 3: Direct Delete
```
1. Doctor has violations
2. Admin clicks Delete
   → Confirmation dialog warns: "PERMANENT DELETION"
3. Admin confirms
   → Email sent: "Account Permanently Deleted"
   → All user data erased
   → Cannot be recovered
4. Doctor receives final email
   → Can contact admin if error
   → Otherwise, permanently removed
```

---

## Status Values

### User Document Status Field
```dart
'pending'    → Awaiting admin approval (new registration)
'approved'   → Active, can login and use all features
'rejected'   → Registration rejected, cannot login
'suspended'  → Temporarily blocked, cannot login (reversible)
[DELETED]    → Permanently removed, no longer exists
```

### isActive Field
```dart
true   → Account active (required for login even if approved)
false  → Account inactive (blocks login)
```

---

## Testing Checklist

### Suspend Account
- [ ] Admin can suspend approved doctor
- [ ] Status changes to 'suspended'
- [ ] isActive becomes false
- [ ] Notification created in app
- [ ] Email sent with Terms violation message
- [ ] User cannot login (blocked with message)
- [ ] Existing session terminated
- [ ] Dashboard shows "SUSPENDED" badge

### Unsuspend Account
- [ ] Admin can remove suspension
- [ ] Status changes to 'approved'
- [ ] isActive becomes true
- [ ] Notification created in app
- [ ] Email sent with reactivation message
- [ ] User can login successfully
- [ ] All features accessible
- [ ] Dashboard shows "APPROVED" badge

### Delete Account
- [ ] Admin sees delete confirmation dialog
- [ ] Warning shows "PERMANENT DELETION"
- [ ] Email sent BEFORE deletion
- [ ] User document deleted
- [ ] All bookings deleted
- [ ] All subscriptions deleted
- [ ] All notifications deleted
- [ ] User cannot login (data not found error)
- [ ] No recovery possible
- [ ] Dashboard removes doctor from list

### Login Blocking
- [ ] Suspended user blocked with Terms message
- [ ] Rejected user blocked with reason
- [ ] Pending user blocked with approval message
- [ ] Inactive user blocked
- [ ] Deleted user blocked with not found error
- [ ] Only approved + active users can login

---

## Email Templates

### 1. Suspension Email
- **Color Theme:** Orange/Warning
- **Icon:** ⚠️
- **Tone:** Serious, formal
- **Key Message:** Terms violation, all activities paused
- **CTA:** Contact admin

### 2. Reactivation Email
- **Color Theme:** Green/Success
- **Icon:** ✅
- **Tone:** Positive, welcoming back
- **Key Message:** Access restored, follow rules
- **CTA:** Login now

### 3. Deletion Email
- **Color Theme:** Red/Danger
- **Icon:** ⛔
- **Tone:** Final, permanent
- **Key Message:** Permanent removal, irreversible
- **CTA:** Contact if error (urgent)

---

## Security Features

1. **Double Check on Login:** Even if suspended status missed, isActive=false blocks login
2. **Immediate Logout:** Suspended users auto-logged out from all devices
3. **Email Before Delete:** User notified before permanent removal
4. **Batch Deletion:** All related data removed in single transaction
5. **No Zombie Accounts:** Deleted users completely removed, no orphaned data
6. **Audit Trail:** Timestamps for suspendedAt, unsuspendedAt, deletedAt
7. **Terms Reference:** All emails mention Terms and Conditions violation

---

## Admin Dashboard UI

### Doctor Card (Suspended)
```
┌─────────────────────────────────┐
│ Dr. Sajoo                      │
│ Endodontist                    │
│ sajoo@example.com              │
│                                │
│ Status: [SUSPENDED] 🔴         │
│                                │
│ [Remove Suspension] (Green)    │
│ [Delete] (Red)                 │
└─────────────────────────────────┘
```

### Doctor Card (Approved)
```
┌─────────────────────────────────┐
│ Dr. Sajoo                      │
│ Endodontist                    │
│ sajoo@example.com              │
│                                │
│ Status: [APPROVED] 🟢          │
│                                │
│ [Suspend Doctor] (Orange)      │
│ [Delete] (Red)                 │
└─────────────────────────────────┘
```

---

## Conclusion

This implementation ensures:
- ✅ Suspended users CANNOT login or use any features
- ✅ Clear Terms violation messaging in all communications
- ✅ Emails sent for suspend/unsuspend/delete actions
- ✅ Delete is truly permanent (all data removed)
- ✅ Proper flow with confirmations and notifications
- ✅ Security checks at authentication level
- ✅ Professional email templates with proper styling

All activities are properly paused/blocked for suspended accounts, and users are clearly informed through multiple channels (email, notification, login message).
