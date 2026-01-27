import 'package:flutter/material.dart';
import '../widgets/workshop_card_widget.dart';
import 'package:sehat_makaan_flutter/features/admin/utils/admin_styles.dart';
import 'package:sehat_makaan_flutter/features/admin/utils/responsive_helper.dart';
import 'package:sehat_makaan_flutter/features/workshops/services/workshop_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkshopsTab extends StatelessWidget {
  final List<Map<String, dynamic>> workshops;
  final List<Map<String, dynamic>> pendingProposals;
  final List<Map<String, dynamic>> workshopRegistrations;
  final bool isSubmittingWorkshop;
  final bool isDeletingWorkshop;
  final VoidCallback onCreateWorkshop;
  final Function(Map<String, dynamic>) onEditWorkshop;
  final Function(Map<String, dynamic>) onDeleteWorkshop;
  final Function(Map<String, dynamic>, double) onApproveProposal;
  final Function(Map<String, dynamic>) onConfirmRegistration;
  final Function(Map<String, dynamic>) onRejectRegistration;
  final Function(Map<String, dynamic>) onDeleteRegistration;
  final Function(Map<String, dynamic>, String)? onReleaseWorkshopPayout;

  // Phase 5: Workshop Service for financial snapshots
  static final WorkshopService _workshopService = WorkshopService();

  const WorkshopsTab({
    super.key,
    required this.workshops,
    required this.pendingProposals,
    required this.workshopRegistrations,
    required this.isSubmittingWorkshop,
    required this.isDeletingWorkshop,
    required this.onCreateWorkshop,
    required this.onEditWorkshop,
    required this.onDeleteWorkshop,
    required this.onApproveProposal,
    required this.onConfirmRegistration,
    required this.onRejectRegistration,
    required this.onDeleteRegistration,
    this.onReleaseWorkshopPayout,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getSpacing(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Workshop Button
          Card(
            child: Padding(
              padding: ResponsiveHelper.getCardPadding(context),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Workshop',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add new professional workshops',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: onCreateWorkshop,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminStyles.primaryColor,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Workshop',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add new professional development workshops',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: onCreateWorkshop,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminStyles.primaryColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: spacing),

          // Pending Workshop Proposals Section
          Card(
            child: Padding(
              padding: ResponsiveHelper.getCardPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pending_actions,
                        size: 20,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pending Workshop Proposals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pendingProposals.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  pendingProposals.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No pending proposals',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final spacing = ResponsiveHelper.getSpacing(
                              context,
                            );
                            final availableWidth = constraints.maxWidth;
                            final columnCount =
                                ResponsiveHelper.getColumnCountForWidth(
                                  availableWidth,
                                  minTileWidth: 420,
                                  maxColumns: 3,
                                );
                            final itemWidth =
                                (availableWidth -
                                    (spacing * (columnCount - 1))) /
                                columnCount;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: pendingProposals.map((proposal) {
                                return SizedBox(
                                  width: itemWidth,
                                  child: _buildProposalCard(context, proposal),
                                );
                              }).toList(),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 💰 PHASE 4: PENDING PAYOUT REQUESTS SECTION
          if (onReleaseWorkshopPayout != null) ...[
            _buildPayoutRequestsSection(context),
            const SizedBox(height: 16),
          ],

          // Workshops List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Workshops',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  workshops.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No workshops found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final spacing = ResponsiveHelper.getSpacing(
                              context,
                            );
                            final availableWidth = constraints.maxWidth;
                            final columnCount =
                                ResponsiveHelper.getColumnCountForWidth(
                                  availableWidth,
                                  minTileWidth: 420,
                                  maxColumns: 3,
                                );
                            final itemWidth =
                                (availableWidth -
                                    (spacing * (columnCount - 1))) /
                                columnCount;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: workshops.map((workshop) {
                                return SizedBox(
                                  width: itemWidth,
                                  child: _buildFinancialLedgerCard(
                                    context,
                                    workshop,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Workshop Registrations Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workshop Registrations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  workshopRegistrations.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No registrations found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final spacing = ResponsiveHelper.getSpacing(
                              context,
                            );
                            final availableWidth = constraints.maxWidth;
                            final columnCount =
                                ResponsiveHelper.getColumnCountForWidth(
                                  availableWidth,
                                  minTileWidth: 380,
                                  maxColumns: 3,
                                );
                            final itemWidth =
                                (availableWidth -
                                    (spacing * (columnCount - 1))) /
                                columnCount;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: workshopRegistrations.map((
                                registration,
                              ) {
                                return SizedBox(
                                  width: itemWidth,
                                  child: _buildRegistrationCard(registration),
                                );
                              }).toList(),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> registration) {
    final status = registration['status'] ?? 'pending';
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration['name'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Email: ${registration['email'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Phone: ${registration['phoneNumber'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (registration['workshopTitle'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Workshop: ${registration['workshopTitle']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onConfirmRegistration(registration),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onRejectRegistration(registration),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onDeleteRegistration(registration),
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProposalCard(
    BuildContext context,
    Map<String, dynamic> proposal,
  ) {
    return _ProposalCardExpansion(
      proposal: proposal,
      onApproveProposal: onApproveProposal,
    );
  }

  // 🏦 PHASE 5: FINANCIAL LEDGER CARD
  Widget _buildFinancialLedgerCard(
    BuildContext context,
    Map<String, dynamic> workshop,
  ) {
    final workshopId = workshop['id'] ?? '';

    return FutureBuilder<Map<String, dynamic>>(
      future: _workshopService.getWorkshopFinancialSnapshot(workshopId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return WorkshopCardWidget(
            workshop: workshop,
            isSubmittingWorkshop: isSubmittingWorkshop,
            isDeletingWorkshop: isDeletingWorkshop,
            onEdit: () => onEditWorkshop(workshop),
            onDelete: () => onDeleteWorkshop(workshop),
          );
        }

        return WorkshopCardWidget(
          workshop: workshop,
          isSubmittingWorkshop: isSubmittingWorkshop,
          isDeletingWorkshop: isDeletingWorkshop,
          onEdit: () => onEditWorkshop(workshop),
          onDelete: () => onDeleteWorkshop(workshop),
        );
      },
    );
  }

  // 💰 PHASE 5: PAYOUT REQUESTS SECTION
  Widget _buildPayoutRequestsSection(BuildContext context) {
    final payoutRequests = workshops
        .where(
          (w) =>
              w['isPayoutRequested'] == true &&
              w['payoutStatus'] == 'requested',
        )
        .toList();

    if (payoutRequests.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pending Payout Requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payoutRequests.length.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = ResponsiveHelper.getSpacing(context);
                final availableWidth = constraints.maxWidth;
                final columnCount = ResponsiveHelper.getColumnCountForWidth(
                  availableWidth,
                  minTileWidth: 420,
                  maxColumns: 3,
                );
                final itemWidth =
                    (availableWidth - (spacing * (columnCount - 1))) /
                    columnCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: payoutRequests.map((workshop) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildPayoutRequestCard(workshop),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutRequestCard(Map<String, dynamic> workshop) {
    final workshopId = workshop['id'] ?? '';
    final workshopTitle = workshop['title'] ?? 'Untitled';

    return FutureBuilder<Map<String, dynamic>>(
      future: _workshopService.getWorkshopFinancialSnapshot(workshopId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final financials = snapshot.data!;
        final doctorPayout = (financials['doctorPayout'] ?? 0.0).toDouble();
        final totalRevenue = (financials['totalRevenue'] ?? 0.0).toDouble();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workshopTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PAYOUT REQUESTED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doctor Payout',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'PKR ${doctorPayout.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Revenue',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'PKR ${totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (onReleaseWorkshopPayout != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        onReleaseWorkshopPayout!(workshop, workshopId),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Release Payout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// 📋 Expandable Workshop Proposal Card with Full Details
class _ProposalCardExpansion extends StatefulWidget {
  final Map<String, dynamic> proposal;
  final Function(Map<String, dynamic>, double) onApproveProposal;

  const _ProposalCardExpansion({
    required this.proposal,
    required this.onApproveProposal,
  });

  @override
  State<_ProposalCardExpansion> createState() => _ProposalCardExpansionState();
}

class _ProposalCardExpansionState extends State<_ProposalCardExpansion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and expand button
          Row(
            children: [
              Expanded(
                child: Text(
                  proposal['title'] ?? 'Untitled Workshop',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.orange.shade700,
                ),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                tooltip: _isExpanded ? 'Show less' : 'Show more details',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Basic preview (always visible)
          Text(
            proposal['description'] ?? 'No description',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: _isExpanded ? null : 2,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Quick stats (always visible)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      proposal['schedule'] ?? 'No schedule',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${proposal['maxParticipants'] ?? 0} seats',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_money, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'PKR ${proposal['price']?.toStringAsFixed(0) ?? '0'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          // Expanded details section
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Full details grid
            _buildDetailRow('Provider', proposal['provider'] ?? 'N/A'),
            _buildDetailRow(
              'Certification Type',
              proposal['certificationType'] ?? 'N/A',
            ),
            _buildDetailRow('Duration', '${proposal['duration'] ?? 0} hours'),
            _buildDetailRow('Location', proposal['location'] ?? 'N/A'),

            if (proposal['instructor'] != null &&
                proposal['instructor'].toString().isNotEmpty)
              _buildDetailRow('Instructor', proposal['instructor']),

            if (proposal['prerequisites'] != null &&
                proposal['prerequisites'].toString().isNotEmpty)
              _buildDetailRow(
                'Prerequisites',
                proposal['prerequisites'],
                isLong: true,
              ),

            if (proposal['materials'] != null &&
                proposal['materials'].toString().isNotEmpty)
              _buildDetailRow(
                'Materials Included',
                proposal['materials'],
                isLong: true,
              ),

            if (proposal['startDate'] != null) ...[
              _buildDetailRow(
                'Start Date',
                _formatTimestamp(proposal['startDate']),
              ),
              if (proposal['startTime'] != null)
                _buildDetailRow('Start Time', proposal['startTime']),
            ],

            if (proposal['endDate'] != null) ...[
              _buildDetailRow(
                'End Date',
                _formatTimestamp(proposal['endDate']),
              ),
              if (proposal['endTime'] != null)
                _buildDetailRow('End Time', proposal['endTime']),
            ],

            if (proposal['bannerImage'] != null &&
                proposal['bannerImage'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Workshop Banner:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        proposal['bannerImage'],
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Loading image...',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Banner image error: $error');
                          debugPrint(
                            'Banner image URL: ${proposal['bannerImage']}',
                          );
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.orange.shade400,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  onPressed: () async {
                                    final url = proposal['bannerImage'];
                                    if (url != null) {
                                      final uri = Uri.parse(url.toString());
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.open_in_browser,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Open in browser',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (proposal['syllabusPdf'] != null &&
                proposal['syllabusPdf'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Syllabus PDF attached',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final url = proposal['syllabusPdf'];
                        if (url != null && url.toString().isNotEmpty) {
                          _showPdfViewer(
                            context,
                            url.toString(),
                            'Workshop Syllabus',
                          );
                        }
                      },
                      child: const Text('View', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Submitted: ${_formatTimestamp(proposal['createdAt'])}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],

          const SizedBox(height: 12),

          // Action button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showApprovalDialog(context, proposal),
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Approve & Set Fee'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: isLong
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '$label:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'N/A';
      }

      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  void _showApprovalDialog(
    BuildContext context,
    Map<String, dynamic> proposal,
  ) {
    final feeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Workshop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workshop: ${proposal['title']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Set Platform Fee (PKR)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter amount (e.g., 5000)',
                prefixText: 'PKR ',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Doctor will have 2 hours to pay this fee after approval.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final fee = double.tryParse(feeController.text);
              if (fee != null && fee > 0) {
                Navigator.pop(context);
                widget.onApproveProposal(proposal, fee);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid fee amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showPdfViewer(BuildContext context, String pdfUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006876),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // PDF Viewer - Using webview or iframe
              Expanded(
                child: Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'PDF Viewer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Loading PDF...',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(pdfUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open in Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006876),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
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
}

// 🕵️ PHASE 5: PARTICIPANT AUDIT DIALOG
class _ParticipantAuditDialog extends StatefulWidget {
  final String workshopTitle;
  final List<dynamic> participants;
  final VoidCallback onExportCsv;

  const _ParticipantAuditDialog({
    required this.workshopTitle,
    required this.participants,
    required this.onExportCsv,
  });

  @override
  State<_ParticipantAuditDialog> createState() =>
      _ParticipantAuditDialogState();
}

class _ParticipantAuditDialogState extends State<_ParticipantAuditDialog> {
  bool _showFullDetails = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF006876),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Participant Audit Trail',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.workshopTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Privacy Toggle
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _showFullDetails
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showFullDetails ? 'Full Details Mode' : 'Privacy Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _showFullDetails = !_showFullDetails);
                        },
                        icon: Icon(
                          _showFullDetails ? Icons.lock_open : Icons.lock,
                          size: 14,
                        ),
                        label: Text(
                          _showFullDetails ? 'Hide' : 'Show Full',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: widget.onExportCsv,
                        icon: const Icon(Icons.download, size: 18),
                        tooltip: 'Export to CSV',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Participant List
            Expanded(
              child: widget.participants.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No paid participants yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.participants.length,
                      itemBuilder: (context, index) {
                        final participant = widget.participants[index];
                        return _buildParticipantCard(participant, index + 1);
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${widget.participants.length} participants',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant, int number) {
    final userName = participant['userName'] ?? 'Unknown';
    final cnic = participant['cnic'] ?? '';
    final phoneNumber = participant['phoneNumber'] ?? '';
    final amountPaid = (participant['amountPaid'] ?? 0.0).toDouble();
    final paidAt = participant['paidAt'];

    // Format timestamp with seconds
    String formattedTime = 'N/A';
    if (paidAt is Timestamp) {
      formattedTime = DateFormat(
        'dd MMM yyyy, hh:mm:ss a',
      ).format(paidAt.toDate());
    }

    // Privacy masking
    String displayCnic = cnic;
    String displayPhone = phoneNumber;
    if (!_showFullDetails && cnic.isNotEmpty) {
      // Mask CNIC: XXXXX-XXXXXX5-X
      final cnicParts = cnic.split('-');
      if (cnicParts.length == 3) {
        final lastPart = cnicParts[2];
        displayCnic =
            'XXXXX-XXXXX${cnicParts[1].substring(cnicParts[1].length - 1)}-${lastPart.substring(lastPart.length - 1)}';
      } else {
        displayCnic = 'XXXXX${cnic.substring(cnic.length - 4)}';
      }
    }
    if (!_showFullDetails && phoneNumber.isNotEmpty) {
      // Mask Phone: XXXXXX1234
      displayPhone = 'XXXXXX${phoneNumber.substring(phoneNumber.length - 4)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006876),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayCnic,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayPhone,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'PAID',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'PKR ${amountPaid.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Payment timestamp
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Payment Time: ',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Expanded(
                    child: Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
