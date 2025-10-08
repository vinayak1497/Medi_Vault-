import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:health_buddy/utils/constants.dart';

class AIService {
  static const String _apiKey = Constants.geminiApiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  /// Sends a message to Gemini API and returns the response
  Future<String> sendMessage(String message) async {
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
          return "I'm currently using the free version of Gemini AI which has limitations. For better responses, please configure a valid API key by following the instructions in docs/GEMINI_API_SETUP.md";
        } else {
          return "There seems to be an issue with the API key configuration. Please check your API key in lib/utils/constants.dart";
        }
      } else if (response.statusCode == 429) {
        // Handle rate limiting
        return "The AI service is currently busy. Please wait a moment and try again.";
      } else {
        return "I'm experiencing technical difficulties with the AI service (Status: ${response.statusCode}). Please try again later.";
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

Please provide information about 5 doctors near this location in the following JSON format:
{
  "doctors": [
    {
      "name": "Doctor's full name",
      "specialty": "Medical specialty",
      "address": "Full address",
      "phone": "Contact number",
      "distance": "Distance from user in km"
    }
  ]
}

Important guidelines:
1. Provide exactly 5 doctors
2. Include all required fields for each doctor
3. Make sure the information is realistic for the location
4. Format the response as valid JSON
5. If you don't have real data, create realistic fictional examples
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
          return text.trim();
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
