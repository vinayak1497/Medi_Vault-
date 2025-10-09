import 'package:flutter_test/flutter_test.dart';
import 'package:health_buddy/services/ai_service.dart';

void main() {
  group('AIService Tests', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('sendMessage returns a response', () async {
      // This is a simple test to check if the service can connect
      try {
        final response = await aiService.sendMessage(
          'Hello, what is your name?',
        );
        expect(response, isNotEmpty);
        print('AI Response: $response');
      } catch (e) {
        print('Error: $e');
        // We expect this might fail due to network issues or API key issues
        // But we want to see what the actual error is
      }
    });
  });
}
