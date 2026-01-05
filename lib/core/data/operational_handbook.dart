/// Operational Handbook Data for Sehat Makaan
/// A comprehensive data structure containing all operational information
/// Extracted from: Operational Handbook (Booklet Small).pdf

class OperationalHandbook {
  // Company Information
  static const String companyName = 'Sehat Makaan';
  static const String tagline = 'A Guideline to Working at Sehat Makaan';
  static const String description =
      'Sehat Makaan is a co-working clinical space and healthcare facility rental service in Pakistan that provides fully-equipped medical, dental, and aesthetic practice spaces to healthcare practitioners on flexible hourly or monthly subscription basis.';

  // Welcome Message
  static const String welcomeMessage =
      'Welcome to Sehat Makaan — a collaborative space built on the values of trust, care, and innovation. Our vision is to empower you to practice with autonomy while enjoying the benefits of a well-equipped, patient-friendly environment.\n\n'
      'This handbook serves as your guide to understanding the operational workflows, facility guidelines, and professional standards that make Sehat Makaan a uniquely supportive clinical platform. Our commitment is not only to provide you with a physical space but also to foster a community of ethical, skilled, and compassionate healthcare providers.\n\n'
      'Thank you for choosing to be part of Sehat Makaan. Together, let\'s create a space where patients feel safe, and professionals feel inspired.';

  // Core Values
  static const List<CoreValue> coreValues = [
    CoreValue(
      title: 'Build The Team',
      description:
          'We believe great care is a team effort. At Sehat Makaan, we cultivate an inclusive and respectful environment where every practitioner, assistant, and support staff member plays a vital role. Collaboration, not competition, drives our culture — ensuring our patients benefit from a collective commitment to excellence.',
    ),
    CoreValue(
      title: 'Think Creative',
      description:
          'We encourage innovation in how care is delivered. From flexible booking models to patient experience design, Sehat Makaan supports out-of-the-box thinking. Whether you\'re introducing a new service or streamlining your workflow, creativity is not just welcomed — it\'s essential.',
    ),
    CoreValue(
      title: 'Create an Impact',
      description:
          'Our mission goes beyond treatment. We aim to positively impact our patients\' lives, our practitioners\' careers, and the broader healthcare ecosystem. Every interaction, procedure, and conversation at Sehat Makaan is an opportunity to educate, uplift, and heal with purpose.',
    ),
    CoreValue(
      title: 'Prioritise Health',
      description:
          'At the heart of all we do is a shared dedication to health. We uphold the highest standards in hygiene, safety, and clinical ethics — ensuring that every patient receives care that is not only effective but compassionate and responsible.',
    ),
  ];

  // Benefits
  static const List<Benefit> benefits = [
    Benefit(
      title: 'Practice Without Overhead',
      description:
          'Skip the burden of setting up your own clinic. Sehat Makaan offers a fully equipped, regulation-compliant space at a fraction of traditional practice costs — with zero long-term lease commitments. You focus on care; we handle the infrastructure.',
    ),
    Benefit(
      title: 'Flexibility that Works for You',
      description:
          'Choose between hourly slots or monthly subscription packages tailored to your pace and specialty. Whether you\'re scaling up or maintaining a niche practice, our model adapts to your professional rhythm.',
    ),
    Benefit(
      title: 'Professional Support Without Micromanagement',
      description:
          'You retain complete autonomy over your patient care and practice style. Meanwhile, our trained support staff, sterilization team, and front-desk services ensure a seamless experience — without interfering with your clinical independence.',
    ),
    Benefit(
      title: 'Collaborative Growth & Community',
      description:
          'Become a part of a network of like-minded practitioners across dental, medical, and aesthetic fields. Our setup fosters inter-specialty collaboration, shared learning, and a sense of belonging that accelerates personal and professional development.',
    ),
  ];

