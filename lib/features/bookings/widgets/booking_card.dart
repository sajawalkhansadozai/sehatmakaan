import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String Function(String) capitalizeFirst;
  final String Function(DateTime) formatDate;
  final Color Function(String) getStatusColor;

  const BookingCard({
    super.key,
    required this.booking,
    required this.capitalizeFirst,
    required this.formatDate,
    required this.getStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final specialty = booking['specialty'] as String?;
    final durationHours = booking['durationHours'] as int?;
    final durationMins = booking['durationMins'] as int?;
    final totalAmount = booking['totalAmount'] as num?;
    final hasPriority = booking['hasPriority'] as bool? ?? false;

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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006876).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF006876),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            capitalizeFirst(
                              booking['suiteType'] as String? ?? '',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF006876),
                            ),
                          ),
                          if (hasPriority) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Priority',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDate((booking['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now())} at ${booking['timeSlot'] as String? ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF006876).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(booking['status'] as String? ?? ''),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    capitalizeFirst(booking['status'] as String? ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (specialty != null) ...[
                  Expanded(
                    child: _buildInfoChip(
                      Icons.medical_services,
                      'Specialty',
                      _formatSpecialty(specialty),
                    ),
                  ),
                ],
                if (durationHours != null || durationMins != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.access_time,
                      'Duration',
                      _formatDuration(durationHours, durationMins),
                    ),
                  ),
                ],
              ],
            ),
            if (totalAmount != null) ...[
              const SizedBox(height: 8),
              _buildInfoChip(
                Icons.payments,
                'Total',
                'PKR ${totalAmount.toStringAsFixed(0)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF006876).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF006876)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF006876).withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF006876),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSpecialty(String specialty) {
    return specialty
        .split('-')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatDuration(int? hours, int? mins) {
    if (hours == null && mins == null) return 'N/A';
    if (hours != null && hours > 0 && (mins == null || mins == 0)) {
      return '${hours}h';
    }
    if (mins != null && mins > 0 && (hours == null || hours == 0)) {
      return '${mins}m';
    }
    return '${hours ?? 0}h ${mins ?? 0}m';
  }
}
