import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_footer.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _clinicImages = [
    'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80', // Modern clinic interior
    'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800&q=80', // Doctor with patient
    'https://images.unsplash.com/photo-1631217868264-e5b90bb7e133?w=800&q=80', // Dental clinic
    'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=800&q=80', // Medical equipment
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _clinicImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(context),
          _buildFeaturesSection(context),
          _buildAppShowcaseSection(context),
          _buildStatsSection(context),
          _buildCTASection(context),
          AppFooter(onNavigate: widget.onNavigate),
        ],
      ),
    );
  }

  Widget _buildClinicImagesSlider() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: _clinicImages.length,
      itemBuilder: (context, index) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _currentPage == index ? 1.0 : 0.7,
          child: Image.network(
            _clinicImages[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.primary.withOpacity(0.3),
                child: const Center(
                  child: Icon(
                    Icons.local_hospital,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppColors.primary.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 700),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            AppColors.secondary,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Clinic Images Slider
          Positioned.fill(child: _buildClinicImagesSlider()),
          // Semi-transparent dark overlay for text readability
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          // Content
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Co-Working Clinical Spaces',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600
                          ? 56
                          : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tagline
                  Text(
                    'Your Practice Space, Simplified',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600
                          ? 28
                          : 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Subtitle
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Text(
                      'Fully-equipped medical, dental, and aesthetic practice spaces for healthcare practitioners. Book on flexible hourly or monthly basis and practice with complete autonomy and professional support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600
                            ? 20
                            : 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Key Features
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildHeroFeature(Icons.schedule, 'Flexible Booking'),
                      _buildHeroFeature(Icons.workspace_premium, 'No Overhead'),
                      _buildHeroFeature(Icons.location_on, 'Prime Location'),
                      _buildHeroFeature(
                        Icons.medical_services,
                        '6 Specialties',
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // CTA Buttons
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => widget.onNavigate?.call(2),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Book Your Space',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => widget.onNavigate?.call(3),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Google Play Button
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Coming Soon! Our app will be available on Play Store very soon.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.primary,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.all(16),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Google Play Logo
                          Image.asset('assets/play.jpg', height: 60),
                        ],
                      ),
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

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Section Header
              Text(
                'Why Choose Sehat Makaan?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 600 ? 42 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your professional space, your way — without the overhead',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 64),
              // Features Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 600
                      ? 2
                      : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 1.0,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.business_center,
                        title: 'No Overhead Costs',
                        description:
                            'Fully equipped, regulation-compliant spaces at a fraction of traditional costs',
                        color: AppColors.primary,
                      ),
                      _buildFeatureCard(
                        icon: Icons.schedule,
                        title: 'Flexible Booking',
                        description:
                            'Hourly slots or monthly packages tailored to your practice needs',
                        color: AppColors.secondary,
                      ),
                      _buildFeatureCard(
                        icon: Icons.medical_services,
                        title: 'Complete Autonomy',
                        description:
                            'Full control over your practice with professional support staff',
                        color: AppColors.accent,
                      ),
                      _buildFeatureCard(
                        icon: Icons.groups,
                        title: 'Collaborative Community',
                        description:
                            'Network with practitioners across dental, medical, and aesthetic fields',
                        color: AppColors.primaryDark,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppShowcaseSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return Column(
                children: [
                  // Section Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Coming Soon to Play Store!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Download Our Mobile App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600
                          ? 42
                          : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Book and manage your clinical space rentals on-the-go',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 64),
                  // Phone Mockup and Features
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Phone Mockup
                            Expanded(
                              flex: 5,
                              child: _buildPhoneMockup(context),
                            ),
                            const SizedBox(width: 64),
                            // App Features
                            Expanded(flex: 5, child: _buildAppFeatures()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildPhoneMockup(context),
                            const SizedBox(height: 48),
                            _buildAppFeatures(),
                          ],
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneMockup(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Status Bar
                  Container(
                    height: 40,
                    color: AppColors.primary,
                    child: const Center(
                      child: Text(
                        '9:41',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // App Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Book Your Space',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Browse available clinical spaces',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Featured Spaces
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available Spaces',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildMockSpaceCard(
                                  'Dental Chair Room',
                                  Icons.medical_services,
                                  AppColors.primary,
                                ),
                                const SizedBox(height: 12),
                                _buildMockSpaceCard(
                                  'Aesthetic Practice Room',
                                  Icons.spa,
                                  AppColors.secondary,
                                ),
                                const SizedBox(height: 12),
                                _buildMockSpaceCard(
                                  'Medical Consultation Room',
                                  Icons.local_hospital,
                                  AppColors.accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom Navigation
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(Icons.home, color: AppColors.primary, size: 28),
                        Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                        Icon(
                          Icons.bookmark_border,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                        Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockSpaceCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available Now',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildAppFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppFeatureItem(
          icon: Icons.search,
          title: 'Find Spaces',
          description:
              'Search for dental, medical, or aesthetic practice spaces',
          color: AppColors.primary,
        ),
        const SizedBox(height: 24),
        _buildAppFeatureItem(
          icon: Icons.calendar_today,
          title: 'Book Slots',
          description: 'Reserve hourly or monthly slots that fit your schedule',
          color: AppColors.secondary,
        ),
        const SizedBox(height: 24),
        _buildAppFeatureItem(
          icon: Icons.notifications_active,
          title: 'Booking Reminders',
          description: 'Get notified about your upcoming reservations',
          color: AppColors.accent,
        ),
        const SizedBox(height: 24),
        _buildAppFeatureItem(
          icon: Icons.verified,
          title: 'Fully Equipped',
          description:
              'All spaces come with complete equipment and support staff',
          color: AppColors.primaryDark,
        ),
      ],
    );
  }

  Widget _buildAppFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.meeting_room,
                      value: '15+',
                      label: 'Clinical Spaces',
                    ),
                    _buildStatItem(
                      icon: Icons.medical_services,
                      value: '6',
                      label: 'Practice Specialties',
                    ),
                    _buildStatItem(
                      icon: Icons.schedule,
                      value: 'Flexible',
                      label: 'Booking Options',
                    ),
                    _buildStatItem(
                      icon: Icons.location_on,
                      value: 'DHA Phase 8',
                      label: 'Prime Location',
                    ),
                  ],
                );
              } else if (constraints.maxWidth > 600) {
                return Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatItem(
                      icon: Icons.meeting_room,
                      value: '15+',
                      label: 'Clinical Spaces',
                    ),
                    _buildStatItem(
                      icon: Icons.medical_services,
                      value: '6',
                      label: 'Practice Specialties',
                    ),
                    _buildStatItem(
                      icon: Icons.schedule,
                      value: 'Flexible',
                      label: 'Booking Options',
                    ),
                    _buildStatItem(
                      icon: Icons.location_on,
                      value: 'DHA Phase 8',
                      label: 'Prime Location',
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildStatItem(
                      icon: Icons.meeting_room,
                      value: '15+',
                      label: 'Clinical Spaces',
                    ),
                    const SizedBox(height: 32),
                    _buildStatItem(
                      icon: Icons.medical_services,
                      value: '6',
                      label: 'Practice Specialties',
                    ),
                    const SizedBox(height: 32),
                    _buildStatItem(
                      icon: Icons.schedule,
                      value: 'Flexible',
                      label: 'Booking Options',
                    ),
                    const SizedBox(height: 32),
                    _buildStatItem(
                      icon: Icons.location_on,
                      value: 'DHA Phase 8',
                      label: 'Prime Location',
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Colors.white),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Start Your Practice?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 600 ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Book your clinical space today and practice with complete autonomy and professional support',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => widget.onNavigate?.call(3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  'Book Space Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroFeature(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