  // Hourly Packages
  static const List<HourlyPackage> hourlyPackages = [
    HourlyPackage(
      specialty: 'General Dentist',
      roomType: 'Dental Chair',
      hourlyRate: 1500,
      details: 'Includes basic chair use, ultrasonic scaler',
    ),
    HourlyPackage(
      specialty: 'Endodontist',
      roomType: 'Dental Chair',
      hourlyRate: 3000,
      details:
          'Includes rotary support (endodontic motor, curing light, single tooth filling material)',
    ),
    HourlyPackage(
      specialty: 'Orthodontist/Prosthodontist',
      roomType: 'Dental Chair',
      hourlyRate: 3000,
      details:
          'Includes orthodontic instruments, impression trays (single patient impression material; alginate, brackets and other material on added cost)',
    ),
    HourlyPackage(
      specialty: 'Maxillofacial Surgery',
      roomType: 'Dental Chair',
      hourlyRate: 2000,
      details:
          'Includes surgical instruments, two LA cartridges, wound dressing material',
    ),
    HourlyPackage(
      specialty: 'Aesthetic Practitioner',
      roomType: 'Aesthetic Room',
      hourlyRate: 3000,
      details:
          'Basic room + LED light + PRP single session support (syringe, butterfly needle, vacutainer, anticoagulant tube, centrifuge)',
    ),
    HourlyPackage(
      specialty: 'General Physician',
      roomType: 'Medical Room',
      hourlyRate: 2000,
      details:
          'Includes basic exam table, BP apparatus, weighing scale and exam equipment',
    ),
  ];

  // Optional Add-Ons
  static const List<AddOn> addOns = [
    AddOn(name: 'Dental assistant (30 mins)', price: 500, category: 'Dental'),
    AddOn(name: 'Intraoral X-ray Use', price: 500, category: 'Dental'),
    AddOn(
      name: 'OPD nurse (30 mins)',
      price: 500,
      category: 'Medical/Aesthetic',
    ),
    AddOn(
      name: 'Laboratory access',
      price: 1000,
      category: 'All',
      period: 'Monthly',
      note: 'Only includes the access and transfer of material/sample',
    ),
    AddOn(name: 'Conveyance', price: 6000, category: 'All', period: 'Monthly'),
  ];

  // Monthly Packages for Dentists
  static const List<MonthlyPackage> dentalMonthlyPackages = [
    MonthlyPackage(
      tier: 'Starter',
      price: 25000,
      hours: 10,
      category: 'Dental',
      inclusions: [
        '10 hours/month chair use (flexible slots)',
        'Basic tray setup',
        'Reception and assistant support',
      ],
    ),
    MonthlyPackage(
      tier: 'Advanced',
      price: 35000,
      hours: 15,
      category: 'Dental',
      inclusions: [
        '15 hours/month',
        'All Starter inclusions',
        'Priority weekend slots',
        'Profile wall branding on digital page',
      ],
    ),
    MonthlyPackage(
      tier: 'Professional',
      price: 45000,
      hours: 20,
      category: 'Dental',
      inclusions: [
        '20 hours/month',
        'All Advanced inclusions',
        'X-ray usage (2 per patient)',
        '10 single patient material usage',
        'Private locker',
        'Pick and drop service',
      ],
    ),
  ];

  // Monthly Packages for Aesthetic Physicians
  static const List<MonthlyPackage> aestheticMonthlyPackages = [
    MonthlyPackage(
      tier: 'Starter',
      price: 25000,
      hours: 10,
      category: 'Aesthetic',
      inclusions: [
        '10 hours/month',
        'LED light',
        'Basic trolley (setup to support single patient PRP session)',
      ],
    ),
    MonthlyPackage(
      tier: 'Advanced',
      price: 35000,
      hours: 15,
      category: 'Aesthetic',
      inclusions: [
        '15 hours/month',
        'Dermachair',
        'Priority booking',
        'Branded profile on digital page',
      ],
    ),
    MonthlyPackage(
      tier: 'Professional',
      price: 45000,
      hours: 20,
      category: 'Aesthetic',
      inclusions: [
        '20 hours/month',
        '2 exclusive photo-shoot days',
        'Patient waiting material display',
        'Custom lighting setup',
        'Pick and drop service',
      ],
    ),
  ];

