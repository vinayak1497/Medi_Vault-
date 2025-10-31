import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health_buddy/services/ai_service.dart';

/// Service to fetch nearby doctors using Gemini AI with location data
class GeminiNearbyDoctorService {
  final AIService _aiService = AIService();

  /// Get nearby doctors using Gemini API with patient's exact location
  /// Passes actual coordinates to Gemini to find doctors in that area
  Future<List<Map<String, dynamic>>> getNearbyDoctorsFromGemini(
    Position userPosition,
  ) async {
    try {
      final latitude = userPosition.latitude;
      final longitude = userPosition.longitude;

      // Get place name from coordinates using reverse geocoding info
      final areaInfo = _getAreaFromCoordinates(latitude, longitude);

      final prompt =
          '''You are a healthcare assistant with access to real-world medical facility data.

A patient is located at:
- Latitude: $latitude
- Longitude: $longitude
- Approximate Area: $areaInfo

Please find and list 8-12 real doctors, clinics, and hospitals that are actually located NEAR these coordinates (within 5-10 km radius). 

For each medical facility, provide:
1. Doctor/Clinic Name (must be real)
2. Doctor Name (if individual practice, provide actual doctor name)
3. Contact Phone Number (realistic format for the region)
4. Opening Time (HH:MM format)
5. Closing Time (HH:MM format)
6. Complete Address with building number and street
7. Specialty/Medical Field
8. Hospital/Clinic Type (Private/Government/Corporate)

IMPORTANT INSTRUCTIONS:
- Only include REAL, VERIFIABLE medical facilities that would logically exist in that region
- Do NOT make up facilities or fake names
- Include diverse specialties (General Practice, Cardiology, Orthopedics, Pediatrics, Dentistry, etc.)
- Phone numbers should match the country format for the region
- Provide realistic operating hours
- Include both individual clinics and larger hospitals

Format your response as a JSON array with this exact structure:
[
  {
    "clinicName": "Clinic/Hospital Name",
    "doctorName": "Doctor Full Name",
    "contactNumber": "Phone Number",
    "openingTime": "HH:MM",
    "closingTime": "HH:MM",
    "address": "Full Address",
    "specialty": "Medical Specialty",
    "facilityType": "Private/Government/Corporate",
    "latitude": approx_lat,
    "longitude": approx_lon
  }
]

Return ONLY the JSON array, no markdown, no extra text, no explanations.
''';

      debugPrint('📍 Searching for doctors near: $latitude, $longitude');
      debugPrint('🔍 Area: $areaInfo');

      final response = await _aiService.getResponse(prompt);
      debugPrint(
        '🤖 Gemini Response (first 500 chars): ${response.substring(0, (response.length > 500 ? 500 : response.length))}',
      );

      // Parse JSON response
      final List<Map<String, dynamic>> doctors = _parseNearbyDoctorsResponse(
        response,
      );

      if (doctors.isNotEmpty) {
        debugPrint('✅ Found ${doctors.length} nearby doctors from Gemini');
      } else {
        debugPrint('⚠️ No doctors found in response');
      }

      return doctors;
    } catch (e) {
      debugPrint('❌ Error getting nearby doctors from Gemini: $e');
      rethrow;
    }
  }

  /// Parse Gemini response and extract doctor information
  List<Map<String, dynamic>> _parseNearbyDoctorsResponse(String response) {
    try {
      // Clean the response - remove markdown code blocks if present
      String cleanedResponse = response;
      if (cleanedResponse.contains('```json')) {
        cleanedResponse =
            cleanedResponse
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();
      } else if (cleanedResponse.contains('```')) {
        cleanedResponse = cleanedResponse.replaceAll('```', '').trim();
      }

      debugPrint('📄 Cleaned Response: $cleanedResponse');

      final List<dynamic> jsonList = jsonDecode(cleanedResponse);

      final doctors = <Map<String, dynamic>>[];

      for (var doc in jsonList) {
        try {
          final Map<String, dynamic> doctorMap = Map<String, dynamic>.from(
            doc as Map,
          );

          // Ensure all required fields exist
          final doctor = {
            'clinicName':
                doctorMap['clinicName']?.toString() ?? 'Unknown Clinic',
            'doctorName': doctorMap['doctorName']?.toString() ?? 'Dr. Unknown',
            'contactNumber': doctorMap['contactNumber']?.toString() ?? '',
            'openingTime': doctorMap['openingTime']?.toString() ?? '09:00',
            'closingTime': doctorMap['closingTime']?.toString() ?? '18:00',
            'address':
                doctorMap['address']?.toString() ?? 'Address not available',
            'specialty':
                doctorMap['specialty']?.toString() ?? 'General Practice',
            'facilityType': doctorMap['facilityType']?.toString() ?? 'Private',
            'latitude': _parseDouble(doctorMap['latitude']),
            'longitude': _parseDouble(doctorMap['longitude']),
            'source': 'gemini_nearby',
          };

          doctors.add(doctor);
        } catch (e) {
          debugPrint('⚠️ Error parsing doctor entry: $e');
          continue;
        }
      }

      return doctors;
    } catch (e) {
      debugPrint('❌ Error parsing Gemini response: $e');
      debugPrint('Response was: $response');
      return [];
    }
  }

  /// Parse double value from various types
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Get area information from coordinates
  /// This is a simplified approach - in production you might use reverse geocoding
  String _getAreaFromCoordinates(double lat, double lon) {
    // Format: "Approximate coordinates: lat, lon"
    // Gemini will understand this and locate the general area
    return 'Coordinates: $lat, $lon (Urban Area)';
  }
}
