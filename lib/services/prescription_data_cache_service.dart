import 'package:flutter/foundation.dart';
import 'package:medivault_ai/models/prescription.dart';

/// Service for temporarily caching prescription data during navigation
/// Ensures data persists when navigating from scanner to review/edit screens
///
/// This service acts as a temporary state management layer, solving the issue
/// where extracted prescription data appears blank on the review screen after navigation.
class PrescriptionDataCacheService {
  static final PrescriptionDataCacheService _instance =
      PrescriptionDataCacheService._internal();

  // Singleton instance
  factory PrescriptionDataCacheService() {
    return _instance;
  }

  PrescriptionDataCacheService._internal();

  // Cache storage
  Prescription? _cachedPrescription;
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Cache a prescription object
  ///
  /// Call this method right before navigation to ensure data is available
  /// on the next screen. This prevents data loss during navigation transitions.
  ///
  /// Example:
  /// ```dart
  /// PrescriptionDataCacheService().cachePrescription(_extractedPrescription);
  /// Navigator.push(context, MaterialPageRoute(...));
  /// ```
  void cachePrescription(Prescription prescription) {
    _cachedPrescription = prescription;
    _cacheTimestamp = DateTime.now();

    debugPrint(
      '✓ [PrescriptionDataCache] Cached prescription with '
      '${prescription.medications.length} medications, '
      'symptoms: ${prescription.currentSymptoms != null ? "Yes" : "No"}, '
      'diagnosis: ${prescription.diagnosis != null ? "Yes" : "No"}',
    );
  }

  /// Retrieve cached prescription
  ///
  /// Call this method in the initState or build method of the target screen
  /// to restore the extracted data. Automatically handles cache expiry.
  ///
  /// Returns:
  /// - Cached Prescription if valid cache exists
  /// - null if no cache, cache expired, or cache is invalid
  Prescription? getCachedPrescription() {
    // Check if cache exists
    if (_cachedPrescription == null) {
      debugPrint('[PrescriptionDataCache] No cached prescription found');
      return null;
    }

    // Check if cache has expired
    if (_cacheTimestamp != null) {
      final elapsed = DateTime.now().difference(_cacheTimestamp!);
      if (elapsed > _cacheExpiry) {
        debugPrint(
          '[PrescriptionDataCache] Cache expired (${elapsed.inMinutes} minutes old)',
        );
        clearCache();
        return null;
      }
    }

    // Validate cached data
    if (!_isValidPrescription(_cachedPrescription)) {
      debugPrint('[PrescriptionDataCache] Cached prescription is invalid');
      clearCache();
      return null;
    }

    debugPrint(
      '✓ [PrescriptionDataCache] Retrieved valid cached prescription '
      '(${DateTime.now().difference(_cacheTimestamp!).inSeconds}s old)',
    );

    return _cachedPrescription;
  }

  /// Validate that prescription contains expected data
  ///
  /// Checks for:
  /// - Non-null medications list (even if empty)
  /// - At least one field populated (to detect truly empty prescriptions)
  /// - Valid doctor ID
  bool _isValidPrescription(Prescription? prescription) {
    if (prescription == null) {
      debugPrint('❌ [PrescriptionDataCache] Validation: Prescription is null');
      return false;
    }

    // Check for doctor ID (always required)
    if (prescription.doctorId.isEmpty) {
      debugPrint('❌ [PrescriptionDataCache] Validation: Missing doctor ID');
      return false;
    }

    // Detail validation of each section
    bool hasSymptomsData =
        prescription.currentSymptoms != null &&
        prescription.currentSymptoms!.isNotEmpty;
    bool hasDiagnosisData =
        prescription.diagnosis != null && prescription.diagnosis!.isNotEmpty;
    bool hasMedications = prescription.medications.isNotEmpty;
    bool hasInstructions =
        prescription.instructions != null &&
        prescription.instructions!.isNotEmpty;

    // Debug info about what data is present
    debugPrint('''
📋 [PrescriptionDataCache] Data validation:
- Symptoms: ${hasSymptomsData ? "✓" : "✗"} ${hasSymptomsData ? '(${prescription.currentSymptoms})' : ''}
- Diagnosis: ${hasDiagnosisData ? "✓" : "✗"} ${hasDiagnosisData ? '(${prescription.diagnosis})' : ''}
- Medications: ${hasMedications ? "✓" : "✗"} (${prescription.medications.length} items)
- Instructions: ${hasInstructions ? "✓" : "✗"} ${hasInstructions ? '(${prescription.instructions})' : ''}
''');

    // Check if at least one field has data (to detect extraction success)
    final hasData =
        hasSymptomsData ||
        hasDiagnosisData ||
        hasMedications ||
        hasInstructions;

    debugPrint(
      hasData
          ? '✓ [PrescriptionDataCache] Validation: Data is valid'
          : '❌ [PrescriptionDataCache] Validation: No valid data found',
    );

    return hasData;
  }

