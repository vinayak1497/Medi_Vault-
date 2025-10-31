import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:health_buddy/models/patient.dart';

/// Service for managing patient data in Firebase Realtime Database
class PatientService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Helper: safely parse a timestamp or ISO string to DateTime
  static DateTime _parseDate(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is int) {
        // Firebase ServerValue.timestamp resolves to milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is double) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
    } catch (_) {}
    return DateTime.now();
  }

  /// Helper: build Patient model from a generic profile map
  static Patient _fromProfile(Map<String, dynamic> data, String id) {
    final name = (data['fullName'] ?? data['name'] ?? 'Patient').toString();
    final createdAt = _parseDate(data['createdAt']);
    final updatedAt = _parseDate(data['updatedAt'] ?? data['createdAt']);

    return Patient(
      id: id,
      name: name,
      age: (data['age'] is int) ? data['age'] as int : null,
      gender: data['gender']?.toString(),
      phoneNumber:
          (data['phoneNumber'] ?? data['phone'] ?? data['mobile'])?.toString(),
      address: data['address']?.toString(),
      email: data['email']?.toString(),
      dateOfBirth:
          data['dateOfBirth'] != null
              ? DateTime.tryParse(data['dateOfBirth'].toString())
              : null,
      bloodGroup: data['bloodGroup']?.toString(),
      weight:
          data['weight'] != null
              ? double.tryParse(data['weight'].toString())
              : null,
      height:
          data['height'] != null
              ? double.tryParse(data['height'].toString())
              : null,
      allergies:
          data['allergies'] is List
              ? List<String>.from(data['allergies'] as List)
              : null,
      medicalHistory:
          data['medicalHistory'] is List
              ? List<String>.from(data['medicalHistory'] as List)
              : null,
      emergencyContact: data['emergencyContact']?.toString(),
      emergencyContactPhone: data['emergencyContactPhone']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Get all patients for a doctor
  static Future<List<Patient>> getPatientsByDoctor(String doctorId) async {
    try {
      // Use a different approach to avoid indexing issues
      // Get all patients and filter on client side for now
      final snapshot = await _database.child('patients').get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Patient> patients = [];
      final Map<String, dynamic> patientsData = Map<String, dynamic>.from(
        snapshot.value as Map,
      );

      patientsData.forEach((key, value) {
        final patientData = Map<String, dynamic>.from(value);
        // Filter by doctorId on client side
        if (patientData['doctorId'] == doctorId) {
          patients.add(Patient.fromJson(patientData, key));
        }
      });

      // Sort by name
      patients.sort((a, b) => a.name.compareTo(b.name));
      return patients;
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      return [];
    }
  }

  /// Add a new patient
  static Future<String?> addPatient(Patient patient, String doctorId) async {
    try {
      final patientRef = _database.child('patients').push();
      final patientId = patientRef.key!;

      final patientData = patient.toJson();
      patientData['doctorId'] = doctorId;

      await patientRef.set(patientData);
      return patientId;
    } catch (e) {
      debugPrint('Error adding patient: $e');
      return null;
    }
  }

  /// Update patient information
  static Future<bool> updatePatient(Patient patient, String doctorId) async {
    try {
      final patientData = patient.toJson();
      patientData['doctorId'] = doctorId;

      await _database.child('patients').child(patient.id).update(patientData);
      return true;
    } catch (e) {
      debugPrint('Error updating patient: $e');
      return false;
    }
  }

  /// Delete a patient
  static Future<bool> deletePatient(String patientId) async {
    try {
      await _database.child('patients').child(patientId).remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      return false;
    }
  }

  /// Get a specific patient by ID
  static Future<Patient?> getPatientById(String patientId) async {
    try {
      final snapshot = await _database.child('patients').child(patientId).get();

      if (!snapshot.exists) {
        return null;
      }

      final patientData = Map<String, dynamic>.from(snapshot.value as Map);
      return Patient.fromJson(patientData, patientId);
    } catch (e) {
      debugPrint('Error fetching patient: $e');
      return null;
    }
  }

  /// Search patients by name for a doctor
  static Future<List<Patient>> searchPatients(
    String doctorId,
    String searchQuery,
  ) async {
    try {
      final allPatients = await getPatientsByDoctor(doctorId);

      if (searchQuery.isEmpty) {
        return allPatients;
      }

      return allPatients
          .where(
            (patient) =>
                patient.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    } catch (e) {
      debugPrint('Error searching patients: $e');
      return [];
    }
  }

  /// Add some sample patients for testing
  static Future<void> addSamplePatients(String doctorId) async {
    try {
      final samplePatients = [
        Patient(
          id: '',
          name: 'Umesh Kundar',
          age: 25,
          gender: 'Male',
          phoneNumber: '9876543210',
          address: 'Bangalore, Karnataka',
          email: 'umesh@example.com',
          bloodGroup: 'O+',
          weight: 70.0,
          height: 175.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Patient(
          id: '',
          name: 'Priya Sharma',
          age: 30,
          gender: 'Female',
          phoneNumber: '8765432109',
          address: 'Mumbai, Maharashtra',
          email: 'priya@example.com',
          bloodGroup: 'A+',
          weight: 60.0,
          height: 165.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Patient(
          id: '',
          name: 'Raj Kumar',
          age: 45,
          gender: 'Male',
          phoneNumber: '7654321098',
          address: 'Delhi, India',
          email: 'raj@example.com',
          bloodGroup: 'B+',
          weight: 80.0,
          height: 170.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final patient in samplePatients) {
        await addPatient(patient, doctorId);
      }
    } catch (e) {
      debugPrint('Error adding sample patients: $e');
    }
  }

  /// New: Get all registered patients (from both `patients` and `patient_profiles`)
  static Future<List<Patient>> getAllRegisteredPatients() async {
    try {
      final List<Patient> results = [];

      // Legacy patients node
      try {
        final snap = await _database.child('patients').get();
        if (snap.exists && snap.value is Map) {
          final map = Map<String, dynamic>.from(snap.value as Map);
          map.forEach((id, value) {
            final data = Map<String, dynamic>.from(value as Map);
            try {
              results.add(Patient.fromJson(data, id));
            } catch (_) {
              results.add(_fromProfile(data, id));
            }
          });
        }
      } catch (e) {
        debugPrint('PatientService: error reading patients: $e');
      }

      // Profiles from signups
      try {
        final snap = await _database.child('patient_profiles').get();
        if (snap.exists && snap.value is Map) {
          final map = Map<String, dynamic>.from(snap.value as Map);
          map.forEach((uid, value) {
            final data = Map<String, dynamic>.from(value as Map);
            final candidate = _fromProfile(data, uid);
            final exists = results.any(
              (p) =>
                  (p.email != null && p.email == candidate.email) ||
                  (p.name == candidate.name &&
                      p.createdAt == candidate.createdAt),
            );
            if (!exists) results.add(candidate);
          });
        }
      } catch (e) {
        debugPrint('PatientService: error reading patient_profiles: $e');
      }

      results.sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (byName != 0) return byName;
        return b.createdAt.compareTo(a.createdAt);
      });
      return results;
    } catch (e) {
      debugPrint('PatientService: error getAllRegisteredPatients: $e');
      return [];
    }
  }

  /// New: Search across all registered patients by name
  static Future<List<Patient>> searchAllPatients(String query) async {
    final all = await getAllRegisteredPatients();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }
}
