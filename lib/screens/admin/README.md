# Admin Dashboard - Refactored Structure

## File Organization

### Main File
- **admin_dashboard_page.dart** - Main coordinator with state management

### Utils (Helper Functions)
- **utils/admin_formatters.dart** - Date and text formatting functions
- **utils/admin_styles.dart** - Colors and style constants

### Widgets (Reusable UI Components)
- **widgets/stat_card_widget.dart** - Statistics card for overview
- **widgets/doctor_card_widget.dart** - Doctor information card
- **widgets/booking_card_widget.dart** - Booking information card
- **widgets/workshop_card_widget.dart** - Workshop information card  
- **widgets/registration_card_widget.dart** (to be created) - Registration card

### Tabs (Main Content Screens)
- **tabs/overview_tab.dart** (to be created) - Statistics overview
- **tabs/doctors_tab.dart** (to be created) - Doctor management
- **tabs/bookings_tab.dart** (to be created) - Booking management
- **tabs/workshops_tab.dart** (to be created) - Workshop management

### Dialogs (Modal Interactions)
- **dialogs/doctor_dialogs.dart** (to be created) - Reject & delete doctor dialogs
- **dialogs/booking_dialog.dart** (to be created) - Cancel booking dialog
- **dialogs/workshop_dialog.dart** (to be created) - Create/edit workshop stepper

## Benefits of This Structure

1. **Maintainability** - Each file has a single responsibility
2. **Reusability** - Widgets can be used across different parts
3. **Testability** - Easier to write unit tests for isolated components
4. **Readability** - Smaller files are easier to understand
5. **Collaboration** - Multiple developers can work on different files

## How State Management Works

The main `admin_dashboard_page.dart` file maintains all state variables and passes:
- **Data** down to widgets as props
- **Callbacks** for user interactions back up to the main file

This keeps business logic centralized while UI remains modular.

## Usage Example

```dart
// In main file
DoctorCardWidget(
  doctor: doctor,
  isExpanded: _expandedDoctors.contains(doctorId),
  isApprovingDoctor: _isApprovingDoctor,
  onToggleExpand: () => setState(() => /* toggle expand */),
  onApprove: () => _approveDoctor(doctor),
  onReject: () => _showRejectDialog(doctor),
  onDelete: () => _showDeleteDialog(doctor),
)
```

## Next Steps

To complete the refactoring:
1. Create remaining widget files (registration_card_widget.dart)
2. Create tab files (overview_tab.dart, doctors_tab.dart, etc.)
3. Create dialog files (doctor_dialogs.dart, etc.)
4. Update main file to import and use these components
5. Test all functionality to ensure nothing is broken
