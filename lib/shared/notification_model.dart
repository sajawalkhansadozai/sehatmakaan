import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification model for user notifications
class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final String
  type; // 'booking_cancelled', 'booking_refunded', 'booking_reminder', 'booking_confirmed', 'system', 'info'
  final String? relatedBookingId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedBookingId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      relatedBookingId: data['relatedBookingId'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedBookingId': relatedBookingId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? relatedBookingId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedBookingId: relatedBookingId ?? this.relatedBookingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
