import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin model for system administrators
class AdminModel {
  final String? id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final DateTime createdAt;

  AdminModel({
    this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.role = 'admin',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create AdminModel from Firestore document
  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'admin',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  AdminModel copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return AdminModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
