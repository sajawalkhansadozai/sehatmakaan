import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sehatmakaan/features/admin/models/pricing_config_model.dart';
import 'package:sehatmakaan/features/admin/services/pricing_service.dart';
import 'package:sehatmakaan/features/admin/utils/responsive_helper.dart';
import 'package:sehatmakaan/core/utils/dynamic_pricing.dart';

class PricingManagementTab extends StatefulWidget {
  final String adminId;

  const PricingManagementTab({super.key, required this.adminId});

  @override
  State<PricingManagementTab> createState() => _PricingManagementTabState();
}

class _PricingManagementTabState extends State<PricingManagementTab> {
  final PricingService _pricingService = PricingService();

  bool _isLoading = true;
  bool _isSaving = false;
  PricingConfig? _currentConfig;

  // Text controllers for all pricing fields
  // Suite Base Rates
  final TextEditingController _dentalBaseRateController =
      TextEditingController();
  final TextEditingController _dentalSpecialistRateController =
      TextEditingController();
  final TextEditingController _medicalBaseRateController =
      TextEditingController();
  final TextEditingController _medicalSpecialistRateController =
      TextEditingController();
  final TextEditingController _aestheticBaseRateController =
      TextEditingController();
  final TextEditingController _aestheticSpecialistRateController =
      TextEditingController();

  // Monthly Packages - Dental
  final TextEditingController _dentalStarterController =
      TextEditingController();
  final TextEditingController _dentalAdvancedController =
      TextEditingController();
  final TextEditingController _dentalProfessionalController =
      TextEditingController();

  // Monthly Packages - Medical
  final TextEditingController _medicalStarterController =
      TextEditingController();
  final TextEditingController _medicalAdvancedController =
      TextEditingController();
  final TextEditingController _medicalProfessionalController =
      TextEditingController();

  // Monthly Packages - Aesthetic
  final TextEditingController _aestheticStarterController =
      TextEditingController();
  final TextEditingController _aestheticAdvancedController =
      TextEditingController();
  final TextEditingController _aestheticProfessionalController =
      TextEditingController();

  // Monthly Add-ons
  final TextEditingController _extra10HoursController = TextEditingController();
  final TextEditingController _dedicatedLockerController =
      TextEditingController();
  final TextEditingController _clinicalAssistantController =
      TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();

  // Hourly Add-ons
  final TextEditingController _dentalAssistantController =
      TextEditingController();
  final TextEditingController _medicalNurseController = TextEditingController();
  final TextEditingController _intraoralXrayController =
      TextEditingController();
  final TextEditingController _priorityBookingController =
      TextEditingController();
  final TextEditingController _extendedHoursController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    setState(() => _isLoading = true);

