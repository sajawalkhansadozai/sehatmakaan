import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class AppFooter extends StatelessWidget {
  final Function(int)? onNavigate;

  const AppFooter({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDark.withOpacity(0.9),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Brand Section
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.width > 600 ? 40 : 32,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: MediaQuery.of(context).size.width > 600
                              ? 50
                              : 40,
                          height: MediaQuery.of(context).size.width > 600
                              ? 50
                              : 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Sehat Makaan',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: MediaQuery.of(context).size.width > 600
                              ? 28
                              : 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Co-Working Clinical Spaces',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                    fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Content Sections
          Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Desktop: 3 columns side by side (>900px)
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildFooterColumn(context, 'About Us', [
                          FooterItem(
                            'Company',
                            () => _navigateToAbout(context),
                          ),
                          FooterItem(
                            'Our Services',
                            () => _navigateToServices(context),
                          ),
                          FooterItem('Careers', () => _showComingSoon(context)),
                          FooterItem(
                            'Contact Us',
                            () => _navigateToHandbook(context),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 1,
                        child: _buildFooterColumn(context, 'Policies', [
                          FooterItem(
                            'Privacy Policy',
                            () => _navigateToPrivacyPolicy(context),
                          ),
                          FooterItem(
                            'Terms & Conditions',
                            () => _navigateToTerms(context),
                          ),
                          FooterItem(
                            'Refund Policy',
                            () => _navigateToRefundPolicy(context),
                          ),
                          FooterItem(
                            'Shipping & Delivery',
                            () => _navigateToShippingPolicy(context),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 48),
                      Expanded(flex: 2, child: _buildContactSection(context)),
                    ],
                  );
                }
                // Tablet: 2 columns + contact full width below (>600px)
                else if (constraints.maxWidth > 600) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildFooterColumn(context, 'About Us', [
                              FooterItem(
                                'Company',
                                () => _navigateToAbout(context),
                              ),
                              FooterItem(
                                'Our Services',
                                () => _navigateToServices(context),
                              ),
                              FooterItem(
                                'Careers',
                                () => _showComingSoon(context),
                              ),
                              FooterItem(
                                'Contact Us',
                                () => _navigateToHandbook(context),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _buildFooterColumn(context, 'Policies', [
                              FooterItem(
                                'Privacy Policy',
                                () => _navigateToPrivacyPolicy(context),
                              ),
                              FooterItem(
                                'Terms & Conditions',
                                () => _navigateToTerms(context),
                              ),
                              FooterItem(
                                'Refund Policy',
                                () => _navigateToRefundPolicy(context),
                              ),
                              FooterItem(
                                'Shipping & Delivery',
                                () => _navigateToShippingPolicy(context),
                              ),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildContactSection(context),
                    ],
                  );
                }
                // Mobile: Single column, stacked layout (<600px)
                else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFooterColumn(context, 'About Us', [
                        FooterItem('Company', () => _navigateToAbout(context)),
                        FooterItem(
                          'Our Services',
                          () => _navigateToServices(context),
                        ),
                        FooterItem('Careers', () => _showComingSoon(context)),
                        FooterItem(
                          'Contact Us',
                          () => _navigateToHandbook(context),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildFooterColumn(context, 'Policies', [
                        FooterItem(
                          'Privacy Policy',
                          () => _navigateToPrivacyPolicy(context),
                        ),
                        FooterItem(
                          'Terms & Conditions',
                          () => _navigateToTerms(context),
                        ),
                        FooterItem(
                          'Refund Policy',
                          () => _navigateToRefundPolicy(context),
                        ),
                        FooterItem(
                          'Shipping & Delivery',
                          () => _navigateToShippingPolicy(context),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildContactSection(context),
                    ],
                  );
                }
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 40 : 32),
          const Divider(color: Colors.white24, thickness: 1),
          SizedBox(height: MediaQuery.of(context).size.width > 600 ? 24 : 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '© 2026 Sehat Makaan. All rights reserved.',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.7),
                fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterColumn(
    BuildContext context,
    String title,
    List<FooterItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.textLight.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: item.onTap,
              hoverColor: Colors.white12,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: MouseRegion(
                  cursor: item.onTap != null
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: Text(
                    item.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textLight.withOpacity(0.85),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.textLight.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Text(
            'Contact Us',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildContactItem(
          context,
          Icons.location_on_outlined,
          'Office 304, 3rd Floor, Plaza 95\nMain Boulevard, DHA Phase 8\nLahore - 54000, Punjab, Pakistan',
          null,
        ),
        const SizedBox(height: 16),
        _buildContactItem(
          context,
          Icons.phone_outlined,
          '+92 324 9043006',
          () => _launchPhone('+923249043006'),
        ),
        const SizedBox(height: 16),
        _buildContactItem(
          context,
          Icons.email_outlined,
          'support@sehatmakaan.com',
          () => _launchEmail('support@sehatmakaan.com'),
        ),
        const SizedBox(height: 16),
        _buildContactItem(
          context,
          Icons.schedule_outlined,
          'Mon - Sat: 9:00 AM - 6:00 PM\nSun: Closed (Emergency: 24/7)',
          null,
        ),
      ],
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white12,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.textLight, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MouseRegion(
                cursor: onTap != null
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAbout(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(2); // About page index
    }
  }

  void _navigateToServices(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(1); // Services page index
    }
  }

  void _navigateToHandbook(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(3); // Handbook page index
    }
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(4); // Privacy Policy page index
    }
  }

  void _navigateToTerms(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(5); // Terms page index
    }
  }

  void _navigateToRefundPolicy(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(6); // Refund Policy page index
    }
  }

  void _navigateToShippingPolicy(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(7); // Shipping Policy page index
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 12),
            Text('Coming soon!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class FooterItem {
  final String text;
  final VoidCallback? onTap;

  FooterItem(this.text, this.onTap);
}
