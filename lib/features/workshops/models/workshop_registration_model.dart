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
    };
  }
}
