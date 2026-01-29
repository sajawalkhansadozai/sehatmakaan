import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sehatmakaan/core/constants/constants.dart';
import 'privacy_policy_page.dart';
import 'terms_conditions_page.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';
import 'dart:async'; // ✅ Import for Timer and StreamSubscription

class LandingPage extends ConsumerStatefulWidget {
  final VoidCallback? onLoginClick;

  const LandingPage({super.key, this.onLoginClick});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentImageIndex = 0;
  DateTime _currentTime = DateTime.now();

  // ✅ Stream management to prevent memory leaks
  StreamSubscription? _clockSubscription;
  Timer? _carouselTimer;

  // Carousel images paths (you'll need to add these to assets)
  final List<String> _carouselImages = [
    'assets/package1.jpg',
    'assets/package2.jpg',
    'assets/package3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController(initialPage: 0);

    // ✅ Update time every minute with StreamSubscription
    _clockSubscription = Stream.periodic(const Duration(minutes: 1)).listen((
      _,
    ) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // ✅ Auto-advance carousel with Timer (better control)
    _startCarouselTimer();
  }

  // ✅ Start/restart carousel auto-advance timer
  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _nextImage();
      }
    });
  }

  @override
  void dispose() {
    _clockSubscription?.cancel(); // ✅ Cancel clock stream
    _carouselTimer?.cancel(); // ✅ Cancel carousel timer
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (!_pageController.hasClients) return;
    final nextIndex = (_currentImageIndex + 1) % _carouselImages.length;
    _pageController.animateToPage(
      nextIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevImage() {
    if (!_pageController.hasClients) return;
    final prevIndex =
        (_currentImageIndex - 1 + _carouselImages.length) %
        _carouselImages.length;
    _pageController.animateToPage(
      prevIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tab buttons removed - only show after login
          // _buildTabBar(),
          Expanded(
            // Show only Practice tab content (no tabs)
            child: _buildPracticeRegistrationTab(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Sehat Makaan',
            style: TextStyle(
              color: Color(0xFF006876),
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
            );
          },
          child: Text(
            'Privacy',
            style: TextStyle(
              color: Color(0xFF006876),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TermsConditionsPage()),
            );
          },
          child: Text(
            'Terms',
            style: TextStyle(
              color: Color(0xFF006876),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: widget.onLoginClick,
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF006876),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPracticeRegistrationTab() {
    return SingleChildScrollView(
      child: Column(
        children: [_buildHeroSection(), _buildPricingSection(), _buildFooter()],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F7F9), Color(0xFFF0FAFB), Colors.white],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: _buildHeroContent()),
                  SizedBox(width: 48),
                  Expanded(child: _buildAvailabilityCard()),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildHeroContent(),
                  SizedBox(height: 32),
                  _buildAvailabilityCard(),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeroContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isWideScreen =
            constraints.maxWidth > 800; // ✅ Detect wide screens
        final titleSize = isSmallScreen ? 32.0 : 48.0;
        final subtitleSize = isSmallScreen ? 14.0 : 18.0;
        // ✅ Left align on wide screens, center on mobile
        final textAlign = isWideScreen ? TextAlign.left : TextAlign.center;
        final crossAxisAlignment = isWideScreen
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center;

        return Column(
          crossAxisAlignment: crossAxisAlignment, // ✅ Dynamic alignment
          children: [
            SizedBox(height: isSmallScreen ? 20 : 40),
            Text(
              'Start Your Practice',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
                height: 1.2,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Color(0xFF006876).withValues(alpha: 0.1),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: textAlign, // ✅ Dynamic text alignment
            ),
            Text(
              ' Today',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
                height: 1.2,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Color(0xFFFF6B35).withValues(alpha: 0.2),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: textAlign, // ✅ Dynamic text alignment
            ),
            SizedBox(height: 16),
            Text(
              'Join Sehat Makaan\'s collaborative healthcare platform. Practice with autonomy in our well-equipped, patient-friendly environment designed for dental, medical, and aesthetic professionals.',
              style: TextStyle(
                fontSize: subtitleSize,
                color: Color(0xFF006876).withValues(alpha: 0.8),
                height: 1.6,
              ),
              textAlign: textAlign, // ✅ Dynamic text alignment
            ),
            SizedBox(height: 32),
            ..._buildFeaturesList(),
            SizedBox(height: 32),
            _buildActionButtons(),
            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        );
      },
    );
  }

  List<Widget> _buildFeaturesList() {
    final features = [
      'Practice without overhead costs',
      'Flexible hourly slots and monthly packages',
      'Professional support without micromanagement',
    ];

    return features.map((feature) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF90D26D),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Color(0xFF006876), size: 16),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                feature,
                style: TextStyle(color: Color(0xFF006876), fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final buttonTextSize = isSmallScreen ? 16.0 : 18.0;
        final buttonPadding = isSmallScreen ? 12.0 : 16.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8555)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF6B35).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to agreement page
                  Navigator.pushNamed(context, '/agreement');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: buttonPadding,
                    horizontal: isSmallScreen ? 24 : 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Start Your Practice Today',
                        style: TextStyle(
                          fontSize: buttonTextSize,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      elevation: 12,
      shadowColor: Color(0xFF006876).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFAFDFD)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Today',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006876),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF90D26D),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF90D26D).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      'Live',
                      style: TextStyle(
                        color: Color(0xFF006876),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ...AppConstants.suites.map((suite) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE6F7F9), Color(0xFFF0FAFB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF006876).withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF006876).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suite.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF006876),
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Color(
                                    0xFF006876,
                                  ).withValues(alpha: 0.7),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Multiple slots available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(
                                      0xFF006876,
                                    ).withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'PKR ${suite.baseRate.toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Color(0xFF006876).withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Last updated: ${_currentTime.hour}:${_currentTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF006876).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final titleSize = isSmallScreen ? 28.0 : 36.0;
        final subtitleSize = isSmallScreen ? 14.0 : 18.0;
        final verticalPadding = isSmallScreen ? 40.0 : 80.0;

        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: isSmallScreen ? 16 : 24,
          ),
          child: Column(
            children: [
              Text(
                'Comprehensive Pricing',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
              Text(
                ' Packages',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Explore our transparent pricing for all medical/dental specialties and subscription packages',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Color(0xFF006876).withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 24 : 48),
              _buildCarousel(),
              SizedBox(height: isSmallScreen ? 24 : 48),
              _buildPricingCTA(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCarousel() {
    return Container(
      constraints: BoxConstraints(maxWidth: 1000),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _carouselImages.length,
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                    // ✅ Reset timer on manual swipe
                    _startCarouselTimer();
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () =>
                          _showImageZoom(context, _carouselImages[index]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          _carouselImages[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 100,
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: _prevImage,
                      icon: Icon(Icons.chevron_left),
                      iconSize: 32,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.95),
                        foregroundColor: Color(0xFF006876),
                        shadowColor: Color(0xFF006876).withValues(alpha: 0.2),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: _nextImage,
                      icon: Icon(Icons.chevron_right),
                      iconSize: 32,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.95),
                        foregroundColor: Color(0xFF006876),
                        shadowColor: Color(0xFF006876).withValues(alpha: 0.2),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_carouselImages.length, (index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? Color(0xFFFF6B35)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            '${_currentImageIndex + 1} of ${_carouselImages.length}',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF006876).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCTA() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final textSize = isSmallScreen ? 14.0 : 18.0;
        final buttonTextSize = isSmallScreen ? 16.0 : 18.0;
        final buttonPadding = isSmallScreen ? 12.0 : 16.0;

        return Column(
          children: [
            Text(
              'Ready to start your practice with transparent, competitive pricing?',
              style: TextStyle(
                fontSize: textSize,
                color: Color(0xFF006876).withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/agreement');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: buttonPadding,
                  horizontal: isSmallScreen ? 24 : 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Get Started Today',
                      style: TextStyle(
                        fontSize: buttonTextSize,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImageZoom(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                  iconSize: 32,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: Color(0xFF006876),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pinch to zoom • Drag to pan',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Color(0xFF006876),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // ✅ Wrap instead of Row to prevent overflow
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivacyPolicyPage(),
                    ),
                  );
                },
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Text(
                '|',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TermsConditionsPage(),
                    ),
                  );
                },
                child: Text(
                  'Terms & Conditions',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '© 2026 Sehat Makaan. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Office 304, 3rd Floor, Plaza 95, Main Boulevard, DHA Phase 8, Lahore',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
