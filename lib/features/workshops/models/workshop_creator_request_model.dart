import 'package:cloud_firestore/cloud_firestore.dart';

/// Workshop Creator Request model - User requests to become workshop creator
class WorkshopCreatorRequestModel {
  final String? id;
  final String userId; // User who is requesting
  final String fullName;
  final String email;
  final String? specialty;
  final String? message; // Optional message from user (legacy field)

  // New comprehensive form fields
  final String? workshopType; // Medical Training, Clinical Skills, etc.
  final String? workshopTopic; // Specific topic
  final String? workshopDescription; // Detailed description
  final String? expectedDuration; // 1-2 hours, 2-4 hours, etc.
  final String? expectedParticipants; // Expected number of attendees
  final String? teachingExperience; // Teaching credentials

  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? respondedBy; // Admin ID who approved/rejected
  final String? rejectionReason;

  WorkshopCreatorRequestModel({
    this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.specialty,
    this.message,
    this.workshopType,
    this.workshopTopic,
    this.workshopDescription,
    this.expectedDuration,
    this.expectedParticipants,
    this.teachingExperience,
    this.status = 'pending',
    DateTime? createdAt,
    this.respondedAt,
    this.respondedBy,
    this.rejectionReason,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from Firestore document
  factory WorkshopCreatorRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkshopCreatorRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      specialty: data['specialty'],
      message: data['message'],
      workshopType: data['workshopType'],
      workshopTopic: data['workshopTopic'],
      workshopDescription: data['workshopDescription'],
      expectedDuration: data['expectedDuration'],
      expectedParticipants: data['expectedParticipants'],
      teachingExperience: data['teachingExperience'],
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      respondedBy: data['respondedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'specialty': specialty,
      'message': message,
      'workshopType': workshopType,
      'workshopTopic': workshopTopic,
      'workshopDescription': workshopDescription,
      'expectedDuration': expectedDuration,
      'expectedParticipants': expectedParticipants,
      'teachingExperience': teachingExperience,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
      'respondedBy': respondedBy,
      'rejectionReason': rejectionReason,
    };
  }

  /// Create a copy with updated fields
  WorkshopCreatorRequestModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? specialty,
    String? message,
    String? workshopType,
    String? workshopTopic,
    String? workshopDescription,
    String? expectedDuration,
    String? expectedParticipants,
    String? teachingExperience,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? respondedBy,
    String? rejectionReason,
  }) {
    return WorkshopCreatorRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      message: message ?? this.message,
      workshopType: workshopType ?? this.workshopType,
      workshopTopic: workshopTopic ?? this.workshopTopic,
      workshopDescription: workshopDescription ?? this.workshopDescription,
      expectedDuration: expectedDuration ?? this.expectedDuration,
      expectedParticipants: expectedParticipants ?? this.expectedParticipants,
      teachingExperience: teachingExperience ?? this.teachingExperience,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
