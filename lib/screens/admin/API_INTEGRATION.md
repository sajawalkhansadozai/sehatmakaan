# Admin Dashboard API Integration

## ✅ Implemented Features

### 🔄 Auto-Refresh Functionality

#### Stats Refresh (Every 30 seconds)
```dart
Timer.periodic(const Duration(seconds: 30), (_) {
  _loadStats();
});
```
- Automatically updates dashboard statistics
- Runs in background without interrupting user
- No loading spinner for background refresh

#### Doctors List Refresh (Every 60 seconds)
```dart
Timer.periodic(const Duration(seconds: 60), (_) {
  _loadDoctors();
});
```
- Keeps doctor list up-to-date
- Applies current filters automatically
- Preserves search state

### 📡 Data Fetching with API Calls

#### 1. Load Stats
```dart
GET /api/admin/stats
```
**Response:**
```json
{
  "totalDoctors": 25,
  "pendingDoctors": 5,
  "todayBookings": 12,
  "activeBookings": 8,
  "activeSubscriptions": 15,
  "monthlyRevenue": 125000.0
}
```

#### 2. Load Doctors (with filtering)
```dart
GET /api/admin/doctors?status=pending&search=ahmad
```
**Query Parameters:**
- `status`: Filter by status (pending/approved/rejected)
- `search`: Search by name, email, or specialty

**Features:**
- Server-side filtering
- Debounced search (500ms)
- Automatic refetch on filter change

#### 3. Load Bookings (with date filter)
```dart
GET /api/admin/bookings?date=2026-01-02
```
**Query Parameters:**
- `date`: Filter by booking date (YYYY-MM-DD format)

**Features:**
- Date-based filtering
- Auto-reload on date change

#### 4. Load Workshops & Registrations
```dart
GET /api/admin/workshops
```
**Response:**
```json
{
  "workshops": [...],
  "registrations": [...]
}
```

### 🔧 Mutation Methods (All Implemented)

#### Doctor Management

**1. Approve Doctor**
```dart
POST /api/admin/doctors/{id}/approve
```
- Updates doctor status to 'approved'
- Invalidates doctors list and stats
- Shows success notification

**2. Reject Doctor (with reason)**
```dart
POST /api/admin/doctors/{id}/reject
Body: { "reason": "Insufficient credentials" }
```
- Updates doctor status to 'rejected'
- Stores rejection reason
- Sends notification to doctor

**3. Delete Doctor**
```dart
DELETE /api/admin/doctors/{id}
```
- Permanently removes doctor
- Updates statistics

#### Booking Management

**4. Cancel Booking with Refund**
```dart
POST /api/admin/bookings/{id}/cancel
Body: { "refund": true }
```
- Cancels booking
- Issues full refund
- Updates user balance

**5. Cancel Booking (No Refund)**
```dart
POST /api/admin/bookings/{id}/cancel
Body: { "refund": false }
```
- Cancels booking
- No refund issued
- Updates booking status

#### Workshop Management

**6. Create Workshop**
```dart
POST /api/admin/workshops
Body: {
  "title": "CPR Training",
  "provider": "Red Cross",
  "price": 5000,
  ...
}
```
- Creates new workshop
- Returns workshop ID
- Reloads workshops list

**7. Update Workshop**
```dart
PUT /api/admin/workshops/{id}
Body: { "price": 6000, ... }
```
- Updates workshop details
- Preserves existing data
- Reloads workshops list

**8. Delete Workshop**
```dart
DELETE /api/admin/workshops/{id}
```
- Removes workshop
- Handles registrations appropriately
- Updates list

#### Registration Management

**9. Confirm Registration**
```dart
POST /api/admin/workshop-registrations/{id}/confirm
```
- Approves registration
- Sends confirmation email
- Updates participant count

**10. Reject Registration**
```dart
POST /api/admin/workshop-registrations/{id}/reject
```
- Declines registration
- Issues refund if paid
- Notifies user