    try {
      final config = await _pricingService.getCurrentPricing();
      setState(() {
        _currentConfig = config;
        _populateControllers(config);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pricing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateControllers(PricingConfig config) {
    // Suite Base Rates
    _dentalBaseRateController.text = config.dentalBaseRate.toStringAsFixed(0);
    _dentalSpecialistRateController.text = config.dentalSpecialistRate
        .toStringAsFixed(0);
    _medicalBaseRateController.text = config.medicalBaseRate.toStringAsFixed(0);
    _medicalSpecialistRateController.text = config.medicalSpecialistRate
        .toStringAsFixed(0);
    _aestheticBaseRateController.text = config.aestheticBaseRate
        .toStringAsFixed(0);
    _aestheticSpecialistRateController.text = config.aestheticSpecialistRate
        .toStringAsFixed(0);

    // Monthly Packages - Dental
    _dentalStarterController.text = config.dentalStarterPrice.toStringAsFixed(
      0,
    );
    _dentalAdvancedController.text = config.dentalAdvancedPrice.toStringAsFixed(
      0,
    );
    _dentalProfessionalController.text = config.dentalProfessionalPrice
        .toStringAsFixed(0);

    // Monthly Packages - Medical
    _medicalStarterController.text = config.medicalStarterPrice.toStringAsFixed(
      0,
    );
    _medicalAdvancedController.text = config.medicalAdvancedPrice
        .toStringAsFixed(0);
    _medicalProfessionalController.text = config.medicalProfessionalPrice
        .toStringAsFixed(0);

    // Monthly Packages - Aesthetic
    _aestheticStarterController.text = config.aestheticStarterPrice
        .toStringAsFixed(0);
    _aestheticAdvancedController.text = config.aestheticAdvancedPrice
        .toStringAsFixed(0);
    _aestheticProfessionalController.text = config.aestheticProfessionalPrice
        .toStringAsFixed(0);

    // Monthly Add-ons
    _extra10HoursController.text = config.extra10HoursPrice.toStringAsFixed(0);
    _dedicatedLockerController.text = config.dedicatedLockerPrice
        .toStringAsFixed(0);
    _clinicalAssistantController.text = config.clinicalAssistantPrice
        .toStringAsFixed(0);
    _socialMediaController.text = config.socialMediaHighlightPrice
        .toStringAsFixed(0);

    // Hourly Add-ons
    _dentalAssistantController.text = config.dentalAssistantPrice
        .toStringAsFixed(0);
    _medicalNurseController.text = config.medicalNursePrice.toStringAsFixed(0);
    _intraoralXrayController.text = config.intraoralXrayPrice.toStringAsFixed(
      0,
    );
    _priorityBookingController.text = config.priorityBookingPrice
        .toStringAsFixed(0);
    _extendedHoursController.text = config.extendedHoursPrice.toStringAsFixed(
      0,
    );
  }

  Future<void> _savePricing() async {
    setState(() => _isSaving = true);

    try {
      final updatedConfig = PricingConfig(
        id: _currentConfig?.id,
        dentalBaseRate: double.parse(_dentalBaseRateController.text),
        dentalSpecialistRate: double.parse(
          _dentalSpecialistRateController.text,
        ),
        medicalBaseRate: double.parse(_medicalBaseRateController.text),
        medicalSpecialistRate: double.parse(
          _medicalSpecialistRateController.text,
        ),
        aestheticBaseRate: double.parse(_aestheticBaseRateController.text),
        aestheticSpecialistRate: double.parse(
          _aestheticSpecialistRateController.text,
        ),
        dentalStarterPrice: double.parse(_dentalStarterController.text),
        dentalAdvancedPrice: double.parse(_dentalAdvancedController.text),
        dentalProfessionalPrice: double.parse(
          _dentalProfessionalController.text,
        ),
        medicalStarterPrice: double.parse(_medicalStarterController.text),
        medicalAdvancedPrice: double.parse(_medicalAdvancedController.text),
        medicalProfessionalPrice: double.parse(
          _medicalProfessionalController.text,
        ),
        aestheticStarterPrice: double.parse(_aestheticStarterController.text),
        aestheticAdvancedPrice: double.parse(_aestheticAdvancedController.text),
        aestheticProfessionalPrice: double.parse(
          _aestheticProfessionalController.text,
        ),
        extra10HoursPrice: double.parse(_extra10HoursController.text),
        dedicatedLockerPrice: double.parse(_dedicatedLockerController.text),
        clinicalAssistantPrice: double.parse(_clinicalAssistantController.text),
        socialMediaHighlightPrice: double.parse(_socialMediaController.text),
        dentalAssistantPrice: double.parse(_dentalAssistantController.text),
        medicalNursePrice: double.parse(_medicalNurseController.text),
        intraoralXrayPrice: double.parse(_intraoralXrayController.text),
        priorityBookingPrice: double.parse(_priorityBookingController.text),
        extendedHoursPrice: double.parse(_extendedHoursController.text),
      );

      final result = await _pricingService.updatePricing(
        config: updatedConfig,
        adminId: widget.adminId,
      );

      // Clear cache to force all users to fetch new prices immediately
      DynamicPricing.clearCache();

      setState(() => _isSaving = false);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Pricing updated successfully! All users will see changes instantly.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          _loadPricing(); // Reload to get updated data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving pricing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _dentalBaseRateController.dispose();
    _dentalSpecialistRateController.dispose();
    _medicalBaseRateController.dispose();
    _medicalSpecialistRateController.dispose();
    _aestheticBaseRateController.dispose();
    _aestheticSpecialistRateController.dispose();
    _dentalStarterController.dispose();
    _dentalAdvancedController.dispose();
    _dentalProfessionalController.dispose();
    _medicalStarterController.dispose();
    _medicalAdvancedController.dispose();
    _medicalProfessionalController.dispose();
    _aestheticStarterController.dispose();
    _aestheticAdvancedController.dispose();
    _aestheticProfessionalController.dispose();
    _extra10HoursController.dispose();
    _dedicatedLockerController.dispose();
    _clinicalAssistantController.dispose();
    _socialMediaController.dispose();
    _dentalAssistantController.dispose();
    _medicalNurseController.dispose();
    _intraoralXrayController.dispose();
    _priorityBookingController.dispose();
    _extendedHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006876)),
        ),
      );
    }

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 Pricing Management',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006876),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all system prices from one place',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentConfig?.updatedAt != null)
                Flexible(
                  child: Text(
                    'Last updated: ${_formatDate(_currentConfig!.updatedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suite Base Rates Section
                  _buildSection(
                    title: '🏥 Suite Hourly Base Rates (PKR/hour)',
                    children: [
                      _buildPriceRow(
                        'Dental Suite - General',
                        _dentalBaseRateController,
                        Icons.medical_services,
                        Colors.blue,
                      ),
                      _buildPriceRow(
                        'Dental Suite - Specialist',
                        _dentalSpecialistRateController,
                        Icons.medical_services,
                        Colors.blue[700]!,
                      ),
                      _buildPriceRow(
                        'Medical Suite - General',
                        _medicalBaseRateController,
                        Icons.local_hospital,
                        Colors.red,
                      ),
                      _buildPriceRow(
                        'Medical Suite - Specialist',
                        _medicalSpecialistRateController,
                        Icons.local_hospital,
                        Colors.red[700]!,
                      ),
                      _buildPriceRow(
                        'Aesthetic Suite - General',
                        _aestheticBaseRateController,
                        Icons.spa,
                        Colors.purple,
                      ),
                      _buildPriceRow(
                        'Aesthetic Suite - Specialist',
                        _aestheticSpecialistRateController,
                        Icons.spa,
                        Colors.purple[700]!,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Monthly Packages Section
                  _buildSection(
                    title: '📦 Monthly Package Prices (PKR/month)',
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          '🦷 Dental Packages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      _buildPriceRow(
                        'Starter Package (10 hours)',
                        _dentalStarterController,
                        Icons.star_border,
                        Colors.blue[300]!,
                      ),
                      _buildPriceRow(
                        'Advanced Package (20 hours)',
                        _dentalAdvancedController,
                        Icons.star_half,
                        Colors.blue[500]!,
                      ),
                      _buildPriceRow(
                        'Professional Package (40 hours)',
                        _dentalProfessionalController,
                        Icons.star,
                        Colors.blue[700]!,
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          '🩺 Medical Packages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      _buildPriceRow(
                        'Starter Package (10 hours)',
                        _medicalStarterController,
                        Icons.star_border,
                        Colors.red[300]!,
                      ),
                      _buildPriceRow(
                        'Advanced Package (20 hours)',
                        _medicalAdvancedController,
                        Icons.star_half,
                        Colors.red[500]!,
                      ),
                      _buildPriceRow(
                        'Professional Package (40 hours)',
                        _medicalProfessionalController,
                        Icons.star,
                        Colors.red[700]!,
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          '✨ Aesthetic Packages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      _buildPriceRow(
                        'Starter Package (10 hours)',
                        _aestheticStarterController,
                        Icons.star_border,
                        Colors.purple[300]!,
                      ),
                      _buildPriceRow(
                        'Advanced Package (20 hours)',
                        _aestheticAdvancedController,
                        Icons.star_half,
                        Colors.purple[500]!,
                      ),
                      _buildPriceRow(
                        'Professional Package (40 hours)',
                        _aestheticProfessionalController,
                        Icons.star,
                        Colors.purple[700]!,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Monthly Add-ons Section
                  _buildSection(
                    title: '➕ Monthly Package Add-ons (PKR)',
                    children: [
                      _buildPriceRow(
                        'Extra 10 Hour Block',
                        _extra10HoursController,
                        Icons.access_time,
                        Colors.orange,
                      ),
                      _buildPriceRow(
                        'Dedicated Locker',
                        _dedicatedLockerController,
                        Icons.lock,
                        Colors.brown,
                      ),
                      _buildPriceRow(
                        'Clinical Assistant',
                        _clinicalAssistantController,
                        Icons.person,
                        Colors.teal,
                      ),
                      _buildPriceRow(
                        'Social Media Highlight',
                        _socialMediaController,
                        Icons.campaign,
                        Colors.pink,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Hourly Add-ons Section
                  _buildSection(
                    title: '⏱️ Hourly Booking Add-ons (PKR)',
                    children: [
                      _buildPriceRow(
                        'Dental Assistant (30 mins)',
                        _dentalAssistantController,
                        Icons.person_outline,
                        Colors.blue,
                      ),
                      _buildPriceRow(
                        'Medical Nurse (30 mins)',
                        _medicalNurseController,
                        Icons.person_outline,
                        Colors.red,
                      ),
                      _buildPriceRow(
                        'Intraoral X-ray Use',
                        _intraoralXrayController,
                        Icons.camera_alt,
                        Colors.indigo,
                      ),
                      _buildPriceRow(
                        'Priority Booking',
                        _priorityBookingController,
                        Icons.priority_high,
                        Colors.deepOrange,
                      ),
                      _buildPriceRow(
                        'Extended Hours (+30 mins)',
                        _extendedHoursController,
                        Icons.schedule,
                        Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  Center(
                    child: SizedBox(
                      width: isMobile ? double.infinity : 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePricing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006876),
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save All Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: isMobile ? 3 : 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: isMobile ? 120 : 150,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: 'PKR ',
                prefixStyle: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF006876),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
