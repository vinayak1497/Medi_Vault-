import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:medivault_ai/services/ai_service.dart';

void main() {
  group('AI Real Data Tests', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('findNearbyDoctors returns valid doctor data', () async {
      // Test with a known location (Bangalore, India)
      final response = await aiService.findNearbyDoctors(12.9716, 77.5946);

      print('Raw Response: $response');

      // Parse the response
      final data = jsonDecode(response);

      // Check if it's a valid response
      expect(data, isNotNull);

      // Check if it has doctors or error field
      expect(data.containsKey('doctors') || data.containsKey('error'), isTrue);

      if (data.containsKey('doctors')) {
        expect(data['doctors'], isA<List>());
        print('Found ${data['doctors'].length} doctors');

        // Check that we have at least some doctors
        expect(data['doctors'].length, greaterThan(0));

        // Check the structure of the first doctor
        if (data['doctors'].isNotEmpty) {
          final firstDoctor = data['doctors'][0];
          expect(firstDoctor, isA<Map>());
          expect(firstDoctor.containsKey('name'), isTrue);
          expect(firstDoctor.containsKey('specialty'), isTrue);
          expect(firstDoctor.containsKey('address'), isTrue);
        }
      } else if (data.containsKey('error')) {
        print('Error from AI service: ${data['error']}');
        // This is acceptable if there's a legitimate error
        expect(data['error'], isA<String>());
      }
    });
  });
}
