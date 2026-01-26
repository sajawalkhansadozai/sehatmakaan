import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/cart_service.dart';

/// Premium Workshop Card with Hero Animation, Glassmorphism, and Interactive Effects
class WorkshopCard extends StatefulWidget {
  final Map<String, dynamic> workshop;
  final String? creatorName;
  final VoidCallback onTap;
  final VoidCallback? onManageRequests;
  final VoidCallback? onViewAnalytics;
  final bool isCreator;

  const WorkshopCard({
    super.key,
    required this.workshop,
    this.creatorName,
    required this.onTap,
    this.onManageRequests,
    this.onViewAnalytics,
    this.isCreator = false,
  });

  @override
  State<WorkshopCard> createState() => _WorkshopCardState();
}

class _WorkshopCardState extends State<WorkshopCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    final maxParticipants = widget.workshop['maxParticipants'] as int? ?? 0;
    final currentParticipants =
        widget.workshop['currentParticipants'] as int? ?? 0;
    final spotsRemaining = maxParticipants - currentParticipants;
    final isFull = spotsRemaining <= 0;
    final fillPercentage = maxParticipants > 0
        ? (currentParticipants / maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Card(
          margin: EdgeInsets.only(
            bottom: isSmallScreen ? 12 : 16,
            left: isSmallScreen ? 8 : 0,
            right: isSmallScreen ? 8 : 0,
          ),
          elevation: _isPressed ? 2 : 6,
          shadowColor: const Color(0xFF006876).withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎨 HERO BANNER WITH GLASSMORPHISM PRICE TAG
              _buildHeroBanner(
                context,
                isSmallScreen: isSmallScreen,
                isMediumScreen: isMediumScreen,
              ),

              // 📝 CONTENT SECTION
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Creator
                    _buildTitleSection(context, isSmallScreen: isSmallScreen),

                    SizedBox(height: isSmallScreen ? 8 : 12),

                    // 🏅 PREMIUM STATUS CHIPS WITH GRADIENT
                    _buildStatusChips(context, isSmallScreen: isSmallScreen),

                    SizedBox(height: isSmallScreen ? 10 : 12),

                    // Description
                    _buildDescription(context, isSmallScreen: isSmallScreen),

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Info Grid
                    _buildInfoGrid(context, isSmallScreen: isSmallScreen),

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // 📊 SOCIAL PROOF: PARTICIPANTS PROGRESS BAR
                    _buildParticipantsProgress(
                      fillPercentage: fillPercentage,
                      currentParticipants: currentParticipants,
                      maxParticipants: maxParticipants,
                      isFull: isFull,
                      isSmallScreen: isSmallScreen,
                    ),

                    if (widget.workshop['schedule'] != null) ...[
                      SizedBox(height: isSmallScreen ? 10 : 12),
                      _buildDetailSection(
                        Icons.calendar_month,
                        'Schedule',
                        widget.workshop['schedule'] as String,
                        isSmallScreen: isSmallScreen,
                      ),
                    ],

                    if (widget.workshop['prerequisites'] != null &&
                        (widget.workshop['prerequisites'] as String)
                            .isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildDetailSection(
                        Icons.book,
                        'Prerequisites',
                        widget.workshop['prerequisites'] as String,
                        isSmallScreen: isSmallScreen,
                      ),
                    ],

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // 📋 SYLLABUS PDF BUTTON
                    if (widget.workshop['syllabusPdf'] != null &&
                        (widget.workshop['syllabusPdf'] as String)
                            .isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openSyllabusPdf(
                            context,
                            widget.workshop['syllabusPdf'] as String,
                          ),
                          icon: const Icon(Icons.file_present),
                          label: const Text('View Syllabus PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                    ],

                    // 🚀 JOIN WORKSHOP BUTTON (for participants)
                    if (!widget.isCreator) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onTap,
                          icon: const Icon(Icons.event_available),
                          label: const Text('Join Workshop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006876),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 11 : 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // 🛒 ADD TO CART BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _addToCart(context),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to Cart'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(
                              color: Colors.orange.shade700,
                              width: 1.5,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 12),
                    ],

                    // 🎯 CREATOR ACTION BUTTONS
                    if (widget.isCreator) ...[
                      if (widget.onManageRequests != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: widget.onManageRequests,
                            icon: Icon(
                              Icons.people_alt,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            label: Text(
                              'Manage Join Requests',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF006876),
                              side: const BorderSide(color: Color(0xFF006876)),
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (widget.onManageRequests != null)
                        const SizedBox(height: 8),
                      if (widget.onViewAnalytics != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: widget.onViewAnalytics,
                            icon: Icon(
                              Icons.analytics,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            label: Text(
                              'View Deep Analytics',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006876),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 HERO BANNER WITH GLASSMORPHISM OVERLAY
  Widget _buildHeroBanner(
    BuildContext context, {
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    final workshopId = widget.workshop['id']?.toString() ?? '';
    final bannerImage = widget.workshop['bannerImage'] as String?;
    final price = (widget.workshop['price'] as num? ?? 0).toDouble();
    final duration = widget.workshop['duration'] as int? ?? 0;

    final bannerHeight = isSmallScreen
        ? 160.0
        : isMediumScreen
        ? 180.0
        : 200.0;

    return SizedBox(
      height: bannerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Hero Animated Image
          if (bannerImage != null && bannerImage.isNotEmpty)
            Hero(
              tag: 'workshop_banner_$workshopId',
              child: CachedNetworkImage(
                imageUrl: bannerImage,
                height: bannerHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF006876),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF006876).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.image_not_supported,
                    size: isSmallScreen ? 40 : 48,
                    color: const Color(0xFF006876),
                  ),
                ),
              ),
            )
          else
            Container(
              height: bannerHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF006876),
                    const Color(0xFF006876).withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.school,
                  size: isSmallScreen ? 60 : 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),

          // Gradient Overlay
          Container(
            height: bannerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          // 💎 GLASSMORPHISM PRICE TAG (Top Right)
          Positioned(
            top: isSmallScreen ? 8 : 12,
            right: isSmallScreen ? 8 : 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 14,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(
                      isSmallScreen ? 12 : 16,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        size: isSmallScreen ? 14 : 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        price.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
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

          // Duration Badge (Bottom Left)
          if (duration > 0)
            Positioned(
              bottom: isSmallScreen ? 8 : 12,
              left: isSmallScreen ? 8 : 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: isSmallScreen ? 12 : 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${duration}h',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 📝 TITLE & CREATOR SECTION
  Widget _buildTitleSection(
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.workshop['title'] as String? ?? 'Untitled Workshop',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006876),
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.creatorName != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: isSmallScreen ? 12 : 14,
                color: const Color(0xFF006876).withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.creatorName!,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 🏅 PREMIUM GRADIENT STATUS CHIPS
  Widget _buildStatusChips(
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    final provider = widget.workshop['provider'] as String? ?? '';
    final certificationType =
        widget.workshop['certificationType'] as String? ?? '';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (provider.isNotEmpty)
          _buildGradientChip(
            label: provider,
            gradient: const LinearGradient(
              colors: [Color(0xFF006876), Color(0xFF00A896)],
            ),
            isSmallScreen: isSmallScreen,
          ),
        if (certificationType.isNotEmpty)
          _buildGradientChip(
            label: certificationType,
            gradient: LinearGradient(
              colors: [const Color(0xFFFF6B35), const Color(0xFFFF8C42)],
            ),
            isSmallScreen: isSmallScreen,
          ),
      ],
    );
  }

  Widget _buildGradientChip({
    required String label,
    required Gradient gradient,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 12,
        vertical: isSmallScreen ? 5 : 6,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: isSmallScreen ? 10 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 📄 DESCRIPTION
  Widget _buildDescription(
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    final description = widget.workshop['description'] as String? ?? '';
    if (description.isEmpty) return const SizedBox.shrink();

    return Text(
      description,
      style: TextStyle(
        fontSize: isSmallScreen ? 13 : 14,
        color: const Color(0xFF006876).withValues(alpha: 0.7),
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 📊 INFO GRID
  Widget _buildInfoGrid(BuildContext context, {required bool isSmallScreen}) {
    final location = widget.workshop['location'] as String? ?? '';
    final instructor = widget.workshop['instructor'] as String? ?? '';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoChip(
                Icons.location_on,
                location.isNotEmpty ? location : 'TBA',
                isSmallScreen: isSmallScreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoChip(
                Icons.school,
                instructor.isNotEmpty ? instructor : 'TBA',
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text, {
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF006876).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF006876).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 14 : 16,
            color: const Color(0xFF006876).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: const Color(0xFF006876).withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 SOCIAL PROOF: PARTICIPANTS PROGRESS BAR
  Widget _buildParticipantsProgress({
    required double fillPercentage,
    required int currentParticipants,
    required int maxParticipants,
    required bool isFull,
    required bool isSmallScreen,
  }) {
    Color progressColor;
    if (fillPercentage >= 0.9) {
      progressColor = Colors.red;
    } else if (fillPercentage >= 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = const Color(0xFF90D26D);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: isSmallScreen ? 14 : 16,
                  color: const Color(0xFF006876).withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF006876).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10,
                vertical: isSmallScreen ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: progressColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$currentParticipants/$maxParticipants',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background
            Container(
              height: isSmallScreen ? 6 : 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Progress Fill
            FractionallySizedBox(
              widthFactor: fillPercentage,
              child: Container(
                height: isSmallScreen ? 6 : 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      progressColor,
                      progressColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isFull
              ? '🔴 Workshop Full'
              : fillPercentage >= 0.9
              ? '⚠️ Almost Full!'
              : fillPercentage >= 0.7
              ? '🔥 Filling Fast!'
              : '✅ Spots Available',
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: progressColor,
          ),
        ),
      ],
    );
  }

  /// 📌 DETAIL SECTION
  Widget _buildDetailSection(
    IconData icon,
    String title,
    String content, {
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF006876).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF006876).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 14 : 16,
            color: const Color(0xFF006876).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: const Color(0xFF006876).withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 OPEN SYLLABUS PDF IN BROWSER
  Future<void> _openSyllabusPdf(BuildContext context, String pdfUrl) async {
    try {
      debugPrint('📄 Opening syllabus PDF: $pdfUrl');
      if (await canLaunchUrl(Uri.parse(pdfUrl))) {
        await launchUrl(
          Uri.parse(pdfUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch PDF';
      }
    } catch (e) {
      debugPrint('❌ Error opening PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening PDF: $e')));
      }
    }
  }

  /// 🛒 ADD WORKSHOP TO CART
  Future<void> _addToCart(BuildContext context) async {
    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to add items to cart'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create cart item from workshop
      final cartItem = CartService.createWorkshopCartItem(widget.workshop);

      // Add to cart using CartService
      final cartService = CartService();
      final success = await cartService.addToCart(
        context: context,
        userId: userId,
        item: cartItem,
        showSnackbar: true,
      );

      if (success) {
        debugPrint('✅ Workshop added to cart: ${widget.workshop['title']}');
      }
    } catch (e) {
      debugPrint('❌ Error adding workshop to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
