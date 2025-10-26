import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/models/prescription.dart';

/// Service for doctor-related operations in Firebase
class DoctorService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Save prescription to Firebase
  static Future<void> savePrescription(Prescription prescription) async {
    try {
      // Generate ID if not provided
      String prescriptionId =
          prescription.id ?? _database.child('prescriptions').push().key!;

      // Create prescription with updated timestamp
      final updatedPrescription = prescription.copyWith(
        id: prescriptionId,
        updatedAt: DateTime.now(),
      );

      // Save to prescriptions node
      await _database
          .child('prescriptions')
          .child(prescriptionId)
          .set(updatedPrescription.toMap());

      // Save reference in doctor's prescriptions
      await _database
          .child('doctors')
          .child(prescription.doctorId)
          .child('prescriptions')
          .child(prescriptionId)
          .set(true);

      // Save reference in patient's prescriptions if patientId exists
      if (prescription.patientId != null) {
        await _database
            .child('patients')
            .child(prescription.patientId!)
            .child('prescriptions')
            .child(prescriptionId)
            .set(true);
      }
    } catch (e) {
      throw Exception('Failed to save prescription: $e');
    }
  }

  /// Get prescription by ID
  static Future<Prescription?> getPrescription(String prescriptionId) async {
    try {
      final snapshot =
          await _database.child('prescriptions').child(prescriptionId).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Prescription.fromMap(data, prescriptionId);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get prescription: $e');
    }
  }

  /// Get all prescriptions for a doctor
  static Future<List<Prescription>> getDoctorPrescriptions(
    String doctorId,
  ) async {
    try {
      // Get prescription IDs for the doctor
      final doctorSnapshot =
          await _database
              .child('doctors')
              .child(doctorId)
              .child('prescriptions')
              .get();

      if (!doctorSnapshot.exists || doctorSnapshot.value == null) {
        return [];
      }

      final prescriptionIds =
          Map<String, dynamic>.from(doctorSnapshot.value as Map).keys;
      final prescriptions = <Prescription>[];

      // Get each prescription
      for (final id in prescriptionIds) {
        final prescription = await getPrescription(id);
        if (prescription != null) {
          prescriptions.add(prescription);
        }
      }

      // Sort by creation date (newest first)
      prescriptions.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.now();
        final bDate = b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      return prescriptions;
    } catch (e) {
      throw Exception('Failed to get doctor prescriptions: $e');
    }
  }

  /// Get all prescriptions for a patient
  static Future<List<Prescription>> getPatientPrescriptions(
    String patientId,
  ) async {
    try {
      // Get prescription IDs for the patient
      final patientSnapshot =
          await _database
              .child('patients')
              .child(patientId)
              .child('prescriptions')
              .get();

      if (!patientSnapshot.exists || patientSnapshot.value == null) {
        return [];
      }

      final prescriptionIds =
          Map<String, dynamic>.from(patientSnapshot.value as Map).keys;
      final prescriptions = <Prescription>[];

      // Get each prescription
      for (final id in prescriptionIds) {
        final prescription = await getPrescription(id);
        if (prescription != null) {
          prescriptions.add(prescription);
        }
      }

      // Sort by creation date (newest first)
      prescriptions.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.now();
        final bDate = b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      return prescriptions;
    } catch (e) {
      throw Exception('Failed to get patient prescriptions: $e');
    }
  }

  /// Update prescription status
  static Future<void> updatePrescriptionStatus(
    String prescriptionId,
    PrescriptionStatus status,
  ) async {
    try {
      await _database
          .child('prescriptions')
          .child(prescriptionId)
          .child('status')
          .set(status.name);

      await _database
          .child('prescriptions')
          .child(prescriptionId)
          .child('updatedAt')
          .set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      throw Exception('Failed to update prescription status: $e');
    }
  }

  /// Delete prescription
  static Future<void> deletePrescription(String prescriptionId) async {
    try {
      // Get prescription to find associated doctor and patient
      final prescription = await getPrescription(prescriptionId);
      if (prescription == null) {
        throw Exception('Prescription not found');
      }

      // Remove from main prescriptions node
      await _database.child('prescriptions').child(prescriptionId).remove();

      // Remove from doctor's prescriptions
      await _database
          .child('doctors')
          .child(prescription.doctorId)
          .child('prescriptions')
          .child(prescriptionId)
          .remove();

      // Remove from patient's prescriptions if exists
      if (prescription.patientId != null) {
        await _database
            .child('patients')
            .child(prescription.patientId!)
            .child('prescriptions')
            .child(prescriptionId)
            .remove();
      }
    } catch (e) {
      throw Exception('Failed to delete prescription: $e');
    }
  }

  /// Search prescriptions by patient name or symptoms
  static Future<List<Prescription>> searchPrescriptions(
    String doctorId,
    String query,
  ) async {
    try {
      final allPrescriptions = await getDoctorPrescriptions(doctorId);

      if (query.isEmpty) {
        return allPrescriptions;
      }

      final filteredPrescriptions =
          allPrescriptions.where((prescription) {
            final patientName = prescription.patientName?.toLowerCase() ?? '';
            final symptoms = prescription.currentSymptoms?.toLowerCase() ?? '';
            final diagnosis = prescription.diagnosis?.toLowerCase() ?? '';
            final queryLower = query.toLowerCase();

            return patientName.contains(queryLower) ||
                symptoms.contains(queryLower) ||
                diagnosis.contains(queryLower);
          }).toList();

      return filteredPrescriptions;
    } catch (e) {
      throw Exception('Failed to search prescriptions: $e');
    }
  }

  /// Get prescription statistics for doctor
  static Future<Map<String, int>> getPrescriptionStats(String doctorId) async {
    try {
      final prescriptions = await getDoctorPrescriptions(doctorId);

      final stats = <String, int>{
        'total': prescriptions.length,
        'active': 0,
        'completed': 0,
        'cancelled': 0,
        'thisMonth': 0,
      };

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);

      for (final prescription in prescriptions) {
        // Count by status
        switch (prescription.status) {
          case PrescriptionStatus.active:
          case PrescriptionStatus.verified:
            stats['active'] = (stats['active'] ?? 0) + 1;
            break;
          case PrescriptionStatus.completed:
            stats['completed'] = (stats['completed'] ?? 0) + 1;
            break;
          case PrescriptionStatus.cancelled:
            stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
            break;
          default:
            break;
        }

        // Count this month
        final prescriptionDate =
            prescription.createdAt ?? prescription.prescriptionDate;
        if (prescriptionDate != null && prescriptionDate.isAfter(thisMonth)) {
          stats['thisMonth'] = (stats['thisMonth'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get prescription stats: $e');
    }
  }
}
