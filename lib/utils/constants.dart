import 'types.dart';

/// All Suites Available
class AppConstants {
  static final List<Suite> suites = [
    Suite(
      type: SuiteType.dental,
      name: 'Dental Suite',
      baseRate: 1500,
      specialistRate: 3000,
      description: 'Fully equipped dental operatory with modern instruments',
      features: [
        'Dental chair & basic instruments',
        'Ultrasonic scaler',
        'X-ray facilities available',
      ],
      icon: 'tooth',
    ),
    Suite(
      type: SuiteType.medical,
      name: 'Medical Suite',
      baseRate: 2000,
      description: 'Professional consultation room for general medicine',
      features: [
        'Examination table',
        'BP apparatus & weighing scale',
        'Prescription desk',
      ],
      icon: 'stethoscope',
    ),
    Suite(
      type: SuiteType.aesthetic,
      name: 'Aesthetic Suite',
      baseRate: 3000,
      description: 'Premium setup for cosmetic and aesthetic procedures',
      features: [
        'LED lighting system',
        'Professional trolley',
        'Photo-ready environment',
      ],
      icon: 'magic',
    ),
  ];

  /// Monthly Package Add-ons
  static final List<Addon> monthlyAddons = [
    Addon(
      name: 'Extra 10 Hour Block',
      price: 10000,
      code: 'extra_10_hours',
      applicableFor: ['all'],
    ),
    Addon(
      name: 'Dedicated Locker',
      price: 2000,
      code: 'dedicated_locker',
      applicableFor: ['all'],
    ),
    Addon(
      name: 'Clinical Assistant',
      price: 5000,
      code: 'clinical_assistant',
      applicableFor: ['all'],
    ),
    Addon(
      name: 'Social Media Highlight',
      price: 3000,
      code: 'social_media_highlight',
      applicableFor: ['all'],
      minPackage: PackageType.advanced,
    ),
  ];

  /// Hourly Package Add-ons
  static final List<Addon> hourlyAddons = [
    Addon(
      name: 'Dental Assistant Support (30 mins)',
      price: 500,
      code: 'dental_assistant_support',
      applicableFor: ['dental'],
    ),
    Addon(
      name: 'Assistant Support (30 mins)',
      price: 500,
      code: 'assistant_support',
      applicableFor: ['aesthetic'],
    ),
    Addon(
      name: 'Sterile Consumables Kit',
      price: 300,
      code: 'sterile_consumables',
      applicableFor: ['dental', 'aesthetic'],
    ),
    Addon(
      name: 'Instrument Kit Use',
      price: 1000,
      code: 'instruments',
      applicableFor: ['dental'],
    ),
    Addon(
      name: 'Intraoral X-ray Use',
      price: 500,
      code: 'xray',
      applicableFor: ['dental'],
    ),
    Addon(
      name: 'OPD nurse (30 mins)',
      price: 500,
      code: 'opd_nurse',
      applicableFor: ['medical'],
    ),
    Addon(
      name: 'Laboratory access',
      price: 1000,
      code: 'laboratory',
      applicableFor: ['all'],
    ),
    Addon(
      name: 'Conveyance',
      price: 6000,
      code: 'conveyance',
      applicableFor: ['all'],
    ),
  ];

  /// All Add-ons
  static List<Addon> get allAddons => [...monthlyAddons, ...hourlyAddons];

