import 'package:cloud_firestore/cloud_firestore.dart';

/// Workshop Creator model - Authorized users who can create workshops
class WorkshopCreatorModel {
  final String? id;
  final String userId; // Reference to user in 'users' collection
  final String fullName;
  final String email;
  final String? specialty;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy; // Admin ID who authorized this creator

  WorkshopCreatorModel({
    this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.specialty,
    this.isActive = true,
    DateTime? createdAt,
    required this.createdBy,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from Firestore document
  factory WorkshopCreatorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkshopCreatorModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      specialty: data['specialty'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'specialty': specialty,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  /// Create a copy with updated fields
  WorkshopCreatorModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? specialty,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return WorkshopCreatorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
