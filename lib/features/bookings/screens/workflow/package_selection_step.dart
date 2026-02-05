import 'package:flutter/material.dart';
import 'package:sehatmakaan/core/constants/constants.dart';
import 'package:sehatmakaan/core/constants/types.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';

class PackageSelectionStep extends StatefulWidget {
  final SuiteType? selectedSuite;
  final PackageType? selectedPackage;
  final Function(PackageType) onPackageSelected;

  const PackageSelectionStep({
    super.key,
    required this.selectedSuite,
    required this.selectedPackage,
    required this.onPackageSelected,
  });

  @override
  State<PackageSelectionStep> createState() => _PackageSelectionStepState();
}

class _PackageSelectionStepState extends State<PackageSelectionStep> {
  @override
  Widget build(BuildContext context) {
    if (widget.selectedSuite == null) {
      return Center(
        child: Text(
          'Please select a suite first',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: Colors.grey,
          ),
        ),
      );
    }

    // ✅ Use static packages instead of StreamBuilder to prevent constant rebuilds
    final packages = AppConstants.packages[widget.selectedSuite!.value] ?? [];
    return _buildPackageList(packages);
  }

  Widget _buildPackageList(List<Package> packages) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Choose Your Package',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006876),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context) * 0.3,
          ),
          Text(
            'Select a monthly package that fits your needs',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          ...packages.map((pkg) => _buildPackageCard(pkg)),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package pkg) {
    final isSelected = widget.selectedPackage == pkg.type;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF006876) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => widget.onPackageSelected(pkg.type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pkg.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006876),
                    ),
                  ),
                  if (pkg.popular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'PKR ${pkg.price.toStringAsFixed(0)}/month',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${pkg.hours} hours included',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF006876).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              ...pkg.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF90D26D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
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
