import 'package:cloud_firestore/cloud_firestore.dart';

/// Pricing Configuration Model for centralized price management
class PricingConfig {
  final String? id;

  // Suite Base Rates (Hourly)
  final double dentalBaseRate;
  final double dentalSpecialistRate;
  final double medicalBaseRate;
  final double medicalSpecialistRate;
  final double aestheticBaseRate;
  final double aestheticSpecialistRate;

  // Monthly Package Prices - Dental
  final double dentalStarterPrice;
  final double dentalAdvancedPrice;
  final double dentalProfessionalPrice;

  // Monthly Package Prices - Medical
  final double medicalStarterPrice;
  final double medicalAdvancedPrice;
  final double medicalProfessionalPrice;

  // Monthly Package Prices - Aesthetic
  final double aestheticStarterPrice;
  final double aestheticAdvancedPrice;
  final double aestheticProfessionalPrice;

  // Monthly Add-ons
  final double extra10HoursPrice;
  final double dedicatedLockerPrice;
  final double clinicalAssistantPrice;
  final double socialMediaHighlightPrice;

  // Hourly Add-ons
  final double dentalAssistantPrice;
  final double medicalNursePrice;
  final double intraoralXrayPrice;
  final double priorityBookingPrice;
  final double extendedHoursPrice;

  final DateTime? updatedAt;
  final String? updatedBy;

  PricingConfig({
    this.id,
    required this.dentalBaseRate,
    required this.dentalSpecialistRate,
    required this.medicalBaseRate,
    required this.medicalSpecialistRate,
    required this.aestheticBaseRate,
    required this.aestheticSpecialistRate,
    required this.dentalStarterPrice,
    required this.dentalAdvancedPrice,
    required this.dentalProfessionalPrice,
    required this.medicalStarterPrice,
    required this.medicalAdvancedPrice,
    required this.medicalProfessionalPrice,
    required this.aestheticStarterPrice,
    required this.aestheticAdvancedPrice,
    required this.aestheticProfessionalPrice,
    required this.extra10HoursPrice,
    required this.dedicatedLockerPrice,
    required this.clinicalAssistantPrice,
    required this.socialMediaHighlightPrice,
    required this.dentalAssistantPrice,
    required this.medicalNursePrice,
    required this.intraoralXrayPrice,
    required this.priorityBookingPrice,
    required this.extendedHoursPrice,
    this.updatedAt,
    this.updatedBy,
  });

  /// Create from Firestore document
  factory PricingConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PricingConfig(
      id: doc.id,
      dentalBaseRate: (data['dentalBaseRate'] ?? 1500).toDouble(),
      dentalSpecialistRate: (data['dentalSpecialistRate'] ?? 3000).toDouble(),
      medicalBaseRate: (data['medicalBaseRate'] ?? 2000).toDouble(),
      medicalSpecialistRate: (data['medicalSpecialistRate'] ?? 0).toDouble(),
      aestheticBaseRate: (data['aestheticBaseRate'] ?? 3000).toDouble(),
      aestheticSpecialistRate: (data['aestheticSpecialistRate'] ?? 0)
          .toDouble(),
      dentalStarterPrice: (data['dentalStarterPrice'] ?? 25000).toDouble(),
      dentalAdvancedPrice: (data['dentalAdvancedPrice'] ?? 30000).toDouble(),
      dentalProfessionalPrice: (data['dentalProfessionalPrice'] ?? 35000)
          .toDouble(),
      medicalStarterPrice: (data['medicalStarterPrice'] ?? 20000).toDouble(),
      medicalAdvancedPrice: (data['medicalAdvancedPrice'] ?? 25000).toDouble(),
      medicalProfessionalPrice: (data['medicalProfessionalPrice'] ?? 30000)
          .toDouble(),
      aestheticStarterPrice: (data['aestheticStarterPrice'] ?? 30000)
          .toDouble(),
      aestheticAdvancedPrice: (data['aestheticAdvancedPrice'] ?? 35000)
          .toDouble(),
      aestheticProfessionalPrice: (data['aestheticProfessionalPrice'] ?? 40000)
          .toDouble(),
      extra10HoursPrice: (data['extra10HoursPrice'] ?? 10000).toDouble(),
      dedicatedLockerPrice: (data['dedicatedLockerPrice'] ?? 2000).toDouble(),
      clinicalAssistantPrice: (data['clinicalAssistantPrice'] ?? 5000)
          .toDouble(),
      socialMediaHighlightPrice: (data['socialMediaHighlightPrice'] ?? 3000)
          .toDouble(),
      dentalAssistantPrice: (data['dentalAssistantPrice'] ?? 500).toDouble(),
      medicalNursePrice: (data['medicalNursePrice'] ?? 500).toDouble(),
      intraoralXrayPrice: (data['intraoralXrayPrice'] ?? 300).toDouble(),
      priorityBookingPrice: (data['priorityBookingPrice'] ?? 500).toDouble(),
      extendedHoursPrice: (data['extendedHoursPrice'] ?? 500).toDouble(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      updatedBy: data['updatedBy'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'dentalBaseRate': dentalBaseRate,
      'dentalSpecialistRate': dentalSpecialistRate,
      'medicalBaseRate': medicalBaseRate,
      'medicalSpecialistRate': medicalSpecialistRate,
      'aestheticBaseRate': aestheticBaseRate,
      'aestheticSpecialistRate': aestheticSpecialistRate,
      'dentalStarterPrice': dentalStarterPrice,
      'dentalAdvancedPrice': dentalAdvancedPrice,
      'dentalProfessionalPrice': dentalProfessionalPrice,
      'medicalStarterPrice': medicalStarterPrice,
      'medicalAdvancedPrice': medicalAdvancedPrice,
      'medicalProfessionalPrice': medicalProfessionalPrice,
      'aestheticStarterPrice': aestheticStarterPrice,
      'aestheticAdvancedPrice': aestheticAdvancedPrice,
      'aestheticProfessionalPrice': aestheticProfessionalPrice,
      'extra10HoursPrice': extra10HoursPrice,
      'dedicatedLockerPrice': dedicatedLockerPrice,
      'clinicalAssistantPrice': clinicalAssistantPrice,
      'socialMediaHighlightPrice': socialMediaHighlightPrice,
      'dentalAssistantPrice': dentalAssistantPrice,
      'medicalNursePrice': medicalNursePrice,
      'intraoralXrayPrice': intraoralXrayPrice,
      'priorityBookingPrice': priorityBookingPrice,
      'extendedHoursPrice': extendedHoursPrice,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  /// Create default pricing configuration
  static PricingConfig createDefault() {
    return PricingConfig(
      dentalBaseRate: 1500,
      dentalSpecialistRate: 3000,
      medicalBaseRate: 2000,
      medicalSpecialistRate: 0,
      aestheticBaseRate: 3000,
      aestheticSpecialistRate: 0,
      dentalStarterPrice: 25000,
      dentalAdvancedPrice: 30000,
      dentalProfessionalPrice: 35000,
      medicalStarterPrice: 20000,
      medicalAdvancedPrice: 25000,
      medicalProfessionalPrice: 30000,
      aestheticStarterPrice: 30000,
      aestheticAdvancedPrice: 35000,
      aestheticProfessionalPrice: 40000,
      extra10HoursPrice: 10000,
      dedicatedLockerPrice: 2000,
      clinicalAssistantPrice: 5000,
      socialMediaHighlightPrice: 3000,
      dentalAssistantPrice: 500,
      medicalNursePrice: 500,
      intraoralXrayPrice: 300,
      priorityBookingPrice: 500,
      extendedHoursPrice: 500,
    );
  }
}
