import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medivault_ai/models/prescription.dart';
import 'package:medivault_ai/services/ai_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for extracting text from prescription images using Gemini AI
/// Provides accurate parsing to fill prescription template fields
class TextRecognitionService {
  static final AIService _aiService = AIService();

  /// Parse dosage form string to DosageForm enum
  static DosageForm _parseDosageForm(String? dosageForm) {
    if (dosageForm == null) return DosageForm.tablet;

    final lower = dosageForm.toLowerCase();
    for (final form in DosageForm.values) {
      if (lower.contains(form.displayName.toLowerCase())) {
        return form;
      }
    }
    return DosageForm.tablet;
  }

  /// Parse frequency string to DosageFrequency enum
  static DosageFrequency _parseFrequency(String? frequency) {
    if (frequency == null) return DosageFrequency.onceDaily;

    final lower = frequency.toLowerCase();
    for (final freq in DosageFrequency.values) {
      if (lower.contains(freq.displayName.toLowerCase())) {
        return freq;
      }
    }
    return DosageFrequency.onceDaily;
  }

  /// Parse a date string or timestamp into DateTime object
  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is DateTime) return dateValue;
      if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
      if (dateValue is String) {
        // Try different date formats
        final formats = [
          RegExp(
            r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})',
          ), // dd/mm/yyyy or dd-mm-yyyy
          RegExp(
            r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})',
          ), // yyyy/mm/dd or yyyy-mm-dd
        ];

        for (final format in formats) {
          final match = format.firstMatch(dateValue);
          if (match != null) {
            final parts = [
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            ];

            if (parts[0] > 1900) {
              // yyyy/mm/dd format
              return DateTime(parts[0], parts[1], parts[2]);
            } else {
              // dd/mm/yyyy format
              return DateTime(parts[2], parts[1], parts[0]);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return null;
  }

  /// Parse medications data into MedicationItem objects
  static List<MedicationItem> _parseMedications(dynamic medicationsData) {
    final List<MedicationItem> medications = [];

    if (medicationsData is List) {
      for (final item in medicationsData) {
        if (item is Map<String, dynamic>) {
          try {
            medications.add(
              MedicationItem(
                name: item['name'] ?? '',
                genericName: item['genericName'] ?? item['name'] ?? '',
                strength: item['strength'] ?? '',
                dosageForm: _parseDosageForm(item['dosageForm']),
                frequency: _parseFrequency(item['frequency']),
                duration: item['duration'] ?? '',
                instructions: item['instructions'] ?? '',
              ),
            );
          } catch (e) {
            debugPrint('Error parsing medication item: $e');
          }
        }
      }
    }

    return medications;
  }

  /// Maximum retries for extraction
  static const _maxExtractionRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  /// Fallback: Extract raw text with on-device ML Kit OCR when Gemini fails
  static Future<String> _extractRawTextWithMlKit(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      try {
        final RecognizedText recognizedText = await textRecognizer.processImage(
          inputImage,
        );
        final text = recognizedText.text.trim();
        return text;
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      debugPrint('⚠️ [TextRecognition] ML Kit OCR failed: $e');
      return '';
    }
  }

  /// Extract text from prescription image using Gemini AI and parse into structured data
  static Future<Prescription> extractPrescriptionData(
    File imageFile,
    String doctorId,
  ) async {
    var retryCount = 0;
    var currentDelay = _retryDelay;

    while (retryCount <= _maxExtractionRetries) {
      try {
        debugPrint(
          '🔍 [TextRecognition] Starting Gemini AI text extraction'
          '${retryCount > 0 ? ' (Attempt ${retryCount + 1}/$_maxExtractionRetries)' : ''}',
        );

        // Extract data using Gemini AI
        final aiResult = await _aiService.extractPrescriptionFromImage(
          imageFile.path,
        );

        // If server returned rate limit, do not keep retrying; fallback to OCR
        if (aiResult['error'] != null &&
            aiResult['error'].toString().toLowerCase().contains('rate limit')) {
          debugPrint(
            '⌛ [TextRecognition] Server rate limit reached; skipping retries and using OCR',
          );
          throw Exception('rate limit');
        }

        // Handle other errors
        if (aiResult['error'] != null) {
          throw Exception(aiResult['error']);
        }

        final data = aiResult['data'];
        final extractedText = data.toString();
        debugPrint('✓ [TextRecognition] Gemini AI extraction successful');

        return Prescription(
          doctorId: doctorId,
          createdAt: DateTime.now(),
          originalImagePath: imageFile.path,
          extractedText: extractedText,
          status: PrescriptionStatus.draft,
        );
      } catch (e) {
        debugPrint('Error extracting text: $e');
        retryCount++;

        // Do not spin on rate limit; fail fast to OCR
        if (e.toString().toLowerCase().contains('rate limit')) {
          // fall through to OCR below
        } else if (retryCount <= _maxExtractionRetries) {
          debugPrint(
            '⌛ [TextRecognition] Retrying in ${currentDelay.inSeconds}s',
          );
          await Future.delayed(currentDelay);
          currentDelay *= 2; // Exponential backoff
          continue;
        }

        // If all retries exhausted, try on-device OCR as a fallback
        debugPrint(
          '🧭 [TextRecognition] Falling back to on-device OCR (ML Kit)',
        );
        final rawText = await _extractRawTextWithMlKit(imageFile);
        if (rawText.isNotEmpty) {
          debugPrint('✓ [TextRecognition] ML Kit OCR extraction successful');
          return Prescription(
            doctorId: doctorId,
            createdAt: DateTime.now(),
            originalImagePath: imageFile.path,
            extractedText: rawText,
            status: PrescriptionStatus.draft,
          );
        }

        // If OCR also fails, return error prescription
        return Prescription(
          doctorId: doctorId,
          createdAt: DateTime.now(),
          originalImagePath: imageFile.path,
          extractedText:
              'Error: Failed to extract text after $_maxExtractionRetries retries - $e',
          status: PrescriptionStatus.draft,
        );
      }
    }

    // Fallback prescription in case all retries failed
    return Prescription(
      doctorId: doctorId,
      createdAt: DateTime.now(),
      originalImagePath: imageFile.path,
      extractedText:
          'Error: Failed to extract text after $_maxExtractionRetries retries',
      status: PrescriptionStatus.draft,
    );
  }

  /// Dispose method for cleanup - no static needed since it's an instance method
  void dispose() {
    // No resources to dispose since we're only using Gemini AI
  }
}
