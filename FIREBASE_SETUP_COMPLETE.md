# 🔥 Sehat Makaan Flutter - Complete Firebase Setup

## ✅ Setup Complete!

Your Flutter app is now **fully configured** to work with Firebase Firestore, Firebase Authentication, and Firebase Storage.

---

## 📦 **What's Been Configured**

### 1. **Firebase Initialization** ✅
- ✅ Firebase initialized in `main.dart`
- ✅ Firebase options configured for Web, Android, and iOS
- ✅ All Firebase packages installed and ready

### 2. **Complete Services Created** ✅

| Service | File | Purpose |
|---------|------|---------|
| **Auth Service** | `services/auth_service.dart` | Registration, Login, Logout, Password Reset |
| **Booking Service** | `services/booking_service.dart` | Create, Read, Cancel bookings |
| **Subscription Service** | `services/subscription_service.dart` | Monthly/Hourly package management |
| **Workshop Service** | `services/workshop_service.dart` | Workshop CRUD & Registration |
| **Admin Service** | `services/admin_service.dart` | User approval, Stats, Management |
| **Notification Service** | `services/notification_service.dart` | Push notifications, Alerts |
| **Firebase Storage Service** | `services/firebase_storage_service.dart` | File uploads (images, PDFs) |
| **PayFast Service** | `services/payfast_service.dart` | Payment processing |

### 3. **Complete Data Models** ✅

| Model | File | Fields |
|-------|------|--------|
| **UserModel** | `models/firebase_models.dart` | 18 fields (fullName, email, PMDC, CNIC, specialty, etc.) |
| **AdminModel** | `models/firebase_models.dart` | 6 fields (username, email, role, etc.) |
| **BookingModel** | `models/firebase_models.dart` | 17 fields (suite, date, time, duration, payment, etc.) |
| **SubscriptionModel** | `models/subscription_model.dart` | 20+ fields (hours, type, price, etc.) |
| **WorkshopModel** | `models/firebase_models.dart` | 20 fields (title, price, dates, location, etc.) |
| **WorkshopRegistrationModel** | `models/firebase_models.dart` | 13 fields (biodata, status, payment, etc.) |
| **NotificationModel** | `models/firebase_models.dart` | 8 fields (title, message, type, etc.) |

---

## 🚀 **How to Use Firebase Services**

### **Example 1: User Registration & Login**

```dart
import 'package:sehat_makaan_flutter/services/auth_service.dart';

final authService = AuthService();

// Register new doctor
onPressed: () async {
  final result = await authService.registerDoctor(
    email: 'doctor@example.com',
    password: 'password123',
    fullName: 'Dr. Ahmed Ali',
    username: 'ahmed_ali',
    age: 35,
    gender: 'Male',
    pmdcNumber: 'PMDC12345',
    cnicNumber: '12345-1234567-1',
    phoneNumber: '+92-300-1234567',
    specialty: 'Dental',
    yearsOfExperience: 10,
  );

  if (result['success']) {
    print('✅ Registration successful!');
    Navigator.pushNamed(context, '/verification');
  } else {
    showErrorDialog(result['error']);
  }
}

// Login doctor
onPressed: () async {
  final result = await authService.loginDoctor(
    email: emailController.text,
    password: passwordController.text,
  );

  if (result['success']) {
    Navigator.pushReplacementNamed(context, '/dashboard');
  } else {
    showErrorDialog(result['error']);
  }
}
```

### **Example 2: Realtime Bookings with StreamBuilder**

```dart
import 'package:sehat_makaan_flutter/services/booking_service.dart';

final bookingService = BookingService();

StreamBuilder<List<BookingModel>>(
  stream: bookingService.getUserBookings(userId, limit: 10),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    final bookings = snapshot.data ?? [];
    
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return ListTile(
          title: Text('${booking.suiteType} Suite'),
          subtitle: Text('${booking.bookingDate} at ${booking.timeSlot}'),
          trailing: Text('PKR ${booking.totalAmount}'),
        );
      },
    );
  },
)
```

### **Example 3: Create Booking**

```dart
import 'package:sehat_makaan_flutter/services/booking_service.dart';

final bookingService = BookingService();

onPressed: () async {
  final result = await bookingService.createBooking(
    userId: currentUserId,
    suiteType: 'dental',
    bookingDate: selectedDate,
    timeSlot: '10:00',
    durationMins: 60,
    baseRate: 5000.0,
    totalAmount: 5500.0,
    addons: ['wifi', 'parking'],
  );

  if (result['success']) {
    print('✅ Booking created: ${result['bookingId']}');
    showSuccessDialog();
  } else {
    showErrorDialog(result['error']);
  }
}
```

### **Example 4: Admin - Approve/Reject Users**

```dart
import 'package:sehat_makaan_flutter/services/admin_service.dart';

final adminService = AdminService();

// Get pending users (Realtime)
StreamBuilder<List<UserModel>>(
  stream: adminService.getPendingUsers(),
  builder: (context, snapshot) {
    final users = snapshot.data ?? [];
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            title: Text(user.fullName),
            subtitle: Text('${user.specialty} - ${user.email}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    final result = await adminService.approveUser(user.id);
                    if (result['success']) {
                      showSnackBar('User approved!');
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => showRejectDialog(user.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  },
)
```

