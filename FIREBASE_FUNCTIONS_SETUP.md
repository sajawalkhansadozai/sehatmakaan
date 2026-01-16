# Firebase Cloud Functions Setup Guide for Sehat Makaan

## 📋 Prerequisites

1. Node.js 18+ installed
2. Firebase CLI installed: `npm install -g firebase-tools`
3. Firebase project created
4. Gmail account with App Password

## 🚀 Setup Steps

### 1. Login to Firebase
```bash
firebase login
```

### 2. Initialize Functions (if not already done)
```bash
cd sehat_makaan_flutter
firebase init functions
```
- Select "Use an existing project"
- Choose your Firebase project
- Select JavaScript
- Do not overwrite existing files
- Install dependencies: Yes

### 3. Install Dependencies
```bash
cd functions
npm install
```

### 4. Configure Gmail Credentials

#### Generate Gmail App Password:
1. Go to https://myaccount.google.com/apppasswords
2. Select "Mail" and "Windows Computer"
3. Generate password (save it)

#### Set Firebase Config:
```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-16-digit-app-password"
```

#### Verify Configuration:
```bash
firebase functions:config:get
```

### 5. Deploy Functions
```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendQueuedEmail
```

## 📧 Available Cloud Functions

### 1. `sendQueuedEmail` (Firestore Trigger)
**Purpose**: Automatically sends emails when documents are added to `email_queue` collection

**Trigger**: Firestore onCreate event on `email_queue/{emailId}`

**How it works**:
- Listens for new documents in `email_queue` collection
- Sends email using Nodemailer + Gmail
- Updates document with `sent` status or `failed` status

**No code changes needed** - Flutter already queues emails correctly!

### 2. `retryFailedEmails` (Callable Function)
**Purpose**: Manually retry failed emails (max 3 retries)

**Usage from Flutter**:
```dart
final callable = FirebaseFunctions.instance.httpsCallable('retryFailedEmails');
final result = await callable.call();
print('Retried: ${result.data}');
```

### 3. `cleanOldEmails` (Scheduled Function)
**Purpose**: Runs daily to delete email_queue documents older than 30 days

**Schedule**: Every 24 hours

### 4. `sendTestEmail` (Callable Function)
**Purpose**: Test email configuration

**Usage from Flutter**:
```dart
final callable = FirebaseFunctions.instance.httpsCallable('sendTestEmail');
final result = await callable.call({
  'to': 'test@example.com',
  'subject': 'Test Email',
  'message': 'This is a test message'
});
```

## 🔍 Testing

### Test in Local Emulator:
```bash
cd functions
npm run serve
```

### View Logs:
```bash
# Real-time logs
firebase functions:log --only sendQueuedEmail

# All logs
firebase functions:log
```

### Check Email Queue in Firestore:
1. Open Firebase Console → Firestore Database
2. Go to `email_queue` collection
3. Check document status fields:
   - `status: 'pending'` - Waiting to be sent
   - `status: 'sent'` - Successfully sent
   - `status: 'failed'` - Failed to send
   - `status: 'demo_sent'` - No credentials (demo mode)

## 🐛 Troubleshooting

### Issue: "Gmail authentication failed"
**Solution**: 
1. Make sure you're using App Password, not regular password
2. Enable 2FA on Gmail account first
3. Generate new App Password
4. Re-run: `firebase functions:config:set gmail.password="new-app-password"`
5. Redeploy: `firebase deploy --only functions`

### Issue: "Function not found"
**Solution**:
```bash
# List deployed functions
firebase functions:list

# Redeploy
firebase deploy --only functions
```

### Issue: "Permission denied"
**Solution**:
```bash
# Make sure you're logged in
firebase login

# Check current project
firebase use

# Switch project if needed
firebase use sehat-makaan-project-id
```

## 📊 Monitoring

### View Function Dashboard:
1. Open Firebase Console
2. Go to "Functions" section
3. Monitor:
   - Invocations
   - Execution time
   - Errors
   - Logs

### Email Queue Monitoring:
Create a Firestore index on `email_queue` collection:
```json
{
  "collectionGroup": "email_queue",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

## 💰 Cost Estimation

### Free Tier Includes:
- 2 million invocations/month
- 400,000 GB-seconds compute time
- 200,000 GHz-seconds compute time
- 5 GB egress

**For Sehat Makaan**:
- Estimated: 1000-5000 emails/month
- Well within free tier limits!

## 🔒 Security Rules

The email queue is already protected by Firestore security rules. Only authenticated users can create email_queue documents.

## 📝 Environment Variables

Current configuration variables:
```
gmail.email    = your-email@gmail.com
gmail.password = your-16-digit-app-password
```

Add more if needed:
```bash
firebase functions:config:set stripe.key="sk_test_..." 
firebase functions:config:set payfast.merchant_id="10000100"
```

## ✅ Verification Checklist

After deployment, verify:
- [ ] Functions deployed successfully
- [ ] Gmail credentials configured
- [ ] Test email sent successfully
- [ ] Doctor approval sends email
- [ ] Workshop confirmation sends email
- [ ] Email_queue documents updated with 'sent' status
- [ ] Failed emails show proper error messages

## 🎉 Success!

Once deployed, your Flutter app will automatically send emails through Cloud Functions with no code changes needed!

**What happens now**:
1. Flutter app adds document to `email_queue` collection ✅ (already implemented)
2. Cloud Function triggers automatically ⚡ (just deployed)
3. Email sends via Gmail 📧 (configured)
4. Document updates with status ✅ (automatic)

**Zero changes needed in Flutter code!** The email queue helper is already perfect.