  /// Clear the cached prescription
  ///
  /// Call this after successfully saving the prescription to prevent
  /// using stale data on subsequent navigations.
  void clearCache() {
    _cachedPrescription = null;
    _cacheTimestamp = null;
    debugPrint('[PrescriptionDataCache] Cache cleared');
  }

  /// Get cache status information (useful for debugging)
  ///
  /// Returns a map with:
  /// - hasCachedData: Whether cache exists and is valid
  /// - cacheAge: Duration since cache was created
  /// - medicationsCount: Number of medications in cache
  /// - fieldsPopulated: List of populated fields
  Map<String, dynamic> getCacheStatus() {
    if (_cachedPrescription == null || _cacheTimestamp == null) {
      return {
        'hasCachedData': false,
        'cacheAge': null,
        'medicationsCount': 0,
        'fieldsPopulated': [],
      };
    }

    final cacheAge = DateTime.now().difference(_cacheTimestamp!);
    final populatedFields = <String>[];

    if (_cachedPrescription!.currentSymptoms != null &&
        _cachedPrescription!.currentSymptoms!.isNotEmpty) {
      populatedFields.add('symptoms');
    }
    if (_cachedPrescription!.diagnosis != null &&
        _cachedPrescription!.diagnosis!.isNotEmpty) {
      populatedFields.add('diagnosis');
    }
    if (_cachedPrescription!.medications.isNotEmpty) {
      populatedFields.add('medications');
    }
    if (_cachedPrescription!.instructions != null &&
        _cachedPrescription!.instructions!.isNotEmpty) {
      populatedFields.add('instructions');
    }
    if (_cachedPrescription!.medicalHistory != null &&
        _cachedPrescription!.medicalHistory!.isNotEmpty) {
      populatedFields.add('medicalHistory');
    }
    if (_cachedPrescription!.allergies != null &&
        _cachedPrescription!.allergies!.isNotEmpty) {
      populatedFields.add('allergies');
    }

    return {
      'hasCachedData': true,
      'cacheAge': cacheAge,
      'medicationsCount': _cachedPrescription!.medications.length,
      'fieldsPopulated': populatedFields,
    };
  }

  /// Debug method to print full cache contents
  ///
  /// Useful for troubleshooting data persistence issues
  void debugPrintCacheContents() {
    if (_cachedPrescription == null) {
      debugPrint('[PrescriptionDataCache] No cached data');
      return;
    }

    debugPrint('''
╔════════════════════════════════════════════════════════════╗
║        PRESCRIPTION DATA CACHE CONTENTS (DEBUG)            ║
╚════════════════════════════════════════════════════════════╝

📋 SYMPTOMS & DIAGNOSIS
  • Symptoms: ${_cachedPrescription!.currentSymptoms ?? 'N/A'}
  • Diagnosis: ${_cachedPrescription!.diagnosis ?? 'N/A'}
  • Medical History: ${_cachedPrescription!.medicalHistory ?? 'N/A'}
  • Allergies: ${_cachedPrescription!.allergies ?? 'N/A'}

💊 MEDICATIONS (${_cachedPrescription!.medications.length} items)
${_cachedPrescription!.medications.isEmpty ? '  • None' : _cachedPrescription!.medications.asMap().entries.map((e) => '  ${e.key + 1}. ${e.value.name} - ${e.value.strength} ${e.value.dosageForm.toString().split('.').last} ${e.value.frequency.toString().split('.').last}').join('\n')}

📝 INSTRUCTIONS & NOTES
  • Instructions: ${_cachedPrescription!.instructions ?? 'N/A'}
  • Precautions: ${_cachedPrescription!.precautions ?? 'N/A'}
  • Follow-up: ${_cachedPrescription!.followUpInstructions ?? 'N/A'}
  • Notes: ${_cachedPrescription!.doctorNotes ?? 'N/A'}

⏱️ CACHE INFO
  • Cached at: ${_cacheTimestamp?.toIso8601String() ?? 'N/A'}
  • Age: ${DateTime.now().difference(_cacheTimestamp ?? DateTime.now()).inSeconds}s
  • Valid: ${_isValidPrescription(_cachedPrescription) ? 'Yes ✓' : 'No ✗'}

╚════════════════════════════════════════════════════════════╝
    ''');
  }
}
