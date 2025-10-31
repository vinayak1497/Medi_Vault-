import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health_buddy/models/prescription.dart';
import 'package:health_buddy/screens/doctor/simple_prescription_form_screen.dart';
import 'package:health_buddy/services/ai_service.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/services/camera_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Minimal screen: select an image -> extract plain text with Gemini 2.0 Flash (v1beta) -> auto-format -> review/edit
class MinimalImageToTextScreen extends StatefulWidget {
  const MinimalImageToTextScreen({super.key});

  @override
  State<MinimalImageToTextScreen> createState() =>
      _MinimalImageToTextScreenState();
}

class _MinimalImageToTextScreenState extends State<MinimalImageToTextScreen> {
  final _ai = AIService();
  File? _image;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final file = await CameraService.showImageSourceDialog(context);
    if (file == null) return;

    // Optional: basic validation
    if (!CameraService.isValidImage(file)) {
      _showError('Please select a valid image file (JPG/PNG/WEBP).');
      return;
    }

    setState(() => _image = file);
  }

  Future<void> _extractText() async {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      _showError('Please login to continue.');
      return;
    }

    if (_image == null) {
      _showError('Please select a prescription image first.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _ai.extractPlainTextFromImage(_image!.path);

      String? text = result['text'] as String?;
      final String? error = result['error'] as String?;

      if (error != null) {
        // On rate limit or other failures, fallback to on-device OCR
        if (error.toLowerCase().contains('rate limit')) {
          text = await _fallbackOcr(_image!);
        } else {
          // Try OCR as a best-effort fallback too
          text = await _fallbackOcr(_image!);
        }
      }

      if (text == null || text.trim().isEmpty) {
        _showError('Failed to extract any text from the image.');
        setState(() => _isProcessing = false);
        return;
      }

      // Post-process: normalize/translate/format text via Gemini
      String formatted = '';
      try {
        formatted = await _ai.normalizePrescriptionText(text.trim());
      } catch (e) {
        debugPrint('Normalize error: $e');
      }

      final prescription = Prescription(
        doctorId: currentUser.uid,
        createdAt: DateTime.now(),
        originalImagePath: _image!.path,
        extractedText: (formatted.isNotEmpty ? formatted : text.trim()),
        status: PrescriptionStatus.draft,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  SimplePrescriptionFormScreen(prescription: prescription),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error extracting text: $e');
    }
  }

  Future<String> _fallbackOcr(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      try {
        final recognized = await textRecognizer.processImage(inputImage);
        return recognized.text.trim();
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      debugPrint('OCR fallback error: $e');
      return '';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          'Extract Text',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_image != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear',
              onPressed: () => setState(() => _image = null),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: _isProcessing ? null : _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child:
                        _image == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 64,
                                  color: Color(0xFF4CAF50),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Tap to choose prescription image',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _extractText,
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.psychology, color: Colors.white),
                label: Text(_isProcessing ? 'Extracting...' : 'Extract Text'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Ensure good lighting and keep the prescription flat and clear for best results.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
