import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sehat_makaan_flutter/features/admin/tabs/overview_tab.dart';
import 'package:sehat_makaan_flutter/features/admin/tabs/doctors_tab.dart';
import 'package:sehat_makaan_flutter/features/admin/tabs/bookings_tab_bookings.dart';
import 'package:sehat_makaan_flutter/features/admin/tabs/workshops_tab.dart';
import 'package:sehat_makaan_flutter/features/admin/tabs/workshop_creators_tab.dart';
import 'package:sehat_makaan_flutter/features/admin/tabs/marketing_tab.dart';
import 'package:sehat_makaan_flutter/features/admin/dialogs/doctor_dialogs.dart';
import 'package:sehat_makaan_flutter/features/admin/dialogs/booking_dialogs.dart';
import 'package:sehat_makaan_flutter/features/admin/dialogs/workshop_dialogs.dart';
import 'package:sehat_makaan_flutter/features/admin/utils/admin_formatters.dart';
import 'package:sehat_makaan_flutter/features/admin/utils/admin_styles.dart';
import 'package:sehat_makaan_flutter/features/admin/utils/responsive_helper.dart';
import 'package:sehat_makaan_flutter/features/admin/services/admin_data_service.dart';
import 'package:sehat_makaan_flutter/features/admin/services/admin_mutations_service.dart';
import 'package:sehat_makaan_flutter/services/session_storage_service.dart';

class AdminDashboardPage extends StatefulWidget {
  final Map<String, dynamic> adminSession;

  const AdminDashboardPage({super.key, required this.adminSession});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  String _selectedSection = 'overview';

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Service instances
  late final AdminDataService _dataService;
  late final AdminMutationsService _mutationsService;

  // Auto-refresh timers
  Timer? _statsRefreshTimer;
  Timer? _doctorsRefreshTimer;
  Timer? _searchDebounceTimer;

  // Real-time listeners
  StreamSubscription? _doctorsSubscription;
  StreamSubscription? _bookingsSubscription;
  StreamSubscription? _workshopsSubscription;

  // Data
  final List<Map<String, dynamic>> _doctors = [];
  final List<Map<String, dynamic>> _bookings = [];
  final List<Map<String, dynamic>> _workshops = [];
  final List<Map<String, dynamic>> _pendingProposals = [];
  final List<Map<String, dynamic>> _workshopRegistrations = [];

  // Doctors tab state
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  final Set<String> _expandedDoctors = {};
  final TextEditingController _rejectionReasonController =
      TextEditingController();

  // Bookings tab state
  DateTime _selectedBookingDate = DateTime.now();

  // Loading states for async operations
  bool _isApprovingDoctor = false;
  bool _isRejectingDoctor = false;
  bool _isDeletingDoctor = false;
  bool _isSuspendingDoctor = false;
  bool _isSubmittingWorkshop = false;
  bool _isDeletingWorkshop = false;

  // Workshop form controllers
  final TextEditingController _workshopTitleController =
      TextEditingController();
  final TextEditingController _workshopDescController = TextEditingController();
  final TextEditingController _workshopProviderController =
      TextEditingController();
  final TextEditingController _workshopCertTypeController =
      TextEditingController();
  final TextEditingController _workshopLocationController =
      TextEditingController();
  final TextEditingController _workshopDurationController =
      TextEditingController();
  final TextEditingController _workshopPriceController =
      TextEditingController();
  final TextEditingController _workshopMaxParticipantsController =
      TextEditingController();
  final TextEditingController _workshopScheduleController =
      TextEditingController();
  final TextEditingController _workshopInstructorController =
      TextEditingController();
  final TextEditingController _workshopPrereqController =
      TextEditingController();
  final TextEditingController _workshopMaterialsController =
      TextEditingController();

  List<Map<String, dynamic>> get _filteredDoctors {
    List<Map<String, dynamic>> filtered = _doctors;

    if (_filterStatus != 'all') {
      filtered = filtered
          .where((d) => (d['status'] as String?) == _filterStatus)
          .toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((d) {
        final name = (d['fullName'] as String? ?? '').toLowerCase();
        final email = (d['email'] as String? ?? '').toLowerCase();
        final specialty = (d['specialty'] as String? ?? '').toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            specialty.contains(query);
      }).toList();
    }

    return filtered;
  }

