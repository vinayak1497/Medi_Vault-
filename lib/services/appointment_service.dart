import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// Appointment status enum
enum AppointmentStatus { pending, accepted, rejected, cancelled, completed }

/// Service for managing doctor-patient appointments
class AppointmentService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Book an appointment
  static Future<String> bookAppointment({
    required String doctorId,
    required String patientId,
    required String patientName,
    required String doctorName,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? notes,
  }) async {
    try {
      final appointmentId = _database.child('appointments').push().key!;

      final appointmentData = {
        'id': appointmentId,
        'doctorId': doctorId,
        'patientId': patientId,
        'patientName': patientName,
        'doctorName': doctorName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'status': AppointmentStatus.pending.name,
        'notes': notes ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save to appointments node
      await _database
          .child('appointments')
          .child(appointmentId)
          .set(appointmentData);

      // Save reference in patient's appointments
      await _database
          .child('patient_profiles')
          .child(patientId)
          .child('appointments')
          .child(appointmentId)
          .set({
            'status': AppointmentStatus.pending.name,
            'doctorId': doctorId,
            'createdAt': DateTime.now().toIso8601String(),
          });

      // Save reference in doctor's appointments
      await _database
          .child('doctor_profiles')
          .child(doctorId)
          .child('appointments')
          .child(appointmentId)
          .set({
            'status': AppointmentStatus.pending.name,
            'patientId': patientId,
            'createdAt': DateTime.now().toIso8601String(),
          });

      debugPrint('✅ Appointment booked: $appointmentId');
      return appointmentId;
    } catch (e) {
      debugPrint('❌ Error booking appointment: $e');
      throw Exception('Failed to book appointment: $e');
    }
  }

  /// Get appointment by ID
  static Future<Map<String, dynamic>?> getAppointment(
    String appointmentId,
  ) async {
    try {
      final snapshot =
          await _database.child('appointments').child(appointmentId).get();

      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting appointment: $e');
      throw Exception('Failed to get appointment: $e');
    }
  }

  /// Get all appointments for a patient
  static Future<List<Map<String, dynamic>>> getPatientAppointments(
    String patientId,
  ) async {
    try {
      final snapshot =
          await _database
              .child('patient_profiles')
              .child(patientId)
              .child('appointments')
              .get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final appointmentIds =
          Map<String, dynamic>.from(snapshot.value as Map).keys;
      final appointments = <Map<String, dynamic>>[];

      for (final id in appointmentIds) {
        final appointment = await getAppointment(id);
        if (appointment != null) {
          appointments.add(appointment);
        }
      }

      // Sort by date (nearest first)
      appointments.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['appointmentDate'] ?? '') ?? DateTime.now();
        final dateB =
            DateTime.tryParse(b['appointmentDate'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      return appointments;
    } catch (e) {
      debugPrint('❌ Error getting patient appointments: $e');
      throw Exception('Failed to get patient appointments: $e');
    }
  }

  /// Get all appointments for a doctor
  static Future<List<Map<String, dynamic>>> getDoctorAppointments(
    String doctorId,
  ) async {
    try {
      final snapshot =
          await _database
              .child('doctor_profiles')
              .child(doctorId)
              .child('appointments')
              .get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final appointmentIds =
          Map<String, dynamic>.from(snapshot.value as Map).keys;
      final appointments = <Map<String, dynamic>>[];

      for (final id in appointmentIds) {
        final appointment = await getAppointment(id);
        if (appointment != null) {
          appointments.add(appointment);
        }
      }

      // Sort by date (nearest first)
      appointments.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['appointmentDate'] ?? '') ?? DateTime.now();
        final dateB =
            DateTime.tryParse(b['appointmentDate'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      return appointments;
    } catch (e) {
      debugPrint('❌ Error getting doctor appointments: $e');
      throw Exception('Failed to get doctor appointments: $e');
    }
  }

  /// Get pending appointments for doctor
  static Future<List<Map<String, dynamic>>> getDoctorPendingAppointments(
    String doctorId,
  ) async {
    try {
      final allAppointments = await getDoctorAppointments(doctorId);
      return allAppointments
          .where((app) => app['status'] == AppointmentStatus.pending.name)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting pending appointments: $e');
      throw Exception('Failed to get pending appointments: $e');
    }
  }

  /// Update appointment status
  static Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    try {
      final appointment = await getAppointment(appointmentId);
      if (appointment == null) {
        throw Exception('Appointment not found');
      }

      final patientId = appointment['patientId'];
      final doctorId = appointment['doctorId'];

      // Update main appointment record
      await _database.child('appointments').child(appointmentId).update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update in patient's appointments
      if (patientId != null) {
        await _database
            .child('patient_profiles')
            .child(patientId)
            .child('appointments')
            .child(appointmentId)
            .update({'status': status.name});
      }

      // Update in doctor's appointments
      if (doctorId != null) {
        await _database
            .child('doctor_profiles')
            .child(doctorId)
            .child('appointments')
            .child(appointmentId)
            .update({'status': status.name});
      }

      debugPrint(
        '✅ Appointment status updated: $appointmentId -> ${status.name}',
      );
    } catch (e) {
      debugPrint('❌ Error updating appointment status: $e');
      throw Exception('Failed to update appointment status: $e');
    }
  }

  /// Accept appointment
  static Future<void> acceptAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, AppointmentStatus.accepted);
  }

  /// Reject appointment
  static Future<void> rejectAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, AppointmentStatus.rejected);
  }

  /// Cancel appointment
  static Future<void> cancelAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
  }

  /// Get appointment status color
  static Color getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF4CAF50); // Green
      case 'rejected':
        return const Color(0xFFF44336); // Red
      case 'pending':
        return const Color(0xFFFFC107); // Yellow
      case 'cancelled':
        return const Color(0xFF9E9E9E); // Gray
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  /// Get appointment status text
  static String getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}
