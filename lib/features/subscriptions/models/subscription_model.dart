import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription model for monthly/hourly packages
class SubscriptionModel {
  final String? id;
  final String userId;
  final String suiteType;
  final String packageType; // 'starter', 'advanced', 'professional'
  final double monthlyPrice;
  final int hoursIncluded;
  final DateTime startDate;
  final DateTime endDate;
  final String? paymentMethod;
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? paymentId;
  final double price;
  final int hours;
  final String status; // 'active', 'inactive', 'expired'
  final bool isActive;
  final String type; // 'monthly' or 'hourly'
  final int? slotsRemaining;
  final String? specialty;
  final String? roomType;
  final double? baseRate;
  final String? details;
  final int hoursUsed;
  final int? remainingHours;
  final DateTime createdAt;

  SubscriptionModel({
    this.id,
    required this.userId,
    required this.suiteType,
    required this.packageType,
    required this.monthlyPrice,
    required this.hoursIncluded,
    required this.startDate,
    required this.endDate,
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.paymentId,
    required this.price,
    required this.hours,
    this.status = 'active',
    this.isActive = true,
    this.type = 'monthly',
    this.slotsRemaining,
    this.specialty,
    this.roomType,
    this.baseRate,
    this.details,
    this.hoursUsed = 0,
    this.remainingHours,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create SubscriptionModel from Firestore document
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      suiteType: data['suiteType'] ?? '',
      packageType: data['packageType'] ?? '',
      monthlyPrice: (data['monthlyPrice'] ?? 0).toDouble(),
      hoursIncluded: data['hoursIncluded'] ?? 0,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      paymentMethod: data['paymentMethod'],
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentId: data['paymentId'],
      price: (data['price'] ?? 0).toDouble(),
      hours: data['hours'] ?? 0,
      status: data['status'] ?? 'active',
      isActive: data['isActive'] ?? true,
      type: data['type'] ?? 'monthly',
      slotsRemaining: data['slotsRemaining'],
      specialty: data['specialty'],
      roomType: data['roomType'],
      baseRate: data['baseRate'] != null ? (data['baseRate']).toDouble() : null,
      details: data['details'],
      hoursUsed: data['hoursUsed'] ?? 0,
      remainingHours: data['remainingHours'],
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
      'packageType': packageType,
      'monthlyPrice': monthlyPrice,
      'hoursIncluded': hoursIncluded,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'price': price,
      'hours': hours,
      'status': status,
      'isActive': isActive,
      'type': type,
      'slotsRemaining': slotsRemaining,
      'specialty': specialty,
      'roomType': roomType,
      'baseRate': baseRate,
      'details': details,
      'hoursUsed': hoursUsed,
      'remainingHours': remainingHours,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? suiteType,
    String? packageType,
    double? monthlyPrice,
    int? hoursIncluded,
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentId,
    double? price,
    int? hours,
    String? status,
    bool? isActive,
    String? type,
    int? slotsRemaining,
    String? specialty,
    String? roomType,
    double? baseRate,
    String? details,
    int? hoursUsed,
    int? remainingHours,
    DateTime? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      suiteType: suiteType ?? this.suiteType,
      packageType: packageType ?? this.packageType,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      hoursIncluded: hoursIncluded ?? this.hoursIncluded,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      price: price ?? this.price,
      hours: hours ?? this.hours,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      slotsRemaining: slotsRemaining ?? this.slotsRemaining,
      specialty: specialty ?? this.specialty,
      roomType: roomType ?? this.roomType,
      baseRate: baseRate ?? this.baseRate,
      details: details ?? this.details,
      hoursUsed: hoursUsed ?? this.hoursUsed,
      remainingHours: remainingHours ?? this.remainingHours,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