  List<Map<String, dynamic>> get _filteredBookings {
    final selectedDateStr = AdminFormatters.formatDateOnly(
      _selectedBookingDate,
    );
    return _bookings.where((booking) {
      final bookingDateStr = AdminFormatters.formatDateOnly(
        booking['bookingDate'],
      );
      return bookingDateStr == selectedDateStr;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    // Debug: Print admin session data
    debugPrint('🔍 Admin Session Data: ${widget.adminSession}');
    debugPrint('🔍 Admin fullName: ${widget.adminSession['fullName']}');

    // Initialize services
    _dataService = AdminDataService(_firestore);
    _mutationsService = AdminMutationsService(
      firestore: _firestore,
      onLoadingStart: _startLoading,
      onLoadingEnd: _endLoading,
      showSuccess: _showSuccessSnackBar,
      showError: _showErrorSnackBar,
    );

    _loadDashboardData();
    _startAutoRefresh();
  }

  // Helper methods for service callbacks
  void _startLoading() {
    setState(() {
      // Set appropriate loading flag based on operation
      _isLoading = true;
    });
  }

  void _endLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _statsRefreshTimer?.cancel();
    _doctorsRefreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _doctorsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _workshopsSubscription?.cancel();
    _searchController.dispose();
    _rejectionReasonController.dispose();
    _workshopTitleController.dispose();
    _workshopDescController.dispose();
    _workshopProviderController.dispose();
    _workshopCertTypeController.dispose();
    _workshopLocationController.dispose();
    _workshopDurationController.dispose();
    _workshopPriceController.dispose();
    _workshopMaxParticipantsController.dispose();
    _workshopScheduleController.dispose();
    _workshopInstructorController.dispose();
    _workshopPrereqController.dispose();
    _workshopMaterialsController.dispose();
    super.dispose();
  }

  // ============================================================================
  // AUTO-REFRESH FUNCTIONALITY
  // ============================================================================

  void _startAutoRefresh() {
    // Start real-time listeners for doctors, bookings, and workshops
    _startRealtimeListeners();
  }

  void _startRealtimeListeners() {
    // Real-time listener for doctors (legacy) and users (new registrations)
    _doctorsSubscription = _firestore
        .collection('users')
        .where('userType', isEqualTo: 'doctor')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _doctors.clear();
              for (var doc in snapshot.docs) {
                _doctors.add({'id': doc.id, ...doc.data()});
              }
            });
          }
        });

    // Real-time listener for bookings
    _bookingsSubscription = _firestore.collection('bookings').snapshots().listen((
      snapshot,
    ) async {
      if (mounted) {
        final now = DateTime.now();

        // Auto-update booking statuses based on time
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final status = data['status'] as String?;

          // Skip cancelled bookings
          if (status == 'cancelled') continue;

          DateTime? bookingStartTime;
          DateTime? bookingEndTime;
          final bookingDateField = data['bookingDate'];

          // Parse booking date and time
          if (bookingDateField is Timestamp) {
            bookingStartTime = bookingDateField.toDate();

            // Use totalDurationMins if available, otherwise calculate from hours + mins
            int totalMinutes;
            if (data['totalDurationMins'] != null) {
              totalMinutes = data['totalDurationMins'] as int;
            } else {
              final durationHours = data['durationHours'] as int? ?? 0;
              final durationMins = data['durationMins'] as int? ?? 0;
              totalMinutes = (durationHours * 60) + durationMins;
            }

            bookingEndTime = bookingStartTime.add(
              Duration(minutes: totalMinutes),
            );
          } else if (bookingDateField is String) {
            try {
              final parts = bookingDateField.split('/');
              if (parts.length == 3) {
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                final year = int.parse(parts[2]);

                // Add time slot
                final timeSlot = data['timeSlot'] as String?;
                if (timeSlot != null) {
                  final timeParts = timeSlot.split(':');
                  if (timeParts.length >= 2) {
                    final hour = int.tryParse(timeParts[0]) ?? 0;
                    final minute = int.tryParse(timeParts[1]) ?? 0;
                    bookingStartTime = DateTime(year, month, day, hour, minute);

                    // Calculate end time using totalDurationMins
                    int totalMinutes;
                    if (data['totalDurationMins'] != null) {
                      totalMinutes = data['totalDurationMins'] as int;
                    } else {
                      final durationHours = data['durationHours'] as int? ?? 0;
                      final durationMins = data['durationMins'] as int? ?? 0;
                      totalMinutes = (durationHours * 60) + durationMins;
                    }

                    bookingEndTime = bookingStartTime.add(
                      Duration(minutes: totalMinutes),
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('Error parsing date: $bookingDateField');
            }
          }

          if (bookingStartTime != null && bookingEndTime != null) {
            String? newStatus;

            // Determine correct status based on time
            if (now.isBefore(bookingStartTime)) {
              // Future booking - should be confirmed or pending
              if (status == 'completed' || status == 'in_progress') {
                newStatus = 'confirmed';
              }
            } else if (now.isAfter(bookingEndTime)) {
              // Past booking - should be completed
              if (status == 'confirmed' || status == 'in_progress') {
                newStatus = 'completed';
              }
            } else {
              // Currently in progress
              if (status != 'in_progress') {
                newStatus = 'in_progress';
              }
            }

            // Update status if needed
            if (newStatus != null) {
              try {
                await _firestore.collection('bookings').doc(doc.id).update({
                  'status': newStatus,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                debugPrint(
                  '✅ Auto-updated booking ${doc.id}: $status → $newStatus',
                );
              } catch (e) {
                debugPrint('⚠️ Error updating booking ${doc.id}: $e');
              }
            }
          }
        }

        // Refresh the bookings list
        if (mounted) {
          setState(() {
            _bookings.clear();
            for (var doc in snapshot.docs) {
              final data = doc.data();
              final bookingDateField = data['bookingDate'];

              DateTime? bookingDateTime;

              // Handle both String and Timestamp formats
              if (bookingDateField is String) {
                try {
                  final parts = bookingDateField.split('/');
                  if (parts.length == 3) {
                    bookingDateTime = DateTime(
                      int.parse(parts[2]), // year
                      int.parse(parts[0]), // month
                      int.parse(parts[1]), // day
                    );
                  }
                } catch (e) {
                  debugPrint(
                    'Error parsing booking date string: $bookingDateField - $e',
                  );
                }
              } else if (bookingDateField is Timestamp) {
                bookingDateTime = bookingDateField.toDate();
              }

              _bookings.add({
                'id': doc.id,
                ...data,
                'bookingDate': bookingDateTime,
              });
            }
          });
        }
      }
    });

    // Real-time listener for workshops
    _workshopsSubscription = _firestore
        .collection('workshops')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _workshops.clear();
              _pendingProposals.clear();
              for (var doc in snapshot.docs) {
                final data = {'id': doc.id, ...doc.data()};
                final permissionStatus =
                    data['permissionStatus'] ?? 'pending_admin';

                if (permissionStatus == 'pending_admin') {
                  _pendingProposals.add(data);
                } else if (data['isActive'] == true) {
                  _workshops.add(data);
                }
              }
            });
          }
        });
  }

  // ============================================================================
  // DATA FETCHING WITH FIREBASE
  // ============================================================================

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_loadDoctors(), _loadBookings(), _loadWorkshops()]);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load dashboard data: $e');
      }
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await _dataService.loadDoctors(_filterStatus);

      if (mounted) {
        setState(() {
          _doctors.clear();
          _doctors.addAll(doctors);
        });
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      if (mounted && _doctors.isEmpty) {
        _showErrorSnackBar('Failed to load doctors: $e');
      }
    }
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await _dataService.loadBookings(_selectedBookingDate);

      if (mounted) {
        setState(() {
          _bookings.clear();
          _bookings.addAll(bookings);
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (mounted && _bookings.isEmpty) {
        _showErrorSnackBar('Failed to load bookings: $e');
      }
    }
  }

  Future<void> _loadWorkshops() async {
    try {
      final result = await _dataService.loadWorkshops();

      if (mounted) {
        setState(() {
          _workshops.clear();
          final workshops = result['workshops'];
          if (workshops != null) {
            _workshops.addAll(workshops.cast<Map<String, dynamic>>());
          }
          _workshopRegistrations.clear();
          final registrations = result['registrations'];
          if (registrations != null) {
            _workshopRegistrations.addAll(
              registrations.cast<Map<String, dynamic>>(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading workshops: $e');
      if (mounted && _workshops.isEmpty) {
        _showErrorSnackBar('Failed to load workshops: $e');
      }
    }
  }

  // ============================================================================
  // MUTATION METHODS WITH FIREBASE - Now using service layer
  // ============================================================================

  Future<void> _approveDoctorMutation(Map<String, dynamic> doctor) async {
    setState(() => _isApprovingDoctor = true);
    final adminId = _auth.currentUser?.uid;
    await _mutationsService.approveDoctor(doctor, adminId);
    await _loadDoctors(); // Refresh data
    if (mounted) setState(() => _isApprovingDoctor = false);
  }

  Future<void> _rejectDoctorMutation(
    Map<String, dynamic> doctor,
    String reason,
  ) async {
    setState(() => _isRejectingDoctor = true);
    final adminId = _auth.currentUser?.uid;
    await _mutationsService.rejectDoctor(doctor, reason, adminId);
    await _loadDoctors(); // Refresh data
    if (mounted) setState(() => _isRejectingDoctor = false);
  }

  Future<void> _suspendDoctorMutation(Map<String, dynamic> doctor) async {
    setState(() => _isSuspendingDoctor = true);
    final adminId = _auth.currentUser?.uid;
    await _mutationsService.suspendDoctor(doctor, adminId);
    await _loadDoctors(); // Refresh data
    if (mounted) setState(() => _isSuspendingDoctor = false);
  }

  Future<void> _unsuspendDoctorMutation(Map<String, dynamic> doctor) async {
    setState(() => _isSuspendingDoctor = true);
    await _mutationsService.unsuspendDoctor(doctor);
    await _loadDoctors(); // Refresh data
    if (mounted) setState(() => _isSuspendingDoctor = false);
  }

  Future<void> _deleteDoctorMutation(Map<String, dynamic> doctor) async {
    setState(() => _isDeletingDoctor = true);
    await _mutationsService.deleteDoctor(doctor);
    await _loadDoctors(); // Refresh data
    if (mounted) setState(() => _isDeletingDoctor = false);
  }

  Future<void> _cancelBookingWithRefundMutation(
    Map<String, dynamic> booking,
  ) async {
    await _mutationsService.cancelBookingWithRefund(booking);
    await _loadBookings(); // Refresh data
  }

  Future<void> _cancelBookingMutation(Map<String, dynamic> booking) async {
    await _mutationsService.cancelBooking(booking);
    await _loadBookings(); // Refresh data
  }

  Future<void> _createWorkshopMutation(Map<String, dynamic> data) async {
    setState(() => _isSubmittingWorkshop = true);
    await _mutationsService.createWorkshop(data);
    await _loadWorkshops(); // Refresh data
    if (mounted) setState(() => _isSubmittingWorkshop = false);
  }

  Future<void> _updateWorkshopMutation(
    int workshopId,
    Map<String, dynamic> data,
  ) async {
    setState(() => _isSubmittingWorkshop = true);
    await _mutationsService.updateWorkshop(workshopId.toString(), data);
    await _loadWorkshops(); // Refresh data
    if (mounted) setState(() => _isSubmittingWorkshop = false);
  }

  Future<void> _deleteWorkshopMutation(Map<String, dynamic> workshop) async {
    setState(() => _isDeletingWorkshop = true);
    await _mutationsService.deleteWorkshop(workshop);
    await _loadWorkshops(); // Refresh data
    if (mounted) setState(() => _isDeletingWorkshop = false);
  }

  Future<void> _confirmRegistrationMutation(
    Map<String, dynamic> registration,
  ) async {
    setState(() => _isLoading = true);
    await _mutationsService.confirmRegistration(registration);
    await _loadWorkshops(); // Refresh data
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _rejectRegistrationMutation(
    Map<String, dynamic> registration,
  ) async {
    setState(() => _isLoading = true);
    await _mutationsService.rejectRegistration(registration);
    await _loadWorkshops(); // Refresh data
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteRegistrationMutation(
    Map<String, dynamic> registration,
  ) async {
    setState(() => _isLoading = true);
    await _mutationsService.deleteRegistration(registration);
    await _loadWorkshops(); // Refresh data
    if (mounted) setState(() => _isLoading = false);
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Set new timer for 500ms debounce
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadDoctors();
    });
  }

  void _onFilterChanged(String value) {
    setState(() => _filterStatus = value);
    _loadDoctors();
  }

  void _onBookingDateChanged(DateTime date) {
    setState(() => _selectedBookingDate = date);
    _loadBookings();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminStyles.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminStyles.errorColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyles.backgroundColor,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedSection == value;
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.9),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final isMobile = ResponsiveHelper.isMobile(context);
    final titleFontSize = ResponsiveHelper.getTitleFontSize(context);

    return Container(
      decoration: BoxDecoration(gradient: AdminStyles.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMobile ? 'Admin' : 'Admin Dashboard',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (!isMobile)
                          Text(
                            'Welcome back, ${widget.adminSession['fullName']?.toString() ?? widget.adminSession['email']?.toString().split('@')[0] ?? 'Administrator'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: isMobile ? 24 : 28,
                    ),
                    offset: const Offset(0, 50),
                    color: const Color(0xFF006876),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    onSelected: (String value) async {
                      if (value == 'logout') {
                        // Clear encrypted session
                        final sessionService = SessionStorageService();
                        await sessionService.clearUserSession();
                        debugPrint('🔓 Admin session cleared');

                        if (context.mounted) {
                          Navigator.pop(context); // Return to login
                        }
                      } else {
                        setState(() {
                          _selectedSection = value;
                        });
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      _buildPopupMenuItem(
                        value: 'overview',
                        icon: Icons.dashboard,
                        label: 'Overview',
                      ),
                      _buildPopupMenuItem(
                        value: 'doctors',
                        icon: Icons.people,
                        label: 'Doctors',
                      ),
                      _buildPopupMenuItem(
                        value: 'bookings',
                        icon: Icons.calendar_today,
                        label: 'Bookings',
                      ),
                      _buildPopupMenuItem(
                        value: 'workshops',
                        icon: Icons.school,
                        label: 'Workshops',
                      ),
                      _buildPopupMenuItem(
                        value: 'creators',
                        icon: Icons.group_add,
                        label: 'Workshop Creators',
                      ),
                      _buildPopupMenuItem(
                        value: 'marketing',
                        icon: Icons.campaign,
                        label: 'Marketing',
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case 'overview':
        return const OverviewTab();
      case 'doctors':
        return DoctorsTab(
          searchController: _searchController,
          filterStatus: _filterStatus,
          filteredDoctors: _filteredDoctors,
          allDoctors: _doctors,
          expandedDoctors: _expandedDoctors,
          isApprovingDoctor: _isApprovingDoctor,
          isRejectingDoctor: _isRejectingDoctor,
          isDeletingDoctor: _isDeletingDoctor,
          isSuspendingDoctor: _isSuspendingDoctor,
          onSearchChanged: _onSearchChanged,
          onFilterChanged: _onFilterChanged,
          onRefresh: _loadDashboardData,
          onToggleExpand: (doctorId) {
            setState(() {
              if (_expandedDoctors.contains(doctorId)) {
                _expandedDoctors.remove(doctorId);
              } else {
                _expandedDoctors.add(doctorId);
              }
            });
          },
          onApprove: _approveDoctor,
          onReject: _showRejectDialog,
          onDelete: _showDeleteDialog,
          onSuspend: _showSuspendDialog,
        );
      case 'bookings':
        return BookingsTab(
          selectedBookingDate: _selectedBookingDate,
          filteredBookings: _filteredBookings,
          allBookings: _bookings,
          onDateChanged: _onBookingDateChanged,
          onRefresh: _loadDashboardData,
          onCancel: _showCancelBookingDialog,
        );
      case 'workshops':
        return WorkshopsTab(
          workshops: _workshops,
          pendingProposals: _pendingProposals,
          workshopRegistrations: _workshopRegistrations,
          isSubmittingWorkshop: _isSubmittingWorkshop,
          isDeletingWorkshop: _isDeletingWorkshop,
          onCreateWorkshop: () => _showWorkshopDialog(),
          onEditWorkshop: _editWorkshop,
          onDeleteWorkshop: _showDeleteWorkshopDialog,
          onApproveProposal: _approveWorkshopProposal,
          onConfirmRegistration: _confirmRegistration,
          onRejectRegistration: _rejectRegistration,
          onDeleteRegistration: _showDeleteRegistrationDialog,
        );
      case 'creators':
        return WorkshopCreatorsTab(
          adminId: widget.adminSession['id']?.toString() ?? '',
        );
      case 'marketing':
        return const MarketingTab();
      default:
        return const OverviewTab();
    }
  }

  // ============================================================================
  // DIALOG METHODS
  // ============================================================================

  Future<void> _showRejectDialog(Map<String, dynamic> doctor) async {
    final reason = await DoctorDialogs.showRejectDialog(context, doctor);
    if (reason != null) {
      await _rejectDoctor(doctor, reason);
    }
  }

  Future<void> _showSuspendDialog(Map<String, dynamic> doctor) async {
    final status = doctor['status'] as String? ?? 'approved';
    final isSuspended = status == 'suspended';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSuspended ? 'Remove Suspension' : 'Suspend Doctor'),
        content: Text(
          isSuspended
              ? 'Remove suspension for ${doctor['fullName']}? The doctor will be able to login again.'
              : 'Suspend ${doctor['fullName']}? The doctor will not be able to login until unsuspended.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuspended ? Colors.green : Colors.orange,
            ),
            child: Text(isSuspended ? 'Remove Suspension' : 'Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isSuspended) {
        await _unsuspendDoctor(doctor);
      } else {
        await _suspendDoctor(doctor);
      }
    }
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> doctor) async {
    final confirmed = await DoctorDialogs.showDeleteDialog(context, doctor);
    if (confirmed) {
      await _deleteDoctor(doctor);
    }
  }

  Future<void> _showCancelBookingDialog(Map<String, dynamic> booking) async {
    final action = await BookingDialogs.showCancelBookingDialog(
      context,
      booking,
    );

    switch (action) {
      case CancelBookingAction.withRefund:
        await _cancelBookingWithRefundMutation(booking);
        break;
      case CancelBookingAction.withoutRefund:
        await _cancelBookingMutation(booking);
        break;
      case CancelBookingAction.cancel:
        // User cancelled
        break;
    }
  }

  Future<void> _showWorkshopDialog({Map<String, dynamic>? initialData}) async {
    final workshopData = await WorkshopDialogs.showWorkshopDialog(
      context,
      initialData: initialData,
    );

    if (workshopData != null) {
      if (initialData == null) {
        // Create new workshop
        await _createWorkshopMutation(workshopData);
      } else {
        // Update existing workshop
        final workshopId = initialData['id'] as int;
        await _updateWorkshopMutation(workshopId, workshopData);
      }
    }
  }

  Future<void> _showDeleteWorkshopDialog(Map<String, dynamic> workshop) async {
    final confirmed = await WorkshopDialogs.showDeleteWorkshopDialog(
      context,
      workshop,
    );
    if (confirmed) {
      await _deleteWorkshop(workshop);
    }
  }

  // ============================================================================
  // ACTION WRAPPER METHODS
  // ============================================================================

  Future<void> _approveDoctor(Map<String, dynamic> doctor) async {
    await _approveDoctorMutation(doctor);
  }

  Future<void> _rejectDoctor(Map<String, dynamic> doctor, String reason) async {
    await _rejectDoctorMutation(doctor, reason);
  }

  Future<void> _suspendDoctor(Map<String, dynamic> doctor) async {
    await _suspendDoctorMutation(doctor);
  }

  Future<void> _unsuspendDoctor(Map<String, dynamic> doctor) async {
    await _unsuspendDoctorMutation(doctor);
  }

  Future<void> _deleteDoctor(Map<String, dynamic> doctor) async {
    await _deleteDoctorMutation(doctor);
  }

  void _editWorkshop(Map<String, dynamic> workshop) {
    _showWorkshopDialog(initialData: workshop);
  }

  Future<void> _deleteWorkshop(Map<String, dynamic> workshop) async {
    await _deleteWorkshopMutation(workshop);
  }

  Future<void> _confirmRegistration(Map<String, dynamic> registration) async {
    await _confirmRegistrationMutation(registration);
  }

  Future<void> _approveWorkshopProposal(
    Map<String, dynamic> proposal,
    double fee,
  ) async {
    try {
      await _mutationsService.grantWorkshopPermission(
        workshopId: proposal['id'],
        adminSetFee: fee,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve proposal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRegistration(Map<String, dynamic> registration) async {
    await _rejectRegistrationMutation(registration);
  }

  Future<void> _showDeleteRegistrationDialog(
    Map<String, dynamic> registration,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Registration'),
        content: Text(
          'Are you sure you want to delete registration for ${registration['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminStyles.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRegistrationMutation(registration);
    }
  }
}
