import 'package:cloud_firestore/cloud_firestore.dart';

/// Purchased Add-on model
class PurchasedAddonModel {
  final String? id;
  final String userId;
  final String addonCode;
  final String addonName;
  final double price;
  final String suiteType;
  final int quantity;
  final bool isUsed;
  final DateTime? usedAt;
  final String? usedInBookingId;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final String type; // 'time-extension', 'material', 'other'
  final int durationMins;

  PurchasedAddonModel({
    this.id,
    required this.userId,
    required this.addonCode,
    required this.addonName,
    required this.price,
    required this.suiteType,
    this.quantity = 1,
    this.isUsed = false,
    this.usedAt,
    this.usedInBookingId,
    DateTime? purchasedAt,
    this.expiresAt,
    this.type = 'other',
    this.durationMins = 30,
  }) : purchasedAt = purchasedAt ?? DateTime.now();

  /// Create PurchasedAddonModel from Firestore document
  factory PurchasedAddonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchasedAddonModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      addonCode: data['addonCode'] ?? '',
      addonName: data['addonName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      suiteType: data['suiteType'] ?? '',
      quantity: data['quantity'] ?? 1,
      isUsed: data['isUsed'] ?? false,
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] as Timestamp).toDate()
          : null,
      usedInBookingId: data['usedInBookingId'],
      purchasedAt: data['purchasedAt'] != null
          ? (data['purchasedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      type: data['type'] ?? 'other',
      durationMins: data['durationMins'] ?? 30,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'addonCode': addonCode,
      'addonName': addonName,
      'price': price,
      'suiteType': suiteType,
      'quantity': quantity,
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'usedInBookingId': usedInBookingId,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'type': type,
      'durationMins': durationMins,
    };
  }

  /// Create a copy with updated fields
  PurchasedAddonModel copyWith({
    String? id,
    String? userId,
    String? addonCode,
    String? addonName,
    double? price,
    String? suiteType,
    int? quantity,
    bool? isUsed,
    DateTime? usedAt,
    String? usedInBookingId,
    DateTime? purchasedAt,
    DateTime? expiresAt,
    String? type,
    int? durationMins,
  }) {
    return PurchasedAddonModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addonCode: addonCode ?? this.addonCode,
      addonName: addonName ?? this.addonName,
      price: price ?? this.price,
      suiteType: suiteType ?? this.suiteType,
      quantity: quantity ?? this.quantity,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
      usedInBookingId: usedInBookingId ?? this.usedInBookingId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      type: type ?? this.type,
      durationMins: durationMins ?? this.durationMins,
    );
  }
}
