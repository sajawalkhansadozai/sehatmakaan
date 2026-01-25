import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';
import 'package:sehat_makaan_flutter/core/constants/types.dart';

class PackagesPage extends StatefulWidget {
  final Map<String, dynamic>? userSession;
  final SuiteType? selectedSuite;

  const PackagesPage({super.key, this.userSession, this.selectedSuite});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isCreating = false;

  Future<void> _handlePackageSelect(
    PackageType packageType,
    double price,
    int hours,
  ) async {
    setState(() => _isCreating = true);

    try {
      final userId = widget.userSession?['id']?.toString();
      if (userId == null) {
        throw Exception('User session not found');
      }

      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));

      final subscriptionData = {
        'userId': userId,
        'suiteType': widget.selectedSuite?.value ?? 'dental',
        'packageType': packageType.value,
        'type': 'monthly',
        'monthlyPrice': price,
        'price': price,
        'hoursIncluded': hours,
        'hoursUsed': 0,
        'remainingHours': hours,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'paymentMethod': 'direct',
        'paymentStatus': 'paid',
        'paymentId': 'direct_${now.millisecondsSinceEpoch}',
        'status': 'active',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('subscriptions').add(subscriptionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package Activated Successfully!'),
            backgroundColor: Color(0xFF90D26D),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/dashboard',
            arguments: widget.userSession,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  List<Package> _getPackages() {
    final suiteKey = widget.selectedSuite?.value ?? 'dental';
    return AppConstants.packages[suiteKey] ?? AppConstants.packages['dental']!;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📦 Packages Page - userSession: ${widget.userSession}');
    debugPrint('📦 Packages Page - fullName: ${widget.userSession?['fullName']}');
    final packages = _getPackages();

    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      body: Column(
        children: [
          _buildTopBanner(),
          Expanded(
            child: ResponsiveContainer(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  children: [
                    Text(
                      'Monthly Subscription Packages',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006876),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.7),
                    Text(
                      'Choose a monthly package for better value and priority access',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                        color: const Color(0xFF006876).withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 1.5),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 900) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: packages.map((pkg) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: _buildPackageCard(pkg),
                                ),
                              );
                            }).toList(),
                          );
                        } else {
                          return Column(
                            children: packages.map((pkg) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildPackageCard(pkg),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/booking-workflow',
                          arguments: widget.userSession,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006876),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        side: const BorderSide(
                          color: Color(0xFF006876),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Or Book Individual Hours',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildTopBanner() {
    final userName =
        widget.userSession?['fullName']?.toString().split(' ').first ??
        'Doctor';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006876), Color(0xFF004D57)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          'Welcome, $userName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select packages, hourly bookings, or add-ons',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/dashboard',
                            arguments: widget.userSession,
                          );
                        },
                        icon: const Icon(Icons.dashboard, color: Colors.white),
                        tooltip: 'Dashboard',
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Implement logout
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: package.popular
            ? Border.all(color: const Color(0xFFFF6B35), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                if (package.popular) const SizedBox(height: 12),
                Text(
                  package.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'PKR ${package.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'per month',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ...package.features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Color(0xFF90D26D),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF006876),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating
                        ? null
                        : () => _handlePackageSelect(
                            package.type,
                            package.price,
                            package.hours,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Select ${package.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (package.popular)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Most Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
