import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking model for suite reservations
class BookingModel {
  final String? id;
  final String userId;
  final String suiteType; // 'dental', 'medical', 'aesthetic'
  final String bookingDate;
  final String timeSlot;
  final String? startTime; // "14:00"
  final int durationMins;
  final double baseRate;
  final String? addons; // JSON string of selected addons
  final double totalAmount;
  final String status; // 'confirmed', 'completed', 'cancelled'
  final String? cancellationType; // 'refund', 'no-refund'
  final String? paymentMethod;
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? paymentId;
  final String? subscriptionId;
  final int rescheduleCount; // Number of times booking has been rescheduled
  final DateTime createdAt;

  BookingModel({
    this.id,
    required this.userId,
    required this.suiteType,
    required this.bookingDate,
    required this.timeSlot,
    this.startTime,
    this.durationMins = 60,
    required this.baseRate,
    this.addons,
    required this.totalAmount,
    this.status = 'confirmed',
    this.cancellationType,
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.paymentId,
    this.subscriptionId,
    this.rescheduleCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create BookingModel from Firestore document
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      suiteType: data['suiteType'] ?? '',
      bookingDate: data['bookingDate'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      startTime: data['startTime'],
      durationMins: data['durationMins'] ?? 60,
      baseRate: (data['baseRate'] ?? 0).toDouble(),
      addons: data['addons'],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'confirmed',
      cancellationType: data['cancellationType'],
      paymentMethod: data['paymentMethod'],
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentId: data['paymentId'],
      subscriptionId: data['subscriptionId'],
      rescheduleCount: data['rescheduleCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'suiteType': suiteType,
      'bookingDate': bookingDate,
      'timeSlot': timeSlot,
      'startTime': startTime,
      'durationMins': durationMins,
      'baseRate': baseRate,
      'addons': addons,
      'totalAmount': totalAmount,
      'status': status,
      'cancellationType': cancellationType,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'subscriptionId': subscriptionId,
      'rescheduleCount': rescheduleCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  BookingModel copyWith({
    String? id,
    String? userId,
    String? suiteType,
    String? bookingDate,
    String? timeSlot,
    String? startTime,
    int? durationMins,
    double? baseRate,
    String? addons,
    double? totalAmount,
    String? status,
    String? cancellationType,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentId,
    String? subscriptionId,
    int? rescheduleCount,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      suiteType: suiteType ?? this.suiteType,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      startTime: startTime ?? this.startTime,
      durationMins: durationMins ?? this.durationMins,
      baseRate: baseRate ?? this.baseRate,
      addons: addons ?? this.addons,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      cancellationType: cancellationType ?? this.cancellationType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
