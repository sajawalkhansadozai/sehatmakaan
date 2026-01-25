import 'package:cloud_firestore/cloud_firestore.dart';

/// Workshop Registration model
class WorkshopRegistrationModel {
  final String? id;
  final String? userId; // Optional for anonymous registrations
  final String workshopId;
  final String name;
  final String email;
  final String cnicNumber;
  final String phoneNumber;
  final String profession;
  final String address;
  final DateTime registrationDate;
  final String? registrationNumber;
  final String
  status; // 'pending', 'confirmed', 'attended', 'missed', 'cancelled'
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;

  // 📜 NEW: Certificate generation for attended workshops
  final String? certificateUrl; // PDF certificate with QR code

  // ⏳ NEW: Seat locking mechanism (10-min reservation)
  final DateTime? seatLockedUntil; // Timestamp when seat lock expires

  // ✅ NEW: Attendance tracking for certification eligibility
  final DateTime? attendedAt; // When user marked as attended

  // 🔒 PHASE 3: Creator Approval System for Participants
  final String
  approvalStatus; // 'pending_creator', 'approved_by_creator', 'rejected'
  final DateTime? creatorApprovedAt; // When creator approved the request
  final String? rejectionReason; // Why creator rejected the request
  final DateTime? paymentDeadline; // currentTime + 1 hour when creator approves

  WorkshopRegistrationModel({
    this.id,
    this.userId,
    required this.workshopId,
    required this.name,
    required this.email,
    required this.cnicNumber,
    required this.phoneNumber,
    required this.profession,
    required this.address,
    DateTime? registrationDate,
    this.registrationNumber,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.paymentMethod,
    this.notes,
    DateTime? createdAt,
    this.certificateUrl,
    this.seatLockedUntil,
    this.attendedAt,
    this.approvalStatus = 'pending_creator',
    this.creatorApprovedAt,
    this.rejectionReason,
    this.paymentDeadline,
  }) : registrationDate = registrationDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  /// Create WorkshopRegistrationModel from Firestore document
  factory WorkshopRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkshopRegistrationModel(
      id: doc.id,
      userId: data['userId'],
      workshopId: data['workshopId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      cnicNumber: data['cnicNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profession: data['profession'] ?? '',
      address: data['address'] ?? '',
      registrationDate: data['registrationDate'] != null
          ? (data['registrationDate'] as Timestamp).toDate()
          : DateTime.now(),
      registrationNumber: data['registrationNumber'],
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentMethod: data['paymentMethod'],
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      certificateUrl: data['certificateUrl'],
      seatLockedUntil: data['seatLockedUntil'] != null
          ? (data['seatLockedUntil'] as Timestamp).toDate()
          : null,
      attendedAt: data['attendedAt'] != null
          ? (data['attendedAt'] as Timestamp).toDate()
          : null,
      approvalStatus: data['approvalStatus'] ?? 'pending_creator',
      creatorApprovedAt: data['creatorApprovedAt'] != null
          ? (data['creatorApprovedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
      paymentDeadline: data['paymentDeadline'] != null
          ? (data['paymentDeadline'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'workshopId': workshopId,
      'name': name,
      'email': email,
      'cnicNumber': cnicNumber,
      'phoneNumber': phoneNumber,
      'profession': profession,
      'address': address,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'registrationNumber': registrationNumber,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'certificateUrl': certificateUrl,
      'seatLockedUntil': seatLockedUntil != null
          ? Timestamp.fromDate(seatLockedUntil!)
          : null,
      'attendedAt': attendedAt != null ? Timestamp.fromDate(attendedAt!) : null,
      'approvalStatus': approvalStatus,
      'creatorApprovedAt': creatorApprovedAt != null
          ? Timestamp.fromDate(creatorApprovedAt!)
          : null,
      'rejectionReason': rejectionReason,
      'paymentDeadline': paymentDeadline != null
          ? Timestamp.fromDate(paymentDeadline!)
          : null,
    };
  }
}
