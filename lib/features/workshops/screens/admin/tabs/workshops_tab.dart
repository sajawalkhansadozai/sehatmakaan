import 'package:flutter/material.dart';
import '../widgets/workshop_card_widget.dart';
import '../../../../../../screens/admin/utils/admin_styles.dart';

class WorkshopsTab extends StatelessWidget {
  final List<Map<String, dynamic>> workshops;
  final List<Map<String, dynamic>> workshopRegistrations;
  final bool isSubmittingWorkshop;
  final bool isDeletingWorkshop;
  final VoidCallback onCreateWorkshop;
  final Function(Map<String, dynamic>) onEditWorkshop;
  final Function(Map<String, dynamic>) onDeleteWorkshop;
  final Function(Map<String, dynamic>) onConfirmRegistration;
  final Function(Map<String, dynamic>) onRejectRegistration;
  final Function(Map<String, dynamic>) onDeleteRegistration;

  const WorkshopsTab({
    super.key,
    required this.workshops,
    required this.workshopRegistrations,
    required this.isSubmittingWorkshop,
    required this.isDeletingWorkshop,
    required this.onCreateWorkshop,
    required this.onEditWorkshop,
    required this.onDeleteWorkshop,
    required this.onConfirmRegistration,
    required this.onRejectRegistration,
    required this.onDeleteRegistration,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Workshop Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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
          const SizedBox(height: 16),

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
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: workshops.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final workshop = workshops[index];
                            return WorkshopCardWidget(
                              workshop: workshop,
                              isSubmittingWorkshop: isSubmittingWorkshop,
                              isDeletingWorkshop: isDeletingWorkshop,
                              onEdit: () => onEditWorkshop(workshop),
                              onDelete: () => onDeleteWorkshop(workshop),
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
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: workshopRegistrations.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final registration = workshopRegistrations[index];
                            return _buildRegistrationCard(registration);
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
}
