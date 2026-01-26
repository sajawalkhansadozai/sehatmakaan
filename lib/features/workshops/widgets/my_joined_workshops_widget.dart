import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget to display user's joined workshops in a card format
class MyJoinedWorkshopsWidget extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userSession;

  const MyJoinedWorkshopsWidget({
    super.key,
    required this.userId,
    required this.userSession,
  });

  @override
  State<MyJoinedWorkshopsWidget> createState() =>
      _MyJoinedWorkshopsWidgetState();
}

class _MyJoinedWorkshopsWidgetState extends State<MyJoinedWorkshopsWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<List<Map<String, dynamic>>> _joinedWorkshopsStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _joinedWorkshopsStream = _firestore
        .collection('workshop_registrations')
        .where('userId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('confirmedAt', descending: true)
        .snapshots()
        .asyncMap((registrationSnapshot) async {
          final List<Map<String, dynamic>> joinedWorkshops = [];

          for (final regDoc in registrationSnapshot.docs) {
            final regData = regDoc.data();
            final workshopId = regData['workshopId'] as String;

            final workshopDoc = await _firestore
                .collection('workshops')
                .doc(workshopId)
                .get();

            if (workshopDoc.exists) {
              final workshopData = workshopDoc.data() ?? {};
              workshopData['id'] = workshopDoc.id;
              workshopData['registrationData'] = regData;
              joinedWorkshops.add(workshopData);
            }
          }

          return joinedWorkshops;
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _joinedWorkshopsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final joinedWorkshops = snapshot.data ?? [];

        if (joinedWorkshops.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildJoinedWorkshopsSection(joinedWorkshops);
      },
    );
  }

  /// Main section header + list of joined workshops
  Widget _buildJoinedWorkshopsSection(
    List<Map<String, dynamic>> joinedWorkshops,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF90D26D), Color(0xFF70B24D)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF90D26D).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'My Joined Workshops',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF90D26D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '[${joinedWorkshops.length}]',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF90D26D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...joinedWorkshops.map((workshop) => _buildCard(workshop)),
        ],
      ),
    );
  }

  /// Individual workshop card
  Widget _buildCard(Map<String, dynamic> workshop) {
    final title = workshop['title'] as String? ?? 'Workshop';
    final price = (workshop['price'] as num?)?.toDouble() ?? 0;
    final desc = workshop['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF90D26D).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF90D26D), Color(0xFF70B24D)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Confirmed',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PKR ${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: const Color(0xFF90D26D).withValues(alpha: 0.1),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/workshop-detail',
                    arguments: workshop,
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF90D26D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
