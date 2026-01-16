import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WorkshopsPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const WorkshopsPage({super.key, required this.userSession});

  @override
  State<WorkshopsPage> createState() => _WorkshopsPageState();
}

class _WorkshopsPageState extends State<WorkshopsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _workshops = [];
  final Map<String, String> _creatorNames = {}; // Map creatorId to name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
  }

  Future<void> _loadWorkshops() async {
    setState(() => _isLoading = true);

    try {
      final query = await _firestore
          .collection('workshops')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final workshops = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load creator names
      final creatorIds = workshops
          .where((w) => w['createdBy'] != null)
          .map((w) => w['createdBy'] as String)
          .toSet();

      final Map<String, String> creatorNames = {};
      for (final creatorId in creatorIds) {
        try {
          final creatorDoc = await _firestore
              .collection('workshop_creators')
              .doc(creatorId)
              .get();
          if (creatorDoc.exists) {
            creatorNames[creatorId] =
                creatorDoc.data()?['fullName'] ?? 'Unknown Creator';
          }
        } catch (e) {
          creatorNames[creatorId] = 'Unknown Creator';
        }
      }

      if (mounted) {
        setState(() {
          _workshops.clear();
          _workshops.addAll(workshops);
          _creatorNames.addAll(creatorNames);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading workshops: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _isLoading
                ? _buildLoadingGrid()
                : (_workshops.isEmpty
                      ? _buildEmptyState()
                      : _buildWorkshopGrid()),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: const Color(0xFF006876),
      elevation: 2,
      title: const Text(
        'Professional Workshops',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/dashboard',
              arguments: widget.userSession,
            );
          },
          icon: const Icon(Icons.dashboard, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3E5F5), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: 'Professional ',
                  style: TextStyle(color: Color(0xFF006876)),
                ),
                TextSpan(
                  text: 'Workshops',
                  style: TextStyle(color: Color(0xFFFF6B35)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enhance your medical skills with certified training programs and earn continuing education credits',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF006876).withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        childCount: 3,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 80,
                color: Color(0xFF006876),
              ),
              const SizedBox(height: 24),
              const Text(
                'No workshops available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back soon for new professional development opportunities',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF006876).withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkshopGrid() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final workshop = _workshops[index];
        return _buildWorkshopCard(workshop);
      }, childCount: _workshops.length),
    );
  }

  Widget _buildWorkshopCard(Map<String, dynamic> workshop) {
    final maxParticipants = workshop['maxParticipants'] as int? ?? 0;
    final currentParticipants = workshop['currentParticipants'] as int? ?? 0;
    final spotsRemaining = maxParticipants - currentParticipants;
    final isFull = spotsRemaining <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          if (workshop['bannerImage'] != null &&
              (workshop['bannerImage'] as String).isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: workshop['bannerImage'] as String,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF006876).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Color(0xFF006876),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workshop['title'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006876),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Creator name
                          if (workshop['createdBy'] != null)
                            Text(
                              'Created by: ${_creatorNames[workshop['createdBy']] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(
                                  0xFF006876,
                                ).withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF006876,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    workshop['provider'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF006876),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(
                                        0xFF006876,
                                      ).withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    workshop['certificationType'] as String? ??
                                        '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(
                                        0xFF006876,
                                      ).withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'PKR ${(workshop['price'] as double? ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  workshop['description'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.access_time,
                        '${workshop['duration'] as int? ?? 0}h',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.people,
                        '$currentParticipants/$maxParticipants',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.location_on,
                        workshop['location'] as String? ?? '',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.school,
                        workshop['instructor'] as String? ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailSection(
                  Icons.calendar_month,
                  'Schedule',
                  workshop['schedule'] as String? ?? '',
                ),
                if (workshop['prerequisites'] != null &&
                    (workshop['prerequisites'] as String).isNotEmpty)
                  _buildDetailSection(
                    Icons.book,
                    'Prerequisites',
                    workshop['prerequisites'] as String,
                  ),
                if (workshop['materials'] != null &&
                    (workshop['materials'] as String).isNotEmpty)
                  _buildDetailSection(
                    Icons.check_circle,
                    'Materials Included',
                    workshop['materials'] as String,
                  ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isFull
                          ? Colors.red.withValues(alpha: 0.1)
                          : const Color(0xFF90D26D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFull
                          ? 'Workshop Full - $currentParticipants/$maxParticipants registered'
                          : '$spotsRemaining spots remaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFull ? Colors.red : const Color(0xFF90D26D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isFull
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              '/workshop-registration',
                              arguments: {
                                'workshop': workshop,
                                'userSession': {
                                  'id': 1,
                                  'email': 'user@example.com',
                                },
                              },
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isFull ? 'Workshop Full' : 'Register Now',
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
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF006876).withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF006876).withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFF006876).withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF006876).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF006876).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
