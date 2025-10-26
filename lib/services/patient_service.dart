import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:health_buddy/models/patient.dart';

/// Service for managing patient data in Firebase Realtime Database
class PatientService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

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
}
