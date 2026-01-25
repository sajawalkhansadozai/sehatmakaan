import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';

/// Specialty Tips Widget
/// Displays helpful tips for each specialty including best times, pricing insights, etc.
class SpecialtyTipsWidget extends StatefulWidget {
  final String specialtyId;
  final bool compact;

  const SpecialtyTipsWidget({
    super.key,
    required this.specialtyId,
    this.compact = false,
  });

  @override
  State<SpecialtyTipsWidget> createState() => _SpecialtyTipsWidgetState();
}

class _SpecialtyTipsWidgetState extends State<SpecialtyTipsWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.compact;
  }

  @override
  Widget build(BuildContext context) {
    final specialty = AppConstants.hourlySpecialties.firstWhere(
      (s) => s['id'] == widget.specialtyId,
      orElse: () => {},
    );

    if (specialty.isEmpty) return const SizedBox.shrink();

    final tips = _getTipsForSpecialty(widget.specialtyId);
    if (tips == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      color: const Color(0xFFF0F9FF), // Light blue background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF14B8A6).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: widget.compact
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF14B8A6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tips for ${specialty['name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (widget.compact)
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF14B8A6),
                    ),
                ],
              ),
            ),
          ),

          // Content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Best Times
                  if (tips['bestTimes'] != null) ...[
                    _buildTipSection(
                      icon: Icons.schedule,
                      title: 'Best Times to Book',
                      content: tips['bestTimes']!,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Peak Hours
                  if (tips['peakHours'] != null) ...[
                    _buildTipSection(
                      icon: Icons.trending_up,
                      title: 'Peak Hours',
                      content: tips['peakHours']!,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Cost Savings
                  if (tips['costSavings'] != null) ...[
                    _buildTipSection(
                      icon: Icons.savings_outlined,
                      title: 'Save Money',
                      content: tips['costSavings']!,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Popular Duration
                  if (tips['popularDuration'] != null) ...[
                    _buildTipSection(
                      icon: Icons.timer_outlined,
                      title: 'Popular Duration',
                      content: tips['popularDuration']!,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Pro Tips
                  if (tips['proTips'] != null &&
                      (tips['proTips'] as List).isNotEmpty) ...[
                    _buildProTipsSection(tips['proTips'] as List<String>),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProTipsSection(List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_objects, color: Color(0xFF14B8A6), size: 20),
              SizedBox(width: 8),
              Text(
                'Pro Tips',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14B8A6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
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

  Map<String, dynamic>? _getTipsForSpecialty(String specialtyId) {
    final tipsMap = {
      'radiology': {
        'bestTimes':
            'Early morning (8-10 AM) for X-rays and scans when equipment is freshly calibrated.',
        'peakHours':
            'Avoid 2-5 PM when most patients schedule appointments after lunch.',
        'costSavings':
            'Book 4+ hours for discounted rates. Weekend morning slots often available at 15% off.',
        'popularDuration':
            'Most patients book 2-3 hours for comprehensive imaging services.',
        'proTips': [
          'Arrive 15 minutes early for pre-scan preparation',
          'Fasting required for certain scans - confirm beforehand',
          'Bring previous reports for comparison',
        ],
      },
      'physiotherapy': {
        'bestTimes':
            'Mid-morning (10 AM-12 PM) when therapists are fresh and focused.',
        'peakHours':
            'Late afternoon (4-6 PM) is busiest. Book earlier for personalized attention.',
        'costSavings': 'Monthly packages save 20-30% compared to hourly rates.',
        'popularDuration':
            '1-2 hour sessions are most common for effective treatment.',
        'proTips': [
          'Wear comfortable, loose-fitting clothes',
          'Book recurring sessions for better progress tracking',
          'Ask about home exercise routines',
        ],
      },
      'pathology': {
        'bestTimes':
            'Early morning (7-9 AM) for fasting blood tests ensures accurate results.',
        'peakHours': 'Avoid 11 AM-1 PM when lunch rush causes delays.',
        'costSavings':
            'Bundled test packages cost 40% less than individual tests.',
        'popularDuration': 'Most lab work completes within 1 hour.',
        'proTips': [
          'Fast 8-12 hours before blood glucose and lipid tests',
          'Stay hydrated for easier blood draws',
          'Bring previous reports for trend analysis',
        ],
      },
      'ultrasound': {
        'bestTimes': 'Morning appointments (9-11 AM) have shorter wait times.',
        'peakHours': 'Afternoons fill up quickly. Book 2-3 days in advance.',
        'costSavings':
            'Package deals with radiology save 15-20% on combined services.',
        'popularDuration': 'Standard ultrasounds take 30-45 minutes.',
        'proTips': [
          'Drink water before pelvic ultrasounds (full bladder required)',
          'Bring previous ultrasound images for comparison',
          'Ask for digital copies of images',
        ],
      },
      'ct-scan': {
        'bestTimes':
            'Early morning slots (8-10 AM) minimize wait times and ensure rested radiologists.',
        'peakHours':
            'Mid-afternoon sees highest traffic. Early/late slots recommended.',
        'costSavings':
            'Multi-area scans in one session save 25% vs separate appointments.',
        'popularDuration':
            'CT scans typically take 15-30 minutes including prep.',
        'proTips': [
          'Inform staff of any metal implants or allergies',
          'Remove jewelry and metal accessories',
          'Fasting may be required - confirm 24 hours ahead',
        ],
      },
      'mri': {
        'bestTimes': 'Morning or evening slots reduce scheduling conflicts.',
        'peakHours': 'Midday slots book fastest. Reserve 5-7 days in advance.',
        'costSavings':
            'Package with consultation saves 20%. Insurance often covers portions.',
        'popularDuration':
            'MRI sessions range from 30-90 minutes depending on area.',
        'proTips': [
          'No metal objects allowed - includes hearing aids, watches',
          'Notify staff if you have claustrophobia (sedation available)',
          'Ask about open MRI options for comfort',
        ],
      },
      'minor-surgery': {
        'bestTimes':
            'Morning surgeries (9-11 AM) ensure surgeon is fresh and alert.',
        'peakHours': 'Avoid Friday afternoons - book Monday-Thursday mornings.',
        'costSavings':
            'Package with follow-up care saves 15-20% on total costs.',
        'popularDuration':
            'Minor procedures typically need 2-4 hour booking blocks.',
        'proTips': [
          'Arrange transportation - no driving post-anesthesia',
          'Fast 6-8 hours before surgery',
          'Bring a companion for post-op support',
        ],
      },
      'consultation': {
        'bestTimes':
            'Early morning or late afternoon for undivided doctor attention.',
        'peakHours': 'Lunch hours (12-2 PM) see longest waits.',
        'costSavings':
            'Bundle with tests for 10% discount on consultation fee.',
        'popularDuration':
            '30-60 minutes is standard for thorough consultation.',
        'proTips': [
          'Prepare questions beforehand to maximize time',
          'Bring all medical records and current medications list',
          'Consider virtual consultation for follow-ups',
        ],
      },
    };

    return tipsMap[specialtyId];
  }
}

/// Specialty Quick Tip Badge
/// Shows a concise tip as a small badge/chip
class SpecialtyQuickTip extends StatelessWidget {
  final String specialtyId;

  const SpecialtyQuickTip({super.key, required this.specialtyId});

  @override
  Widget build(BuildContext context) {
    final tip = _getQuickTip(specialtyId);
    if (tip == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Light yellow
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.tips_and_updates,
            size: 14,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
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

  String? _getQuickTip(String specialtyId) {
    final tips = {
      'radiology': 'Best time: Early morning 8-10 AM',
      'physiotherapy': 'Save 20-30% with monthly packages',
      'pathology': 'Fasting required for blood tests',
      'ultrasound': 'Drink water before pelvic scans',
      'ct-scan': 'Remove all metal jewelry',
      'mri': 'Notify staff if claustrophobic',
      'minor-surgery': 'Arrange post-op transportation',
      'consultation': 'Bring all medical records',
    };
    return tips[specialtyId];
  }
}

/// Booking Insight Banner
/// Shows time-sensitive booking insights
class BookingInsightBanner extends StatelessWidget {
  final String specialtyId;
  final String? timeSlot;

  const BookingInsightBanner({
    super.key,
    required this.specialtyId,
    this.timeSlot,
  });

  @override
  Widget build(BuildContext context) {
    final insight = _getInsight(specialtyId, timeSlot);
    if (insight == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            insight['color'].withValues(alpha: 0.1),
            insight['color'].withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight['color'].withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(insight['icon'], color: insight['color'], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight['message'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getInsight(String specialtyId, String? timeSlot) {
    // Check if it's a peak time
    if (timeSlot != null) {
      final hour = int.tryParse(timeSlot.split(':')[0]) ?? 0;

      if (hour >= 14 && hour <= 17) {
        return {
          'icon': Icons.trending_up,
          'color': Colors.orange,
          'message':
              'Peak hours - Consider booking earlier for shorter wait times',
        };
      }

      if (hour >= 8 && hour <= 10) {
        return {
          'icon': Icons.wb_sunny_outlined,
          'color': Colors.green,
          'message':
              'Great choice! Morning slots ensure fresh equipment and focused staff',
        };
      }
    }

    return null;
  }
}
