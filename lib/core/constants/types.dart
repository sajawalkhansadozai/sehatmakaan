/// Suite Types
enum SuiteType {
  dental,
  medical,
  aesthetic;

  String get displayName {
    switch (this) {
      case SuiteType.dental:
        return 'Dental Suite';
      case SuiteType.medical:
        return 'Medical Suite';
      case SuiteType.aesthetic:
        return 'Aesthetic Suite';
    }
  }

  String get value {
    switch (this) {
      case SuiteType.dental:
        return 'dental';
      case SuiteType.medical:
        return 'medical';
      case SuiteType.aesthetic:
        return 'aesthetic';
    }
  }

  static SuiteType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'dental':
        return SuiteType.dental;
      case 'medical':
        return SuiteType.medical;
      case 'aesthetic':
        return SuiteType.aesthetic;
      default:
        throw ArgumentError('Invalid suite type: $value');
    }
  }
}

/// Package Types
enum PackageType {
  starter,
  advanced,
  professional;

  String get displayName {
    switch (this) {
      case PackageType.starter:
        return 'Starter';
      case PackageType.advanced:
        return 'Advanced';
      case PackageType.professional:
        return 'Professional';
    }
  }

  String get value {
    switch (this) {
      case PackageType.starter:
        return 'starter';
      case PackageType.advanced:
        return 'advanced';
      case PackageType.professional:
        return 'professional';
    }
  }

  static PackageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'starter':
        return PackageType.starter;
      case 'advanced':
        return PackageType.advanced;
      case 'professional':
        return PackageType.professional;
      default:
        throw ArgumentError('Invalid package type: $value');
    }
  }
}

/// Cart Item Types
enum CartItemType {
  package,
  addon,
  hourly;

  String get value {
    switch (this) {
      case CartItemType.package:
        return 'package';
      case CartItemType.addon:
        return 'addon';
      case CartItemType.hourly:
        return 'hourly';
    }
  }

  String get displayName {
    switch (this) {
      case CartItemType.package:
        return 'Package';
      case CartItemType.addon:
        return 'Add-on';
      case CartItemType.hourly:
        return 'Hourly';
    }
  }
}

/// Addon Model
class Addon {
  final String name;
  final double price;
  final String code;
  final String description;
  final List<String>? applicableFor;
  final PackageType? minPackage;

  Addon({
    required this.name,
    required this.price,
    required this.code,
    this.description = '',
    this.applicableFor,
    this.minPackage,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'code': code,
      'description': description,
      'applicableFor': applicableFor,
      'minPackage': minPackage?.value,
    };
  }

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      code: json['code'] as String,
      applicableFor: json['applicableFor'] != null
          ? List<String>.from(json['applicableFor'])
          : null,
      minPackage: json['minPackage'] != null
          ? PackageType.fromString(json['minPackage'])
          : null,
    );
  }
}

/// Suite Model
class Suite {
  final SuiteType type;
  final String name;
  final double baseRate;
  final double? specialistRate;
  final String description;
  final List<String> features;
  final String icon;

  Suite({
    required this.type,
    required this.name,
    required this.baseRate,
    this.specialistRate,
    required this.description,
    required this.features,
    required this.icon,
  });
}

/// Package Model
class Package {
  final PackageType type;
  final String name;
  final double price;
  final int hours;
  final List<String> features;
  final bool popular;

  Package({
    required this.type,
    required this.name,
    required this.price,
    required this.hours,
    required this.features,
    this.popular = false,
  });
}

/// Cart Item Model
class CartItem {
  final String id;
  final CartItemType type;
  final String name;
  final double price;
  final int quantity;
  final SuiteType? suiteType;
  final PackageType? packageType;
  final int? hours;
  final String? code;
  final String? description;
  final String? specialty;
  final String? roomType;
  final String? details;

  CartItem({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    required this.quantity,
    this.suiteType,
    this.packageType,
    this.hours,
    this.code,
    this.description,
    this.specialty,
    this.roomType,
    this.details,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? id,
    CartItemType? type,
    String? name,
    double? price,
    int? quantity,
    SuiteType? suiteType,
    PackageType? packageType,
    int? hours,
    String? code,
    String? description,
    String? specialty,
    String? roomType,
    String? details,
  }) {
    return CartItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      suiteType: suiteType ?? this.suiteType,
      packageType: packageType ?? this.packageType,
      hours: hours ?? this.hours,
      code: code ?? this.code,
      description: description ?? this.description,
      specialty: specialty ?? this.specialty,
      roomType: roomType ?? this.roomType,
      details: details ?? this.details,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      type: CartItemType.values.firstWhere(
        (e) => e.toString() == 'CartItemType.${json['type']}',
        orElse: () => CartItemType.package,
      ),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      suiteType: json['suiteType'] != null
          ? SuiteType.fromString(json['suiteType'] as String)
          : null,
      packageType: json['packageType'] != null
          ? PackageType.values.firstWhere(
              (e) => e.toString() == 'PackageType.${json['packageType']}',
              orElse: () => PackageType.starter,
            )
          : null,
      hours: json['hours'] as int?,
      code: json['code'] as String?,
      description: json['description'] as String?,
      specialty: json['specialty'] as String?,
      roomType: json['roomType'] as String?,
      details: json['details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (suiteType != null) 'suiteType': suiteType!.value,
      if (packageType != null)
        'packageType': packageType.toString().split('.').last,
      if (hours != null) 'hours': hours,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (specialty != null) 'specialty': specialty,
      if (roomType != null) 'roomType': roomType,
      if (details != null) 'details': details,
    };
  }
}

/// Quick Booking Shortcut Model
class QuickBookingShortcut {
  final String id;
  final String name;
  final String duration;
  final double price;
  final SuiteType suiteType;
  final String specialty;
  final int hours;
  final String icon;
  final String description;
  final bool popular;

  QuickBookingShortcut({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    required this.suiteType,
    required this.specialty,
    required this.hours,
    required this.icon,
    required this.description,
    required this.popular,
  });
}
