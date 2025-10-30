import 'package:flutter/foundation.dart';

/// Data model for medical prescriptions following standard template
/// Contains patient information, prescription details, and medical instructions
class Prescription {
  // Unique identifiers
  final String? id;
  final String doctorId;
  final String? doctorName; // Doctor's full name
  final String? patientId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? prescriptionDate;

  // 1. Patient Information Section
  final String? patientName;
  final int? patientAge;
  final String? patientGender; // Updated field name
  final String? patientAddress;
  final String? patientPhone; // New field
  final double? patientWeight; // kg
  final String? currentSymptoms;
  final String? opdRegistrationNumber;

  // 2. Medical Information
  final String? diagnosis; // New field
  final String? medicalHistory; // New field
  final String? allergies; // New field
  final String? vitalSigns; // New field

  // 3. Prescription Details (Main Body)
  final List<MedicationItem> medications;

  // 4. Directions and Instructions
  final String? instructions; // General instructions
  final String? precautions; // New field
  final String? followUpInstructions; // Updated field name
  final String? doctorNotes; // New field

  // Legacy fields (for backward compatibility)
  final String? specialInstructions;
  final String? investigationsAdvised;
  final String? dietaryAdvice;
  final String? followUpDate;
  final String? additionalNotes;

  // Metadata
  final String? originalImagePath; // Path to scanned image
  final String? extractedText; // Raw extracted text from ML Kit
  final bool isVerified; // Doctor verified the extracted data
  final PrescriptionStatus status;

  const Prescription({
    this.id,
    required this.doctorId,
    this.doctorName,
    this.patientId,
    this.createdAt,
    this.updatedAt,
    this.prescriptionDate,

    // Patient Information
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.patientAddress,
    this.patientPhone,
    this.patientWeight,
    this.currentSymptoms,
    this.opdRegistrationNumber,

    // Medical Information
    this.diagnosis,
    this.medicalHistory,
    this.allergies,
    this.vitalSigns,

    // Prescription Details
    this.medications = const [],

    // Instructions
    this.instructions,
    this.precautions,
    this.followUpInstructions,
    this.doctorNotes,

    // Legacy fields
    this.specialInstructions,
    this.investigationsAdvised,
    this.dietaryAdvice,
    this.followUpDate,
    this.additionalNotes,

    // Metadata
    this.originalImagePath,
    this.extractedText,
    this.isVerified = false,
    this.status = PrescriptionStatus.active,
  });

  /// Create prescription from Firebase snapshot data
  factory Prescription.fromMap(Map<String, dynamic> data, String id) {
    return Prescription(
      id: id,
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'],
      patientId: data['patientId'],
      createdAt:
          data['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
              : null,
      updatedAt:
          data['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
              : null,
      prescriptionDate:
          data['prescriptionDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['prescriptionDate'])
              : null,

      // Patient Information
      patientName: data['patientName'],
      patientAge: data['patientAge'],
      patientGender:
          data['patientGender'] ?? data['patientSex'], // Backward compatibility
      patientAddress: data['patientAddress'],
      patientPhone: data['patientPhone'],
      patientWeight: data['patientWeight']?.toDouble(),
      currentSymptoms: data['currentSymptoms'],
      opdRegistrationNumber: data['opdRegistrationNumber'],

      // Medical Information
      diagnosis: data['diagnosis'],
      medicalHistory: data['medicalHistory'],
      allergies: data['allergies'],
      vitalSigns: data['vitalSigns'],

      // Prescription Details
      medications:
          (data['medications'] as List<dynamic>? ?? [])
              .map((med) => MedicationItem.fromMap(med as Map<String, dynamic>))
              .toList(),

      // Instructions
      instructions: data['instructions'],
      precautions: data['precautions'],
      followUpInstructions: data['followUpInstructions'],
      doctorNotes: data['doctorNotes'],

      // Legacy fields
      specialInstructions: data['specialInstructions'],
      investigationsAdvised: data['investigationsAdvised'],
      dietaryAdvice: data['dietaryAdvice'],
      followUpDate: data['followUpDate'],
      additionalNotes: data['additionalNotes'],

      // Metadata
      originalImagePath: data['originalImagePath'],
      extractedText: data['extractedText'],
      isVerified: data['isVerified'] ?? false,
      status: PrescriptionStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => PrescriptionStatus.active,
      ),
    );
  }

  /// Convert prescription to Firebase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientId': patientId,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'prescriptionDate': prescriptionDate?.millisecondsSinceEpoch,

      // Patient Information
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientAddress': patientAddress,
      'patientPhone': patientPhone,
      'patientWeight': patientWeight,
      'currentSymptoms': currentSymptoms,
      'opdRegistrationNumber': opdRegistrationNumber,

      // Medical Information
      'diagnosis': diagnosis,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'vitalSigns': vitalSigns,

      // Prescription Details
      'medications': medications.map((med) => med.toMap()).toList(),

      // Instructions
      'instructions': instructions,
      'precautions': precautions,
      'followUpInstructions': followUpInstructions,
      'doctorNotes': doctorNotes,

      // Legacy fields
      'specialInstructions': specialInstructions,
      'investigationsAdvised': investigationsAdvised,
      'dietaryAdvice': dietaryAdvice,
      'followUpDate': followUpDate,
      'additionalNotes': additionalNotes,

      // Metadata
      'originalImagePath': originalImagePath,
      'extractedText': extractedText,
      'isVerified': isVerified,
      'status': status.name,
    };
  }

