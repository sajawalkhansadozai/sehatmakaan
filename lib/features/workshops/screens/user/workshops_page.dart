import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/workshop_service.dart';
import '../../models/workshop_model.dart';
import '../../models/workshop_registration_model.dart';
import '../../widgets/workshop_card_widget.dart';
import '../../widgets/my_joined_workshops_widget.dart';

class WorkshopsPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const WorkshopsPage({super.key, required this.userSession});

  @override
  State<WorkshopsPage> createState() => _WorkshopsPageState();
}

class _WorkshopsPageState extends State<WorkshopsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkshopService _workshopService = WorkshopService();
  final List<Map<String, dynamic>> _workshops = [];
  List<WorkshopModel> _myProposals = [];
  List<WorkshopRegistrationModel> _myRegistrations = [];
  final Map<String, String> _creatorNames = {}; // Map creatorId to name
  final Map<String, Map<String, dynamic>> _workshopCache =
      {}; // Cache workshop details
  bool _isLoading = true;
  Timer? _countdownTimer;
  StreamSubscription<List<WorkshopModel>>? _proposalsSubscription;
  StreamSubscription<List<WorkshopRegistrationModel>>?
  _registrationsSubscription;

  // 📄 Pagination State
  static const int _workshopsPerPage = 12;
  bool _hasMoreWorkshops = true;
  DocumentSnapshot? _lastDocument;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _proposalsSubscription?.cancel();
    _registrationsSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
    _loadMyProposals();
    _loadMyRegistrations();
  }

  void _loadMyProposals() {
    final userId = widget.userSession['id']?.toString();

    debugPrint('🔍 _loadMyProposals called');
    debugPrint('  userId: $userId');
    debugPrint('  userSession: ${widget.userSession}');

    if (userId == null) {
      debugPrint('❌ No userId found!');
      return;
    }

    // Use WorkshopService stream to get real-time updates
    _proposalsSubscription?.cancel();
    _proposalsSubscription = _workshopService.getWorkshopsByCreator(userId).listen((
      workshops,
    ) async {
      if (!mounted) return;

      debugPrint('📦 Received ${workshops.length} workshops from Firestore');

      for (var w in workshops) {
        debugPrint('  Workshop: ${w.title}');
        debugPrint('    - id: ${w.id}');
        debugPrint('    - permissionStatus: ${w.permissionStatus}');
        debugPrint('    - isActive: ${w.isActive}');
        debugPrint('    - isCreationFeePaid: ${w.isCreationFeePaid}');
        debugPrint('    - adminSetFee: ${w.adminSetFee}');
        debugPrint('    - createdBy: ${w.createdBy}');
      }

      // Filter proposals (exclude fully active workshops)
      final proposals = workshops
          .where(
            (w) =>
                w.permissionStatus == 'pending_admin' ||
                w.permissionStatus == 'approved' ||
                w.permissionStatus == 'rejected' ||
                (w.permissionStatus == 'expired' && !w.isActive),
          )
          .toList();

      debugPrint('✅ Filtered to ${proposals.length} proposals');
      for (var p in proposals) {
        debugPrint('  - ${p.title}: ${p.permissionStatus}');
      }

      // Check for expired workshops and mark them
      for (final workshop in proposals) {
        if (workshop.permissionStatus == 'approved' &&
            !workshop.isCreationFeePaid &&
            _workshopService.hasPaymentExpired(workshop.permissionGrantedAt)) {
          // Mark as expired
          await _workshopService.updateWorkshop(
            workshopId: workshop.id!,
            updates: {'permissionStatus': 'expired'},
          );
        }
      }

      setState(() {
        _myProposals = proposals;
      });

      // Start timer to update countdown every second if there are approved proposals
      _countdownTimer?.cancel();
      if (proposals.any(
        (p) => p.permissionStatus == 'approved' && !p.isCreationFeePaid,
      )) {
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          try {
            setState(() {}); // Trigger rebuild to update countdown
          } catch (e) {
            // Ignore errors if widget is disposed during setState
          }
        });
      }
    });
  }

  void _loadMyRegistrations() {
    final userId = widget.userSession['id']?.toString();
    if (userId == null) return;

    // Use WorkshopService stream to get real-time registration updates
    _registrationsSubscription?.cancel();
    _registrationsSubscription = _workshopService
        .getUserRegistrations(userId)
        .listen((registrations) async {
          if (!mounted) return;

          // Filter pending/approved registrations (exclude completed/rejected)
          final activeRegistrations = registrations
              .where(
                (r) =>
                    r.approvalStatus == 'pending_creator' ||
                    r.approvalStatus == 'approved_by_creator' ||
                    r.paymentStatus == 'pending',
              )
              .toList();

          // Fetch workshop details for each registration
          for (final registration in activeRegistrations) {
            if (!_workshopCache.containsKey(registration.workshopId)) {
              final workshopDoc = await _firestore
                  .collection('workshops')
                  .doc(registration.workshopId)
                  .get();
              if (workshopDoc.exists) {
                final workshopData = workshopDoc.data() ?? {};
                workshopData['id'] = workshopDoc.id;
                _workshopCache[registration.workshopId] = workshopData;
              }
            }
          }

          setState(() {
            _myRegistrations = activeRegistrations;
          });

          // Start timer to update countdown for approved registrations awaiting payment
          _countdownTimer?.cancel();
          if (activeRegistrations.any(
            (r) =>
                r.approvalStatus == 'approved_by_creator' &&
                r.paymentStatus == 'pending',
          )) {
            _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (!mounted) return;
              try {
                setState(() {}); // Trigger rebuild to update countdown
              } catch (e) {
                // Ignore errors if widget is disposed during setState
              }
            });
          }
        });
  }

  Future<void> _loadWorkshops() async {
    setState(() => _isLoading = true);

    try {
      // 📄 Paginated query: Load workshops in batches
      Query query = _firestore
          .collection('workshops')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_workshopsPerPage);

      // If loading next page, start after last document
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      // Check if we've reached the end
      _hasMoreWorkshops = querySnapshot.docs.length == _workshopsPerPage;

      // Store last document for pagination
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      final workshops = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // 🚀 Load creator names from users collection (createdBy holds userId)
      final creatorIds = workshops
          .where((w) => w['createdBy'] != null)
          .map((w) => w['createdBy'] as String)
          .toSet();

      final Map<String, String> creatorNames = {};

      if (creatorIds.isNotEmpty) {
        try {
          // Firestore whereIn limit is 30 items, so batch if needed
          final List<String> creatorIdsList = creatorIds.toList();

          for (int i = 0; i < creatorIdsList.length; i += 30) {
            final batch = creatorIdsList.skip(i).take(30).toList();

            final usersSnapshot = await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

            for (final doc in usersSnapshot.docs) {
              final data = doc.data();
              final name =
                  data['fullName'] ??
                  data['name'] ??
                  data['firstName'] ??
                  'Unknown Creator';
              creatorNames[doc.id] = name.toString();
            }
          }

          // Add "Unknown Creator" for missing IDs
          for (final id in creatorIds) {
            creatorNames.putIfAbsent(id, () => 'Unknown Creator');
          }
        } catch (e) {
          debugPrint('❌ Error loading creators: $e');
          for (final id in creatorIds) {
            creatorNames[id] = 'Unknown Creator';
          }
        }
      }

      if (mounted) {
        setState(() {
          _workshops.clear();
          _workshops.addAll(workshops);
          _creatorNames.addAll(creatorNames);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading workshops: $e')));
      }
    }
  }

  // ============================================================================
  // WORKSHOP ACTIONS
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final userId = widget.userSession['id']?.toString();
    final myCreatedWorkshops = _workshops
        .where((w) => w['createdBy']?.toString() == userId)
        .toList();
    final isCreator = myCreatedWorkshops.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeader()),
          // 🎯 CREATOR COMMAND CENTER: Quick Stats
          if (isCreator) ...[
            SliverToBoxAdapter(
              child: _buildCreatorQuickStats(myCreatedWorkshops),
            ),
          ],
          // Always show My Proposals section if user has created any workshops
          SliverToBoxAdapter(child: _buildMyProposalsSection()),
          if (_myRegistrations.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildMyRegistrationsSection()),
          ],
          // 🎯 MY JOINED WORKSHOPS: Show only confirmed registrations
          SliverToBoxAdapter(
            child: MyJoinedWorkshopsWidget(
              userId: userId ?? '',
              userSession: widget.userSession,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _isLoading
                ? _buildLoadingGrid()
                : (_workshops.isEmpty
                      ? _buildEmptyState()
                      : _buildWorkshopGrid()),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: const Color(0xFF006876),
      elevation: 2,
      title: const Text(
        'Professional Workshops',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/dashboard',
              arguments: widget.userSession,
            );
          },
          icon: const Icon(Icons.dashboard, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3E5F5), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: 'Professional ',
                  style: TextStyle(color: Color(0xFF006876)),
                ),
                TextSpan(
                  text: 'Workshops',
                  style: TextStyle(color: Color(0xFFFF6B35)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enhance your medical skills with certified training programs and earn continuing education credits',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF006876).withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        childCount: 3,
      ),
    );
  }

  /// 🎭 GOD-LEVEL EMPTY STATE
  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              // Soft gradient circle background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF006876).withValues(alpha: 0.1),
                      const Color(0xFF006876).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 60,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'No Workshops Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Discover professional development opportunities\nand join workshops from expert doctors',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF006876).withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Premium CTA button with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006876), Color(0xFF004D57)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006876).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Refresh workshops
                    _loadWorkshops();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Refresh Workshops',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkshopGrid() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        // Show workshop cards
        if (index < _workshops.length) {
          final workshop = _workshops[index];
          return _buildWorkshopCard(workshop);
        }

        // Show "Load More" button at the end if there are more workshops
        if (index == _workshops.length && _hasMoreWorkshops) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadMoreWorkshops,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(_isLoading ? 'Loading...' : 'Load More Workshops'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006876),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      }, childCount: _workshops.length + (_hasMoreWorkshops ? 1 : 0)),
    );
  }

  /// 📄 Load more workshops (pagination)
  Future<void> _loadMoreWorkshops() async {
    if (!_hasMoreWorkshops || _isLoading) return;

    await _loadWorkshops();
  }

  /// 🎨 PREMIUM WORKSHOP CARD USING NEW WIDGET
  Widget _buildWorkshopCard(Map<String, dynamic> workshop) {
    final creatorId = workshop['createdBy'] as String?;
    final isCreator = widget.userSession['id']?.toString() == creatorId;

    return WorkshopCard(
      workshop: workshop,
      creatorName: creatorId != null ? _creatorNames[creatorId] : null,
      isCreator: isCreator,
      onTap: () {
        // ✅ PROPER FLOW: Go to registration form first
        Navigator.pushNamed(
          context,
          '/workshop-registration',
          arguments: {'workshop': workshop, 'userSession': widget.userSession},
        );
      },
      onManageRequests: isCreator
          ? () => _showJoinRequestsDialog(workshop)
          : null,
      onViewAnalytics: isCreator
          ? () => _showWorkshopAnalytics(workshop)
          : null,
    );
  }

  // ============================================================================
  // 🎯 PHASE 2: CREATOR COMMAND CENTER
  // ============================================================================

  /// 📊 FLOATING QUICK-STATS FOR CREATORS
  Widget _buildCreatorQuickStats(List<Map<String, dynamic>> myWorkshops) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006876), Color(0xFF004D57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006876).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creator Command Center',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your Workshop Analytics Dashboard',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 140,
            padding: const EdgeInsets.only(bottom: 16),
            child: StreamBuilder<List<WorkshopRegistrationModel>>(
              stream: _getCreatorRequests(myWorkshops),
              builder: (context, requestSnapshot) {
                final pendingRequests = requestSnapshot.data ?? [];
                return _buildQuickStatsScroll(
                  myWorkshops,
                  pendingRequests.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<WorkshopRegistrationModel>> _getCreatorRequests(
    List<Map<String, dynamic>> workshops,
  ) {
    if (workshops.isEmpty) {
      return Stream.value([]);
    }

    final workshopIds = workshops
        .map((w) => w['id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (workshopIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('workshop_registrations')
        .where('workshopId', whereIn: workshopIds.take(10).toList())
        .where('approvalStatus', isEqualTo: 'pending_creator')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkshopRegistrationModel.fromFirestore(doc))
              .toList();
        });
  }

  Widget _buildQuickStatsScroll(
    List<Map<String, dynamic>> workshops,
    int pendingCount,
  ) {
    // Calculate total revenue
    double totalRevenue = 0;
    int totalSeats = 0;
    int filledSeats = 0;

    for (final workshop in workshops) {
      final price = (workshop['price'] as num?)?.toDouble() ?? 0;
      final currentParticipants =
          (workshop['currentParticipants'] as int?) ?? 0;
      final maxParticipants = (workshop['maxParticipants'] as int?) ?? 0;

      totalRevenue += price * currentParticipants;
      totalSeats += maxParticipants;
      filledSeats += currentParticipants;
    }

    final fillPercentage = totalSeats > 0
        ? (filledSeats / totalSeats * 100).clamp(0, 100)
        : 0.0;

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 💰 TOTAL REVENUE CARD - Tap to see breakdown
        GestureDetector(
          onTap: () => _showRevenueBreakdown(workshops),
          child: _buildStatCard(
            icon: Icons.attach_money,
            title: 'Total Revenue',
            value: 'PKR ${totalRevenue.toStringAsFixed(0)}',
            subtitle: 'From $filledSeats participants',
            iconColor: const Color(0xFFFFD700),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.2),
                const Color(0xFFFFA500).withValues(alpha: 0.2),
              ],
            ),
            isClickable: true,
          ),
        ),
        const SizedBox(width: 12),
        // 🔔 PENDING REQUESTS CARD - Tap to view requests
        GestureDetector(
          onTap: pendingCount > 0
              ? () => _showAllPendingRequests(workshops)
              : null,
          child: _buildStatCard(
            icon: Icons.notifications_active,
            title: 'Pending Requests',
            value: pendingCount.toString(),
            subtitle: pendingCount == 1
                ? '1 person waiting'
                : pendingCount == 0
                ? 'No pending requests'
                : '$pendingCount people waiting',
            iconColor: const Color(0xFFFF6B35),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6B35).withValues(alpha: 0.2),
                const Color(0xFFFF8C42).withValues(alpha: 0.2),
              ],
            ),
            isPulsing: pendingCount > 0,
            isClickable: pendingCount > 0,
          ),
        ),
        const SizedBox(width: 12),
        // 💺 SEATS FILLED CARD - Tap to see seat allocation
        GestureDetector(
          onTap: () => _showSeatsBreakdown(workshops, filledSeats, totalSeats),
          child: _buildStatCard(
            icon: Icons.event_seat,
            title: 'Seats Filled',
            value: '${fillPercentage.toStringAsFixed(0)}%',
            subtitle: '$filledSeats / $totalSeats seats',
            iconColor: const Color(0xFF90D26D),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF90D26D).withValues(alpha: 0.2),
                const Color(0xFF70B24D).withValues(alpha: 0.2),
              ],
            ),
            showProgress: true,
            progressValue: fillPercentage / 100,
            isClickable: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    required Gradient gradient,
    bool isPulsing = false,
    bool showProgress = false,
    double progressValue = 0.0,
    bool isClickable = false,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClickable
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.3),
          width: isClickable ? 2 : 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (isPulsing)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: iconColor.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                if (isClickable && !isPulsing)
                  Icon(
                    Icons.touch_app,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            if (showProgress) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isClickable) ...[
              const SizedBox(height: 4),
              Text(
                'Tap for details',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// � REVENUE BREAKDOWN DIALOG
  void _showRevenueBreakdown(List<Map<String, dynamic>> workshops) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Revenue Breakdown',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006876),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (workshops.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No workshops yet')),
                ),
              if (workshops.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: workshops.length,
                    itemBuilder: (context, index) {
                      final workshop = workshops[index];
                      final price =
                          (workshop['price'] as num?)?.toDouble() ?? 0;
                      final participants =
                          (workshop['currentParticipants'] as int?) ?? 0;
                      final revenue = price * participants;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.2),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            workshop['title'] ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$participants participants × PKR ${price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            'PKR ${revenue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006876),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006876),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔔 ALL PENDING REQUESTS DIALOG
  void _showAllPendingRequests(List<Map<String, dynamic>> workshops) {
    final workshopIds = workshops
        .map((w) => w['id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (workshopIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Color(0xFFFF6B35),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pending Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006876),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('workshop_registrations')
                    .where('workshopId', whereIn: workshopIds.take(10).toList())
                    .where('approvalStatus', isEqualTo: 'pending_creator')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final requests = snapshot.data!.docs;

                  if (requests.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No pending requests')),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final registration =
                            requests[index].data() as Map<String, dynamic>;
                        final firstName = registration['firstName'] ?? '';
                        final lastName = registration['lastName'] ?? '';
                        final email = registration['email'] ?? '';
                        final workshopId = registration['workshopId'] ?? '';
                        final workshop = workshops.firstWhere(
                          (w) => w['id'] == workshopId,
                          orElse: () => {},
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFFFF6B35,
                              ).withValues(alpha: 0.2),
                              child: Text(
                                '${firstName[0]}${lastName[0]}'.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '$firstName $lastName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                if (workshop.isNotEmpty)
                                  Text(
                                    workshop['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                if (workshop.isNotEmpty) {
                                  _showJoinRequestsDialog(workshop);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006876),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 💺 SEATS BREAKDOWN DIALOG
  void _showSeatsBreakdown(
    List<Map<String, dynamic>> workshops,
    int filledSeats,
    int totalSeats,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF90D26D).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_seat,
                      color: Color(0xFF90D26D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Seats Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006876),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF90D26D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          filledSeats.toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF90D26D),
                          ),
                        ),
                        const Text(
                          'Filled',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          (totalSeats - filledSeats).toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const Text(
                          'Available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          totalSeats.toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006876),
                          ),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (workshops.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: workshops.length,
                    itemBuilder: (context, index) {
                      final workshop = workshops[index];
                      final current =
                          (workshop['currentParticipants'] as int?) ?? 0;
                      final max = (workshop['maxParticipants'] as int?) ?? 0;
                      final percentage = max > 0
                          ? (current / max * 100).clamp(0, 100)
                          : 0.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            workshop['title'] ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey.withValues(
                                    alpha: 0.2,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF90D26D),
                                      ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$current / $max seats (${percentage.toStringAsFixed(0)}%)',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006876),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// �📊 DEEP ANALYTICS BOTTOM SHEET
  void _showWorkshopAnalytics(Map<String, dynamic> workshop) {
    final workshopId = workshop['id'] as String?;
    if (workshopId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF006876), Color(0xFF004D57)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Deep Analytics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006876),
                              ),
                            ),
                            Text(
                              workshop['title'] as String? ?? 'Workshop',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Analytics Content
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('workshop_registrations')
                        .where('workshopId', isEqualTo: workshopId)
                        .where('paymentStatus', isEqualTo: 'paid')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No participant data yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final registrations = snapshot.data!.docs;
                      final professionCounts = <String, int>{};

                      for (final doc in registrations) {
                        final data = doc.data() as Map<String, dynamic>;
                        final profession =
                            (data['profession'] as String?) ?? 'Unknown';
                        professionCounts[profession] =
                            (professionCounts[profession] ?? 0) + 1;
                      }

                      final total = registrations.length;
                      final professionData =
                          professionCounts.entries
                              .map(
                                (e) => MapEntry(
                                  e.key,
                                  (e.value / total * 100).toStringAsFixed(1),
                                ),
                              )
                              .toList()
                            ..sort(
                              (a, b) => double.parse(
                                b.value,
                              ).compareTo(double.parse(a.value)),
                            );

                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildAnalyticsCard(
                            title: 'Participant Breakdown',
                            icon: Icons.people,
                            child: Column(
                              children: [
                                ...professionData.map((entry) {
                                  final percentage = double.parse(entry.value);
                                  return _buildProfessionBar(
                                    profession: entry.key,
                                    percentage: percentage,
                                    count: professionCounts[entry.key]!,
                                  );
                                }),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF006876,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Participants',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF006876),
                                        ),
                                      ),
                                      Text(
                                        total.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF006876),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnalyticsCard(
                            title: 'Revenue Metrics',
                            icon: Icons.monetization_on,
                            child: Column(
                              children: [
                                _buildMetricRow(
                                  'Price per Seat',
                                  'PKR ${(workshop['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                  Icons.attach_money,
                                  const Color(0xFFFFD700),
                                ),
                                const Divider(height: 24),
                                _buildMetricRow(
                                  'Total Revenue',
                                  'PKR ${((workshop['price'] as num?)?.toDouble() ?? 0 * total).toStringAsFixed(0)}',
                                  Icons.account_balance_wallet,
                                  const Color(0xFF90D26D),
                                ),
                                const Divider(height: 24),
                                _buildMetricRow(
                                  'Capacity',
                                  '${workshop['currentParticipants'] ?? 0}/${workshop['maxParticipants'] ?? 0}',
                                  Icons.event_seat,
                                  const Color(0xFF006876),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF006876), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionBar({
    required String profession,
    required double percentage,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  profession,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006876),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF006876),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006876),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // END PHASE 2: CREATOR COMMAND CENTER
  // ============================================================================

  // Legacy helper methods (unused but kept for backward compatibility)
  // ignore: unused_element
  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF006876).withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF006876).withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildDetailSection(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFF006876).withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF006876).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF006876).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProposalsSection() {
    final userId = widget.userSession['id']?.toString();

    // Debug: Print current state
    debugPrint('🔍 My Proposals Section:');
    debugPrint('  userId: $userId');
    debugPrint('  _myProposals.length: ${_myProposals.length}');

    if (_myProposals.isNotEmpty) {
      for (var p in _myProposals) {
        debugPrint(
          '  - ${p.title}: ${p.permissionStatus} (paid: ${p.isCreationFeePaid}, fee: ${p.adminSetFee})',
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006876), Color(0xFF00A8B8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006876).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'My Workshop Proposals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
              if (_myProposals.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_myProposals.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_myProposals.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userId == null
                          ? 'Please login to view your workshops'
                          : 'No workshop proposals yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (userId != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-workshop');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Your First Workshop'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ..._myProposals.map((proposal) => _buildProposalCard(proposal)),
        ],
      ),
    );
  }

  Widget _buildMyRegistrationsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 GOD-LEVEL SECTION HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'My Registrations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '[${_myRegistrations.length}]',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 🎯 PHASE 3: VERTICAL TIMELINE LAYOUT
          ...(_myRegistrations.asMap().entries.map((entry) {
            final index = entry.key;
            final registration = entry.value;
            final isLast = index == _myRegistrations.length - 1;
            return _buildTimelineRegistrationCard(registration, isLast);
          })),
        ],
      ),
    );
  }

  /// 🎯 PHASE 3: VERTICAL TIMELINE REGISTRATION CARD
  Widget _buildTimelineRegistrationCard(
    WorkshopRegistrationModel registration,
    bool isLast,
  ) {
    final workshop = _workshopCache[registration.workshopId];
    if (workshop == null) {
      return const SizedBox.shrink();
    }

    final approvalStatus = registration.approvalStatus;
    Color dotColor;

    switch (approvalStatus) {
      case 'pending_creator':
        dotColor = Colors.orange;
        break;
      case 'approved_by_creator':
        dotColor = registration.paymentStatus == 'paid'
            ? const Color(0xFF90D26D)
            : Colors.green;
        break;
      case 'rejected':
        dotColor = Colors.red;
        break;
      default:
        dotColor = Colors.grey;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              // Timeline dot
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Timeline vertical line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          dotColor.withValues(alpha: 0.6),
                          dotColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Card content
          Expanded(child: _buildRegistrationCard(registration)),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(WorkshopRegistrationModel registration) {
    final workshop = _workshopCache[registration.workshopId];
    if (workshop == null) {
      return const SizedBox.shrink();
    }

    final approvalStatus = registration.approvalStatus;
    final workshopTitle = workshop['title'] ?? 'Workshop';
    final workshopPrice = (workshop['price'] ?? 0).toDouble();
    final creatorApprovedAt = registration.creatorApprovedAt;

    Color statusColor;
    String statusText;
    IconData statusIcon;
    bool showCountdown = false;
    bool showExpired = false;

    switch (approvalStatus) {
      case 'pending_creator':
        statusColor = Colors.orange;
        statusText = 'PENDING APPROVAL';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved_by_creator':
        if (registration.paymentStatus == 'pending') {
          if (creatorApprovedAt != null &&
              !_workshopService.hasJoiningPaymentExpired(creatorApprovedAt)) {
            statusColor = Colors.green;
            statusText = 'APPROVED - PAY NOW';
            statusIcon = Icons.check_circle;
            showCountdown = true;
          } else {
            statusColor = Colors.red;
            statusText = 'APPROVAL EXPIRED';
            statusIcon = Icons.error_outline;
            showExpired = true;
          }
        } else {
          statusColor = Colors.blue;
          statusText = 'PAYMENT COMPLETED';
          statusIcon = Icons.done_all;
        }
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'REJECTED';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'UNKNOWN';
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workshopTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Registration #${registration.registrationNumber}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            if (showCountdown && creatorApprovedAt != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildRegistrationCountdownTimer(
                creatorApprovedAt,
                workshopPrice,
                workshop,
                registration.id!,
              ),
            ],

            if (showExpired) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your 1-hour payment window has expired. Please register again.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (registration.approvalStatus == 'rejected') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Reason: ${registration.rejectionReason ?? 'Not specified'}',
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                ),
              ),
            ],

            // 🎯 PHASE 3: GOLD-FOIL CERTIFICATE CARD
            if (registration.status == 'attended' ||
                registration.status == 'completed' ||
                registration.certificateUrl != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildGoldCertificateCard(registration, workshop),
            ],
          ],
        ),
      ),
    );
  }

  /// 🎯 PHASE 3: ANIMATED CIRCULAR COUNTDOWN TIMER
  Widget _buildRegistrationCountdownTimer(
    DateTime approvedAt,
    double price,
    Map<String, dynamic> workshop,
    String registrationId,
  ) {
    final remainingSeconds = _workshopService.getRemainingJoiningTime(
      approvedAt,
    );
    final totalSeconds = 3600; // 1 hour
    final progress = remainingSeconds / totalSeconds;
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;

    // Color transitions: Green → Yellow → Orange → Red
    Color timerColor;
    if (progress > 0.5) {
      timerColor = const Color(0xFF90D26D); // Green
    } else if (progress > 0.25) {
      timerColor = Colors.orange; // Orange
    } else {
      timerColor = Colors.red; // Red
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            timerColor.withValues(alpha: 0.1),
            timerColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: timerColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.alarm, color: timerColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Complete Payment Within:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 🎯 CIRCULAR PROGRESS COUNTDOWN
          Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(Colors.grey.shade200),
                ),
              ),
              // Animated progress circle
              SizedBox(
                width: 180,
                height: 180,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: progress),
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation(timerColor),
                    );
                  },
                ),
              ),
              // Time display in center
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCircularTimeUnit(hours.toString(), 'H', timerColor),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: timerColor,
                          ),
                        ),
                      ),
                      _buildCircularTimeUnit(
                        minutes.toString().padLeft(2, '0'),
                        'M',
                        timerColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: timerColor,
                          ),
                        ),
                      ),
                      _buildCircularTimeUnit(
                        seconds.toString().padLeft(2, '0'),
                        'S',
                        timerColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: timerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      progress > 0.5
                          ? '⏰ Time Available'
                          : progress > 0.25
                          ? '⚠️ Hurry Up!'
                          : '🔥 Urgent!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: remainingSeconds <= 0
                  ? null
                  : () {
                      // GOD MODE: Check restrictions before allowing payment

                      // Navigate to checkout page
                      Navigator.pushNamed(
                        context,
                        '/workshop-checkout',
                        arguments: {
                          'workshop': workshop,
                          'registrationId': registrationId,
                          'registrationData': {
                            'userId': widget.userSession['id'],
                          },
                        },
                      );
                    },
              icon: const Icon(Icons.payment, size: 20),
              label: Text(
                'Pay PKR ${price.toStringAsFixed(0)} to Confirm Seat',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: remainingSeconds <= 0
                    ? Colors.grey
                    : timerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTimeUnit(String value, String unit, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// 🎯 PHASE 3: GOLD-FOIL CERTIFICATE CARD WITH SHINE ANIMATION
  Widget _buildGoldCertificateCard(
    WorkshopRegistrationModel registration,
    Map<String, dynamic> workshop,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 3),
      tween: Tween<double>(begin: -1.0, end: 2.0),
      curve: Curves.easeInOut,
      builder: (context, shinePosition, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700), // Gold
                Color(0xFFFFE55C), // Light gold
                Color(0xFFFFD700), // Gold
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shine animation overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: Transform.translate(
                      offset: Offset(
                        MediaQuery.of(context).size.width * shinePosition,
                        0,
                      ),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Column(
                children: [
                  // Certificate icon and title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFFFD700),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎓 Workshop Completed!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your certificate is ready',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Certificate preview card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Color(0xFFFFD700),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          workshop['title'] ?? 'Workshop',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006876),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          registration.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (registration.attendedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Attended on ${_formatDate(registration.attendedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Download button with shine effect
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: registration.certificateUrl != null
                          ? () {
                              // TODO: Implement certificate download
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '📥 Downloading certificate...',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text(
                        'Download Certificate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFFD700),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFFFD700),
                            width: 2,
                          ),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // Restart shine animation in a loop
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.green.shade700),
        ),
      ],
    );
  }

  Widget _buildProposalCard(WorkshopModel proposal) {
    final permissionStatus = proposal.permissionStatus;
    final isCreationFeePaid = proposal.isCreationFeePaid;
    final adminSetFee = proposal.adminSetFee;
    final permissionGrantedAt = proposal.permissionGrantedAt;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (permissionStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'APPROVED';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'REJECTED';
        statusIcon = Icons.cancel;
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusText = 'EXPIRED';
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'PENDING REVIEW';
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proposal.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              proposal.description,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (permissionStatus == 'approved' && !isCreationFeePaid) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildCountdownTimer(permissionGrantedAt, adminSetFee),
            ],

            if (permissionStatus == 'rejected') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejection Reason:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            proposal.rejectionReason ?? 'No reason provided',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 💰 PHASE 4: PAYOUT REQUEST UI
            if (proposal.endDate != null &&
                DateTime.now().isAfter(proposal.endDate!) &&
                proposal.payoutStatus == 'none' &&
                proposal.isCreationFeePaid) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Workshop Completed! Ready for Payout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _requestPayout(proposal),
                        icon: const Icon(Icons.request_quote),
                        label: const Text('Calculate & Request Payout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Show payout status if requested or released
            if (proposal.payoutStatus == 'requested') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payout Requested',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Net Amount: PKR ${proposal.doctorPayout?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Awaiting admin approval',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (proposal.payoutStatus == 'released') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✅ Payout Released!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Amount: PKR ${proposal.doctorPayout?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(
    DateTime? permissionGrantedAt,
    double? adminSetFee,
  ) {
    if (permissionGrantedAt == null || adminSetFee == null) {
      return const SizedBox.shrink();
    }

    // Use WorkshopService to get remaining time
    final remainingSeconds = _workshopService.getRemainingPaymentTime(
      permissionGrantedAt,
    );

    if (remainingSeconds <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payment deadline expired',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alarm, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Payment Required Within:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox('$hours', 'Hours'),
              const Text(
                ' : ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildTimeBox(minutes.toString().padLeft(2, '0'), 'Minutes'),
              const Text(
                ' : ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildTimeBox(seconds.toString().padLeft(2, '0'), 'Seconds'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: remainingSeconds <= 0
                  ? null
                  : () async {
                      // Get the workshop data
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) return;

                      try {
                        final workshopSnapshot = await _firestore
                            .collection('workshops')
                            .where('createdBy', isEqualTo: userId)
                            .where('permissionStatus', isEqualTo: 'approved')
                            .where('isCreationFeePaid', isEqualTo: false)
                            .limit(1)
                            .get();

                        if (workshopSnapshot.docs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Workshop not found'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final workshopDoc = workshopSnapshot.docs.first;
                        final workshop = WorkshopModel.fromFirestore(
                          workshopDoc,
                        );

                        // Navigate to creation fee checkout page
                        Navigator.pushNamed(
                          context,
                          '/workshop-creation-fee-checkout',
                          arguments: {'workshop': workshop},
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.payment),
              label: Text(
                'Pay PKR ${adminSetFee.toStringAsFixed(0)} to Go Live',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💰 PHASE 4: Request workshop payout
  Future<void> _requestPayout(WorkshopModel workshop) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF006876)),
      ),
    );

    try {
      final result = await _workshopService.requestWorkshopPayout(workshop.id!);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result['success']) {
          final doctorPayout = result['doctorPayout'] ?? 0.0;

          // Show success dialog with payout details
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Text('Payout Requested!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your payout request has been submitted successfully.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Net Payout',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PKR ${doctorPayout.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '(After 20% admin commission)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The admin will review and release your payout soon.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it!'),
                ),
              ],
            ),
          );
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to request payout'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 🎯 MODERN REQUEST MANAGEMENT DIALOG WITH QUICK ACTIONS
  void _showJoinRequestsDialog(Map<String, dynamic> workshop) {
    final workshopId = workshop['id'] as String?;
    if (workshopId == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF006876),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Join Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: StreamBuilder<List<WorkshopRegistrationModel>>(
                  stream: _workshopService.getPendingJoinRequests(workshopId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No pending join requests',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    final requests = snapshot.data!;

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return _buildJoinRequestCard(request, workshopId);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinRequestCard(
    WorkshopRegistrationModel request,
    String workshopId,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(
                    0xFF006876,
                  ).withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: Color(0xFF006876)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(request.phoneNumber, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.badge, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(request.cnicNumber, style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.work, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(request.profession, style: const TextStyle(fontSize: 13)),
              ],
            ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Notes:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(request.notes!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // 🎯 QUICK ACTION BUTTONS WITH HAPTIC FEEDBACK
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _rejectJoinRequest(request);
                  },
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _approveJoinRequest(request, workshopId);
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveJoinRequest(
    WorkshopRegistrationModel request,
    String workshopId,
  ) async {
    try {
      final result = await _workshopService.approveJoinRequest(
        registrationId: request.id!,
        workshopId: workshopId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Request approved'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectJoinRequest(WorkshopRegistrationModel request) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Join Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reject ${request.name}\'s request?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, reasonController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      try {
        final result = await _workshopService.rejectJoinRequest(
          registrationId: request.id!,
          reason: reason.isEmpty ? 'Not specified' : reason,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Request rejected'),
              backgroundColor: result['success'] ? Colors.orange : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
