# Cloud Functions Deployment Guide

## New Cloud Functions Added

### 1. **checkSubscriptionExpiry** (Scheduled Function)
- **Purpose**: Automatically checks for expiring subscriptions and sends notifications
- **Schedule**: Runs daily at 9:00 AM Pakistan time (Asia/Karachi)
- **Triggers**: 
  - 7 days before expiry
  - 3 days before expiry
  - 1 day before expiry
- **Actions**:
  - Creates in-app notifications
  - Sends FCM push notifications
  - Prevents duplicate notifications

### 2. **onAdminBookingCancellation** (Firestore Trigger)
- **Purpose**: Sends notifications when admin cancels a booking
- **Trigger**: When booking status changes to 'cancelled' by admin
- **Features**:
  - Detects admin cancellations (cancelledBy starts with 'admin_')
  - Different messages for refund vs no-refund scenarios
  - Creates in-app notifications
  - Sends FCM push notifications

## Deployment Steps

### Option 1: Deploy All Functions
```bash
cd functions
firebase deploy --only functions
```

### Option 2: Deploy Specific Functions
```bash
# Deploy only the new functions
firebase deploy --only functions:checkSubscriptionExpiry
firebase deploy --only functions:onAdminBookingCancellation
```

## Testing

### Test Subscription Expiry Function
Since the scheduled function runs daily, you can test it manually:

```bash
# Call the function manually (requires Firebase CLI)
firebase functions:shell
> checkSubscriptionExpiry()
```

Or wait for the scheduled time (9:00 AM Pakistan time).

### Test Admin Cancellation Function
1. Login as admin
2. Go to bookings management
3. Cancel a booking with refund or without refund
4. User should receive:
   - In-app notification
   - Push notification (if FCM token exists)

## Verification

### Check Function Logs
```bash
# View real-time logs
firebase functions:log --only checkSubscriptionExpiry
firebase functions:log --only onAdminBookingCancellation

# View all logs
firebase functions:log
```

### Expected Log Messages

**checkSubscriptionExpiry:**
```
🔔 Running subscription expiry check...
Found X active subscriptions
Created expiry warning for subscription abc123 (7 days)
✅ Push notification sent to user xyz789 for 7 days warning
✅ Subscription expiry check complete. Created X notifications.
```

**onAdminBookingCancellation:**
```
✅ In-app notification created for user xyz789 (Refund: true)
✅ Push notification sent to user xyz789
```

## Dependencies

All required dependencies are already in `package.json`:
- `firebase-functions`
- `firebase-admin`
- `nodemailer`

## Environment Configuration

No additional environment configuration needed. The functions use:
- Firestore collections: `subscriptions`, `bookings`, `notifications`, `users`
- FCM (Firebase Cloud Messaging) - configured through Firebase Admin SDK

## Important Notes

1. **Subscription Expiry Checks**: 
   - Runs automatically every day at 9 AM
   - Checks all active subscriptions
   - Creates notifications only once per threshold (7/3/1 day)

2. **Admin Cancellation Detection**:
   - Uses `cancelledBy: 'admin_cancellation'` field
   - Only triggers for admin cancellations
   - User cancellations won't trigger this function

3. **Duplicate Prevention**:
   - Expiry function checks for existing notifications before creating new ones
   - Uses `relatedSubscriptionId` and `daysRemaining` to prevent duplicates

4. **FCM Token Handling**:
   - Automatically removes invalid tokens
   - Gracefully handles missing tokens
   - Logs push notification failures

## Troubleshooting

### Function Not Triggering
- Check Firebase Console → Functions for deployment status
- Verify function logs for errors
- Ensure Firestore collections exist

### Notifications Not Received
- Check if FCM token exists for user
- Verify user's notification permissions
- Check function logs for push notification errors

### Testing Scheduled Function
- Use Firebase CLI shell: `firebase functions:shell`
- Or temporarily change schedule to `'*/5 * * * *'` (every 5 minutes) for testing
- Remember to revert schedule after testing!

## Cost Optimization

Both functions are optimized for cost:
- **checkSubscriptionExpiry**: Runs once daily, processes only active subscriptions
- **onAdminBookingCancellation**: Only triggers on status updates to 'cancelled'

Estimated monthly cost: Minimal (likely within Firebase free tier for small-medium usage)
