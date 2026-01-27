import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/features/admin/utils/responsive_helper.dart';
import 'package:sehat_makaan_flutter/features/workshops/models/workshop_creator_model.dart';
import 'package:sehat_makaan_flutter/features/workshops/models/workshop_creator_request_model.dart';
import 'package:sehat_makaan_flutter/features/workshops/services/workshop_creator_service.dart';

class WorkshopCreatorsTab extends StatefulWidget {
  final String adminId;

  const WorkshopCreatorsTab({super.key, required this.adminId});

  @override
  State<WorkshopCreatorsTab> createState() => _WorkshopCreatorsTabState();
}

class _WorkshopCreatorsTabState extends State<WorkshopCreatorsTab>
    with SingleTickerProviderStateMixin {
  final WorkshopCreatorService _creatorService = WorkshopCreatorService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  List<WorkshopCreatorModel> _creators = [];
  Map<String, int> _workshopCounts = {};
  bool _isLoading = true;
  bool _isProcessingRequest = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCreators();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCreators() async {
    setState(() => _isLoading = true);
    try {
      final creators = await _creatorService.getAllWorkshopCreators();
      final Map<String, int> counts = {};

      // Load workshop counts for each creator
      for (final creator in creators) {
        if (creator.id != null) {
          final workshops = await _creatorService.getCreatorWorkshops(
            creator.id!,
          );
          counts[creator.id!] = workshops.length;
        }
      }

      if (mounted) {
        setState(() {
          _creators = creators;
          _workshopCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading creators: $e')));
      }
    }
  }

  Future<void> _showAddCreatorDialog() async {
    // Get list of approved doctors who are not already creators (exclude admins)
    final approvedDoctors = await _firestore
        .collection('users')
        .where('status', isEqualTo: 'approved')
        .where('userType', isEqualTo: 'doctor')
        .get();

    final existingCreatorUserIds = _creators
        .where((c) => c.isActive)
        .map((c) => c.userId)
        .toSet();

    final availableDoctors = approvedDoctors.docs
        .where((doc) => !existingCreatorUserIds.contains(doc.id))
        .toList();

    if (!mounted) return;

    if (availableDoctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No approved doctors available to add as creators'),
        ),
      );
      return;
    }

    String? selectedUserId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Workshop Creator'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a doctor to authorize as workshop creator:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Select Doctor',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: availableDoctors.map((doc) {
                    final data = doc.data();
                    final name = data['fullName'] ?? 'Unknown';
                    final email = data['email'] ?? '';
                    final specialty = data['specialty'] ?? '';
                    return DropdownMenuItem(
                      value: doc.id,
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              '$email${specialty.isNotEmpty ? " • $specialty" : ""}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedUserId = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedUserId == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _addCreator(selectedUserId!);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006876),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Creator'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCreator(String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;

      await _creatorService.addWorkshopCreator(
        userId: userId,
        fullName: userData['fullName'] ?? '',
        email: userData['email'] ?? '',
        specialty: userData['specialty'],
        adminId: widget.adminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workshop creator added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCreators();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding creator: $e')));
      }
    }
  }

  Future<void> _toggleCreatorStatus(
    WorkshopCreatorModel creator,
    bool activate,
  ) async {
    try {
      if (activate) {
        await _creatorService.reactivateWorkshopCreator(creator.id!);
      } else {
        await _creatorService.removeWorkshopCreator(creator.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activate
                  ? 'Creator reactivated successfully'
                  : 'Creator deactivated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCreators();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('workshop_creator_requests')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            final pendingCount = snapshot.hasData
                ? snapshot.data!.docs.length
                : 0;

            return TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF006876),
              indicatorColor: const Color(0xFF006876),
              tabs: [
                Tab(
                  text:
                      'Active Creators (${_creators.where((c) => c.isActive).length})',
                ),
                Tab(text: 'Pending Requests ($pendingCount)'),
              ],
            );
          },
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _creators.isEmpty
                  ? _buildEmptyState()
                  : _buildCreatorsList(),
              _buildPendingRequestsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final activeCount = _creators.where((c) => c.isActive).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workshop Creators',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
                Text(
                  '$activeCount active creator${activeCount != 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddCreatorDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Creator'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006876),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No workshop creators yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add approved doctors as workshop creators',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCreatorDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Creator'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006876),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = ResponsiveHelper.getSpacing(context);
        final availableWidth = constraints.maxWidth;
        final columnCount = ResponsiveHelper.getColumnCountForWidth(
          availableWidth,
          minTileWidth: 360,
          maxColumns: 3,
        );
        final itemWidth =
            (availableWidth - (spacing * (columnCount - 1))) / columnCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: _creators.map((creator) {
              final workshopCount = _workshopCounts[creator.id] ?? 0;

              return SizedBox(
                width: itemWidth,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: creator.isActive
                                  ? const Color(0xFF006876)
                                  : Colors.grey,
                              child: Text(
                                creator.fullName.isNotEmpty
                                    ? creator.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          creator.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!creator.isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Inactive',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    creator.email,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (creator.specialty != null &&
                                      creator.specialty!.isNotEmpty)
                                    Text(
                                      'Specialty: ${creator.specialty}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$workshopCount workshop${workshopCount != 1 ? 's' : ''} created',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006876),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => _toggleCreatorStatus(
                              creator,
                              !creator.isActive,
                            ),
                            icon: Icon(
                              creator.isActive
                                  ? Icons.block
                                  : Icons.check_circle,
                              color: creator.isActive
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            tooltip: creator.isActive
                                ? 'Deactivate'
                                : 'Reactivate',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('workshop_creator_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests =
            snapshot.data?.docs
                .map((doc) => WorkshopCreatorRequestModel.fromFirestore(doc))
                .toList() ??
            [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 80,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No pending requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final spacing = ResponsiveHelper.getSpacing(context);
            final availableWidth = constraints.maxWidth;
            final columnCount = ResponsiveHelper.getColumnCountForWidth(
              availableWidth,
              minTileWidth: 380,
              maxColumns: 2,
            );
            final itemWidth =
                (availableWidth - (spacing * (columnCount - 1))) / columnCount;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: requests.map((request) {
                  return SizedBox(
                    width: itemWidth,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFFF6B35),
                          child: Text(
                            request.fullName.isNotEmpty
                                ? request.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                request.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (request.specialty != null &&
                                  request.specialty!.isNotEmpty)
                                Text(
                                  request.specialty!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF006876),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Workshop Details Section
                    if (request.workshopType != null ||
                        request.workshopTopic != null ||
                        request.workshopDescription != null ||
                        request.expectedDuration != null ||
                        request.expectedParticipants != null ||
                        request.teachingExperience != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF006876,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 16,
                                  color: Color(0xFF006876),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Workshop Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006876),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (request.workshopType != null)
                              _buildDetailRow('Type', request.workshopType!),
                            if (request.workshopTopic != null)
                              _buildDetailRow('Topic', request.workshopTopic!),
                            if (request.expectedDuration != null)
                              _buildDetailRow(
                                'Duration',
                                request.expectedDuration!,
                              ),
                            if (request.expectedParticipants != null)
                              _buildDetailRow(
                                'Participants',
                                '${request.expectedParticipants} attendees',
                              ),
                            if (request.workshopDescription != null)
                              _buildDetailRow(
                                'Description',
                                request.workshopDescription!,
                                isMultiline: true,
                              ),
                            if (request.teachingExperience != null)
                              _buildDetailRow(
                                'Teaching Experience',
                                request.teachingExperience!,
                                isMultiline: true,
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Legacy message field (if exists)
                    if (request.message != null &&
                        request.message!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request.message!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Requested ${_formatTimeAgo(request.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _isProcessingRequest
                              ? null
                              : () => _rejectRequest(request),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isProcessingRequest
                              ? null
                              : () => _approveRequest(request),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006876),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            maxLines: isMultiline ? 5 : 1,
            overflow: isMultiline
                ? TextOverflow.ellipsis
                : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  Future<void> _approveRequest(WorkshopCreatorRequestModel request) async {
    if (request.id == null) return;

    setState(() => _isProcessingRequest = true);

    try {
      // Add user as workshop creator
      await _creatorService.addWorkshopCreator(
        userId: request.userId,
        fullName: request.fullName,
        email: request.email,
        specialty: request.specialty,
        adminId: widget.adminId,
      );

      // Update request status
      await _firestore
          .collection('workshop_creator_requests')
          .doc(request.id)
          .update({
            'status': 'approved',
            'respondedAt': FieldValue.serverTimestamp(),
            'respondedBy': widget.adminId,
          });

      // Send notification to user
      await _firestore.collection('notifications').add({
        'userId': request.userId,
        'type': 'creator_approved',
        'title': 'Workshop Creator Access Granted!',
        'message':
            'Congratulations! You can now create workshops. Go to your dashboard to get started.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved! User notified.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCreators();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingRequest = false);
      }
    }
  }

  Future<void> _rejectRequest(WorkshopCreatorRequestModel request) async {
    if (request.id == null) return;

    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject ${request.fullName}\'s request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != true) return;

    setState(() => _isProcessingRequest = true);

    try {
      // Update request status
      await _firestore
          .collection('workshop_creator_requests')
          .doc(request.id)
          .update({
            'status': 'rejected',
            'respondedAt': FieldValue.serverTimestamp(),
            'respondedBy': widget.adminId,
            'rejectionReason': reasonController.text.isNotEmpty
                ? reasonController.text
                : null,
          });

      // Send notification to user
      await _firestore.collection('notifications').add({
        'userId': request.userId,
        'type': 'creator_rejected',
        'title': 'Workshop Creator Request Status',
        'message': reasonController.text.isNotEmpty
            ? 'Your workshop creator request was declined. Reason: ${reasonController.text}'
            : 'Your workshop creator request was declined.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected. User notified.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingRequest = false);
      }
    }
  }
}
