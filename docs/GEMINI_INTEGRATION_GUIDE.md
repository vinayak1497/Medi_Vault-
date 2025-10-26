# Integration Guide: Using Gemini Flash API for Prescription Extraction

## Quick Start

### Step 1: Import the Service

```dart
import 'package:health_buddy/services/gemini_prescription_extraction_service.dart';
import 'dart:io';
```

### Step 2: Use in Your Code

```dart
// In your prescription form screen or wherever you need to extract data
Future<void> _extractPrescription(File imageFile) async {
  try {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) return;
    
    final Prescription prescription = 
      await GeminiPrescriptionExtractionService.extractPrescriptionData(
        imageFile,
        currentUser.uid,
      );
    
    // Now you have a Prescription object with extracted data
    setState(() {
      _extractedPrescription = prescription;
    });
    
    // Auto-fill form fields
    _populateFormFromPrescription(prescription);
    
  } catch (e) {
    _showErrorSnackBar('Error extracting prescription: $e');
  }
}
```

### Step 3: Access Extracted Data

```dart
void _populateFormFromPrescription(Prescription prescription) {
  // Patient Information
  if (prescription.patientName != null) {
    patientNameController.text = prescription.patientName!;
  }
  
  if (prescription.patientAge != null) {
    patientAgeController.text = prescription.patientAge.toString();
  }
  
  // Medical Information
  if (prescription.currentSymptoms != null) {
    symptomsController.text = prescription.currentSymptoms!;
  }
  
  if (prescription.diagnosis != null) {
    diagnosisController.text = prescription.diagnosis!;
  }
  
  // Medications
  if (prescription.medications.isNotEmpty) {
    for (final medication in prescription.medications) {
      _addMedicationToForm(medication);
    }
  }
  
  // Instructions
  if (prescription.instructions != null) {
    instructionsController.text = prescription.instructions!;
  }
}
```

## Detailed Implementation Example

### Complete Doctor Prescription Screen Integration

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:health_buddy/services/gemini_prescription_extraction_service.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'dart:io';

class DoctorPrescriptionScreen extends StatefulWidget {
  const DoctorPrescriptionScreen({Key? key}) : super(key: key);

  @override
  State<DoctorPrescriptionScreen> createState() =>
      _DoctorPrescriptionScreenState();
}

