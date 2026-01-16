import 'package:cloud_firestore/cloud_firestore.dart';

/// User/Doctor Model
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final int age;
  final String gender;
  final String pmdcNumber;
  final String cnicNumber;
  final String phoneNumber;
  final String specialty;
  final int yearsOfExperience;
  final bool isVerified;
  final bool isApproved;
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.age,
    required this.gender,
    required this.pmdcNumber,
    required this.cnicNumber,
    required this.phoneNumber,
    required this.specialty,
    required this.yearsOfExperience,
    this.isVerified = false,
    this.isApproved = false,
    this.status = 'pending',
    this.rejectionReason,
    this.approvedAt,
    this.rejectedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      username: data['username'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      pmdcNumber: data['pmdcNumber'] ?? '',
      cnicNumber: data['cnicNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      specialty: data['specialty'] ?? '',
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
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
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'username': username,
      'age': age,
      'gender': gender,
      'pmdcNumber': pmdcNumber,
      'cnicNumber': cnicNumber,
      'phoneNumber': phoneNumber,
      'specialty': specialty,
      'yearsOfExperience': yearsOfExperience,
      'isVerified': isVerified,
      'isApproved': isApproved,
      'status': status,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt,
      'rejectedAt': rejectedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Admin Model
class AdminModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final DateTime? createdAt;

  AdminModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.role = 'admin',
    this.createdAt,
  });

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
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt,
    };
  }
}

/// Booking Model
class BookingModel {
  final String id;
  final String userId;
  final String suiteType; // dental, medical, aesthetic
  final DateTime bookingDate;
  final String timeSlot;
  final DateTime? startTime;
  final int durationMins;
  final double baseRate;
  final List<String> addons;
  final double totalAmount;
  final String status; // confirmed, cancelled, completed
  final String? cancellationType; // user, admin, refund, no-refund
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentId;
  final String? subscriptionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.suiteType,
    required this.bookingDate,
    required this.timeSlot,
    this.startTime,
    required this.durationMins,
    required this.baseRate,
    this.addons = const [],
    required this.totalAmount,
    this.status = 'confirmed',
    this.cancellationType,
    this.paymentMethod = 'payfast',
    this.paymentStatus = 'pending',
    this.paymentId,
    this.subscriptionId,
    this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      suiteType: data['suiteType'] ?? '',
      bookingDate: data['bookingDate'] != null
          ? (data['bookingDate'] as Timestamp).toDate()
          : DateTime.now(),
      timeSlot: data['timeSlot'] ?? '',
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : null,
      durationMins: data['durationMins'] ?? 60,
      baseRate: (data['baseRate'] ?? 0).toDouble(),
      addons: List<String>.from(data['addons'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'confirmed',
      cancellationType: data['cancellationType'],
      paymentMethod: data['paymentMethod'] ?? 'payfast',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentId: data['paymentId'],
      subscriptionId: data['subscriptionId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'suiteType': suiteType,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'timeSlot': timeSlot,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
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
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Workshop Model
class WorkshopModel {
  final String id;
  final String title;
  final String description;
  final String provider;
  final String certificationType;
  final int duration; // in hours
  final double price;
  final int maxParticipants;
  final int currentParticipants;
  final String location;
  final String? instructor;
  final String? prerequisites;
  final String? materials;
  final String schedule;
  final String? bannerImage;
  final String? syllabusPdf;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;
  final bool isActive;
  final String createdBy; // Workshop creator/organizer ID
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkshopModel({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    required this.certificationType,
    required this.duration,
    required this.price,
    required this.maxParticipants,
    this.currentParticipants = 0,
    required this.location,
    this.instructor,
    this.prerequisites,
    this.materials,
    required this.schedule,
    this.bannerImage,
    this.syllabusPdf,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isActive = true,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkshopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkshopModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      provider: data['provider'] ?? '',
      certificationType: data['certificationType'] ?? '',
      duration: data['duration'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      location: data['location'] ?? '',
      instructor: data['instructor'],
      prerequisites: data['prerequisites'],
      materials: data['materials'],
      schedule: data['schedule'] ?? '',
      bannerImage: data['bannerImage'],
      syllabusPdf: data['syllabusPdf'],
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      startTime: data['startTime'],
      endTime: data['endTime'],
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'provider': provider,
      'certificationType': certificationType,
      'duration': duration,
      'price': price,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'location': location,
      'instructor': instructor,
      'prerequisites': prerequisites,
      'materials': materials,
      'schedule': schedule,
      'bannerImage': bannerImage,
      'syllabusPdf': syllabusPdf,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Workshop Registration Model
class WorkshopRegistrationModel {
  final String id;
  final String userId;
  final String workshopId;
  final String name;
  final String email;
  final String cnicNumber;
  final String phoneNumber;
  final String profession;
  final String address;
  final String? registrationNumber;
  final String status; // pending, confirmed, rejected
  final String paymentStatus; // pending, paid, refunded
  final String paymentMethod;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkshopRegistrationModel({
    required this.id,
    required this.userId,
    required this.workshopId,
    required this.name,
    required this.email,
    required this.cnicNumber,
    required this.phoneNumber,
    required this.profession,
    required this.address,
    this.registrationNumber,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.paymentMethod = 'payfast',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkshopRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkshopRegistrationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      workshopId: data['workshopId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      cnicNumber: data['cnicNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profession: data['profession'] ?? '',
      address: data['address'] ?? '',
      registrationNumber: data['registrationNumber'],
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'payfast',
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workshopId': workshopId,
      'name': name,
      'email': email,
      'cnicNumber': cnicNumber,
      'phoneNumber': phoneNumber,
      'profession': profession,
      'address': address,
      'registrationNumber': registrationNumber,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Notification Model
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // booking, subscription, workshop, system
  final String? relatedBookingId;
  final String? relatedWorkshopId;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedBookingId,
    this.relatedWorkshopId,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'system',
      relatedBookingId: data['relatedBookingId'],
      relatedWorkshopId: data['relatedWorkshopId'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedBookingId': relatedBookingId,
      'relatedWorkshopId': relatedWorkshopId,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
