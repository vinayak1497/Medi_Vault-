import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medivault_ai/utils/constants.dart';
import 'package:medivault_ai/models/gov_scheme.dart';

/// Service to fetch government medical and health schemes using Gemini API
class GovSchemeAIService {
  final String _apiKey = Constants.apiKey;
  final String _baseUrl = Constants.apiUrl;

  /// Fetch all government medical and health schemes from Gemini API
  /// Returns a list of GovScheme objects with details and website links
  Future<List<GovScheme>> fetchGovernmentMedicalSchemes() async {
    try {
      final Uri url = Uri.parse(_baseUrl);
      final Map<String, String> headers = _getAuthHeaders();

      // Comprehensive prompt to Gemini for fetching government medical schemes
      final String prompt = '''
You are a healthcare information specialist. Provide detailed information about government medical and health schemes in India.

For EACH government medical/health scheme, provide the following information in this EXACT JSON format:
[
  {
    "id": "unique_id",
    "title": "Scheme Name",
    "description": "2-3 line brief description",
    "eligibility": "Who is eligible (e.g., poor families, government employees, etc.)",
    "benefits": "Key benefits provided (comma-separated)",
    "websiteUrl": "https://official-website-link",
    "coverage": "Coverage details (e.g., hospital expenses up to amount, etc.)"
  }
]

Include AT LEAST these major schemes:
1. Ayushman Bharat Pradhan Mantri Jan Arogya Yojana (AB-PMJAY)
2. Central Government Health Scheme (CGHS)
3. Rashtriya Swasthya Bima Yojana (RSBY)
4. Employees' State Insurance Scheme (ESIS)
5. National Health Mission (NHM)
6. Pradhan Mantri Matritva Vandana Yojana (PMMVY)
7. Rajiv Gandhi Scheme for Health (RGSH)
8. AAROGYA KARNATAKA scheme
9. Chief Minister Health Insurance Scheme (various states)
10. Pregnant Women Health & Nutrition Scheme

Provide ONLY valid JSON array, nothing else. Ensure all URLs are real official government websites.
''';

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
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final responseText =
              data['candidates'][0]['content']['parts'][0]['text'];

          // Parse JSON response from Gemini
          final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(responseText);
          if (jsonMatch != null) {
            final jsonString = jsonMatch.group(0)!;
            final List<dynamic> schemesList = jsonDecode(jsonString);

            // Convert to GovScheme objects
            final schemes =
                schemesList
                    .map((scheme) => _parseSchemeFromJson(scheme))
                    .where((scheme) => scheme != null)
                    .cast<GovScheme>()
                    .toList();

            return schemes.isNotEmpty ? schemes : _getDefaultSchemes();
          }
        }

        // Fallback to default schemes if API response is invalid
        return _getDefaultSchemes();
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        print('Authentication error: ${response.statusCode}');
        return _getDefaultSchemes();
      } else {
        print('API error: ${response.statusCode}');
        return _getDefaultSchemes();
      }
    } catch (e) {
      print('Error fetching schemes: $e');
      return _getDefaultSchemes();
    }
  }

  /// Parse a scheme JSON object into GovScheme
  GovScheme? _parseSchemeFromJson(dynamic json) {
    try {
      return GovScheme(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imageUrl:
            json['imageUrl']?.toString() ??
            'https://via.placeholder.com/300x200?text=Gov+Scheme',
        websiteUrl: json['websiteUrl']?.toString() ?? '',
        launchDate: DateTime.now(),
        eligibility: json['eligibility']?.toString() ?? '',
        benefits: json['benefits']?.toString() ?? '',
        coverage: json['coverage']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing scheme: $e');
      return null;
    }
  }

  /// Get default government schemes as fallback
  List<GovScheme> _getDefaultSchemes() {
    return [
      GovScheme(
        id: '1',
        title: 'Ayushman Bharat Pradhan Mantri Jan Arogya Yojana (AB-PMJAY)',
        description:
            'World\'s largest health insurance scheme providing free treatment for hospital stays.',
        imageUrl: 'https://via.placeholder.com/300x200?text=PMJAY',
        websiteUrl: 'https://pmjay.gov.in',
        launchDate: DateTime(2018, 9, 23),
        eligibility: 'Poor and vulnerable families (based on SECC database)',
        benefits: 'Free treatment up to ₹5 lakhs per family per year',
        coverage: 'Hospital expenses, treatment costs, diagnostics',
      ),
      GovScheme(
        id: '2',
        title: 'Central Government Health Scheme (CGHS)',
        description:
            'Comprehensive medical care for central government employees and pensioners.',
        imageUrl: 'https://via.placeholder.com/300x200?text=CGHS',
        websiteUrl: 'https://cghs.gov.in',
        launchDate: DateTime(1954, 1, 1),
        eligibility: 'Central government employees, pensioners, and dependents',
        benefits:
            'Outpatient and inpatient services, medicines, diagnostic tests',
        coverage: 'Comprehensive healthcare coverage for government employees',
      ),
      GovScheme(
        id: '3',
        title: 'Rashtriya Swasthya Bima Yojana (RSBY)',
        description:
            'Health insurance scheme for unorganized sector workers and dependents.',
        imageUrl: 'https://via.placeholder.com/300x200?text=RSBY',
        websiteUrl: 'https://rsby.gov.in',
        launchDate: DateTime(2007, 10, 1),
        eligibility: 'Unorganized sector workers (construction, mining, etc.)',
        benefits: 'Free inpatient treatment up to ₹30,000 per annum',
        coverage: 'Hospitalization expenses, cash benefits for injuries',
      ),
      GovScheme(
        id: '4',
        title: 'Employees\' State Insurance Scheme (ESIS)',
        description:
            'Social security and health insurance scheme for organized sector workers.',
        imageUrl: 'https://via.placeholder.com/300x200?text=ESIS',
        websiteUrl: 'https://www.esic.gov.in',
        launchDate: DateTime(1952, 1, 1),
        eligibility:
            'Organized sector employees (wage earners below ₹21,000/month)',
        benefits: 'Medical and cash benefits, occupational hazard coverage',
        coverage: 'Hospitalization, outpatient care, rehabilitation benefits',
      ),
      GovScheme(
        id: '5',
        title: 'National Health Mission (NHM)',
        description:
            'Government initiative to provide free healthcare services to all citizens.',
        imageUrl: 'https://via.placeholder.com/300x200?text=NHM',
        websiteUrl: 'https://nhm.gov.in',
        launchDate: DateTime(2013, 5, 1),
        eligibility: 'All citizens, especially poor and vulnerable populations',
        benefits: 'Free primary and secondary healthcare services',
        coverage: 'Primary health centers, community health workers',
      ),
      GovScheme(
        id: '6',
        title: 'Pradhan Mantri Matritva Vandana Yojana (PMMVY)',
        description:
            'Cash assistance scheme for pregnant women and lactating mothers.',
        imageUrl: 'https://via.placeholder.com/300x200?text=PMMVY',
        websiteUrl: 'https://pmmvy.aahar.gov.in',
        launchDate: DateTime(2017, 1, 1),
        eligibility: 'Pregnant women and lactating mothers above 19 years',
        benefits: 'Cash incentives for safe motherhood practices',
        coverage: 'Maternity benefits, health checkups for mother and child',
      ),
    ];
  }

  /// Get authorization headers for Gemini API
  Map<String, String> _getAuthHeaders() {
    return {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey};
  }
}
