import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_footer.dart';

class ShippingDeliveryPolicyPage extends StatelessWidget {
  final Function(int)? onNavigate;

  const ShippingDeliveryPolicyPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildContentSection(context),
          AppFooter(onNavigate: onNavigate),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Policy Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.article_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shipping & Delivery Policy',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Service Delivery & Fulfilment Terms',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.accent,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Please read this policy to understand how our services are delivered.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Effective Date: January 6, 2026',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '1. Nature of Service Delivery\n\nSehat Makaan provides clinical co‑working space and digital booking services exclusively for licensed healthcare Practitioners (doctors, dentists, and other registered professionals) to reserve and use clinical rooms and related facilities. The Platform itself does not sell or provide medical services directly to patients; all clinical care is independently provided by Practitioners. Our "delivery" therefore consists of providing Practitioners access to booked clinical rooms, time slots, and related facility services at Sehat Makaan.\n\n2. Digital Confirmations and Booking Vouchers\n\nAfter a successful online payment or booking, Practitioners (and, where applicable, their administrative staff or patients) receive a digital confirmation via the Platform and/or email/SMS, where available. This confirmation acts as the booking "voucher" and includes the date, time, room or package selected, and relevant booking details. Users are responsible for ensuring that their contact information (such as email and mobile number) is accurate and up to date so confirmations can be delivered correctly.\n\n3. Service Fulfilment Timeframes\n\nHourly bookings / single slots: These are fulfilled at the date and time selected at the time of booking, at the Sehat Makaan facility. Practitioners must arrive in time to set up and use the space during the booked slot.\n\nMonthly packages and add‑ons: Access to included hours and services begins from the activation date specified in the package agreement or confirmation and remains valid for the defined duration (for example, one calendar month), unless stated otherwise in writing.\n\n4. Physical Documents, Invoices, or Contracts\n\nWhere necessary, rental agreements, booking agreements, or invoices may be provided in digital form (for example, PDF via email) or printed and signed on‑site at the clinic. If original hard copy documents are required, they will typically be issued and handed over in person at the Sehat Makaan facility. Routine courier or postal delivery of documents is not part of our standard service unless explicitly agreed in writing for a specific case.\n\n5. No Standard Product Shipping\n\nSehat Makaan does not operate as an e‑commerce store for physical goods and does not routinely ship medicines, devices, or other clinical products to Practitioners or patients. Any such supply, if applicable, is handled separately under specific agreements with relevant vendors or service providers and is not covered by this general Shipping & Delivery Policy.\n\n6. Delays, Rescheduling, and Access Issues\n\nIf operational issues (such as facility maintenance, technical faults, or other disruptions) affect access to a booked slot or package, Sehat Makaan will make reasonable efforts to notify affected Practitioners in advance using their registered contact details. Where possible, an alternative date/time or room will be offered. If the facility service cannot be provided, the Sehat Makaan Refund Policy will apply to any eligible payments.\n\nPractitioners are responsible for arriving at the facility on time and for organizing their own patients accordingly. The No‑Show and Cancellation rules set out in the Terms & Conditions, Digital Booking Policy, and Refund Policy will apply.\n\n7. Third‑Party Delivery / Courier (If Applicable)\n\nIn special circumstances where any documents or materials must be sent by courier or post, such shipments will be sent to the address provided by the Practitioner or authorized User and may be subject to separate handling or courier charges, notified in advance. Delivery times will depend on the courier company and the destination; tracking details will be shared where available. Sehat Makaan is not responsible for delays or service failures caused by third‑party courier providers but will provide reasonable support in following up with the courier where feasible.\n\n8. Contact for Shipping / Delivery Queries\n\nIf you have any questions regarding the delivery of confirmations, access to your bookings, or any exceptional courier requirement, please contact:\n\nSehat Makaan – Support\nEmail: support@sehatmakaan.com\nPhone: +92 324 9043006',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Contact Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.contact_support,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Need Help?',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'If you have any questions or concerns about service delivery, please feel free to contact us:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        _buildEnhancedContactItem(
                          context,
                          Icons.location_on,
                          'DHA Phase 5, Lahore, Pakistan',
                          AppColors.primary,
                        ),
                        _buildEnhancedContactItem(
                          context,
                          Icons.phone,
                          '+92 324 9043006',
                          AppColors.secondary,
                        ),
                        _buildEnhancedContactItem(
                          context,
                          Icons.email,
                          'support@sehatmakaan.com',
                          AppColors.accent,
                        ),
                        _buildEnhancedContactItem(
                          context,
                          Icons.access_time,
                          'Available 24/7',
                          AppColors.primaryDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedContactItem(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
