import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:medivault_ai/utils/constants.dart';

class AIService {
  final String _apiKey = Constants.apiKey;
  // Use the URL from constants
  final String _baseUrl = Constants.apiUrl;

  Future<String> getResponse(String prompt) async {
    try {
      // Build URL without embedding API key. Auth is via header x-goog-api-key.
      final Uri url = Uri.parse(_baseUrl);
      final Map<String, String> headers = _getAuthHeaders();

      // Add timeout to prevent hanging
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          'You are a professional healthcare assistant. Provide accurate, helpful and concise medical information. Answer the following health-related question: $prompt\n\nImportant: Be concise and helpful. If you\'re unsure about something, recommend consulting with a healthcare professional.',
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if response has the expected structure
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return text.trim();
        } else {
          // Handle cases where API returns no candidates
          return "I couldn't generate a proper response to your question. Please try rephrasing or ask another health-related question.";
        }
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // Handle authentication issues
        if (_apiKey.isEmpty) {
          return '{"error":"API key is missing. Please configure a valid Gemini API key by following the instructions in README.md"}';
        } else {
          // Provide more specific error information
          String errorMessage = "API key authentication failed. ";
          if (response.statusCode == 400) {
            errorMessage += "Bad request - check API key validity.";
          } else if (response.statusCode == 403) {
            errorMessage +=
                "Access forbidden - API key may be invalid or expired.";
          }
          errorMessage +=
              " Please check your Gemini API key in lib/utils/constants.dart";
          return '{"error":"$errorMessage"}';
        }
      } else if (response.statusCode == 429) {
        // Handle rate limiting
        return '{"error":"The AI service is currently busy. Please wait a moment and try again."}';
      } else {
        return '{"error":"I\'m experiencing technical difficulties with the AI service (Status: ${response.statusCode}). Please try again later."}';
      }
    } on TimeoutException catch (_) {
      return "The request to the AI service timed out. Please check your internet connection and try again.";
    } catch (e) {
      // Provide a more helpful fallback message
      return "I'm having trouble connecting to the AI service right now. Please check your internet connection or try again later. Remember to consult with a healthcare professional for serious medical concerns.";
    }
  }

  /// Minimal image-to-text extraction using Gemini 2.5 Flash
  /// Returns plain text only (no JSON), or an error message on failure
  Future<Map<String, dynamic>> extractPlainTextFromImage(
    String imagePath,
  ) async {
    try {
      final File imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        return {
          'error': 'Image file not found at path: $imagePath',
          'text': null,
        };
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = await Isolate.run(() => base64Encode(imageBytes));
      final String mimeType = _getMimeType(imagePath);

      const String prompt =
          'Transcribe ALL visible text from the prescription image, including handwritten and faint text, '
          'as plain UTF-8 text. Preserve natural line breaks and ordering from top-to-bottom and left-to-right. '
          'Do not summarize. Do not omit difficult handwriting—attempt best-effort transcription. '
          'Do NOT return JSON or markdown; return ONLY the raw text.';

      final Uri url = Uri.parse(_baseUrl);

      await _throttlePerMinute();
      await _waitForRateLimit();

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.0,
          'topK': 32,
          'topP': 0.9,
          'maxOutputTokens': 8192,
        },
      };

      debugPrint('🌐 [PlainText] API URL: $url');
      debugPrint(
        '🔑 [PlainText] API Key prefix: '
        '${_apiKey.isNotEmpty ? _apiKey.substring(0, 6) : '(empty)'}',
      );

      final response = await http
          .post(url, headers: _getAuthHeaders(), body: jsonEncode(requestBody))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        if (response.statusCode == 429) {
          return {
            'error': 'API rate limit exceeded. Please wait and try again.',
            'text': null,
          };
        }
        return {
          'error': 'API error: Status ${response.statusCode}.',
          'text': null,
        };
      }

      final data = jsonDecode(response.body);
      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null &&
          data['candidates'][0]['content']['parts'].isNotEmpty) {
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return {'error': null, 'text': (text ?? '').toString().trim()};
      }

      return {'error': 'No valid response from API', 'text': null};
    } on TimeoutException {
      return {
        'error': 'Request timeout. Please check your internet connection.',
        'text': null,
      };
    } catch (e) {
      return {'error': 'Error extracting text: ${e.toString()}', 'text': null};
    }
  }

  /// Normalize prescription text:
  /// - Translate to English if needed
  /// - Clean up OCR artifacts
  /// - Format into a standardized, readable structure (plain text)
  /// Returns formatted text on success; original text on strict failures is handled by caller
  Future<String> normalizePrescriptionText(String rawText) async {
    final String input = rawText.trim();
    if (input.isEmpty) return '';

    try {
      await _throttlePerMinute();
      await _waitForRateLimit();

      const String instructions =
          'You are an expert medical scribe. Transform the following prescription text into a '
          'clear, standardized summary in ENGLISH. If the text is in any other language, translate '
          'faithfully to English. Do NOT invent missing data. If a field is not present, use "-".\n\n'
          'Output format (plain text ONLY, no markdown, no JSON):\n'
          'Patient\n'
          '- Name: <name or ->\n'
          '- Age: <age or ->\n'
          '- Gender: <gender or ->\n'
          '- Date: <date or ->\n\n'
          'Doctor\n'
          '- Name: <name or ->\n'
          '- Registration No: <number or ->\n'
          '- Clinic: <clinic/hospital or ->\n\n'
          'Diagnosis / Chief Complaint:\n'
          '<diagnosis or ->\n\n'
          'Medications:\n'
          '1) <Drug name> <strength> — <route if present> — <frequency> — <duration> — <instructions>\n'
          '2) ... (one per line; include only if present)\n\n'
          'Investigations:\n'
          '<tests or ->\n\n'
          'Advice / Instructions:\n'
          '<advice or ->\n\n'
          'Follow-up:\n'
          '<follow-up plan or ->\n\n'
          'Notes:\n'
          '<additional notes or ->\n\n'
          'Rules:\n'
          '• Keep it concise and readable.\n'
          '• Use the exact section order and labels above.\n'
          '• Use dashes (-) for missing fields.\n'
          '• Do not add commentary or disclaimers.\n'
          '• Return plain text only.';

      final Uri url = Uri.parse(_baseUrl);
      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': instructions},
              {'text': '\n\n---\nSOURCE TEXT:\n$input'},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 1024},
      };

      final response = await http
          .post(url, headers: _getAuthHeaders(), body: jsonEncode(requestBody))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        // On rate limit or other errors, let caller fallback
        debugPrint('[Normalize] API error: ${response.statusCode}');
        return '';
      }

      final data = jsonDecode(response.body);
      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null &&
          data['candidates'][0]['content']['parts'].isNotEmpty) {
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return (text ?? '').toString().trim();
      }

      return '';
    } on TimeoutException {
      return '';
    } catch (e) {
      debugPrint('[Normalize] Error: $e');
      return '';
    }
  }

  /// Sends a message to Gemini API and returns the response
  Future<String> sendMessage(String message) async {
    // Add a safety check for empty messages
    if (message.trim().isEmpty) {
      return "Please enter a valid question.";
    }

    try {
      // Build URL without embedding API key. Auth is via header x-goog-api-key.
      final Uri url = Uri.parse(_baseUrl);
      final Map<String, String> headers = _getAuthHeaders();

      // Add timeout to prevent hanging
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          'You are a professional healthcare assistant. Provide accurate, helpful and concise medical information. Answer the following health-related question: $message\n\nImportant: Be concise and helpful. If you\'re unsure about something, recommend consulting with a healthcare professional.',
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if response has the expected structure
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return text.trim();
        } else {
          // Handle cases where API returns no candidates
          return "I couldn't generate a proper response to your question. Please try rephrasing or ask another health-related question.";
        }
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // Handle authentication issues
        if (_apiKey.isEmpty) {
          return '{"error":"API key is missing. Please configure a valid Gemini API key by following the instructions in README.md"}';
        } else {
          // Provide more specific error information
          String errorMessage = "API key authentication failed. ";
          if (response.statusCode == 400) {
            errorMessage += "Bad request - check API key validity.";
          } else if (response.statusCode == 403) {
            errorMessage +=
                "Access forbidden - API key may be invalid or expired.";
          }
          errorMessage +=
              " Please check your Gemini API key in lib/utils/constants.dart";
          return '{"error":"$errorMessage"}';
        }
      } else if (response.statusCode == 429) {
        // Handle rate limiting
        return '{"error":"The AI service is currently busy. Please wait a moment and try again."}';
      } else {
        return '{"error":"I\'m experiencing technical difficulties with the AI service (Status: ${response.statusCode}). Please try again later."}';
      }
    } on TimeoutException catch (_) {
      return "The request to the AI service timed out. Please check your internet connection and try again.";
    } catch (e) {
      // Provide a more helpful fallback message
      return "I'm having trouble connecting to the AI service right now. Please check your internet connection or try again later. Remember to consult with a healthcare professional for serious medical concerns.";
    }
  }

  /// Finds nearby doctors based on location using Gemini API
  Future<String> findNearbyDoctors(double latitude, double longitude) async {
    try {
      // Build URL without embedding API key. Auth is via header x-goog-api-key.
      final Uri url = Uri.parse(_baseUrl);
      final Map<String, String> headers = _getAuthHeaders();

      final prompt = '''
You are a healthcare assistant that helps users find doctors near their location.
User location: Latitude $latitude, Longitude $longitude

Please provide information about doctors near this location in the following EXACT JSON format:
{
  "doctors": [
    {
      "name": "Doctor's full name",
      "specialty": "Medical specialty",
      "clinic": "Clinic or hospital name",
      "address": "Full address",
      "phone": "Contact number with country code",
      "distance": "Distance from user in km",
      "lat": latitude_number,
      "lng": longitude_number,
      "reviews": rating_number
    }
  ]
}

VERY IMPORTANT INSTRUCTIONS:
1. Return ONLY valid JSON, no other text
2. Do not use markdown code blocks
3. Use real numbers for lat, lng, and reviews (not strings)
4. Make sure phone numbers include country code
5. Provide at least 3 doctors if possible
6. Find REAL doctors near the provided coordinates (Latitude: $latitude, Longitude: $longitude)
7. If you cannot find real doctors at this exact location, find doctors in the same city/area
8. Distance should be realistic (within 5 km if possible)
9. Make sure all fields are filled with realistic data
10. If you absolutely cannot find any doctors in this area, return an empty doctors array: {"doctors":[]}
11. DO NOT make up fake doctors with fictional names and addresses - try to find real doctors or return empty array

Example of correct response format:
{
  "doctors": [
    {
      "name": "Dr. Ramesh Kumar",
      "specialty": "Cardiologist",
      "clinic": "Apollo Heart Center",
      "address": "123 Bannerghatta Road, Bangalore",
      "phone": "+91 80 1234 5678",
      "distance": "2.5 km",
      "lat": 12.9716,
      "lng": 77.5946,
      "reviews": 4.8
    }
  ]
}
''';

      // Add timeout to prevent hanging
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if response has the expected structure
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];

          // Extract JSON from the response text
          // Look for JSON data between curly braces
          String jsonString = text;

          // Remove markdown code block markers if present
          if (jsonString.contains('```json')) {
            final start = jsonString.indexOf('```json') + 7;
            final end = jsonString.lastIndexOf('```');
            if (start > 6 && end > start) {
              jsonString = jsonString.substring(start, end).trim();
            }
          } else if (jsonString.contains('```')) {
            final start = jsonString.indexOf('```') + 3;
            final end = jsonString.lastIndexOf('```');
            if (start > 2 && end > start) {
              jsonString = jsonString.substring(start, end).trim();
            }
          }

          // Find the first { and last } to extract JSON
          final jsonStart = jsonString.indexOf('{');
          final jsonEnd = jsonString.lastIndexOf('}');

          if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
            jsonString = jsonString.substring(jsonStart, jsonEnd + 1);

            // Validate that this is valid JSON
            try {
              final jsonData = jsonDecode(jsonString);

              // Check if it has the expected doctors structure
              if (jsonData is Map && jsonData.containsKey('doctors')) {
                return jsonString;
              } else {
                // If structure is not as expected, return empty doctors array
                return '{"doctors":[]}';
              }
            } catch (e) {
              // If JSON parsing fails, return an empty doctors array
              return '{"doctors":[]}';
            }
          } else {
            // If no JSON found, return an empty doctors array
            return '{"doctors":[]}';
          }
        } else {
          // Handle cases where API returns no candidates
          return '{"doctors":[]}';
        }
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // Handle authentication issues
        if (_apiKey.isEmpty) {
          return '{"error":"API key required for this feature. Please configure a valid API key by following the instructions in docs/GEMINI_API_SETUP.md"}';
        } else {
          return '{"error":"There seems to be an issue with the API key configuration. Please check your API key in lib/utils/constants.dart"}';
        }
      } else if (response.statusCode == 404) {
        // Handle endpoint not found
        return '{"error":"API endpoint not found. The model or endpoint may be incorrect or deprecated. Please check the model name in lib/services/ai_service.dart"}';
      } else if (response.statusCode == 429) {
        // Handle rate limiting
        return '{"error":"The AI service is currently busy. Please wait a moment and try again."}';
      } else {
        return '{"error":"I\'m experiencing technical difficulties with the AI service (Status: ${response.statusCode}). Please try again later."}';
      }
    } on TimeoutException catch (_) {
      return '{"error":"The request to the AI service timed out. Please check your internet connection and try again."}';
    } catch (e) {
      // Provide a more helpful fallback message
      return '{"error":"I\'m having trouble connecting to the AI service right now. Please check your internet connection or try again later."}';
    }
  }

  /// Helper method to create authenticated request URL and headers
  Map<String, String> _getAuthHeaders() {
    // Authenticate using API key header as required by Gemini API
    return {'Content-Type': 'application/json', 'X-goog-api-key': _apiKey};
  }

  /// Rate limiting variables
  static DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(
    milliseconds: 500,
  ); // 500ms between requests
  static const _maxRetries = 3;
  static const _initialBackoff = Duration(seconds: 2);
  // Per-minute throttle to avoid server-side 429
  static DateTime? _rpmWindowStart;
  static int _rpmCount = 0;

  /// Delay between requests to respect rate limits
  Future<void> _waitForRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Ensure we do not exceed a conservative per-minute quota
  Future<void> _throttlePerMinute() async {
    final now = DateTime.now();
    _rpmWindowStart ??= now;
    // Reset window if more than 60s elapsed
    if (now.difference(_rpmWindowStart!).inSeconds >= 60) {
      _rpmWindowStart = now;
      _rpmCount = 0;
    }
    // If exceeded, wait remaining seconds in the minute window
    if (_rpmCount >= Constants.maxRequestsPerMinute) {
      final waitMs = 60000 - now.difference(_rpmWindowStart!).inMilliseconds;
      if (waitMs > 0) {
        debugPrint('⏳ Throttling to avoid 429. Waiting ${waitMs ~/ 1000}s');
        await Future.delayed(Duration(milliseconds: waitMs));
      }
      _rpmWindowStart = DateTime.now();
      _rpmCount = 0;
    }
    _rpmCount++;
  }

  /// Extract prescription data from a handwritten prescription image using Gemini Flash API
  /// Uses image input capability to fetch textual and contextual information
  Future<Map<String, dynamic>> extractPrescriptionFromImage(
    String imagePath,
  ) async {
    try {
      final File imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        return {
          'error': 'Image file not found at path: $imagePath',
          'data': null,
        };
      }

      // Read image file and convert to base64 off the UI isolate
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = await Isolate.run(() => base64Encode(imageBytes));

      // Determine MIME type from file extension
      final String mimeType = _getMimeType(imagePath);

      // Prepare the prompt for prescription extraction
      const String extractionPrompt =
          '''You are an expert medical prescription analyzer. Your task is to carefully analyze this prescription image and extract information into a structured format.

IMPORTANT INSTRUCTIONS:
1. Extract ALL text visible in the prescription image, including partially visible or unclear text
2. For any field not visible or unclear, use null or empty string
3. Parse medication details carefully and match to standard formats
4. Match dosage frequencies to: "Once daily", "Twice daily", "Three times daily", "Four times daily", "As needed"
5. Match dosage forms to: "Tablet", "Capsule", "Syrup", "Injection", "Drops", "Cream", "Ointment"
6. Return ONLY valid JSON, no other text
7. Look for section headers like "Symptoms:", "Diagnosis:", "Rx:", "Medicines:", "Instructions:", etc.
8. If text is unclear but context suggests what it might be, include it with low confidence note
9. Include ALL visible text somewhere in the output

Extract the information into this EXACT JSON structure:
{
  "patientName": null,
  "patientAge": null,
  "patientGender": null,
  "opdRegistrationNumber": null,
  "prescriptionDate": null,
  "currentSymptoms": null,
  "diagnosis": null,
  "medicalHistory": null,
  "allergies": null,
  "vitalSigns": null,
  "medications": [
    {
      "name": "Medicine name",
      "genericName": "Generic name if specified",
      "strength": "Strength with units (e.g., 500 mg)",
      "dosageForm": "One of: Tablet/Capsule/Syrup/Injection/Drops/Cream/Ointment",
      "frequency": "One of: Once daily/Twice daily/Three times daily/Four times daily/As needed",
      "duration": "Duration (e.g., 5 days, 1 week)",
      "instructions": "Additional instructions for this medication"
    }
  ],
  "instructions": null,
  "precautions": null,
  "followUpInstructions": null,
  "dietaryAdvice": null,
  "additionalNotes": null
}

DO NOT return any text outside the JSON. Return only a valid JSON object.''';

      // Make API call to Gemini with retries (API key in header, not URL)
      final Uri url = Uri.parse(_baseUrl);
      http.Response? response;
      var retryCount = 0;
      var currentBackoff = _initialBackoff;

      // Apply client-side per-minute throttling before first attempt
      await _throttlePerMinute();

      while (retryCount < 1) {
        // avoid spamming server on 429; one attempt
        try {
          // Wait for rate limit before making request
          await _waitForRateLimit();

          // Print request details for debugging
          final requestBody = {
            // Model is specified in the URL
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': extractionPrompt},
                  {
                    'inline_data': {'mime_type': mimeType, 'data': base64Image},
                  },
                ],
              },
            ],
            // Use camelCase per Gemini API spec
            'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 2048},
          };

          debugPrint('🌐 API URL: $url');
          debugPrint(
            '🔑 API Key prefix: ${_apiKey.isNotEmpty ? _apiKey.substring(0, 10) : '(empty)'}',
          );
          debugPrint('📤 Request Body Structure: ${jsonEncode(requestBody)}');

          response = await http
              .post(
                url,
                headers: _getAuthHeaders(),
                body: jsonEncode(requestBody),
              )
              .timeout(const Duration(seconds: 60));

          // Success - break out of retry loop
          if (response.statusCode == 200) {
            break;
          }

          // Rate limit hit - bail out early; caller may fallback to OCR
          if (response.statusCode == 429) {
            break;
          }

          // Other error - break out
          break;
        } catch (e) {
          retryCount++;
          if (retryCount < _maxRetries) {
            debugPrint(
              '⚠️ Request failed, retrying in ${currentBackoff.inSeconds}s: $e',
            );
            await Future.delayed(currentBackoff);
            currentBackoff *= 2;
            continue;
          }
          rethrow;
        }
      }

      if (response == null) {
        return {
          'error': 'Failed to get response from API after retries',
          'data': null,
        };
      }

      // Log non-200 responses to aid debugging
      if (response.statusCode != 200) {
        debugPrint('📥 Response Status: ${response.statusCode}');
        final bodyPreview =
            response.body.length > 500
                ? '${response.body.substring(0, 500)}...'
                : response.body;
        debugPrint('📥 Response Body (truncated): $bodyPreview');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final responseText =
              data['candidates'][0]['content']['parts'][0]['text'];

          // Extract JSON from response
          final parsedJson = _extractJsonFromResponse(responseText);

          if (parsedJson != null) {
            return {'error': null, 'data': parsedJson};
          } else {
            return {
              'error': 'Failed to parse prescription data from image',
              'data': null,
            };
          }
        } else {
          return {'error': 'No valid response from API', 'data': null};
        }
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        return {
          'error':
              _apiKey.isEmpty
                  ? 'API key is missing. Please configure a valid Gemini API key.'
                  : 'API key authentication failed. Please check your Gemini API key.',
          'data': null,
        };
      } else if (response.statusCode == 429) {
        return {
          'error': 'API rate limit exceeded. Please wait and try again.',
          'data': null,
        };
      } else {
        return {
          'error':
              'API error: Status ${response.statusCode}. Please try again later.',
          'data': null,
        };
      }
    } on TimeoutException {
      return {
        'error': 'Request timeout. Please check your internet connection.',
        'data': null,
      };
    } catch (e) {
      return {
        'error': 'Error extracting prescription: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Helper method to determine MIME type from file extension
  String _getMimeType(String filePath) {
    final ext = filePath.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Extract JSON object from API response text
  Map<String, dynamic>? _extractJsonFromResponse(String responseText) {
    try {
      // Remove markdown code blocks if present
      String jsonString = responseText;

      if (jsonString.contains('```json')) {
        final start = jsonString.indexOf('```json') + 7;
        final end = jsonString.lastIndexOf('```');
        if (start > 6 && end > start) {
          jsonString = jsonString.substring(start, end).trim();
        }
      } else if (jsonString.contains('```')) {
        final start = jsonString.indexOf('```') + 3;
        final end = jsonString.lastIndexOf('```');
        if (start > 2 && end > start) {
          jsonString = jsonString.substring(start, end).trim();
        }
      }

      // Find JSON object boundaries
      final jsonStart = jsonString.indexOf('{');
      final jsonEnd = jsonString.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonString = jsonString.substring(jsonStart, jsonEnd + 1);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }

      // Try parsing the entire string as JSON
      return jsonDecode(responseText) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing JSON response: $e');
      return null;
    }
  }
}