  // Monthly Packages for General Physicians
  static const List<MonthlyPackage> medicalMonthlyPackages = [
    MonthlyPackage(
      tier: 'Starter',
      price: 20000,
      hours: 10,
      category: 'Medical',
      inclusions: [
        '10 hours/month',
        'Reception scheduling',
        'Basic diagnostic support (BP, thermometer, etc.)',
      ],
    ),
    MonthlyPackage(
      tier: 'Advanced',
      price: 25000,
      hours: 15,
      category: 'Medical',
      inclusions: [
        '15 hours/month',
        'Digital prescription pad',
        'Profile board',
        'Medical assistant (4 sessions)',
      ],
    ),
    MonthlyPackage(
      tier: 'Professional',
      price: 35000,
      hours: 20,
      category: 'Medical',
      inclusions: [
        '20 hours/month',
        'Extended consultation hours',
        '1 conference room slot/month',
        'EMR record access (optional)',
        'Pick and drop service',
      ],
    ),
  ];

  // Monthly Add-Ons
  static const List<MonthlyAddOn> monthlyAddOns = [
    MonthlyAddOn(
      service: 'Extra 10 Hour Block',
      cost: 10000,
      applicableTiers: 'All',
    ),
    MonthlyAddOn(
      service: 'Dedicated Locker',
      cost: 2000,
      applicableTiers: 'All',
    ),
    MonthlyAddOn(
      service: 'Clinical Assistant',
      cost: 5000,
      applicableTiers: 'All',
    ),
    MonthlyAddOn(
      service: 'Social Media Highlight',
      cost: 3000,
      applicableTiers: 'Advanced & up',
    ),
    MonthlyAddOn(
      service: 'Sterile kits x4',
      cost: 2000,
      applicableTiers: 'All',
    ),
  ];

  // Workplace Etiquette
  static const List<EtiquetteRule> workplaceEtiquette = [
    EtiquetteRule(
      category: 'General Conduct',
      rules: [
        'Maintain punctuality and arrive at least 10 minutes before your clinical slot',
        'Dress in clean, professional attire or scrubs appropriate to your specialty',
        'Respect shared spaces — keep work areas clean and return equipment to designated places',
        'Use polite, inclusive, and respectful language with both staff and patients',
        'Personal mobile use should be minimized during working hours except in emergencies',
      ],
    ),
    EtiquetteRule(
      category: 'Confidentiality',
      rules: [
        'Patient records, medical histories, and treatment details must be kept strictly confidential',
        'Do not disclose any patient information without explicit written consent',
        'Photographs and clinical images must only be used with informed patient consent and in accordance with ethical guidelines',
        'Respect the privacy and autonomy of each patient as per PMDC\'s ethical requirements',
        'Avoid any form of discussion regarding patients in public or common spaces',
      ],
    ),
    EtiquetteRule(
      category: 'Patient Dealing Protocol',
      rules: [
        'Greet patients respectfully and explain procedures clearly before proceeding',
        'Ensure informed consent is obtained and documented before treatment',
        'Handle patient concerns or dissatisfaction with empathy and professionalism',
        'Never solicit or promote unverified treatments or products for personal gain',
        'Emergency protocols should be followed in case of patient distress or reaction',
      ],
    ),
    EtiquetteRule(
      category: 'Company Facilities Use Policy',
      rules: [
        'Use of the clinic space is restricted to registered users and their scheduled slots only',
        'Practitioners are responsible for the condition of the operatory during and after their slot',
        'Misuse of clinic branding, property, or patient data may lead to termination of rental privileges',
        'All practitioners are expected to uphold the Sehat Makaan code of conduct and maintain standards aligned with the PMDC Code of Ethics',
      ],
    ),
  ];

  // Health & Safety
  static const HealthSafety healthSafety = HealthSafety(
    facilityStandards: [
      'Routine disinfection of clinical surfaces and waiting areas',
      'Availability of PPE and hand sanitizers across the facility',
      'Adherence to sterilization SOPs for all instruments and operatories',
      'Waste disposal follows proper biomedical safety protocols',
    ],
    safetyGuidelines: [
      'Report any spills, leaks, or hazards to the clinic manager immediately',
      'Avoid overcrowding in treatment or sterilization areas',
      'Use gloves and safety gear when handling biological material',
      'Know the location of emergency exits and fire extinguishers',
      'Participate in periodic safety drills or briefings',
    ],
    securityPolicies: [
      'Entry to the clinic is restricted to registered practitioners and scheduled patients',
      'CCTV monitoring is in place in common areas for safety and transparency',
      'All users must log in their bookings and usage accurately',
      'Personal and patient belongings should be handled responsibly',
    ],
    smokeFreePolicy:
        'Sehat Makaan is a designated smoke-free zone. Smoking is strictly prohibited within all indoor areas, including clinical rooms, restrooms, and waiting spaces.',
  );

