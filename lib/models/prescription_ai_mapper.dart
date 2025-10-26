import 'package:health_buddy/models/prescription.dart';

/// Maps AI-extracted data to Prescription model
class PrescriptionAIMapper {
  /// Convert AI response data to Prescription model
  static Prescription mapToPrescription(
    Map<String, dynamic> aiData,
    String doctorId,
    String imagePath,
  ) {
    try {
      // Convert AI medications data to MedicationItem list
      final List<MedicationItem> medications = [];
      if (aiData['medications'] != null) {
        for (var med in aiData['medications']) {
          if (med['name'] != null && med['name'].isNotEmpty) {
            medications.add(
              MedicationItem(
                name: med['name'] ?? '',
                genericName: med['genericName'] ?? med['name'] ?? '',
                strength: med['strength'] ?? '',
                dosageForm: _parseDosageForm(med['dosageForm']),
                frequency: _parseFrequency(med['frequency']),
                duration: med['duration'] ?? '',
                instructions: med['instructions'] ?? '',
              ),
            );
          }
        }
      }

      return Prescription(
        doctorId: doctorId,
        createdAt: DateTime.now(),
        originalImagePath: imagePath,
        extractedText: aiData.toString(),
        prescriptionDate: _parseDate(aiData['prescriptionDate']),
        currentSymptoms: _cleanString(aiData['currentSymptoms']),
        diagnosis: _cleanString(aiData['diagnosis']),
        medicalHistory: _cleanString(aiData['medicalHistory']),
        allergies: _cleanString(aiData['allergies']),
        vitalSigns: _cleanString(aiData['vitalSigns']),
        medications: medications,
        instructions: _cleanString(aiData['instructions']),
        precautions: _cleanString(aiData['precautions']),
        followUpInstructions: _cleanString(aiData['followUpInstructions']),
        doctorNotes: _cleanString(aiData['additionalNotes']),
        specialInstructions: _cleanString(aiData['instructions']),
        investigationsAdvised: '',
        dietaryAdvice: _cleanString(aiData['dietaryAdvice']),
        followUpDate: null,
        additionalNotes: _cleanString(aiData['additionalNotes']),
        status: PrescriptionStatus.draft,
      );
    } catch (e) {
      return Prescription(
        doctorId: doctorId,
        createdAt: DateTime.now(),
        originalImagePath: imagePath,
        extractedText: 'Error: Failed to map AI data - $e',
        status: PrescriptionStatus.draft,
      );
    }
  }

  /// Clean string values from AI response
  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final cleaned = value.trim();
      return cleaned.isEmpty ? null : cleaned;
    }
    return value.toString();
  }

  /// Parse dosage form from string to enum
  static DosageForm _parseDosageForm(String? form) {
    if (form == null) return DosageForm.tablet;

    final lower = form.toLowerCase();
    for (final dosageForm in DosageForm.values) {
      if (lower.contains(dosageForm.displayName.toLowerCase())) {
        return dosageForm;
      }
    }
    return DosageForm.tablet;
  }

  /// Parse frequency from string to enum
  static DosageFrequency _parseFrequency(String? freq) {
    if (freq == null) return DosageFrequency.onceDaily;

    final lower = freq.toLowerCase();
    for (final frequency in DosageFrequency.values) {
      if (lower.contains(frequency.displayName.toLowerCase())) {
        return frequency;
      }
    }
    return DosageFrequency.onceDaily;
  }

  /// Parse date string to DateTime
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      // Try different date formats
      final formats = [
        RegExp(
          r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})',
        ), // dd/mm/yyyy or dd-mm-yyyy
        RegExp(
          r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})',
        ), // yyyy/mm/dd or yyyy-mm-dd
      ];

      for (final format in formats) {
        final match = format.firstMatch(dateStr);
        if (match != null) {
          var day = int.parse(match.group(1)!);
          var month = int.parse(match.group(2)!);
          var year = int.parse(match.group(3)!);

          // Handle 2-digit years
          if (year < 100) {
            year += 2000;
          }

          // Check if it's yyyy/mm/dd format
          if (year > 31) {
            final temp = day;
            day = int.parse(match.group(3)!);
            year = temp;
          }

          // Basic validation
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
