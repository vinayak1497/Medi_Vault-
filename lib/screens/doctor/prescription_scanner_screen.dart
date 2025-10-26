// Deprecated scanner screen: replaced by MinimalImageToTextScreen
// This file is intentionally reduced to prevent use. Please use
// lib/screens/doctor/minimal_image_to_text_screen.dart instead.
// Keeping the file to avoid routing breaks in environments where it's still referenced.

import 'package:flutter/material.dart';

@Deprecated('Use MinimalImageToTextScreen instead')
class PrescriptionScannerScreen extends StatelessWidget {
  const PrescriptionScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription Scanner (Deprecated)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.info_outline, size: 48, color: Colors.orange),
              SizedBox(height: 12),
              Text(
                'This screen has been replaced by a simpler flow.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please navigate to MinimalImageToTextScreen to extract text with Gemini 2.0 Flash (v1beta).',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
