import 'package:flutter/material.dart';
import '../../../../../../screens/admin/utils/admin_formatters.dart';
import '../../../../../../screens/admin/utils/admin_styles.dart';

class WorkshopCardWidget extends StatelessWidget {
  final Map<String, dynamic> workshop;
  final bool isSubmittingWorkshop;
  final bool isDeletingWorkshop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WorkshopCardWidget({
    super.key,
    required this.workshop,
    required this.isSubmittingWorkshop,
    required this.isDeletingWorkshop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = workshop['isActive'] as bool? ?? true;
    final currentParticipants = workshop['currentParticipants'] as int? ?? 0;
    final maxParticipants = workshop['maxParticipants'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workshop['title'] as String? ?? 'Workshop',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AdminStyles.successColor
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Provider', workshop['provider']),
                              _buildDetailRow(
                                'Certification',
                                workshop['certificationType'],
                              ),
                              _buildDetailRow('Location', workshop['location']),
                              _buildDetailRow(
                                'Duration',
                                '${workshop['duration']} hours',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Price',
                                'PKR ${workshop['price']}',
                              ),
                              _buildDetailRow(
                                'Participants',
                                '$currentParticipants/$maxParticipants',
                              ),
                              _buildDetailRow('Schedule', workshop['schedule']),
                              if (workshop['instructor'] != null)
                                _buildDetailRow(
                                  'Instructor',
                                  workshop['instructor'],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (workshop['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              workshop['description'] as String,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
          if (workshop['prerequisites'] != null ||
              workshop['materials'] != null) ...[
            const Divider(height: 24),
            if (workshop['prerequisites'] != null)
              _buildDetailRow('Prerequisites', workshop['prerequisites']),
            if (workshop['materials'] != null)
              _buildDetailRow('Materials', workshop['materials']),
          ],
          if (workshop['createdAt'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Created: ${AdminFormatters.formatDate(workshop['createdAt'])}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSubmittingWorkshop ? null : onEdit,
                  icon: isSubmittingWorkshop
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AdminStyles.primaryColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.edit, size: 16),
                  label: Text(isSubmittingWorkshop ? 'Loading...' : 'Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminStyles.primaryColor,
                    side: const BorderSide(color: AdminStyles.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isDeletingWorkshop ? null : onDelete,
                  icon: isDeletingWorkshop
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                          ),
                        )
                      : const Icon(Icons.delete_outline, size: 16),
                  label: Text(isDeletingWorkshop ? 'Deleting...' : 'Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value?.toString() ?? 'N/A'),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
