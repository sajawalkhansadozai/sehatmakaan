import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for doctors/healthcare professionals
class UserModel {
  final String? id;
  final String fullName;
  final String email;
  final int age;
  final String gender;
  final String pmdcNumber;
  final String cnicNumber;
  final String phoneNumber;
  final String specialty;
  final int yearsOfExperience;
  final String? username;
  final bool isVerified;
  final bool isApproved;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.age,
    required this.gender,
    required this.pmdcNumber,
    required this.cnicNumber,
    required this.phoneNumber,
    required this.specialty,
    required this.yearsOfExperience,
    this.username,
    this.isVerified = false,
    this.isApproved = false,
    this.status = 'pending',
    this.rejectionReason,
    this.approvedAt,
    this.rejectedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      pmdcNumber: data['pmdcNumber'] ?? '',
      cnicNumber: data['cnicNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      specialty: data['specialty'] ?? '',
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      username: data['username'],
      isVerified: data['isVerified'] ?? false,
      isApproved: data['isApproved'] ?? false,
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: data['rejectedAt'] != null
          ? (data['rejectedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'age': age,
      'gender': gender,
      'pmdcNumber': pmdcNumber,
      'cnicNumber': cnicNumber,
      'phoneNumber': phoneNumber,
      'specialty': specialty,
      'yearsOfExperience': yearsOfExperience,
      'username': username,
      'isVerified': isVerified,
      'isApproved': isApproved,
      'status': status,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    int? age,
    String? gender,
    String? pmdcNumber,
    String? cnicNumber,
    String? phoneNumber,
    String? specialty,
    int? yearsOfExperience,
    String? username,
    bool? isVerified,
    bool? isApproved,
    String? status,
    String? rejectionReason,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      pmdcNumber: pmdcNumber ?? this.pmdcNumber,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialty: specialty ?? this.specialty,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      username: username ?? this.username,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