  /// Quick Booking Shortcuts
  static final List<QuickBookingShortcut> quickBookingShortcuts = [
    QuickBookingShortcut(
      id: 'general-dentist-1h',
      name: 'General Dentist',
      duration: '1 Hour',
      price: 1500,
      suiteType: SuiteType.dental,
      specialty: 'general-dentist',
      hours: 1,
      icon: '🦷',
      description: 'Quick 1-hour dental consultation',
      popular: true,
    ),
    QuickBookingShortcut(
      id: 'orthodontist-2h',
      name: 'Orthodontist',
      duration: '2 Hours',
      price: 6000,
      suiteType: SuiteType.dental,
      specialty: 'orthodontist',
      hours: 2,
      icon: '🦷',
      description: 'Orthodontic treatment session',
      popular: true,
    ),
    QuickBookingShortcut(
      id: 'general-physician-1h',
      name: 'General Physician',
      duration: '1 Hour',
      price: 2000,
      suiteType: SuiteType.medical,
      specialty: 'general-physician',
      hours: 1,
      icon: '🩺',
      description: 'Medical consultation',
      popular: true,
    ),
    QuickBookingShortcut(
      id: 'aesthetic-practitioner-1h',
      name: 'Aesthetic Practitioner',
      duration: '1 Hour',
      price: 3000,
      suiteType: SuiteType.aesthetic,
      specialty: 'aesthetic-practitioner',
      hours: 1,
      icon: '✨',
      description: 'Aesthetic procedure session',
      popular: false,
    ),
    QuickBookingShortcut(
      id: 'general-dentist-2h',
      name: 'General Dentist Extended',
      duration: '2 Hours',
      price: 3000,
      suiteType: SuiteType.dental,
      specialty: 'general-dentist',
      hours: 2,
      icon: '🦷',
      description: 'Extended dental treatment',
      popular: false,
    ),
    QuickBookingShortcut(
      id: 'general-physician-2h',
      name: 'General Physician Extended',
      duration: '2 Hours',
      price: 4000,
      suiteType: SuiteType.medical,
      specialty: 'general-physician',
      hours: 2,
      icon: '🩺',
      description: 'Extended medical consultation',
      popular: false,
    ),
  ];

  /// Packages by Suite Type
  static final Map<String, List<Package>> packages = {
    'dental': [
      Package(
        type: PackageType.starter,
        name: 'Starter',
        price: 25000,
        hours: 10,
        features: [
          '10 hours/month chair use (flexible slots)',
          'Basic tray setup',
          'Reception and assistant support',
        ],
      ),
      Package(
        type: PackageType.advanced,
        name: 'Advanced',
        price: 30000,
        hours: 20,
        features: [
          '20 hours/month',
          'Starter inclusions',
          'Priority weekend slots',
          'Profile wall branding',
        ],
        popular: true,
      ),
      Package(
        type: PackageType.professional,
        name: 'Professional',
        price: 35000,
        hours: 40,
        features: [
          '40 hours/month',
          'Advanced inclusions',
          'X-ray usage (2 per week)',
          'Consumable kits (4/month)',
          'Private locker',
          'Pick and drop service',
        ],
      ),
    ],
    'medical': [
      Package(
        type: PackageType.starter,
        name: 'Starter',
        price: 20000,
        hours: 10,
        features: [
          '10 hours/month',
          'Reception scheduling',
          'Basic diagnostic support (BP, thermometer, etc.)',
        ],
      ),
      Package(
        type: PackageType.advanced,
        name: 'Advanced',
        price: 25000,
        hours: 20,
        features: [
          '20 hours/month',
          'Digital prescription pad',
          'Profile board',
          'Medical assistant (4 sessions)',
        ],
        popular: true,
      ),
      Package(
        type: PackageType.professional,
        name: 'Professional',
        price: 30000,
        hours: 40,
        features: [
          '40 hours/month',
          'Extended consultation hours',
          '1 conference room slot/month',
          'EMR record access (optional)',
          'Pick and drop service',
        ],
      ),
    ],
    'aesthetic': [
      Package(
        type: PackageType.starter,
        name: 'Starter',
        price: 30000,
        hours: 10,
        features: [
          '10 hours/month',
          'LED light',
          'Basic trolley',
          'Shared assistant',
        ],
      ),
      Package(
        type: PackageType.advanced,
        name: 'Advanced',
        price: 35000,
        hours: 20,
        features: [
          '20 hours/month',
          'Premium dermachair',
          'Priority booking',
          'Branded profile on digital page',
        ],
        popular: true,
      ),
      Package(
        type: PackageType.professional,
        name: 'Professional',
        price: 40000,
        hours: 40,
        features: [
          '40 hours/month',
          '2 exclusive photo-shoot days',
          'Patient waiting material display',
          'Custom lighting setup',
          'Pick and drop service',
        ],
      ),
    ],
  };

