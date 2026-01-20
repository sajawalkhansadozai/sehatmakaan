import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final String Function(String) capitalizeFirst;
  final String Function(DateTime) formatDate;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.capitalizeFirst,
    required this.formatDate,
  });

  Color _getExpiryColor(int daysRemaining) {
    if (daysRemaining > 7) {
      return const Color(0xFF90D26D); // Green
    } else if (daysRemaining >= 3) {
      return Colors.orange; // Orange
    } else {
      return const Color(0xFFFF6B35); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoursIncluded = subscription['hoursIncluded'] as int? ?? 0;
    final remainingHours = subscription['remainingHours'] as int? ?? 0;
    final remainingMinutes = subscription['remainingMinutes'] as int? ?? 0;
    final hoursUsed = hoursIncluded - remainingHours;
    final progress = hoursIncluded > 0 ? hoursUsed / hoursIncluded : 0.0;

    // Format remaining time display
    final remainingTimeDisplay = remainingMinutes > 0
        ? '$remainingHours:${remainingMinutes.toString().padLeft(2, '0')}'
        : '$remainingHours';

    // Calculate days remaining until expiry
    final endDate =
        (subscription['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    final expiryColor = _getExpiryColor(daysRemaining);
    final isExpiringSoon = daysRemaining <= 7;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${capitalizeFirst(subscription['suiteType'] as String? ?? '')} Suite',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF90D26D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    capitalizeFirst(
                      subscription['packageType'] as String? ?? 'Active',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hours Remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF006876).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remainingTimeDisplay / $hoursIncluded',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExpiringSoon)
                          Icon(
                            Icons.warning_rounded,
                            size: 16,
                            color: expiryColor,
                          ),
                        if (isExpiringSoon) const SizedBox(width: 4),
                        Text(
                          'Valid Until',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF006876,
                            ).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(endDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: expiryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$daysRemaining days left',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: expiryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE6F7F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF90D26D),
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
