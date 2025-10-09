import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:health_buddy/services/ai_service.dart';

void main() {
  group('Doctor Service Tests', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('findNearbyDoctors returns valid JSON', () async {
      // Test with a known location (Bangalore, India)
      final response = await aiService.findNearbyDoctors(12.9716, 77.5946);

      print('Response: $response');

      // Parse the response
      final data = jsonDecode(response);

      // Check if it's a valid response
      expect(data, isNotNull);

      // Check if it has doctors or error field
      expect(data.containsKey('doctors') || data.containsKey('error'), isTrue);

      if (data.containsKey('doctors')) {
        expect(data['doctors'], isA<List>());
        print('Found ${data['doctors'].length} doctors');
      }
    });
  });
}
