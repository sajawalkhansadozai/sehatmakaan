# 🚀 Quick Start Guide - Workshop Revenue System

## ⚡ TL;DR (Quick Summary)

**What**: Workshop payments go to admin first, auto-released to creator 1 hour after workshop ends  
**Who Pays Fees**: Creator (2.9% + PKR 3 per transaction)  
**When Released**: Automatic after 1 hour, or manual by admin  
**Admin Control**: Can hold or release payments anytime

---

## 📱 Flutter Integration Code

### 1. Admin Hold Payment
```dart
Future<void> holdWorkshopPayment(String workshopId, String reason) async {
  try {
    final result = await FirebaseFunctions.instance
      .httpsCallable('adminControlWorkshopPayout')
      .call({
        'workshopId': workshopId,
        'action': 'hold',
        'reason': reason,
      });
    
    if (result.data['success'] == true) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment held successfully')),
      );
    }
  } catch (e) {
    // Handle error
    print('Error: $e');
  }
}
```

### 2. Admin Release Payment
```dart
Future<void> releaseWorkshopPayment(String workshopId, String reason) async {
  try {
    final result = await FirebaseFunctions.instance
      .httpsCallable('adminControlWorkshopPayout')
      .call({
        'workshopId': workshopId,
        'action': 'release',
        'reason': reason,
      });
    
    if (result.data['success'] == true) {
      final netAmount = result.data['netAmount'];
      final payoutId = result.data['payoutId'];
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment released: PKR $netAmount')),
      );
    }
  } catch (e) {
    // Handle error
    print('Error: $e');
  }
}
```

### 3. View Payout History (Admin)
```dart
Future<List<Map<String, dynamic>>> getWorkshopPayouts(String workshopId) async {
  try {
    final result = await FirebaseFunctions.instance
      .httpsCallable('getPayoutHistory')
      .call({'workshopId': workshopId});
    
    if (result.data['success'] == true) {
      return List<Map<String, dynamic>>.from(result.data['payouts']);
    }
    return [];
  } catch (e) {
    print('Error: $e');
    return [];
  }
}
```

### 4. View Creator's Payouts
```dart
Future<List<Map<String, dynamic>>> getMyPayouts(String creatorId) async {
  try {
    final result = await FirebaseFunctions.instance
      .httpsCallable('getPayoutHistory')
      .call({'creatorId': creatorId});
    
    if (result.data['success'] == true) {
      return List<Map<String, dynamic>>.from(result.data['payouts']);
    }
    return [];
  } catch (e) {
    print('Error: $e');
    return [];
  }
}
```

---

## 🎨 Sample Admin UI Widget

```dart
class WorkshopPaymentControlCard extends StatelessWidget {
  final String workshopId;
  final String workshopTitle;
  final bool isPaymentHeld;
  final bool isRevenueReleased;

  const WorkshopPaymentControlCard({
    required this.workshopId,
    required this.workshopTitle,
    required this.isPaymentHeld,
    required this.isRevenueReleased,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workshopTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isRevenueReleased 
                  ? Colors.green 
                  : isPaymentHeld 
                    ? Colors.orange 
                    : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isRevenueReleased 
                  ? '✅ Released' 
                  : isPaymentHeld 
                    ? '⏸️ On Hold' 
                    : '⏳ Pending',
                style: TextStyle(color: Colors.white),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action Buttons
            if (!isRevenueReleased) ...[
              Row(
                children: [
                  if (!isPaymentHeld)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.pause_circle),
                        label: Text('Hold Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () => _showHoldDialog(context),
                      ),
                    ),
                  
                  if (isPaymentHeld) SizedBox(width: 8),
                  
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check_circle),
                      label: Text('Release Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _showReleaseDialog(context),
                    ),
                  ),
                ],
              ),
            ],
            
            // View History
            TextButton.icon(
              icon: Icon(Icons.history),
              label: Text('View Payout History'),
              onPressed: () => _showPayoutHistory(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showHoldDialog(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hold Payment'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Enter reason for holding payment',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await holdWorkshopPayment(workshopId, reasonController.text);
            },
            child: Text('Hold'),
          ),
        ],
      ),
    );
  }

  void _showReleaseDialog(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Release Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Release workshop revenue to creator?'),
            SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add a note about this release',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await releaseWorkshopPayment(workshopId, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Release'),
          ),
        ],
      ),
    );
  }

  void _showPayoutHistory(BuildContext context) async {
    final payouts = await getWorkshopPayouts(workshopId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payout History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: payouts.length,
            itemBuilder: (context, index) {
              final payout = payouts[index];
              return ListTile(
                title: Text('PKR ${payout['netAmount']}'),
                subtitle: Text(
                  '${payout['releaseType']} - ${payout['releasedAt']}'
                ),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 Revenue Calculation Widget

```dart
class RevenueBreakdownWidget extends StatelessWidget {
  final double totalRevenue;
  final int participantCount;

  const RevenueBreakdownWidget({
    required this.totalRevenue,
    required this.participantCount,
  });