class _DoctorPrescriptionScreenState extends State<DoctorPrescriptionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  Prescription? _extractedPrescription;
  bool _isExtracting = false;

  /// Handle prescription image selection and extraction
  Future<void> _selectAndExtractPrescription() async {
    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (selectedImage == null) return;

      setState(() {
        _isExtracting = true;
      });

      // Extract prescription data using Gemini
      final File imageFile = File(selectedImage.path);
      final currentUser = AuthService.getCurrentUser();
      
      if (currentUser == null) {
        _showErrorSnackBar('Please login to continue');
        return;
      }

      final Prescription prescription =
          await GeminiPrescriptionExtractionService.extractPrescriptionData(
            imageFile,
            currentUser.uid,
          );

      setState(() {
        _extractedPrescription = prescription;
        _isExtracting = false;
      });

      // Show extracted data summary
      _showExtractionSummary(prescription);

      // Optionally auto-fill form fields
      _populateFormFromPrescription(prescription);

    } catch (e) {
      setState(() {
        _isExtracting = false;
      });
      _showErrorSnackBar('Error extracting prescription: $e');
    }
  }

  /// Display extracted data summary
  void _showExtractionSummary(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extraction Summary'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryItem('Patient', prescription.patientName),
              _buildSummaryItem('Age', prescription.patientAge?.toString()),
              _buildSummaryItem('Gender', prescription.patientGender),
              _buildSummaryItem('Symptoms', prescription.currentSymptoms),
              _buildSummaryItem('Diagnosis', prescription.diagnosis),
              const SizedBox(height: 12),
              const Text(
                'Medications:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...prescription.medications.map(
                (med) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    '${med.name} - ${med.strength} ${med.dosageForm.displayName}',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _savePrescription();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Build summary item widget
  Widget _buildSummaryItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  /// Populate form fields from extracted prescription
  void _populateFormFromPrescription(Prescription prescription) {
    // Implementation based on your form structure
    // Auto-fill controllers with extracted data
  }

  /// Save prescription to database
  Future<void> _savePrescription() async {
    if (_extractedPrescription == null) {
      _showErrorSnackBar('No prescription to save');
      return;
    }

    // Save to Firebase or your database
    // prescriptionService.addPrescription(_extractedPrescription!);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Prescription'),
      ),
      body: Column(
        children: [
          // Extraction button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isExtracting ? null : _selectAndExtractPrescription,
              icon: _isExtracting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.image),
              label: Text(
                _isExtracting
                    ? 'Extracting...'
                    : 'Select Prescription & Extract',
              ),
            ),
          ),
          
          // Display extracted prescription data
          if (_extractedPrescription != null)
            Expanded(
              child: _buildPrescriptionDisplay(_extractedPrescription!),
            ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionDisplay(Prescription prescription) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Name', prescription.patientName),
                  _buildInfoRow('Age', prescription.patientAge?.toString()),
                  _buildInfoRow('Gender', prescription.patientGender),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Medical Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medical Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Symptoms', prescription.currentSymptoms),
                  _buildInfoRow('Diagnosis', prescription.diagnosis),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Medications Card
          if (prescription.medications.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...prescription.medications.map(
                      (med) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${med.strength} - ${med.dosageForm.displayName}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${med.frequency.displayName} for ${med.duration}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
```

## Response Handling Examples

### Example 1: Extract and Display

```dart
void handlePrescriptionExtraction() async {
  final result = await GeminiPrescriptionExtractionService
      .extractPrescriptionData(imageFile, doctorId);
  
  // Access extracted information
  print('Patient: ${result.patientName}');
  print('Age: ${result.patientAge}');
  print('Medications: ${result.medications.length}');
}
```

### Example 2: Error Handling

```dart
try {
  final prescription = await GeminiPrescriptionExtractionService
      .extractPrescriptionData(imageFile, doctorId);
  
  if (prescription.extractedText?.contains('Error') ?? false) {
    print('Extraction had issues: ${prescription.extractedText}');
  } else {
    print('Extraction successful!');
  }
} catch (e) {
  print('Failed to extract prescription: $e');
}
```

### Example 3: Batch Processing

```dart
Future<void> processPrescriptions(List<File> images) async {
  final results = <Prescription>[];
  
  for (final image in images) {
    try {
      final prescription = await GeminiPrescriptionExtractionService
          .extractPrescriptionData(image, doctorId);
      results.add(prescription);
    } catch (e) {
      print('Failed to process ${image.path}: $e');
    }
  }
  
  return results;
}
```

## Data Validation Examples

### Validate Extracted Data

```dart
bool _isValidPrescription(Prescription prescription) {
  // Check for required fields
  if (prescription.patientName?.isEmpty ?? true) return false;
  if (prescription.medications.isEmpty) return false;
  if (prescription.currentSymptoms?.isEmpty ?? true) return false;
  
  return true;
}
```

### Verify Medication Data

```dart
bool _isMedicationComplete(MedicationItem medication) {
  return medication.name.isNotEmpty &&
      medication.strength.isNotEmpty &&
      medication.duration.isNotEmpty;
}
```

## API Configuration

### Environment Setup

```dart
// lib/utils/constants.dart
class Constants {
  static const String apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  // Other API endpoints
  static const String geminiBaseUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models';
}
```

### Optional: Configuration Management

```dart
class GeminiConfig {
  static const int REQUEST_TIMEOUT_SECONDS = 60;
  static const int IMAGE_QUALITY = 85;
  static const int MAX_RETRIES = 2;
  static const Duration RETRY_DELAY = Duration(seconds: 2);
}
```

## Testing Checklist

- [ ] API key configured correctly
- [ ] Sample prescription images available
- [ ] Image extraction returns valid JSON
- [ ] Medications parsed correctly
- [ ] Date parsing works for various formats
- [ ] Error handling works gracefully
- [ ] Form population updates UI
- [ ] Save functionality works

---

**Ready to use!** Your Health Buddy app now uses powerful Gemini-based prescription extraction.