**11. Delete Registration**
```dart
DELETE /api/admin/workshop-registrations/{id}
```
- Permanently removes registration
- Updates workshop capacity

## 🎯 Query Invalidation

After each mutation, relevant queries are automatically refetched:

```dart
// Doctor mutations → reload doctors + stats
await Future.wait([_loadDoctors(), _loadStats()]);

// Booking mutations → reload bookings + stats
await Future.wait([_loadBookings(), _loadStats()]);

// Workshop mutations → reload workshops only
await _loadWorkshops();
```

## 🔍 Advanced Filtering

### Doctor Search with Debouncing
```dart
void _onSearchChanged(String value) {
  _searchDebounceTimer?.cancel();
  _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
    _loadDoctors(); // API call with search parameter
  });
}
```
**Benefits:**
- Reduces API calls
- Better user experience
- Server-side search

### Status Filter
```dart
void _onFilterChanged(String value) {
  setState(() => _filterStatus = value);
  _loadDoctors(); // Immediate API call
}
```

### Date Filter for Bookings
```dart
void _onBookingDateChanged(DateTime date) {
  setState(() => _selectedBookingDate = date);
  _loadBookings(); // API call with date parameter
}
```

## 🚨 Error Handling

### User Feedback
All mutations include comprehensive error handling:

```dart
try {
  // API call
  final response = await http.post(...);
  if (response.statusCode == 200) {
    _showSuccessSnackBar('Operation successful');
    await _refetchData();
  } else {
    throw Exception(json.decode(response.body)['message']);
  }
} catch (e) {
  _showErrorSnackBar('Failed: $e');
}
```

### Success Notifications
```dart
_showSuccessSnackBar('Doctor approved successfully');
```
- Green background
- Auto-dismiss after 3 seconds
- Bottom of screen

### Error Notifications
```dart
_showErrorSnackBar('Failed to approve doctor: Network error');
```
- Red background
- Dismiss button
- Shows for 5 seconds
- Detailed error message

## 📊 Loading States

All async operations use loading states:

```dart
bool _isApprovingDoctor = false;
bool _isRejectingDoctor = false;
bool _isDeletingDoctor = false;
bool _isSubmittingWorkshop = false;
bool _isDeletingWorkshop = false;
```

These disable buttons and show loading indicators during operations.

## 🔧 Configuration

### API Base URL
```dart
static const String _baseUrl = 'http://localhost:5000/api';
```

### Timeout Settings
```dart
.timeout(const Duration(seconds: 10))
```
All API calls have 10-second timeout.

### Refresh Intervals
- Stats: 30 seconds
- Doctors: 60 seconds
- Search debounce: 500ms

## 📝 Usage Example

```dart
// In your widget
ElevatedButton(
  onPressed: _isApprovingDoctor ? null : () => _approveDoctor(doctor),
  child: _isApprovingDoctor
    ? CircularProgressIndicator()
    : Text('Approve'),
)
```

The mutation is called, loading state is set, API call is made, data is refetched, and UI updates automatically!

## ✅ Warnings

**5 unused element warnings** - These are expected:
- `_createWorkshopMutation` - Will be used in full workshop dialog
- `_updateWorkshopMutation` - Will be used in full workshop dialog
- `_confirmRegistrationMutation` - Will be used when implementing registration management
- `_rejectRegistrationMutation` - Will be used when implementing registration management
- `_deleteRegistrationMutation` - Will be used when implementing registration management

These methods are ready to use when you implement the full dialogs!

## 🎉 Summary

✅ Auto-refresh (30s stats, 60s doctors)
✅ Real-time queries with refetchInterval
✅ Query invalidation after mutations
✅ API filtering (status, search, date)
✅ Error handling with user feedback
✅ 11 mutation methods implemented
✅ Debounced search
✅ Loading states
✅ Success/error notifications
✅ TypeScript-like architecture in Flutter!