### **Example 5: Admin Statistics**

```dart
onPressed: () async {
  final stats = await adminService.getAdminStats();
  
  print('Total Doctors: ${stats['totalDoctors']}');
  print('Pending Approvals: ${stats['pendingDoctors']}');
  print('Today Bookings: ${stats['todayBookings']}');
  print('Active Subscriptions: ${stats['activeSubscriptions']}');
  print('Monthly Revenue: PKR ${stats['monthlyRevenue']}');
}
```

---

## 📚 **Firestore Database Structure**

Your Firebase Firestore database should have these collections:

```
firestore/
├── users/                          # All doctors/users
│   └── {userId}/
│       ├── email: string
│       ├── fullName: string
│       ├── pmdcNumber: string
│       ├── specialty: string
│       ├── status: 'pending' | 'approved' | 'rejected'
│       └── ...
│
├── admins/                         # Admin users
│   └── {adminId}/
│       ├── username: string
│       ├── email: string
│       └── role: string
│
├── bookings/                       # All bookings
│   └── {bookingId}/
│       ├── userId: string
│       ├── suiteType: 'dental' | 'medical' | 'aesthetic'
│       ├── bookingDate: timestamp
│       ├── timeSlot: string
│       ├── totalAmount: number
│       ├── status: 'confirmed' | 'cancelled' | 'completed'
│       └── ...
│
├── subscriptions/                  # Monthly/hourly packages
│   └── {subscriptionId}/
│       ├── userId: string
│       ├── type: 'monthly' | 'hourly'
│       ├── hours: number
│       ├── hoursUsed: number
│       ├── remainingHours: number
│       ├── isActive: boolean
│       └── ...
│
├── workshops/                      # Workshop management
│   └── {workshopId}/
│       ├── title: string
│       ├── price: number
│       ├── maxParticipants: number
│       ├── currentParticipants: number
│       ├── startDate: timestamp
│       ├── isActive: boolean
│       └── ...
│
├── workshop_registrations/         # Workshop registrations
│   └── {registrationId}/
│       ├── userId: string
│       ├── workshopId: string
│       ├── name: string
│       ├── status: 'pending' | 'confirmed' | 'rejected'
│       └── ...
│
└── notifications/                  # User notifications
    └── {notificationId}/
        ├── userId: string
        ├── title: string
        ├── message: string
        ├── isRead: boolean
        └── ...
```

---

## 🔐 **Firebase Authentication Setup**

### User Types:
1. **Doctors (Regular Users)** - Register via app, needs admin approval
2. **Admins** - Special access to admin dashboard

### Authentication Flow:
```
1. User registers → Firebase Auth creates account
2. User data stored in Firestore → status: 'pending'
3. Admin approves → status: 'approved'
4. User can login → Checked against 'approved' status
```

---

## 🎯 **Next Steps**

### 1. **Setup Firebase Console** (If not already done)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init
```

### 2. **Configure Firebase Security Rules**

Go to Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - users can read their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null;
    }
    
    // Admins collection - only admins can read
    match /admins/{adminId} {
      allow read, write: if request.auth != null && 
                           get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Bookings - users can read their own bookings
    match /bookings/{bookingId} {
      allow read: if request.auth != null && 
                     (resource.data.userId == request.auth.uid || 
                      get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null;
    }
    
    // Subscriptions - users can read their own subscriptions
    match /subscriptions/{subscriptionId} {
      allow read: if request.auth != null && 
                     (resource.data.userId == request.auth.uid || 
                      get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null;
    }
    
    // Workshops - public read, admin write
    match /workshops/{workshopId} {
      allow read: if true;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Workshop Registrations
    match /workshop_registrations/{registrationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Notifications - users can read their own notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

### 3. **Test Your Setup**

```bash
# Run the app
flutter run

# Or build for release
flutter build apk
flutter build ios
flutter build web
```

---

## 📖 **Complete Documentation**

All examples and patterns are in:
```
lib/services/firebase_usage_examples.dart
```

---

## ✅ **Checklist**

- [x] Firebase initialized in main.dart
- [x] Authentication service (register, login, logout)
- [x] Booking service (create, read, cancel)
- [x] Subscription service (monthly/hourly packages)
- [x] Workshop service (CRUD + registration)
- [x] Admin service (approve, reject, stats)
- [x] Notification service (push notifications)
- [x] All data models created
- [x] Flutter analyzer: 0 errors ✅
- [ ] Firebase Console setup (You need to do this)
- [ ] Security rules configured
- [ ] Test authentication flow
- [ ] Test booking flow
- [ ] Test admin approval flow

---

## 🎉 **Your App is Ready!**

All Firebase services are configured and ready to use. Just:
1. Set up your Firebase console
2. Configure security rules
3. Start using the services in your screens

**Happy Coding! 🚀**
