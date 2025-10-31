import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:health_buddy/utils/constants.dart';

/// PersonalizedHealthAIService enhances AI responses with patient-specific healthcare data
/// Fetches prescriptions, medical history, and other health data from Firebase,
/// then provides this as context to Gemini for personalized health advice
class PersonalizedHealthAIService {
  final String _apiKey = Constants.apiKey;
  final String _baseUrl = Constants.apiUrl;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get authorization headers for Gemini API
  Map<String, String> _getAuthHeaders() {
    return {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey};
  }

  /// Fetch all prescriptions for the current patient
  /// Searches through Firebase prescriptions and returns those matching patient name
  Future<List<Map<String, dynamic>>> _getPatientPrescriptions(
    String patientName,
    String patientId,
  ) async {
    try {
      debugPrint(
        '🔍 Fetching prescriptions for patient: $patientName ($patientId)',
      );

      final prescriptions = <Map<String, dynamic>>[];

      // Try to fetch from root prescriptions node
      final snapshot = await _database.ref('prescriptions').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          data.forEach((key, value) {
            if (value is Map) {
              final prescription = Map<String, dynamic>.from(value);
              final rxPatientName =
                  (prescription['patientName'] ?? '')
                      .toString()
                      .toLowerCase()
                      .trim();
              final searchPatientName = patientName.toLowerCase().trim();

              // Match patient by name (case-insensitive)
              if (rxPatientName == searchPatientName) {
                prescription['id'] = key;
                prescriptions.add(prescription);
                debugPrint(
                  '✅ Found matching prescription: ${prescription['id']}',
                );
              }
            }
          });
        }
      }

