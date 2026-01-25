import 'package:cloud_firestore/cloud_firestore.dart';

/// Workshop model for medical training/certification programs
class WorkshopModel {
  final String? id;
  final String title;
  final String description;
  final String provider; // e.g., "AHA", "American Heart Association"
  final String certificationType; // e.g., "BLS", "ACLS", "PALS"
  final int duration; // Duration in hours
  final double price;
  final int maxParticipants;
  final int currentParticipants;
  final String location;
  final String? instructor;
  final String? prerequisites;
  final String? materials; // What's included/provided
  final String schedule; // e.g., "September 15, 2025 - 9:00 AM to 5:00 PM"
  final String? bannerImage; // Workshop banner/cover image URL
  final String? syllabusPdf; // PDF syllabus file URL
  final DateTime? startDate;
  final DateTime? endDate;
  final String? startTime; // "09:00"
  final String? endTime; // "17:00"
  final bool isActive;
  final String createdBy; // Workshop creator/organizer ID
  final DateTime createdAt;

  // 🛡️ PHASE 1: Admin Permission & Payment System
  final String
  permissionStatus; // 'pending_admin', 'approved_by_admin', 'rejected', 'expired'
  final double? adminSetFee; // Dynamic fee set by admin (PKR)
  final DateTime?
  permissionGrantedAt; // Timestamp when admin approves (starts 2-hour countdown)
  final String? rejectionReason; // Reason provided when admin rejects proposal
  final bool
  isCreationFeePaid; // Whether doctor has paid the admin-set creation fee

  // 💰 PHASE 4: Workshop Payout System
  final String payoutStatus; // 'none', 'requested', 'processing', 'released'
  final bool isPayoutRequested; // Whether doctor has requested payout
  final DateTime? payoutRequestedAt; // When doctor requested payout
  final DateTime? payoutReleasedAt; // When admin released payout
  final double? totalRevenue; // Total collected from paid participants
  final double? adminCommission; // Admin's share (e.g., 20% of totalRevenue)
  final double? doctorPayout; // Doctor's net amount after commission

  WorkshopModel({
    this.id,
    required this.title,
    required this.description,
    required this.provider,
    required this.certificationType,
    required this.duration,
    required this.price,
    required this.maxParticipants,
    this.currentParticipants = 0,
    required this.location,
    this.instructor,
    this.prerequisites,
    this.materials,
    required this.schedule,
    this.bannerImage,
    this.syllabusPdf,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isActive = false, // NOT live until creation fee is paid
    required this.createdBy,
    DateTime? createdAt,
    this.permissionStatus = 'pending_admin',
    this.adminSetFee,
    this.permissionGrantedAt,
    this.rejectionReason,
    this.isCreationFeePaid = false,
    this.payoutStatus = 'none',
    this.isPayoutRequested = false,
    this.payoutRequestedAt,
    this.payoutReleasedAt,
    this.totalRevenue,
    this.adminCommission,
    this.doctorPayout,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create WorkshopModel from Firestore document
  factory WorkshopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkshopModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      provider: data['provider'] ?? '',
      certificationType: data['certificationType'] ?? '',
      duration: data['duration'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      location: data['location'] ?? '',
      instructor: data['instructor'],
      prerequisites: data['prerequisites'],
      materials: data['materials'],
      schedule: data['schedule'] ?? '',
      bannerImage: data['bannerImage'],
      syllabusPdf: data['syllabusPdf'],
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      startTime: data['startTime'],
      endTime: data['endTime'],
      isActive: data['isActive'] ?? false, // Default false until payment
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      permissionStatus: data['permissionStatus'] ?? 'pending_admin',
      adminSetFee: data['adminSetFee']?.toDouble(),
      permissionGrantedAt: data['permissionGrantedAt'] != null
          ? (data['permissionGrantedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
      isCreationFeePaid: data['isCreationFeePaid'] ?? false,
      payoutStatus: data['payoutStatus'] ?? 'none',
      isPayoutRequested: data['isPayoutRequested'] ?? false,
      payoutRequestedAt: data['payoutRequestedAt'] != null
          ? (data['payoutRequestedAt'] as Timestamp).toDate()
          : null,
      payoutReleasedAt: data['payoutReleasedAt'] != null
          ? (data['payoutReleasedAt'] as Timestamp).toDate()
          : null,
      totalRevenue: data['totalRevenue']?.toDouble(),
      adminCommission: data['adminCommission']?.toDouble(),
      doctorPayout: data['doctorPayout']?.toDouble(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'provider': provider,
      'certificationType': certificationType,
      'duration': duration,
      'price': price,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'location': location,
      'instructor': instructor,
      'prerequisites': prerequisites,
      'materials': materials,
      'schedule': schedule,
      'bannerImage': bannerImage,
      'syllabusPdf': syllabusPdf,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'permissionStatus': permissionStatus,
      'adminSetFee': adminSetFee,
      'permissionGrantedAt': permissionGrantedAt != null
          ? Timestamp.fromDate(permissionGrantedAt!)
          : null,
      'rejectionReason': rejectionReason,
      'isCreationFeePaid': isCreationFeePaid,
      'payoutStatus': payoutStatus,
      'isPayoutRequested': isPayoutRequested,
      'payoutRequestedAt': payoutRequestedAt != null
          ? Timestamp.fromDate(payoutRequestedAt!)
          : null,
      'payoutReleasedAt': payoutReleasedAt != null
          ? Timestamp.fromDate(payoutReleasedAt!)
          : null,
      'totalRevenue': totalRevenue,
      'adminCommission': adminCommission,
      'doctorPayout': doctorPayout,
    };
  }

  /// Create a copy with updated fields
  WorkshopModel copyWith({
    String? id,
    String? title,
    String? description,
    String? provider,
    String? certificationType,
    int? duration,
    double? price,
    int? maxParticipants,
    int? currentParticipants,
    String? location,
    String? instructor,
    String? prerequisites,
    String? materials,
    String? schedule,
    String? bannerImage,
    String? syllabusPdf,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    String? permissionStatus,
    double? adminSetFee,
    DateTime? permissionGrantedAt,
    String? rejectionReason,
    bool? isCreationFeePaid,
    String? payoutStatus,
    bool? isPayoutRequested,
    DateTime? payoutRequestedAt,
    DateTime? payoutReleasedAt,
    double? totalRevenue,
    double? adminCommission,
    double? doctorPayout,
  }) {
    return WorkshopModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      provider: provider ?? this.provider,
      certificationType: certificationType ?? this.certificationType,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      location: location ?? this.location,
      instructor: instructor ?? this.instructor,
      prerequisites: prerequisites ?? this.prerequisites,
      materials: materials ?? this.materials,
      schedule: schedule ?? this.schedule,
      bannerImage: bannerImage ?? this.bannerImage,
      syllabusPdf: syllabusPdf ?? this.syllabusPdf,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      adminSetFee: adminSetFee ?? this.adminSetFee,
      permissionGrantedAt: permissionGrantedAt ?? this.permissionGrantedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isCreationFeePaid: isCreationFeePaid ?? this.isCreationFeePaid,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      isPayoutRequested: isPayoutRequested ?? this.isPayoutRequested,
      payoutRequestedAt: payoutRequestedAt ?? this.payoutRequestedAt,
      payoutReleasedAt: payoutReleasedAt ?? this.payoutReleasedAt,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      adminCommission: adminCommission ?? this.adminCommission,
      doctorPayout: doctorPayout ?? this.doctorPayout,
    );
  }
}
