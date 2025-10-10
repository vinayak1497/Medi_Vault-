import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:health_buddy/utils/constants.dart';

class AIService {
  final String _apiKey = Constants.apiKey;
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> getResponse(String prompt) async {
    try {
      final Uri url;
      final Map<String, String> headers = {'Content-Type': 'application/json'};

      // Add API key to URL if provided
      if (_apiKey.isNotEmpty) {
        url = Uri.parse('$_baseUrl?key=$_apiKey');
      } else {
        // Using the free API endpoint without API key
        // Note: This may have limitations
        url = Uri.parse(_baseUrl);
      }

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

  /// Sends a message to Gemini API and returns the response
  Future<String> sendMessage(String message) async {
    // Add a safety check for empty messages
    if (message.trim().isEmpty) {
      return "Please enter a valid question.";
    }

    try {
      final Uri url;
      final Map<String, String> headers = {'Content-Type': 'application/json'};

      // Add API key to URL if provided
      if (_apiKey.isNotEmpty) {
        url = Uri.parse('$_baseUrl?key=$_apiKey');
      } else {
        // Using the free API endpoint without API key
        // Note: This may have limitations
        url = Uri.parse(_baseUrl);
      }

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
      final Uri url;
      final Map<String, String> headers = {'Content-Type': 'application/json'};

      // Add API key to URL if provided
      if (_apiKey.isNotEmpty) {
        url = Uri.parse('$_baseUrl?key=$_apiKey');
      } else {
        // Using the free API endpoint without API key
        // Note: This may have limitations
        url = Uri.parse(_baseUrl);
      }

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
}