      debugPrint('📋 Total prescriptions found: ${prescriptions.length}');
      return prescriptions;
    } catch (e) {
      debugPrint('❌ Error fetching prescriptions: $e');
      return [];
    }
  }

  /// Fetch medical conditions and allergies for the patient
  Future<Map<String, dynamic>> _getPatientMedicalInfo(String patientId) async {
    try {
      debugPrint('🔍 Fetching medical info for patient: $patientId');

      final snapshot = await _database.ref('users/$patientId').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          final medicalInfo = {
            'bloodGroup': data['bloodGroup'] ?? 'Unknown',
            'pastConditions': data['pastConditions'] ?? 'None',
            'allergies': data['allergies'] ?? [],
            'emergencyContactName': data['emergencyContactName'],
            'emergencyContactPhone': data['emergencyContactPhone'],
          };
          debugPrint('✅ Retrieved medical info: $medicalInfo');
          return medicalInfo;
        }
      }

      return {'error': 'No medical info found'};
    } catch (e) {
      debugPrint('❌ Error fetching medical info: $e');
      return {'error': e.toString()};
    }
  }

  /// Format prescriptions into a readable context string for AI
  String _formatPrescriptionsContext(
    List<Map<String, dynamic>> prescriptions,
    String patientName,
  ) {
    if (prescriptions.isEmpty) {
      return 'No prescriptions found for $patientName.';
    }

    final buffer = StringBuffer();
    buffer.writeln('PATIENT MEDICAL HISTORY FOR $patientName:');
    buffer.writeln('=' * 60);
    buffer.writeln('Total Prescriptions: ${prescriptions.length}\n');

    for (int i = 0; i < prescriptions.length; i++) {
      final rx = prescriptions[i];
      buffer.writeln('PRESCRIPTION ${i + 1}:');
      buffer.writeln('-' * 40);

      // Add prescription date
      if (rx['prescriptionDate'] != null) {
        buffer.writeln('Date: ${rx['prescriptionDate']}');
      }

      // Add doctor info
      if (rx['doctorName'] != null) {
        buffer.writeln('Doctor: ${rx['doctorName']}');
      }

      // Add diagnosis
      if (rx['diagnosis'] != null && (rx['diagnosis'] as String).isNotEmpty) {
        buffer.writeln('Diagnosis: ${rx['diagnosis']}');
      }

      // Add chief complaint/symptoms
      if (rx['currentSymptoms'] != null &&
          (rx['currentSymptoms'] as String).isNotEmpty) {
        buffer.writeln('Chief Complaint: ${rx['currentSymptoms']}');
      }

      // Add medical history
      if (rx['medicalHistory'] != null &&
          (rx['medicalHistory'] as String).isNotEmpty) {
        buffer.writeln('Medical History: ${rx['medicalHistory']}');
      }

      // Add medications
      if (rx['medications'] != null && rx['medications'] is List) {
        buffer.writeln('\nMedications:');
        final medications = rx['medications'] as List;
        for (var med in medications) {
          if (med is Map) {
            final medName = med['name'] ?? 'Unknown';
            final dose = med['dosage'] ?? '';
            final frequency = med['frequency'] ?? '';
            final duration = med['duration'] ?? '';
            buffer.writeln('  • $medName $dose - $frequency for $duration');
          }
        }
      }

      // Add allergies if present
      if (rx['allergies'] != null && (rx['allergies'] as String).isNotEmpty) {
        buffer.writeln('\nAllergies: ${rx['allergies']}');
      }

      // Add precautions
      if (rx['precautions'] != null &&
          (rx['precautions'] as String).isNotEmpty) {
        buffer.writeln('\nPrecautions: ${rx['precautions']}');
      }

      // Add follow-up instructions
      if (rx['followUpInstructions'] != null &&
          (rx['followUpInstructions'] as String).isNotEmpty) {
        buffer.writeln('Follow-up: ${rx['followUpInstructions']}');
      }

      // Add general instructions
      if (rx['instructions'] != null &&
          (rx['instructions'] as String).isNotEmpty) {
        buffer.writeln('Instructions: ${rx['instructions']}');
      }

      // Add investigations/tests
      if (rx['investigationsAdvised'] != null &&
          (rx['investigationsAdvised'] as String).isNotEmpty) {
        buffer.writeln('Investigations: ${rx['investigationsAdvised']}');
      }

      buffer.writeln('');
    }

    buffer.writeln('=' * 60);
    return buffer.toString();
  }

  /// Format medical info into context string
  String _formatMedicalInfoContext(Map<String, dynamic> medicalInfo) {
    final buffer = StringBuffer();
    buffer.writeln('\nPATIENT MEDICAL PROFILE:');
    buffer.writeln('-' * 40);
    buffer.writeln('Blood Group: ${medicalInfo['bloodGroup'] ?? 'Unknown'}');

    if (medicalInfo['pastConditions'] != null) {
      buffer.writeln('Past Conditions: ${medicalInfo['pastConditions']}');
    }

    if (medicalInfo['allergies'] != null) {
      final allergies = medicalInfo['allergies'];
      if (allergies is List && allergies.isNotEmpty) {
        buffer.writeln('Allergies: ${allergies.join(', ')}');
      } else if (allergies is String && allergies.isNotEmpty) {
        buffer.writeln('Allergies: $allergies');
      }
    }

    return buffer.toString();
  }

  /// Send a personalized message using patient data context
  /// This is the main method to use instead of regular AI service for personalized responses
  Future<String> sendPersonalizedMessage(String userQuery) async {
    try {
      if (userQuery.trim().isEmpty) {
        return 'Please enter a valid question.';
      }

      // Get current user info
      final user = _auth.currentUser;
      if (user == null) {
        return 'Please log in to use personalized health assistant.';
      }

      debugPrint('🔐 Getting personalized response for user: ${user.uid}');

      // Get patient profile
      final profileSnapshot = await _database.ref('users/${user.uid}').get();
      if (!profileSnapshot.exists) {
        return 'Patient profile not found. Please complete your profile setup.';
      }

      final profileData = profileSnapshot.value as Map?;
      if (profileData == null) {
        return 'Unable to retrieve patient profile.';
      }

      final patientName = profileData['fullName'] ?? 'Patient';

      // Fetch prescriptions and medical info in parallel
      final prescriptionsFuture = _getPatientPrescriptions(
        patientName,
        user.uid,
      );
      final medicalInfoFuture = _getPatientMedicalInfo(user.uid);

      final prescriptions = await prescriptionsFuture;
      final medicalInfo = await medicalInfoFuture;

      // Format context
      final prescriptionsContext = _formatPrescriptionsContext(
        prescriptions,
        patientName,
      );
      final medicalContext = _formatMedicalInfoContext(medicalInfo);

      // Build the enhanced prompt with context
      final contextPrompt = '''
You are a professional healthcare AI assistant specifically trained to provide personalized health advice to patients.

PATIENT CONTEXT:
Patient Name: $patientName

$prescriptionsContext
$medicalContext

PATIENT QUESTION: $userQuery

Based on the patient's medical history, prescriptions, and current health profile provided above, answer their health question in a friendly, personalized manner. 

IMPORTANT GUIDELINES:
1. Always be empathetic and use the patient's name when appropriate
2. Reference specific medications, conditions, or allergies from their history when relevant
3. Provide context about their prescriptions when answering medication-related questions
4. Consider their past medical conditions and allergies in your response
5. Be concise but thorough
6. If the question is serious or urgent, recommend consulting their doctor
7. Always emphasize that you're providing general guidance, not medical diagnosis
8. If you don't have enough context from their records, acknowledge this and ask them to clarify
9. Remember to be encouraging and supportive in your tone
10. For medication questions, specifically reference which doctor prescribed it and when

RESPONSE FORMAT:
- Start with a personalized greeting if appropriate
- Answer their specific question with context from their history
- If referencing prescriptions, mention the doctor's name and approximate date
- End with supportive advice or encouragement to follow up with their doctor if needed
''';

      debugPrint('📤 Sending personalized message to Gemini...');

      final Uri url = Uri.parse(_baseUrl);
      final response = await http
          .post(
            url,
            headers: _getAuthHeaders(),
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': contextPrompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.7,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': 1024,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          debugPrint('✅ Personalized response received from Gemini');
          return text.trim();
        }
      }

      return 'Unable to generate personalized response. Please try again or consult with your healthcare provider.';
    } catch (e) {
      debugPrint('❌ Error in personalized message: $e');
      return 'I encountered an error while generating your personalized response. Please check your internet connection and try again.';
    }
  }

  /// Check if user has any medical history/prescriptions for better responses
  Future<bool> hasPatientHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _database.ref('users/${user.uid}').get();
      return snapshot.exists;
    } catch (e) {
      debugPrint('Error checking patient history: $e');
      return false;
    }
  }
}
