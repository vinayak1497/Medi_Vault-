import 'package:medivault_ai/models/gov_scheme.dart';

class GovSchemeService {
  // This would typically fetch from an API
  // For now, we'll use mock data
  Future<List<GovScheme>> fetchMedicalInsuranceSchemes() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data for medical insurance schemes
    final List<Map<String, dynamic>> mockSchemes = [
      {
        'id': '1',
        'title': 'Ayushman Bharat Pradhan Mantri Jan Arogya Yojana (AB-PMJAY)',
        'description':
            'Health insurance scheme for poor and vulnerable population',
        'imageUrl': 'https://example.com/abpmjay.jpg',
        'websiteUrl': 'https://pmjay.gov.in',
        'launchDate': '2018-09-23T00:00:00Z',
      },
      {
        'id': '2',
        'title': 'Central Government Health Scheme (CGHS)',
        'description':
            'Comprehensive medical care for central government employees',
        'imageUrl': 'https://example.com/cghs.jpg',
        'websiteUrl': 'https://cghs.gov.in',
        'launchDate': '2023-01-15T00:00:00Z',
      },
      {
        'id': '3',
        'title': 'Rashtriya Swasthya Bima Yojana (RSBY)',
        'description': 'Health insurance for unorganized workers',
        'imageUrl': 'https://example.com/rsby.jpg',
        'websiteUrl': 'https://rsby.gov.in',
        'launchDate': '2022-11-10T00:00:00Z',
      },
      {
        'id': '4',
        'title': 'Pradhan Mantri Jan Arogya Yojana (PMJAY)',
        'description': 'Health assurance scheme for poor families',
        'imageUrl': 'https://example.com/pmjay.jpg',
        'websiteUrl': 'https://pmjay.gov.in',
        'launchDate': '2023-03-22T00:00:00Z',
      },
    ];

    // Convert to GovScheme objects and sort by launch date (newest first)
    final schemes =
        mockSchemes.map((json) => GovScheme.fromJson(json)).toList()
          ..sort((a, b) => b.launchDate.compareTo(a.launchDate));

    return schemes;
  }
}
