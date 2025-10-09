import 'package:flutter/material.dart';
import 'package:health_buddy/services/ai_service.dart';

class AITestScreen extends StatefulWidget {
  const AITestScreen({super.key});

  @override
  State<AITestScreen> createState() => _AITestScreenState();
}

class _AITestScreenState extends State<AITestScreen> {
  final AIService _aiService = AIService();
  String _response = '';
  bool _isLoading = false;

  Future<void> _testAIService() async {
    setState(() {
      _isLoading = true;
      _response = 'Loading...';
    });

    try {
      final response = await _aiService.findNearbyDoctors(12.9716, 77.5946);
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Service Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testAIService,
              child: const Text('Test AI Service'),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: Text(_response))),
          ],
        ),
      ),
    );
  }
}