  /// Time Slots (Normal working hours: 9AM - 5PM)
  static final List<String> timeSlots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  /// Priority Time Slots (6PM - 10PM, requires Priority Booking addon)
  static final List<String> priorityTimeSlots = [
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
  ];

  /// Extended Time Slots (Available with Extended Hours addon)
  static final List<String> extendedTimeSlots = ['23:00', '00:00'];

  /// Get all time slots including extended if addon is purchased
  static List<String> getAllTimeSlots({bool includeExtended = false}) {
    if (includeExtended) {
      return [...timeSlots, ...priorityTimeSlots, ...extendedTimeSlots];
    }
    return [...timeSlots, ...priorityTimeSlots];
  }

  /// Specialties
  static final List<Map<String, String>> specialties = [
    {'value': 'general-dentist', 'label': 'General Dentist'},
    {'value': 'endodontist', 'label': 'Endodontist'},
    {'value': 'orthodontist', 'label': 'Orthodontist'},
    {'value': 'maxillofacial', 'label': 'Maxillofacial Surgeon'},
    {'value': 'general-physician', 'label': 'General Physician'},
    {'value': 'aesthetic-practitioner', 'label': 'Aesthetic Practitioner'},
  ];

  /// Genders
  static final List<Map<String, String>> genders = [
    {'value': 'male', 'label': 'Male'},
    {'value': 'female', 'label': 'Female'},
    {'value': 'other', 'label': 'Other'},
  ];

  /// Payment Methods
  static final List<Map<String, String>> paymentMethods = [
    {'value': 'jazzcash', 'label': 'JazzCash', 'icon': 'mobile-alt'},
    {'value': 'easypaisa', 'label': 'EasyPaisa', 'icon': 'mobile-alt'},
    {'value': 'bank', 'label': 'Bank Transfer', 'icon': 'university'},
  ];

  /// Hourly Specialties (for specialty tips and recent bookings)
  static final List<Map<String, dynamic>> hourlySpecialties = [
    {'id': 'radiology', 'name': 'Radiology', 'icon': '📻'},
    {'id': 'physiotherapy', 'name': 'Physiotherapy', 'icon': '🏃'},
    {'id': 'pathology', 'name': 'Pathology', 'icon': '🔬'},
    {'id': 'ultrasound', 'name': 'Ultrasound', 'icon': '🔊'},
    {'id': 'ct-scan', 'name': 'CT Scan', 'icon': '🏥'},
    {'id': 'mri', 'name': 'MRI', 'icon': '🧲'},
    {'id': 'minor-surgery', 'name': 'Minor Surgery', 'icon': '🔪'},
    {'id': 'consultation', 'name': 'Consultation', 'icon': '👨‍⚕️'},
    {'id': 'general-dentist', 'name': 'General Dentist', 'icon': '🦷'},
    {'id': 'orthodontist', 'name': 'Orthodontist', 'icon': '🦷'},
    {'id': 'endodontist', 'name': 'Endodontist', 'icon': '🦷'},
    {'id': 'maxillofacial', 'name': 'Maxillofacial Surgeon', 'icon': '🦷'},
    {'id': 'general-physician', 'name': 'General Physician', 'icon': '🩺'},
    {
      'id': 'aesthetic-practitioner',
      'name': 'Aesthetic Practitioner',
      'icon': '✨',
    },
  ];

  /// Format currency to PKR format
  static String formatCurrency(double amount) {
    return 'R${amount.toStringAsFixed(2)}';
  }
}