  // Workflow Steps
  static const List<String> workflowSteps = [
    'Read the operational handbook',
    'Go to the booking website to secure your slot',
    'Sign the booking agreement',
    'Sign the rental agreement',
    'Choose the package best suited to your needs',
    'Arrive at your chosen slot, at least 10 mins early',
    'Attend to your patients',
  ];

  // Booking Policy
  static const BookingPolicy bookingPolicy = BookingPolicy(
    eligibility:
        'Only registered practitioners with an active rental agreement are eligible to access and book clinical slots via the platform.',
    bookingProtocol: [
      'Slots can be booked in hourly increments, subject to availability',
      'Each user will be provided with a secure login to access their dashboard',
      'Bookings must be made at least 2 hours in advance',
      'Cancellation must be made at least 6 hours prior to the reserved slot to avoid penalty',
    ],
    slotTypes: [
      'Clinical slots are categorized by specialty: Dental, Aesthetic, and Medical',
      'Weekday and weekend slots may differ in pricing and availability',
      'Priority booking may be granted to monthly subscribers during peak hours',
    ],
    noShowPolicy: [
      'A no-show without notice may result in forfeiture of the booking fee',
      'Practitioners arriving more than 15 minutes late may lose their reserved slot without refund',
    ],
    technicalSupport:
        'For login, technical or booking issues, contact support at the front desk. Platform support is available from 9:00 AM to 7:00 PM daily.',
  );

  // Contact Information
  static const ContactInfo contactInfo = ContactInfo(
    address:
        'Office 304, 3rd Floor, Plaza 95, Main Boulevard, Gulberg III, Lahore - 54000, Punjab, Pakistan',
    phone: ['+92 324 9043006'],
    email: ['support@sehatmakaan.com'],
    workingHours: 'Monday-Saturday: 9:00 AM - 7:00 PM (Sunday Closed)',
    onlineBooking: 'Available 24/7',
  );
}

// Data Models

class CoreValue {
  final String title;
  final String description;

  const CoreValue({required this.title, required this.description});
}

class Benefit {
  final String title;
  final String description;

  const Benefit({required this.title, required this.description});
}

class HourlyPackage {
  final String specialty;
  final String roomType;
  final int hourlyRate;
  final String details;

  const HourlyPackage({
    required this.specialty,
    required this.roomType,
    required this.hourlyRate,
    required this.details,
  });
}

class AddOn {
  final String name;
  final int price;
  final String category;
  final String? period;
  final String? note;

  const AddOn({
    required this.name,
    required this.price,
    required this.category,
    this.period,
    this.note,
  });
}

class MonthlyPackage {
  final String tier;
  final int price;
  final int hours;
  final String category;
  final List<String> inclusions;

  const MonthlyPackage({
    required this.tier,
    required this.price,
    required this.hours,
    required this.category,
    required this.inclusions,
  });
}

class MonthlyAddOn {
  final String service;
  final int cost;
  final String applicableTiers;

  const MonthlyAddOn({
    required this.service,
    required this.cost,
    required this.applicableTiers,
  });
}

class EtiquetteRule {
  final String category;
  final List<String> rules;

  const EtiquetteRule({required this.category, required this.rules});
}

class HealthSafety {
  final List<String> facilityStandards;
  final List<String> safetyGuidelines;
  final List<String> securityPolicies;
  final String smokeFreePolicy;

  const HealthSafety({
    required this.facilityStandards,
    required this.safetyGuidelines,
    required this.securityPolicies,
    required this.smokeFreePolicy,
  });
}

class BookingPolicy {
  final String eligibility;
  final List<String> bookingProtocol;
  final List<String> slotTypes;
  final List<String> noShowPolicy;
  final String technicalSupport;

  const BookingPolicy({
    required this.eligibility,
    required this.bookingProtocol,
    required this.slotTypes,
    required this.noShowPolicy,
    required this.technicalSupport,
  });
}

class ContactInfo {
  final String address;
  final List<String> phone;
  final List<String> email;
  final String workingHours;
  final String onlineBooking;

  const ContactInfo({
    required this.address,
    required this.phone,
    required this.email,
    required this.workingHours,
    required this.onlineBooking,
  });
}
