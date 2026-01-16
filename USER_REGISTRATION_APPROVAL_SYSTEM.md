# User Registration Approval System

## Overview
Implemented a complete admin approval system for user registration, where new doctors must be approved by admin before they can login to the platform.

## Implementation Date
Completed: January 2025

## System Flow

### 1. User Registration
**File:** `lib/screens/registration_page.dart`

- User fills registration form with:
  - Personal info (name, email, age, gender)
  - Professional details (specialty, years of experience, PMDC number, CNIC)
  - Password (for Firebase Authentication)
  
- **New Fields Added:**
  - Password field with visibility toggle
  - Confirm password field with matching validation
  
- **Firebase Integration:**
  - Creates Firebase Authentication account with email/password
  - Creates user document in `users` collection with `status: 'pending'`
  - Sets `isActive: false` (prevents login until approved)
  - Sends notification to all active admins

- **User Experience:**
  - Success message: "Registration Submitted! Awaiting admin approval."
  - Redirects to verification page showing pending status

### 2. Admin Notification
**Functions:** `functions/index.js`

#### Function: `onUserRegistration`
- **Trigger:** onCreate on `users` collection where status='pending'
- **Actions:**
  - Queries all active admins from `admins` collection
  - Creates notification for each admin
  - Queues professional HTML email with user details:
    - Full name, email, specialty
    - PMDC number, CNIC, phone
    - Years of experience, age, gender
  - Email includes "Review Registration" button link

### 3. Admin Dashboard
**File:** `lib/screens/admin_dashboard_page.dart`

- **Updated to use `users` collection** (was using `doctors` previously)
- Admin sees pending registrations in "Doctors" tab
- Can filter by status: All, Pending, Approved, Rejected
- Real-time updates via Firestore snapshots

#### Approve Action
- Updates user status to `'approved'`
- Sets `isActive: true` (enables login)
- Creates notification for user
- Triggers `onUserApproval` cloud function

#### Reject Action
- Shows rejection reason dialog
- Updates user status to `'rejected'`
- Stores rejection reason
- Creates notification for user
- Triggers `onUserRejection` cloud function

### 4. User Approval Notification
**Function:** `onUserApproval`

- **Trigger:** onUpdate when status changes from 'pending' to 'approved'
- **Actions:**
  - Creates notification: "🎉 Registration Approved!"
  - Queues welcome email with:
    - Congratulations message
    - Login instructions
    - Platform features overview
    - Support contact details

### 5. User Rejection Notification
**Function:** `onUserRejection`

- **Trigger:** onUpdate when status changes from 'pending' to 'rejected'
- **Actions:**
  - Creates notification with rejection reason
  - Queues email explaining:
    - Registration could not be approved
    - Rejection reason (if provided)
    - Contact information for appeals

### 6. Login Protection
**File:** `lib/services/auth_service.dart`

- **Already implemented validation** in `loginDoctor()` method:
  - Checks user `status` field after authentication
  - Blocks login if status != 'approved'
  - Shows appropriate error messages:
    - Pending: "Your account is pending approval."
    - Rejected: "Your account has been rejected: [reason]"
  - Signs out user immediately if not approved

### 7. Verification Page Update
**File:** `lib/screens/verification_page.dart`

- Updated message from "Verification in Progress" to "Registration Submitted"
- Changed description to explain admin approval process
- Updated status text: "Awaiting admin approval"

## Database Schema

### Users Collection
```javascript
{
  fullName: string,
  email: string,
  age: number,
  gender: string,
  yearsOfExperience: number,
  pmdcNumber: string,
  cnicNumber: string,
  phoneNumber: string,
  specialty: string,
  status: 'pending' | 'approved' | 'rejected',
  isActive: boolean,
  createdAt: Timestamp,
  approvedAt?: Timestamp,
  rejectedAt?: Timestamp,
  rejectionReason?: string,
  updatedAt?: Timestamp
}
```

### Notifications Collection
```javascript
{
  userId: string,
  type: 'new_registration' | 'registration_approved' | 'registration_rejected',
  title: string,
  message: string,
  priority: 'normal' | 'high',
  isRead: boolean,
  createdAt: Timestamp,
  metadata?: {
    doctorId: string,
    doctorName: string,
    doctorEmail: string,
    specialty: string,
    pmdcNumber: string
  }
}
```

## Cloud Functions Deployed

