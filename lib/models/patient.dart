/// Patient model for storing patient information
class Patient {
  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? phoneNumber;
  final String? address;
  final String? email;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final double? weight;
  final double? height;
  final List<String>? allergies;
  final List<String>? medicalHistory;
  final String? emergencyContact;
  final String? emergencyContactPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.phoneNumber,
    this.address,
    this.email,
    this.dateOfBirth,
    this.bloodGroup,
    this.weight,
    this.height,
    this.allergies,
    this.medicalHistory,
    this.emergencyContact,
    this.emergencyContactPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Patient from JSON (Firebase)
  factory Patient.fromJson(Map<String, dynamic> json, String id) {
    return Patient(
      id: id,
      name: json['name'] ?? '',
      age: json['age'],
      gender: json['gender'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      email: json['email'],
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'])
              : null,
      bloodGroup: json['bloodGroup'],
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      allergies:
          json['allergies'] != null
              ? List<String>.from(json['allergies'])
              : null,
      medicalHistory:
          json['medicalHistory'] != null
              ? List<String>.from(json['medicalHistory'])
              : null,
      emergencyContact: json['emergencyContact'],
      emergencyContactPhone: json['emergencyContactPhone'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Convert Patient to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'address': address,
      'email': email,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bloodGroup': bloodGroup,
      'weight': weight,
      'height': height,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'emergencyContact': emergencyContact,
      'emergencyContactPhone': emergencyContactPhone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Patient copyWith({
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    String? address,
    String? email,
    DateTime? dateOfBirth,
    String? bloodGroup,
    double? weight,
    double? height,
    List<String>? allergies,
    List<String>? medicalHistory,
    String? emergencyContact,
    String? emergencyContactPhone,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      allergies: allergies ?? this.allergies,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Patient{id: $id, name: $name, age: $age, gender: $gender}';
  }
}
