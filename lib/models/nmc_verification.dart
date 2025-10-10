class NMCVerificationRequest {
  final String fullName;
  final String registrationNumber;
  final String state;
  final String? fatherName;
  final String? specialization;
  final String? yearOfRegistration;

  const NMCVerificationRequest({
    required this.fullName,
    required this.registrationNumber,
    required this.state,
    this.fatherName,
    this.specialization,
    this.yearOfRegistration,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'registration_number': registrationNumber,
      'state': state,
      if (fatherName != null) 'father_name': fatherName,
      if (specialization != null) 'specialization': specialization,
      if (yearOfRegistration != null)
        'year_of_registration': yearOfRegistration,
    };
  }
}

class NMCVerificationResult {
  final bool isVerified;
  final String status;
  final String message;
  final DoctorDetails? doctorDetails;
  final String? errorCode;

  const NMCVerificationResult({
    required this.isVerified,
    required this.status,
    required this.message,
    this.doctorDetails,
    this.errorCode,
  });

  factory NMCVerificationResult.fromJson(Map<String, dynamic> json) {
    return NMCVerificationResult(
      isVerified: json['is_verified'] ?? false,
      status: json['status'] ?? 'unknown',
      message: json['message'] ?? 'No message provided',
      doctorDetails:
          json['doctor_details'] != null
              ? DoctorDetails.fromJson(json['doctor_details'])
              : null,
      errorCode: json['error_code'],
    );
  }

  factory NMCVerificationResult.error(String message, {String? errorCode}) {
    return NMCVerificationResult(
      isVerified: false,
      status: 'error',
      message: message,
      errorCode: errorCode,
    );
  }
}

class DoctorDetails {
  final String? fullName;
  final String? registrationNumber;
  final String? state;
  final String? stateMedicalCouncil;
  final String? registrationDate;
  final String? qualification;
  final String? fatherName;
  final String? address;
  final bool? isActive;

  const DoctorDetails({
    this.fullName,
    this.registrationNumber,
    this.state,
    this.stateMedicalCouncil,
    this.registrationDate,
    this.qualification,
    this.fatherName,
    this.address,
    this.isActive,
  });

  factory DoctorDetails.fromJson(Map<String, dynamic> json) {
    return DoctorDetails(
      fullName: json['full_name'],
      registrationNumber: json['registration_number'],
      state: json['state'],
      stateMedicalCouncil: json['state_medical_council'],
      registrationDate: json['registration_date'],
      qualification: json['qualification'],
      fatherName: json['father_name'],
      address: json['address'],
      isActive: json['is_active'],
    );
  }
}

// Indian states for dropdown selection
class IndianStates {
  static const List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];
}
