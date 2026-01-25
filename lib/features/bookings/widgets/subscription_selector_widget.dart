import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/core/constants/types.dart';

class SubscriptionSelectorWidget extends StatelessWidget {
  final List<Map<String, dynamic>> subscriptions;
  final String? selectedSubscriptionId;
  final ValueChanged<String?> onChanged;

  const SubscriptionSelectorWidget({
    super.key,
    required this.subscriptions,
    required this.selectedSubscriptionId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (subscriptions.length <= 1) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade700, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'You have multiple subscriptions. Please select one:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select Subscription *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006876),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF006876), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSubscriptionId,
              isExpanded: true,
              hint: const Text(
                '👆 Tap here to choose subscription',
                style: TextStyle(color: Colors.grey),
              ),
              items: subscriptions.map((sub) {
                final subId = sub['id'] as String;
                final packageType = sub['packageType'] as String? ?? 'package';
                final suiteType = sub['suiteType'] as String? ?? '';
                final remainingHours = sub['remainingHours'] as int? ?? 0;
                final remainingMins = sub['remainingMinutes'] as int? ?? 0;
                final addons = sub['selectedAddons'] as List? ?? [];

                // Convert packageType to display name
                String packageDisplayName;
                try {
                  packageDisplayName = PackageType.fromString(
                    packageType,
                  ).displayName;
                } catch (e) {
                  packageDisplayName = packageType.toUpperCase();
                }

                // Convert suiteType to display name
                String suiteDisplayName = '';
                switch (suiteType.toLowerCase()) {
                  case 'dental':
                    suiteDisplayName = 'Dental Suite';
                    break;
                  case 'medical':
                    suiteDisplayName = 'Medical Suite';
                    break;
                  case 'aesthetic':
                    suiteDisplayName = 'Aesthetic Suite';
                    break;
                  default:
                    suiteDisplayName = suiteType;
                }

                // Combine suite and package name
                final displayName = suiteDisplayName.isNotEmpty
                    ? '$suiteDisplayName - $packageDisplayName'
                    : packageDisplayName;

                return DropdownMenuItem<String>(
                  value: subId,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$remainingHours hrs${remainingMins > 0 ? ' $remainingMins mins' : ''} • ${addons.isNotEmpty ? '${addons.length} addon${addons.length > 1 ? 's' : ''}' : 'No addons'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
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
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