  /// Create a copy of prescription with updated fields
  Prescription copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? patientId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? prescriptionDate,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? patientAddress,
    String? patientPhone,
    double? patientWeight,
    String? currentSymptoms,
    String? opdRegistrationNumber,
    String? diagnosis,
    String? medicalHistory,
    String? allergies,
    String? vitalSigns,
    List<MedicationItem>? medications,
    String? instructions,
    String? precautions,
    String? followUpInstructions,
    String? doctorNotes,
    String? specialInstructions,
    String? investigationsAdvised,
    String? dietaryAdvice,
    String? followUpDate,
    String? additionalNotes,
    String? originalImagePath,
    String? extractedText,
    bool? isVerified,
    PrescriptionStatus? status,
  }) {
    return Prescription(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      patientId: patientId ?? this.patientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientAddress: patientAddress ?? this.patientAddress,
      patientPhone: patientPhone ?? this.patientPhone,
      patientWeight: patientWeight ?? this.patientWeight,
      currentSymptoms: currentSymptoms ?? this.currentSymptoms,
      opdRegistrationNumber:
          opdRegistrationNumber ?? this.opdRegistrationNumber,
      diagnosis: diagnosis ?? this.diagnosis,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      medications: medications ?? this.medications,
      instructions: instructions ?? this.instructions,
      precautions: precautions ?? this.precautions,
      followUpInstructions: followUpInstructions ?? this.followUpInstructions,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      investigationsAdvised:
          investigationsAdvised ?? this.investigationsAdvised,
      dietaryAdvice: dietaryAdvice ?? this.dietaryAdvice,
      followUpDate: followUpDate ?? this.followUpDate,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      extractedText: extractedText ?? this.extractedText,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Prescription(id: $id, doctorId: $doctorId, patientName: $patientName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prescription &&
        other.id == id &&
        other.doctorId == doctorId &&
        other.patientId == patientId &&
        listEquals(other.medications, medications);
  }

  @override
  int get hashCode {
    return Object.hash(id, doctorId, patientId, medications);
  }
}

/// Individual medication item in prescription
class MedicationItem {
  final String name; // Medicine name (generic or brand)
  final String genericName; // Generic name
  final String strength; // e.g., "500 mg"
  final DosageForm dosageForm; // Tablet, Capsule, Syrup, etc.
  final DosageFrequency frequency; // Once daily, twice daily, etc.
  final String duration; // e.g., "7 days", "2 weeks"
  final String instructions; // Special instructions for this medication

  const MedicationItem({
    required this.name,
    required this.genericName,
    required this.strength,
    required this.dosageForm,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  factory MedicationItem.fromMap(Map<String, dynamic> data) {
    return MedicationItem(
      name: data['name'] ?? data['brandName'] ?? '', // Backward compatibility
      genericName: data['genericName'] ?? '',
      strength: data['strength'] ?? '',
      dosageForm: DosageForm.values.firstWhere(
        (form) => form.name == data['dosageForm'],
        orElse: () => DosageForm.tablet,
      ),
      frequency: DosageFrequency.values.firstWhere(
        (freq) => freq.name == data['frequency'],
        orElse: () => DosageFrequency.onceDaily,
      ),
      duration: data['duration'] ?? '',
      instructions: data['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'genericName': genericName,
      'strength': strength,
      'dosageForm': dosageForm.name,
      'frequency': frequency.name,
      'duration': duration,
      'instructions': instructions,
    };
  }

  MedicationItem copyWith({
    String? name,
    String? genericName,
    String? strength,
    DosageForm? dosageForm,
    DosageFrequency? frequency,
    String? duration,
    String? instructions,
  }) {
    return MedicationItem(
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      strength: strength ?? this.strength,
      dosageForm: dosageForm ?? this.dosageForm,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
    );
  }

  bool get isEmpty {
    return name.isEmpty && genericName.isEmpty && strength.isEmpty;
  }

  @override
  String toString() {
    return 'MedicationItem(name: $name, strength: $strength, frequency: ${frequency.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationItem &&
        other.name == name &&
        other.genericName == genericName &&
        other.strength == strength &&
        other.dosageForm == dosageForm;
  }

  @override
  int get hashCode {
    return Object.hash(name, genericName, strength, dosageForm);
  }
}

/// Status of the prescription in the workflow
enum PrescriptionStatus {
  draft('Draft'), // Just scanned, not verified
  active('Active'), // Active prescription
  verified('Verified'), // Doctor verified and corrected
  completed('Completed'), // Treatment completed
  cancelled('Cancelled'), // Prescription cancelled
  expired('Expired'); // Prescription expired

  const PrescriptionStatus(this.displayName);
  final String displayName;
}

/// Dosage forms for medications
enum DosageForm {
  tablet('Tablet'),
  capsule('Capsule'),
  syrup('Syrup'),
  suspension('Suspension'),
  injection('Injection'),
  ointment('Ointment'),
  cream('Cream'),
  drops('Drops'),
  inhaler('Inhaler'),
  patch('Patch'),
  suppository('Suppository'),
  powder('Powder'),
  gel('Gel'),
  lotion('Lotion');

  const DosageForm(this.displayName);
  final String displayName;
}

/// Dosage frequencies for medications
enum DosageFrequency {
  onceDaily('Once Daily'),
  twiceDaily('Twice Daily'),
  threeTimes('Three Times Daily'),
  fourTimes('Four Times Daily'),
  every4Hours('Every 4 Hours'),
  every6Hours('Every 6 Hours'),
  every8Hours('Every 8 Hours'),
  every12Hours('Every 12 Hours'),
  asNeeded('As Needed'),
  beforeMeals('Before Meals'),
  afterMeals('After Meals'),
  atBedtime('At Bedtime'),
  onEmptyStomach('On Empty Stomach');

  const DosageFrequency(this.displayName);
  final String displayName;
}

/// Common dosage forms for dropdown selection
class DosageForms {
  static const List<String> values = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Suspension',
    'Injection',
    'Ointment',
    'Cream',
    'Drops',
    'Inhaler',
    'Patch',
    'Suppository',
    'Powder',
    'Gel',
    'Lotion',
  ];
}

/// Common frequencies for dropdown selection
class MedicationFrequencies {
  static const List<String> values = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 4 hours',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
    'Before meals',
    'After meals',
    'At bedtime',
    'On empty stomach',
  ];
}

/// Common timings for medication
class MedicationTimings {
  static const List<String> values = [
    'Before meals',
    'After meals',
    'With meals',
    'On empty stomach',
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
    'At bedtime',
    '8 AM',
    '2 PM',
    '8 PM',
    '8 AM, 8 PM',
    '8 AM, 2 PM, 8 PM',
    '6 AM, 12 PM, 6 PM, 12 AM',
  ];
}
