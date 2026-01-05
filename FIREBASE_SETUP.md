# Firebase Setup Guide for Sehat Makaan

## Prerequisites
1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Firestore Database in your Firebase project

## Setup Steps

### 1. Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Add Project"
3. Enter project name: "sehatmakaan" (or your preferred name)
4. Follow the setup wizard

### 2. Enable Firestore
1. In Firebase Console, go to "Build" > "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select your preferred location
5. Click "Enable"

### 3. Get Firebase Configuration
1. In Firebase Console, click the gear icon next to "Project Overview"
2. Select "Project settings"
3. Scroll down to "Your apps"
4. Click the Web icon (</>) to add a web app
5. Register your app with nickname "sehatmakaan-web"
6. Copy the Firebase configuration values

### 4. Update Firebase Config in Code
Open `lib/main.dart` and replace the demo Firebase configuration with your actual values:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",              // Replace with your apiKey
    authDomain: "YOUR_AUTH_DOMAIN",      // Replace with your authDomain
    projectId: "YOUR_PROJECT_ID",        // Replace with your projectId
    storageBucket: "YOUR_STORAGE_BUCKET",// Replace with your storageBucket
    messagingSenderId: "YOUR_SENDER_ID", // Replace with your messagingSenderId
    appId: "YOUR_APP_ID",                // Replace with your appId
  ),
);
```

### 5. Firestore Security Rules (Optional - For Production)
In Firebase Console > Firestore Database > Rules, update to:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /contact_messages/{document=**} {
      allow read: if request.auth != null; // Only authenticated users can read
      allow write: if true; // Anyone can write (for contact form)
    }
  }
}
```

### 6. Install Dependencies
Run the following command:
```bash
flutter pub get
```

### 7. Run the Application
```bash
flutter run -d chrome
```

## Data Structure
Contact messages are stored in Firestore with the following structure:

**Collection**: `contact_messages`

**Document Fields**:
- `name` (string): Full name of the person
- `email` (string): Email address
- `phone` (string): Phone number
- `message` (string): Message content
- `timestamp` (timestamp): Server timestamp when message was created
- `status` (string): Message status (default: "new")

## Viewing Messages
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Click on `contact_messages` collection
4. View all submitted messages

## Troubleshooting

### Error: Firebase not initialized
- Make sure you've replaced the demo config with your actual Firebase config
- Ensure Firebase.initializeApp() is called before runApp()

### Error: Permission denied
- Check Firestore security rules
- For testing, you can use test mode rules (allow read, write: if true)

### Error: Module not found
- Run `flutter pub get`
- Restart your IDE/editor

## Next Steps (Optional)
1. Set up Firebase Authentication for admin access
2. Create an admin panel to view and manage messages
3. Add email notifications when new messages arrive
4. Implement message status updates (new, read, replied, etc.)
