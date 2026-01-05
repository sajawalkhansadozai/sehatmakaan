import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_footer.dart';

class ServicesPage extends StatelessWidget {
  final Function(int)? onNavigate;

  const ServicesPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildServicesListSection(context),
          _buildWhyChooseUsSection(context),
          AppFooter(onNavigate: onNavigate),
        ],
      ),
    );
  }

  Widget _buildServicesListSection(BuildContext context) {
    final services = [
      {
        'icon': Icons.medical_services,
        'title': 'General Dentist - Hourly',
        'description':
            'Dental chair with basic setup including ultrasonic scaler. Perfect for routine dental check-ups and basic procedures.',
        'price': 'Rs. 1,500/hour',
        'features': [
          'Dental Chair Access',
          'Ultrasonic Scaler',
          'Reception Support',
        ],
        'color': AppColors.primary,
      },
      {
        'icon': Icons.healing,
        'title': 'Endodontist - Hourly',
        'description':
            'Specialized dental chair with rotary support, endodontic motor, curing light, and single tooth filling material.',
        'price': 'Rs. 3,000/hour',
        'features': ['Endodontic Motor', 'Curing Light', 'Filling Material'],
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.face_retouching_natural,
        'title': 'Aesthetic Practitioner - Hourly',
        'description':
            'Aesthetic room with LED light and PRP single session support including syringe, butterfly needle, and centrifuge.',
        'price': 'Rs. 3,000/hour',
        'features': ['LED Light', 'PRP Support', 'Sterilized Equipment'],
        'color': AppColors.accent,
      },
      {
        'icon': Icons.local_hospital,
        'title': 'General Physician - Hourly',
        'description':
            'Medical room with basic exam table, BP apparatus, weighing scale and complete examination equipment.',
        'price': 'Rs. 2,000/hour',
        'features': ['Exam Table', 'BP Apparatus', 'Diagnostic Tools'],
        'color': AppColors.primaryDark,
      },
      {
        'icon': Icons.calendar_month,
        'title': 'Dental Monthly Starter Package',
        'description':
            '10 hours/month chair use with flexible slots, basic tray setup, reception and assistant support for dentists.',
        'price': 'Rs. 25,000/month',
        'features': ['10 Hours/Month', 'Assistant Support', 'Priority Booking'],
        'color': AppColors.primary,
      },
      {
        'icon': Icons.workspace_premium,
        'title': 'Dental Monthly Professional Package',
        'description':
            '20 hours/month with x-ray usage (2 per patient), single patient materials, private locker, and pick-drop service.',
        'price': 'Rs. 45,000/month',
        'features': ['20 Hours/Month', 'X-ray Usage', 'Pick & Drop'],
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.spa_outlined,
        'title': 'Aesthetic Monthly Professional',
        'description':
            '20 hours/month with 2 exclusive photo-shoot days, patient waiting material display, custom lighting, pick-drop service.',
        'price': 'Rs. 45,000/month',
        'features': ['20 Hours/Month', 'Photo Shoots', 'Custom Setup'],
        'color': AppColors.accent,
      },
      {
        'icon': Icons.health_and_safety_outlined,
        'title': 'Physician Monthly Professional',
        'description':
            '20 hours/month with extended consultation hours, conference room slot/month, EMR record access, and pick-drop.',
        'price': 'Rs. 35,000/month',
        'features': ['20 Hours/Month', 'EMR Access', 'Conference Room'],
        'color': AppColors.primaryDark,
      },
    ];

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // Page Title
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Our Services',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Clinical Space Rental Packages for Healthcare Professionals',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1100
                      ? 4
                      : constraints.maxWidth > 800
                      ? 3
                      : constraints.maxWidth > 600
                      ? 2
                      : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildServiceCard(context, service);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    final color = service['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.2), width: 2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    service['icon'] as IconData,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  service['title'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['description'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      service['price'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: (service['features'] as List<String>)
                          .map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseUsSection(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.verified,
        'title': 'Certified Professionals',
        'description':
            'All our healthcare providers are certified and experienced',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.price_check,
        'title': 'Transparent Pricing',
        'description': 'No hidden charges, clear pricing for all services',
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.access_time,
        'title': 'Quick Service',
        'description': 'Minimal waiting time with appointment scheduling',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.security,
        'title': 'Data Security',
        'description':
            'Your medical records are completely secure and confidential',
        'color': AppColors.primaryDark,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.primary.withOpacity(0.05)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Why Choose Sehat Makaan?',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your trusted partner in healthcare excellence',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      children: benefits
                          .map(
                            (benefit) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: _buildBenefitCard(
                                  context,
                                  benefit['icon'] as IconData,
                                  benefit['title'] as String,
                                  benefit['description'] as String,
                                  benefit['color'] as Color,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  } else if (constraints.maxWidth > 600) {
                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: benefits
                          .map(
                            (benefit) => SizedBox(
                              width: (constraints.maxWidth - 48) / 2,
                              child: _buildBenefitCard(
                                context,
                                benefit['icon'] as IconData,
                                benefit['title'] as String,
                                benefit['description'] as String,
                                benefit['color'] as Color,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  } else {
                    return Column(
                      children: benefits
                          .map(
                            (benefit) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _buildBenefitCard(
                                context,
                                benefit['icon'] as IconData,
                                benefit['title'] as String,
                                benefit['description'] as String,
                                benefit['color'] as Color,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
