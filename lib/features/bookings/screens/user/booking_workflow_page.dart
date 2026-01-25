import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';
import 'package:sehat_makaan_flutter/core/constants/types.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';
import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/suite_selection_step.dart';
import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/booking_type_selection_step.dart';
import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/package_selection_step.dart';
import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/specialty_selection_step.dart';
import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/date_slot_selection_step.dart';
import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/addons_selection_step.dart';
import 'package:sehat_makaan_flutter/features/bookings/screens/workflow/booking_summary_widget.dart';
import 'package:sehat_makaan_flutter/features/payments/screens/payment_step.dart';

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
        title: Text(
          'Booking Workflow',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
          ),
        ),
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
      ),
      body: ResponsiveContainer(
        maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 1000,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(child: _buildStepContent()),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: ResponsiveHelper.getResponsivePadding(context),
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
                selectedSuite: _selectedSuite,
                selectedSpecialty: _selectedSpecialty,
                onSpecialtySelected: (specialty) =>
                    setState(() => _selectedSpecialty = specialty),
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
                selectedSuite: _selectedSuite,
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
                onEndTimeSelected: (time) {
                  setState(() {
                    _endTime = time;
                    // Calculate hours from time difference
                    if (_startTime != null && _endTime != null) {
                      final startMins =
                          _startTime!.hour * 60 + _startTime!.minute;
                      final endMins = _endTime!.hour * 60 + _endTime!.minute;
                      final totalMins = endMins - startMins;
                      _selectedHours = (totalMins / 60).ceil();
                    }
                  });
                },
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
        return _bookingType == 'hourly'
            ? SingleChildScrollView(
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
              )
            : PaymentStep(
                bookingId: DateTime.now().millisecondsSinceEpoch.toString(),
                bookingType: 'monthly',
                userId: widget.userSession['userId'] ?? '',
                userEmail: widget.userSession['email'] ?? '',
                userName:
                    widget.userSession['fullName'] ??
                    widget.userSession['name'] ??
                    'Guest',
                baseAmount: _calculateBaseAmount(),
                selectedAddons: _selectedAddons,
                totalAmount: _calculateTotalAmount(),
                formKey: _paymentFormKey,
                onPaymentSuccess: () async {
                  debugPrint('✅ Payment successful for monthly booking');
                  // Complete the booking workflow after successful payment
                  await _completeWorkflow();
                },
              );
      case 6:
        // Payment step for hourly booking
        return PaymentStep(
          bookingId: DateTime.now().millisecondsSinceEpoch.toString(),
          bookingType: 'hourly',
          userId: widget.userSession['userId'] ?? '',
          userEmail: widget.userSession['email'] ?? '',
          userName:
              widget.userSession['fullName'] ??
              widget.userSession['name'] ??
              'Guest',
          baseAmount: _calculateBaseAmount(),
          selectedAddons: _selectedAddons,
          totalAmount: _calculateTotalAmount(),
          formKey: _paymentFormKey,
          onPaymentSuccess: () async {
            debugPrint('✅ Payment successful for hourly booking');
            // Complete the booking workflow after successful payment
            await _completeWorkflow();
          },
        );
      default:
        return const Center(child: Text('Invalid step'));
    }
  }

  double _calculateBaseAmount() {
    if (_bookingType == 'monthly' && _selectedPackage != null) {
      final packages = AppConstants.packages[_selectedSuite?.value] ?? [];
      final pkg = packages.firstWhere((p) => p.type == _selectedPackage);
      return pkg.price;
    } else if (_bookingType == 'hourly' && _selectedSpecialty != null) {
      final suite = AppConstants.suites.firstWhere(
        (s) => s.type == _selectedSuite,
      );
      return suite.baseRate * _selectedHours;
    }
    return 0.0;
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

      // Priority Booking addon grants access without additional rate charges
      // Users pay PKR 5,000 for addon, then use priority slots at base rate

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
          // Back button - show on all steps except first
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

          // Next button - hide on payment steps (step 5 for monthly, step 6 for hourly)
          // Payment step has its own "Proceed to Payment" button
          if (!((_bookingType == 'monthly' && _currentStep == 5) ||
              (_bookingType == 'hourly' && _currentStep == 6)))
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
                    : const Text('Next'),
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
      // Complete workflow - no validation needed for PayFast payment
      _completeWorkflow();
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

    // Generate registration ID for tracking
    final registrationId = DateTime.now().millisecondsSinceEpoch.toString();

    await _firestore.collection('subscriptions').add({
      'userId': userId,
      'registrationId': registrationId,
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
      'paymentStatus': 'paid',
      'paymentMethod': 'payfast',
      'currency': 'ZAR',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint(
      '✅ Monthly subscription created with registration: $registrationId',
    );
  }

  Future<void> _createHourlyBooking(String userId) async {
    try {
      final suite = AppConstants.suites.firstWhere(
        (s) => s.type == _selectedSuite,
      );
      var baseRate = suite.baseRate.toDouble();
      final originalRate = suite.baseRate.toDouble();

      // Check if this is a priority time slot (6PM onwards or weekend)
      bool isPrioritySlot = false;
      if (_startTime != null && _endTime != null) {
        final isWeekend =
            _selectedDate.weekday == DateTime.saturday ||
            _selectedDate.weekday == DateTime.sunday;
        final isPriorityTime =
            _startTime!.hour >= 18 ||
            _endTime!.hour >= 18 ||
            _endTime!.hour == 0;
        isPrioritySlot = isWeekend || isPriorityTime;
      }

      // Check if user purchased Priority Booking addon
      final hasPriority = _selectedAddons.any(
        (addon) => addon['code'] == 'priority_booking',
      );

      // Validate Priority Booking addon for priority slots
      if (isPrioritySlot && !hasPriority) {
        throw Exception(
          'Priority Booking addon is required to book slots between 6PM-10PM or on weekends. Please add the Priority Booking addon.',
        );
      }

      // Priority Booking addon grants access without additional rate charges
      // Users pay PKR 5,000 for addon, then use priority slots at base rate

      // Check if user purchased Extended Hours addon
      final hasExtendedHours = _selectedAddons.any(
        (addon) => addon['code'] == 'extended_hours',
      );

      int durationHours = 0;
      int durationMins = 0;
      String? endTimeStr;

      if (_startTime != null && _endTime != null) {
        final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
        final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
        final totalMinutes = endMinutes - startMinutes;

        // 🛡️ EXPLICIT VALIDATION: Check if duration is valid
        if (totalMinutes <= 0) {
          throw Exception(
            'End time must be after start time. Please select a valid duration.',
          );
        }

        durationHours = totalMinutes ~/ 60;
        durationMins = totalMinutes % 60;
        endTimeStr =
            '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

        // ⏰ HARD LIMIT VALIDATION: 22:00 normally, 22:30 with Extended Hours addon
        final hardLimitMins = hasExtendedHours ? (22 * 60 + 30) : (22 * 60);
        if (endMinutes > hardLimitMins) {
          final limitTime = hasExtendedHours
              ? '10:30 PM (22:30)'
              : '10:00 PM (22:00)';
          final endTimeFormatted =
              '${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}';

          // 🚨 Show explicit error instead of silent time reduction
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Selected duration exceeds closing time!\n\n'
                  'Bookings must end by $limitTime\n'
                  'Your selected time would end at: $endTimeFormatted\n\n'
                  '${hasExtendedHours ? "" : "💡 Tip: Purchase Extended Hours addon for 22:30 closing"}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 6),
              ),
            );
          }

          throw Exception(
            'Booking exceeds closing time ($limitTime). Current end time: $endTimeFormatted',
          );
        }
      } else {
        durationHours = _selectedHours;
        durationMins = 0;
      }

      final totalDurationMins = (durationHours * 60) + durationMins;

      // Calculate chargeable minutes with Extended Hours 30 min bonus
      int chargeableMinutes = totalDurationMins;
      if (hasExtendedHours) {
        chargeableMinutes = totalDurationMins > 30 ? totalDurationMins - 30 : 0;
      }

      final hoursForCalculation = chargeableMinutes / 60;
      var totalAmount = baseRate * hoursForCalculation;

      for (final addon in _selectedAddons) {
        totalAmount += addon['price'] as double;
      }

      // 🔒 ATOMIC TRANSACTION: Prevent race condition double-booking
      // Conflict check MUST be inside transaction for true atomicity
      await _firestore.runTransaction((transaction) async {
        if (_startTime != null && _endTime != null) {
          // 🚨 CRITICAL: Check conflicts INSIDE transaction (not outside)
          final startMins = _startTime!.hour * 60 + _startTime!.minute;
          final endMins = _endTime!.hour * 60 + _endTime!.minute;

          final startOfDay = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          );
          final endOfDay = startOfDay.add(const Duration(days: 1));

          // Query bookings within transaction for atomic read
          final bookingsSnapshot = await _firestore
              .collection('bookings')
              .where('suiteType', isEqualTo: _selectedSuite!.value)
              .where(
                'bookingDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
              .where('status', whereIn: ['confirmed', 'in_progress'])
              .get();

          // Check for conflicts with 15-min buffer
          const bufferMins = AppConstants.turnoverBufferMinutes; // 15 mins

          for (final doc in bookingsSnapshot.docs) {
            final data = doc.data();
            final bookedStart = data['startTime'] as String?;
            final bookedEnd = data['endTime'] as String?;

            if (bookedStart != null && bookedEnd != null) {
              final startParts = bookedStart.split(':');
              final endParts = bookedEnd.split(':');

              if (startParts.length >= 2 && endParts.length >= 2) {
                final bStart =
                    int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
                final bEnd =
                    int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

                // 🛡️ Buffer-safe conflict detection
                // New booking conflicts if: startMins < (bEnd + buffer) AND (endMins + buffer) > bStart
                if (startMins < (bEnd + bufferMins) &&
                    (endMins + bufferMins) > bStart) {
                  final conflictTime = '$bookedStart - $bookedEnd';
                  throw Exception(
                    'Time slot conflicts with existing booking ($conflictTime) in ${_selectedSuite!.displayName} Suite. '
                    'Please select a different time with 15-min gap.',
                  );
                }
              }
            }
          }
        }

        // Create booking datetime using actual start time (not timeSlot)
        DateTime bookingDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _startTime!.hour,
          _startTime!.minute,
        );

        // Format start time string
        final startTimeStr =
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';

        // Generate registration ID for tracking
        final registrationId = DateTime.now().millisecondsSinceEpoch.toString();

        // Create booking document reference
        final bookingRef = _firestore.collection('bookings').doc();

        // Set booking data using transaction
        transaction.set(bookingRef, {
          'userId': userId,
          'registrationId': registrationId,
          'doctorId': userId,
          'doctorName': widget.userSession['fullName'] ?? 'Unknown',
          'doctorEmail': widget.userSession['email'] ?? '',
          'suiteType': _selectedSuite!.value,
          'specialty': _selectedSpecialty,
          'bookingType': 'hourly',
          'bookingDate': Timestamp.fromDate(bookingDateTime),
          'timeSlot': _selectedTimeSlot,
          'startTime': startTimeStr,
          'endTime': endTimeStr,
          'hours': durationHours + (durationMins / 60),
          'durationHours': durationHours,
          'durationMins': durationMins,
          'totalDurationMins': totalDurationMins,
          'chargedMinutes': chargeableMinutes,
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
          'hasExtendedHoursBonus': hasExtendedHours,
          'status': 'confirmed',
          'paymentStatus': 'paid',
          'paymentMethod': 'payfast',
          'currency': 'ZAR',
          'isPaid': true,
          'paidAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint(
          '✅ Hourly booking created with registration: $registrationId',
        );
      });

      // Show success message
      if (mounted) {
        final exactHours = totalDurationMins / 60.0;
        final hoursText = exactHours == exactHours.floor()
            ? '${exactHours.toInt()} hour${exactHours.toInt() > 1 ? 's' : ''}'
            : '${exactHours.toStringAsFixed(1)} hours';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking confirmed! $hoursText at PKR ${totalAmount.toStringAsFixed(0)}',
            ),
            backgroundColor: const Color(0xFF90D26D),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating hourly booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
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
