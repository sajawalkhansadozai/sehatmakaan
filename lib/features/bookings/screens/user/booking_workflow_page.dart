import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/utils/constants.dart';
import 'package:sehat_makaan_flutter/utils/types.dart';
import '../../../../../screens/user/booking_workflow/suite_selection_step.dart';
import '../../../../../screens/user/booking_workflow/booking_type_selection_step.dart';
import '../../../../../screens/user/booking_workflow/package_selection_step.dart';
import '../../../../../screens/user/booking_workflow/specialty_selection_step.dart';
import '../../../../../screens/user/booking_workflow/date_slot_selection_step.dart';
import '../../../../../screens/user/booking_workflow/addons_selection_step.dart';
import '../../../../../screens/user/booking_workflow/booking_summary_widget.dart';
import '../../../../../screens/user/booking_workflow/payment_step.dart';

class BookingWorkflowPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const BookingWorkflowPage({super.key, required this.userSession});

  @override
  State<BookingWorkflowPage> createState() => _BookingWorkflowPageState();
}

class _BookingWorkflowPageState extends State<BookingWorkflowPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentStep = 0;
  SuiteType? _selectedSuite;
  String? _bookingType;
  PackageType? _selectedPackage;
  int _selectedHours = 1;
  String? _selectedSpecialty;
  final List<Map<String, dynamic>> _selectedAddons = [];
  bool _isProcessing = false;

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Payment form controllers
  final _paymentFormKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        title: const Text('Booking Workflow'),
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(child: _buildStepContent()),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStep(0, 'Suite', Icons.home_work),
            _buildStepDivider(),
            _buildStep(1, 'Type', Icons.calendar_today),
            _buildStepDivider(),
            _buildStep(
              2,
              _bookingType == 'hourly' ? 'Specialty' : 'Package',
              Icons.medical_services,
            ),
            _buildStepDivider(),
            _buildStep(
              3,
              _bookingType == 'hourly' ? 'Date' : 'Add-ons',
              _bookingType == 'hourly'
                  ? Icons.schedule
                  : Icons.add_shopping_cart,
            ),
            _buildStepDivider(),
            _buildStep(4, 'Summary', Icons.summarize),
            _buildStepDivider(),
            _buildStep(5, 'Payment', Icons.payment),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? const Color(0xFF006876)
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFF006876) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return SuiteSelectionStep(
          selectedSuite: _selectedSuite,
          onSuiteSelected: (suite) => setState(() => _selectedSuite = suite),
        );
      case 1:
        return BookingTypeSelectionStep(
          bookingType: _bookingType,
          onTypeSelected: (type) => setState(() => _bookingType = type),
        );
      case 2:
        return _bookingType == 'hourly'
            ? SpecialtySelectionStep(
                selectedSpecialty: _selectedSpecialty,
                selectedHours: _selectedHours,
                onSpecialtySelected: (specialty) =>
                    setState(() => _selectedSpecialty = specialty),
                onHoursChanged: (hours) =>
                    setState(() => _selectedHours = hours),
              )
            : PackageSelectionStep(
                selectedSuite: _selectedSuite,
                selectedPackage: _selectedPackage,
                onPackageSelected: (pkg) =>
                    setState(() => _selectedPackage = pkg),
              );
      case 3:
        return _bookingType == 'hourly'
            ? AddonsSelectionStep(
                selectedAddons: _selectedAddons,
                onAddonToggle: (addon) {
                  setState(() {
                    if (_selectedAddons.any(
                      (a) => a['code'] == addon['code'],
                    )) {
                      _selectedAddons.removeWhere(
                        (a) => a['code'] == addon['code'],
                      );
                    } else {
                      _selectedAddons.add(addon);
                    }
                  });
                },
                isHourlyBooking: true,
              )
            : Column(
                children: [
                  Expanded(
                    child: AddonsSelectionStep(
                      selectedAddons: _selectedAddons,
                      onAddonToggle: (addon) {
                        setState(() {
                          if (_selectedAddons.any(
                            (a) => a['code'] == addon['code'],
                          )) {
                            _selectedAddons.removeWhere(
                              (a) => a['code'] == addon['code'],
                            );
                          } else {
                            _selectedAddons.add(addon);
                          }
                        });
                      },
                      isHourlyBooking: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: BookingSummaryWidget(
                      selectedSuite: _selectedSuite,
                      bookingType: _bookingType,
                      selectedPackage: _selectedPackage,
                      selectedSpecialty: _selectedSpecialty,
                      selectedDate: _selectedDate,
                      selectedTimeSlot: _selectedTimeSlot,
                      selectedHours: _selectedHours,
                      selectedAddons: _selectedAddons,
                    ),
                  ),
                ],
              );
      case 4:
        return _bookingType == 'hourly'
            ? DateSlotSelectionStep(
                selectedDate: _selectedDate,
                selectedTimeSlot: _selectedTimeSlot,
                startTime: _startTime,
                endTime: _endTime,
                selectedHours: _selectedHours,
                selectedAddons: _selectedAddons,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                    _selectedTimeSlot = null;
                  });
                },
                onTimeSlotSelected: (slot) =>
                    setState(() => _selectedTimeSlot = slot),
                onStartTimeSelected: (time) =>
                    setState(() => _startTime = time),
                onEndTimeSelected: (time) => setState(() => _endTime = time),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review Your Booking',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006876),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please review your booking details before proceeding to payment',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    BookingSummaryWidget(
                      selectedSuite: _selectedSuite,
                      bookingType: _bookingType,
                      selectedPackage: _selectedPackage,
                      selectedSpecialty: _selectedSpecialty,
                      selectedDate: _selectedDate,
                      selectedTimeSlot: _selectedTimeSlot,
                      selectedHours: _selectedHours,
                      selectedAddons: _selectedAddons,
                    ),
                  ],
                ),
              );
      case 5:
        // Payment step
        return PaymentStep(
          totalAmount: _calculateTotalAmount(),
          formKey: _paymentFormKey,
          cardNumberController: _cardNumberController,
          cardHolderController: _cardHolderController,
          expiryController: _expiryController,
          cvvController: _cvvController,
        );
      default:
        return const Center(child: Text('Invalid step'));
    }
  }

  double _calculateTotalAmount() {
    double totalAmount = 0.0;

    if (_bookingType == 'monthly' && _selectedPackage != null) {
      final packages = AppConstants.packages[_selectedSuite?.value] ?? [];
      final pkg = packages.firstWhere((p) => p.type == _selectedPackage);
      totalAmount = pkg.price;
    } else if (_bookingType == 'hourly' && _selectedSpecialty != null) {
      final suite = AppConstants.suites.firstWhere(
        (s) => s.type == _selectedSuite,
      );
      var baseRate = suite.baseRate.toDouble();

      // Check if this is a priority time slot (6PM-10PM or weekend)
      bool isPrioritySlot = false;
      if (_selectedTimeSlot != null) {
        final slotParts = _selectedTimeSlot!.split(':');
        final slotHour = int.parse(slotParts[0]);
        final isWeekend =
            _selectedDate.weekday == DateTime.saturday ||
            _selectedDate.weekday == DateTime.sunday;
        final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
        isPrioritySlot = isWeekend || isPriorityTime;
      }

      // Apply 1.5x rate for priority slots
      if (isPrioritySlot) {
        baseRate = baseRate * 1.5;
      }

      int durationHours = 0;
      int durationMins = 0;

      if (_startTime != null && _endTime != null) {
        final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
        final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
        final totalMinutes = endMinutes - startMinutes;
        durationHours = totalMinutes ~/ 60;
        durationMins = totalMinutes % 60;
      } else {
        durationHours = _selectedHours;
        durationMins = 0;
      }

      final totalDurationMins = (durationHours * 60) + durationMins;
      final hoursForCalculation = totalDurationMins / 60;
      totalAmount = baseRate * hoursForCalculation;
    }

    // Add addons to total
    for (final addon in _selectedAddons) {
      totalAmount += addon['price'] as double;
    }

    return totalAmount;
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF006876)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006876),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_currentStep == 5 ? 'Complete Booking' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedSuite != null;
      case 1:
        return _bookingType != null;
      case 2:
        if (_bookingType == 'monthly') {
          return _selectedPackage != null;
        } else {
          return _selectedSpecialty != null;
        }
      case 3:
        // Addons step - can always proceed (addons are optional)
        return true;
      case 4:
        if (_bookingType == 'hourly') {
          return _selectedTimeSlot != null &&
              _startTime != null &&
              _endTime != null;
        } else {
          return true; // Summary for monthly
        }
      case 5:
        return true; // Summary for hourly, payment for monthly
      case 6:
        // Payment form validation will be checked when clicking Complete
        return true;
      default:
        return false;
    }
  }

  void _handleNext() {
    final maxStep = _bookingType == 'hourly' ? 6 : 5;
    if (_currentStep < maxStep) {
      setState(() => _currentStep++);
    } else {
      // Validate payment form before completing
      if (_paymentFormKey.currentState!.validate()) {
        _completeWorkflow();
      }
    }
  }

  Future<void> _completeWorkflow() async {
    setState(() => _isProcessing = true);

    try {
      debugPrint('📋 UserSession contents: ${widget.userSession}');
      final userId = widget.userSession['id']?.toString();
      debugPrint('👤 Extracted userId: $userId');

      if (userId == null) {
        throw Exception('User ID is null. UserSession: ${widget.userSession}');
      }

      if (_bookingType == 'monthly' && _selectedPackage != null) {
        await _createMonthlySubscription(userId);
      } else if (_bookingType == 'hourly' && _selectedSpecialty != null) {
        await _createHourlyBooking(userId);
      }

      await _purchaseAddons(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking completed successfully!'),
            backgroundColor: Color(0xFF90D26D),
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: widget.userSession,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error completing booking: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _createMonthlySubscription(String userId) async {
    final packages = AppConstants.packages[_selectedSuite?.value] ?? [];
    final pkg = packages.firstWhere((p) => p.type == _selectedPackage);

    // Check if Extra 10 Hour Block addon is selected
    int totalHours = pkg.hours;
    final hasExtraHours = _selectedAddons.any(
      (addon) => addon['code'] == 'extra_10_hours',
    );
    if (hasExtraHours) {
      totalHours += 10; // Add 10 hours from addon
    }

    // Calculate total price including add-ons
    double totalPrice = pkg.price;
    for (final addon in _selectedAddons) {
      totalPrice += addon['price'] as double;
    }

    await _firestore.collection('subscriptions').add({
      'userId': userId,
      'suiteType': _selectedSuite!.value,
      'packageType': _selectedPackage!.value,
      'type': 'monthly',
      'monthlyPrice': pkg.price,
      'price': totalPrice,
      'totalAmount': totalPrice,
      'basePrice': pkg.price,
      'hoursIncluded': totalHours,
      'hoursUsed': 0,
      'remainingHours': totalHours,
      'remainingMinutes':
          0, // Initialize minutes field for proper fractional hour tracking
      'selectedAddons': _selectedAddons
          .map(
            (addon) => {
              'name': addon['name'],
              'code': addon['code'],
              'price': addon['price'],
            },
          )
          .toList(),
      'startDate': Timestamp.fromDate(DateTime.now()),
      'endDate': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
      'status': 'active',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _createHourlyBooking(String userId) async {
    final suite = AppConstants.suites.firstWhere(
      (s) => s.type == _selectedSuite,
    );
    var baseRate = suite.baseRate.toDouble();
    final originalRate = suite.baseRate.toDouble();

    // Check if this is a priority time slot (6PM-10PM or weekend)
    bool isPrioritySlot = false;
    if (_selectedTimeSlot != null) {
      final slotParts = _selectedTimeSlot!.split(':');
      final slotHour = int.parse(slotParts[0]);
      final isWeekend =
          _selectedDate.weekday == DateTime.saturday ||
          _selectedDate.weekday == DateTime.sunday;
      final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
      isPrioritySlot = isWeekend || isPriorityTime;
    }

    // Apply 1.5x rate for priority slots
    if (isPrioritySlot) {
      baseRate = baseRate * 1.5;
    }

    int durationHours = 0;
    int durationMins = 0;
    String? endTimeStr;

    if (_startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      final totalMinutes = endMinutes - startMinutes;
      durationHours = totalMinutes ~/ 60;
      durationMins = totalMinutes % 60;
      endTimeStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
    } else {
      durationHours = _selectedHours;
      durationMins = 0;
    }

    final totalDurationMins = (durationHours * 60) + durationMins;
    final hoursForCalculation = totalDurationMins / 60;
    var totalAmount = baseRate * hoursForCalculation;

    for (final addon in _selectedAddons) {
      totalAmount += addon['price'] as double;
    }

    // Check if user purchased Priority Booking addon
    final hasPriority = _selectedAddons.any(
      (addon) => addon['code'] == 'priority_booking',
    );

    // Check if user purchased Extended Hours addon
    final hasExtendedHours = _selectedAddons.any(
      (addon) => addon['code'] == 'extended_hours',
    );

    // Create booking datetime by combining date and time slot
    DateTime bookingDateTime = _selectedDate;
    if (_selectedTimeSlot != null) {
      final timeParts = _selectedTimeSlot!.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        bookingDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          hour,
          minute,
        );
      }
    }

    await _firestore.collection('bookings').add({
      'userId': userId,
      'doctorId': userId,
      'doctorName': widget.userSession['fullName'] ?? 'Unknown',
      'doctorEmail': widget.userSession['email'] ?? '',
      'suiteType': _selectedSuite!.value,
      'specialty': _selectedSpecialty,
      'bookingType': 'hourly',
      'bookingDate': Timestamp.fromDate(bookingDateTime),
      'timeSlot': _selectedTimeSlot,
      'startTime': _selectedTimeSlot,
      'endTime': endTimeStr,
      'hours': durationHours + (durationMins / 60),
      'durationHours': durationHours,
      'durationMins': durationMins,
      'totalDurationMins': totalDurationMins,
      'baseRate': baseRate,
      'originalRate': originalRate,
      'isPrioritySlot': isPrioritySlot,
      'totalAmount': totalAmount,
      'selectedAddons': _selectedAddons
          .map(
            (addon) => {
              'name': addon['name'],
              'code': addon['code'],
              'price': addon['price'],
            },
          )
          .toList(),
      'hasPriority': hasPriority,
      'hasExtendedHours': hasExtendedHours,
      'status': 'confirmed',
      'paymentStatus': 'paid',
      'paymentMethod': 'card',
      'isPaid': true,
      'paidAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _purchaseAddons(String userId) async {
    for (final addon in _selectedAddons) {
      await _firestore.collection('purchased_addons').add({
        'userId': userId,
        'addonName': addon['name'],
        'addonCode': addon['code'],
        'price': addon['price'],
        'suiteType': _selectedSuite!.value,
        'isUsed': false,
        'purchasedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
