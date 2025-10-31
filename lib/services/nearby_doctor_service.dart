import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class NearbyDoctorService {
  static const double EARTH_RADIUS_KM = 6371;

  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));
    return EARTH_RADIUS_KM * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Get nearby doctors from Firebase with distance calculation
  /// Returns doctors within specified radius sorted by distance
  static Future<List<Map<String, dynamic>>> getNearbyDoctors({
    required Position userPosition,
    double radiusKm = 10,
  }) async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('doctor_profiles').get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final nearbyDoctors = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        try {
          final doctor = Map<String, dynamic>.from(value as Map);

          // Try to get coordinates from doctor profile
          final latitude = _parseCoordinate(doctor['latitude']);
          final longitude = _parseCoordinate(doctor['longitude']);

          if (latitude == null || longitude == null) {
            return; // Skip doctors without coordinates
          }

          // Calculate distance
          final distance = calculateDistance(
            userPosition.latitude,
            userPosition.longitude,
            latitude,
            longitude,
          );

          // Check if within radius
          if (distance <= radiusKm) {
            doctor['doctorId'] = key;
            doctor['source'] = 'firebase';
            doctor['distance'] = distance;
            doctor['displayDistance'] =
                distance < 1
                    ? '${(distance * 1000).toStringAsFixed(0)} m'
                    : '${distance.toStringAsFixed(1)} km';

            nearbyDoctors.add(doctor);
          }
        } catch (e) {
          // Skip this doctor if there's an error
        }
      });

      // Sort by distance
      nearbyDoctors.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      return nearbyDoctors;
    } catch (e) {
      print('❌ Error getting nearby doctors: $e');
      return [];
    }
  }

  /// Parse coordinate value - handles various formats
  static double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    try {
      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value);
      }
    } catch (e) {
      // Return null if parsing fails
    }

    return null;
  }

  /// Search doctors by specialty within radius
  static Future<List<Map<String, dynamic>>> searchDoctorsBySpecialty({
    required Position userPosition,
    required String specialty,
    double radiusKm = 10,
  }) async {
    try {
      final allNearby = await getNearbyDoctors(
        userPosition: userPosition,
        radiusKm: radiusKm,
      );

      return allNearby
          .where(
            (doctor) =>
                (doctor['specialization'] ?? '').toLowerCase().contains(
                  specialty.toLowerCase(),
                ) ||
                (doctor['specialty'] ?? '').toLowerCase().contains(
                  specialty.toLowerCase(),
                ),
          )
          .toList();
    } catch (e) {
      print('❌ Error searching doctors by specialty: $e');
      return [];
    }
  }

  /// Get all registered doctors (no distance filtering)
  static Future<List<Map<String, dynamic>>> getAllRegisteredDoctors() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('doctor_profiles').get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final doctors = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final doctor = Map<String, dynamic>.from(value as Map);
        doctor['doctorId'] = key;
        doctor['source'] = 'firebase';
        doctors.add(doctor);
      });

      return doctors;
    } catch (e) {
      print('❌ Error getting all doctors: $e');
      return [];
    }
  }
}