### 1. onUserRegistration
- **Region:** us-central1
- **Runtime:** Node.js 20 (1st Gen)
- **Trigger:** Firestore onCreate (users collection)
- **Purpose:** Notify admins of new registration

### 2. onUserApproval
- **Region:** us-central1
- **Runtime:** Node.js 20 (1st Gen)
- **Trigger:** Firestore onUpdate (pending → approved)
- **Purpose:** Send welcome notification to approved user

### 3. onUserRejection
- **Region:** us-central1
- **Runtime:** Node.js 20 (1st Gen)
- **Trigger:** Firestore onUpdate (pending → rejected)
- **Purpose:** Send rejection notification to user

## Email Templates

All emails use professional HTML design with:
- Gradient headers (brand colors: #006876, #90D26D, #FF6B35)
- Clean, responsive layout
- Clear call-to-action buttons
- Contact information
- Consistent branding

## Security Features

1. **Firebase Authentication:** All users must create account through Firebase
2. **Status Validation:** Login blocked until admin approval
3. **isActive Flag:** Additional protection layer
4. **Email Verification:** Built into Firebase Auth flow
5. **Admin-Only Access:** Only admins can approve/reject

## User States

```
Registration → Pending → Admin Review → Approved/Rejected
                ↓                        ↓           ↓
            Notification            Can Login   Cannot Login
                ↓                        ↓           ↓
            Email Sent              Dashboard   Error Message
```

## Admin Workflow

1. New registration creates notification (high priority)
2. Admin receives email with all user details
3. Admin logs into admin dashboard
4. Reviews doctor details in Doctors tab (filters by Pending)
5. Makes decision:
   - **Approve:** User gets welcome email, can login immediately
   - **Reject:** User gets rejection email with reason, cannot login

## Files Modified

### Registration Flow
- `lib/screens/registration_page.dart` - Added Firebase integration, password fields
- `lib/screens/verification_page.dart` - Updated messaging for approval flow

### Admin Dashboard
- `lib/screens/admin_dashboard_page.dart` - Updated to use 'users' collection
  - `_startRealtimeListeners()` - Changed from 'doctors' to 'users'
  - `_loadStats()` - Updated queries to 'users' collection
  - `_loadDoctors()` - Updated query to 'users' collection
  - `_approveDoctorMutation()` - Simplified (no credential generation)
  - `_rejectDoctorMutation()` - Streamlined notification only
  - `_deleteDoctorMutation()` - Updated to 'users' collection

### Cloud Functions
- `functions/index.js` - Added 3 new functions:
  - `exports.onUserRegistration`
  - `exports.onUserApproval`
  - `exports.onUserRejection`

### No Changes Needed
- `lib/services/auth_service.dart` - Already had status validation
- `lib/screens/admin/tabs/doctors_tab.dart` - Works with any collection
- `lib/screens/admin/widgets/doctor_card_widget.dart` - Generic design

## Testing Checklist

- [x] User can register with email/password
- [x] Registration creates pending user in Firestore
- [x] Admin receives notification (in-app)
- [x] Admin receives email with user details
- [x] Admin can see pending users in dashboard
- [x] Admin can approve user (status → approved, isActive → true)
- [x] Admin can reject user with reason
- [x] Approved user receives welcome email
- [x] Rejected user receives rejection email
- [x] Pending user cannot login (blocked by auth service)
- [x] Rejected user cannot login (blocked by auth service)
- [x] Approved user can login successfully
- [x] Cloud functions deployed successfully

## Future Enhancements

1. **Email Verification:** Require email verification before admin review
2. **Document Upload:** Allow doctors to upload PMDC certificate
3. **Batch Approval:** Allow admin to approve multiple doctors at once
4. **Auto-Approval:** Auto-approve doctors with verified PMDC numbers
5. **Re-application:** Allow rejected users to reapply after certain period
6. **Audit Log:** Track all admin approval/rejection actions
7. **Push Notifications:** Mobile push notifications for status updates

## Deployment Notes

- All 3 cloud functions deployed successfully on [deployment date]
- Firebase region: us-central1
- Function runtime: Node.js 20
- No breaking changes to existing code
- Backward compatible with existing admin dashboard

## Support & Contact

For issues or questions about this implementation:
- Email: admin@sehatmakaan.com
- Support: support@sehatmakaan.com

---

**Implementation Status:** ✅ Complete and Deployed
**Last Updated:** January 2025