  double get perTransactionFee {
    final perPerson = totalRevenue / participantCount;
    return (perPerson * 0.029) + 3; // 2.9% + PKR 3
  }

  double get totalFees => perTransactionFee * participantCount;
  double get netRevenue => totalRevenue - totalFees;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            _buildRow('Total Collected', totalRevenue, Colors.blue),
            _buildRow('Participants', participantCount.toDouble(), Colors.grey, 
              isCount: true),
            _buildRow('PayFast Fees', -totalFees, Colors.red),
            Divider(thickness: 2),
            _buildRow('NET TO CREATOR', netRevenue, Colors.green, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double value, Color color, 
    {bool isCount = false, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isCount 
              ? value.toInt().toString() 
              : 'PKR ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔍 Firestore Security Rules

Add these rules to your `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Workshop Payouts - Read only
    match /workshop_payouts/{payoutId} {
      allow read: if request.auth != null && (
        // Admin can read all
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin' ||
        // Creator can read their own
        resource.data.creatorId == request.auth.uid
      );
      allow write: if false; // Only Cloud Functions can write
    }
    
    // Admin Actions - Admin only
    match /admin_actions/{actionId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
      allow write: if false; // Only Cloud Functions can write
    }
    
    // Workshops - Update revenue fields
    match /workshops/{workshopId} {
      allow read: if true; // Public workshops
      allow update: if request.auth != null && (
        // Creator can update their workshop
        resource.data.creatorId == request.auth.uid ||
        // Admin can update any workshop
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin'
      ) && (
        // But cannot modify revenue fields directly
        !request.resource.data.diff(resource.data).affectedKeys().hasAny([
          'revenueReleased', 'totalRevenue', 'totalFees', 'netRevenue', 'payoutId'
        ])
      );
    }
  }
}
```

---

## 📋 Testing Checklist

### ✅ Before Going Live

- [ ] Test auto-release with workshop ended 2 hours ago
- [ ] Test admin hold function
- [ ] Test admin release function
- [ ] Test payout history (admin view)
- [ ] Test payout history (creator view)
- [ ] Verify email notifications sent
- [ ] Check Firestore for payout records
- [ ] Check admin_actions logging
- [ ] Verify revenue calculation correct
- [ ] Test with different participant counts

### ⚡ Quick Test Script

```dart
// Run this in your Flutter app as admin
Future<void> quickTest() async {
  final testWorkshopId = 'YOUR_TEST_WORKSHOP_ID';
  
  // 1. Try to hold payment
  print('Testing hold...');
  await holdWorkshopPayment(testWorkshopId, 'Testing hold function');
  await Future.delayed(Duration(seconds: 2));
  
  // 2. Try to release payment
  print('Testing release...');
  await releaseWorkshopPayment(testWorkshopId, 'Testing release function');
  await Future.delayed(Duration(seconds: 2));
  
  // 3. Get payout history
  print('Testing history...');
  final payouts = await getWorkshopPayouts(testWorkshopId);
  print('Found ${payouts.length} payouts');
  
  print('✅ All tests complete!');
}
```

---

## 🚨 Troubleshooting

### Payment Not Auto-Released?

**Check Firestore** (`workshops` collection):
```dart
final doc = await FirebaseFirestore.instance
  .collection('workshops')
  .doc(workshopId)
  .get();

print('End time: ${doc.data()['endDateTime']}');
print('Revenue released: ${doc.data()['revenueReleased']}');
print('Payment hold: ${doc.data()['paymentHold']}');
```

**Check Cloud Function Logs**:
```bash
firebase functions:log --only autoReleaseWorkshopRevenue --limit 50
```

### Admin Function Not Working?

**Verify Admin Status**:
```dart
final user = await FirebaseFirestore.instance
  .collection('users')
  .doc(currentUserId)
  .get();

print('User type: ${user.data()['userType']}'); // Should be 'admin'
```

### Email Not Received?

**Check Email Queue**:
```dart
final emails = await FirebaseFirestore.instance
  .collection('email_queue')
  .where('to', isEqualTo: 'creator@example.com')
  .orderBy('createdAt', descending: true)
  .limit(10)
  .get();

print('Pending emails: ${emails.docs.length}');
```

---

## 📞 Quick Reference

| Action | Function | Type |
|--------|----------|------|
| Auto-release revenue | `autoReleaseWorkshopRevenue` | Scheduled |
| Hold payment | `adminControlWorkshopPayout` | Callable |
| Release payment | `adminControlWorkshopPayout` | Callable |
| View history | `getPayoutHistory` | Callable |

**Admin Email**: sehatmakaan@gmail.com  
**PayFast Fee**: 2.9% + PKR 3 per transaction  
**Auto-release Time**: 1 hour after workshop end

---

## 🎉 You're All Set!

The revenue system is fully deployed and ready to use. Just integrate the Flutter code above into your admin panel and creator dashboard.

**Need Help?** Check the detailed documentation in:
- `WORKSHOP_REVENUE_SYSTEM.md` - Complete technical guide
- `WORKSHOP_REVENUE_DEPLOYMENT_COMPLETE.md` - Deployment details

---

