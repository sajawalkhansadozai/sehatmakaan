import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_footer.dart';

class RefundPolicyPage extends StatelessWidget {
  final Function(int)? onNavigate;

  const RefundPolicyPage({super.key, this.onNavigate});

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
                                'Refund Policy',
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
                                'Payment & Refund Terms',
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
                              'Please read this policy carefully before making any payment or booking.',
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
                      'Effective Date: January 6, 2026\nLast Updated: January 6, 2026',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '1. General Principles\n\nSehat Makaan is a clinical co‑working and digital booking platform that provides rental space and related facilities exclusively to registered Practitioners (doctors, dentists, and other licensed healthcare providers). The Platform does not sell or provide medical services directly to patients; all clinical care is independently provided by Practitioners using the space.\n\nWe do not guarantee clinical treatment, diagnosis, or outcomes; therefore, medical dissatisfaction is generally not a basis for a refund and is handled directly with the Practitioner, in line with their professional judgment and applicable law.\n\n2. Scope of Refunds\n\nThis Refund Policy applies only to payments that:\n\n• Are made through the Sehat Makaan Platform (online card, wallet, bank, etc.), and\n\n• Relate to booking fees, subscription packages, add‑ons, or facility usage charges payable by Practitioners.\n\nThis Policy applies to any charges related to clinical procedures, medicines, lab tests, or a Practitioner\'s independent professional fees only where expressly stated in a separate agreement, and such charges generally remain the sole responsibility of the Practitioner.\n\n3. Non‑Refundable Charges\n\nFor greater transparency, the default rule is that:\n\n• Confirmed bookings for which a Practitioner has blocked a slot are normally non‑refundable, except where this Policy specifically allows otherwise.\n\n• Convenience fees, payment gateway charges, processing fees, and service charges are generally non‑refundable.\n\n• Services that are partially consumed (for example, package hours partly used) are generally not eligible for proportional refunds unless otherwise stated in a written agreement.\n\n4. Cancellations and Eligible Refunds\n\nIf a Practitioner cancels a booking or facility slot within the clinic/Platform\'s defined minimum notice period (for example, 6–24 hours before the start time), a partial or full refund, or a credit voucher may be issued on a case‑by‑case basis, in line with the displayed booking policy.\n\nIn the event of a short‑notice cancellation, fees may be forfeited in whole or in part.\n\nIf Sehat Makaan cancels a booking, or the facility becomes unavailable for operational reasons, an alternative slot may be offered or the applicable booking fee may be refunded or credited.\n\nIf, due to a technical error, system outage, or facility‑side issue, the Practitioner does not receive the booked service, an alternative slot or rescheduling will be offered, or a refund/credit may be processed on a reasonable basis, subject to verification.\n\n5. No‑Show Policy\n\nIf a Practitioner does not arrive at the booked time and fails to provide prior notice as per the booking policy, the booking will be treated as a "no‑show", and the fee is normally non‑refundable.\n\nIf Sehat Makaan is unable to make the booked space available at the agreed time, the Practitioner may be offered an alternative slot or a refund/credit, subject to verification.\n\n6. Technical Payment Issues\n\nIf there is a double charge, payment failure with debit, or a similar technical issue (for example, the amount is deducted but the booking is not confirmed), the Practitioner must provide transaction proof (such as a bank statement snapshot, SMS, or reference ID).\n\nAfter verification, either the booking will be confirmed or an appropriate refund will be initiated.\n\nThe typical processing time for a refund is 7–14 business days, depending on the bank, card issuer, or payment gateway processes.\n\n7. Packages, Subscriptions, and Add‑Ons\n\nMonthly subscription packages (Starter, Advanced, Professional, etc.) are normally non‑refundable once activated, because they include facility reservation, branding, resource allocation, and operational costs.\n\nAdd‑on services (for example, extra hours, assistants, lockers, social media highlight, transport, sterile kits, etc.) are refundable only when the service has not been used at all and Sehat Makaan has clearly allowed a refund in written form.\n\nAfter partial usage, proportional refunds are generally not offered, except with special written approval from Sehat Makaan.\n\n8. Mode and Timeline of Refunds\n\nWhere a refund is approved, the amount is normally returned through the same payment method or channel used for the original payment, where technically possible.\n\nIn some cases, instead of a cash refund, Sehat Makaan may offer a credit voucher or wallet balance that can be used for future bookings on the Platform.\n\nProcessing time typically ranges from 7–14 business days, but may be delayed due to bank or payment gateway policies.\n\n9. Chargebacks and Disputes\n\nIf a user files a chargeback through their bank or card issuer without first contacting Sehat Makaan, it may result in delays in investigation and possible restrictions on the user\'s account.\n\nSehat Makaan works with card networks, banks, and payment gateways to investigate each dispute. If the transaction is genuine and services were provided in line with this Policy, the chargeback may be contested or rejected.\n\nIn cases of fraudulent or abusive chargebacks, Sehat Makaan reserves the right to suspend or terminate the user\'s account, restrict future bookings, and initiate legal action and recovery proceedings where necessary.\n\n10. Exceptions and Special Cases\n\nIn severe emergencies, force majeure events (such as natural disasters, lockdowns, or government restrictions), or other extraordinary circumstances, Sehat Makaan may, at its sole discretion, make flexible refund or credit decisions.\n\nSuch decisions are taken on a case‑by‑case basis and do not create any general right or entitlement under this Policy.\n\n11. Policy Hierarchy and Changes\n\nThis Refund Policy forms a complementary part of Sehat Makaan\'s Terms & Conditions, Rental Agreement, and Digital Booking Policy. In the event of any conflict, the specific signed agreement will typically take priority, followed by the Terms & Conditions, and then this Policy.\n\nSehat Makaan may update this Refund Policy from time to time for business, legal, or operational reasons. The "Effective Date" and "Last Updated" fields will be updated accordingly, and the revised Policy will be published on the Platform.\n\n12. Contact for Refund Queries\n\nIf you have any questions regarding any payment, refund request, or dispute, you can contact us at:\n\nEmail: support@sehatmakaan.com\n\nPhone: +92 324 9043006\n\nPractitioners are encouraged to keep their contact and billing information up to date to avoid delays in processing.',
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
                      'If you have any questions or concerns about our refund policy, please feel free to contact us:',
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
