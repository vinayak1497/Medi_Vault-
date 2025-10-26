import 'package:flutter/material.dart';
import 'package:health_buddy/models/prescription.dart';
import 'package:health_buddy/services/doctor_service.dart';
import 'package:health_buddy/models/patient.dart';
import 'package:health_buddy/screens/doctor/patient_picker_screen.dart';
import 'package:health_buddy/screens/common/auth/signup_screen.dart';
import 'package:health_buddy/services/patient_service.dart';
import 'package:health_buddy/services/auth_service.dart';

/// Simplified prescription form screen that shows the raw extracted text
class SimplePrescriptionFormScreen extends StatefulWidget {
  final Prescription prescription;

  const SimplePrescriptionFormScreen({super.key, required this.prescription});

  @override
  State<SimplePrescriptionFormScreen> createState() =>
      _SimplePrescriptionFormScreenState();
}

class _SimplePrescriptionFormScreenState
    extends State<SimplePrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Text controller for the extracted text
  late TextEditingController _extractedTextController;

  // Selected patient state + editable controllers
  Patient? _selectedPatient;
  final _patientName = TextEditingController();
  final _patientAge = TextEditingController();
  String? _patientGender;
  final _patientPhone = TextEditingController();
  final _patientAddress = TextEditingController();

  @override
  void initState() {
    super.initState();
    _extractedTextController = TextEditingController(
      text: widget.prescription.extractedText,
    );
  }

  @override
  void dispose() {
    _extractedTextController.dispose();
    _patientName.dispose();
    _patientAge.dispose();
    _patientPhone.dispose();
    _patientAddress.dispose();
    super.dispose();
  }

  /// Save prescription to Firebase
  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please add some text to the prescription');
      return;
    }

    if (_selectedPatient == null) {
      _showErrorSnackBar('Please select or create a patient');
      return;
    }

    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      _showErrorSnackBar('Please login to continue');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create updated prescription object
      final updatedPrescription = Prescription(
        id: widget.prescription.id,
        doctorId: currentUser.uid,
        patientId: _selectedPatient!.id,
        patientName:
            _patientName.text.trim().isEmpty
                ? _selectedPatient!.name
                : _patientName.text.trim(),
        patientAge:
            int.tryParse(_patientAge.text.trim()) ?? _selectedPatient!.age,
        patientGender: _patientGender ?? _selectedPatient!.gender,
        patientPhone:
            _patientPhone.text.trim().isEmpty
                ? _selectedPatient!.phoneNumber
                : _patientPhone.text.trim(),
        patientAddress:
            _patientAddress.text.trim().isEmpty
                ? _selectedPatient!.address
                : _patientAddress.text.trim(),
        createdAt: DateTime.now(),
        extractedText: _extractedTextController.text.trim(),
        status: PrescriptionStatus.draft,
        originalImagePath: widget.prescription.originalImagePath,
      );

      // Save to Firebase
      await DoctorService.savePrescription(updatedPrescription);

      setState(() {
        _isSaving = false;
      });

      _showSuccessSnackBar('Prescription saved successfully!');

      // Navigate back after short delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, updatedPrescription);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar('Error saving prescription: ${e.toString()}');
    }
  }

  Future<void> _pickExistingPatient() async {
    final result = await Navigator.push<Patient>(
      context,
      MaterialPageRoute(builder: (_) => const PatientPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedPatient = result;
        _patientName.text = result.name;
        _patientAge.text = result.age?.toString() ?? '';
        _patientGender = result.gender;
        _patientPhone.text = result.phoneNumber ?? '';
        _patientAddress.text = result.address ?? '';
      });
    }
  }

  Future<void> _createNewPatient() async {
    // Launch the full patient signup flow with email verification
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder:
            (_) => const PatientSignupScreen(returnToDoctorDashboard: true),
      ),
    );

    // Result is expected to be the verified patient's profile map
    if (result is Map<String, dynamic>) {
      try {
        final profile = result;
        final currentUser = AuthService.getCurrentUser();
        if (currentUser == null) {
          _showErrorSnackBar('Please login to continue');
          return;
        }

        // Build a minimal Patient model from the profile
        final String name =
            (profile['fullName'] ?? profile['name'] ?? '') as String;
        final String? email = profile['email'] as String?;
        final String? gender = profile['gender'] as String?;
        final String? bloodGroup = profile['bloodGroup'] as String?;
        final String? dobStr = profile['dateOfBirth'] as String?;

        int? computedAge;
        if (dobStr != null) {
          try {
            final dob = DateTime.parse(dobStr);
            final now = DateTime.now();
            computedAge =
                now.year -
                dob.year -
                ((now.month < dob.month ||
                        (now.month == dob.month && now.day < dob.day))
                    ? 1
                    : 0);
          } catch (_) {}
        }

        final tempPatient = Patient(
          id: '', // will be set after adding to patients collection
          name: name.isEmpty && email != null ? email.split('@').first : name,
          age: computedAge,
          gender: gender,
          phoneNumber: null,
          address: null,
          email: email,
          dateOfBirth: null,
          bloodGroup: bloodGroup,
          weight: null,
          height: null,
          allergies:
              (profile['allergies'] is List)
                  ? List<String>.from(profile['allergies'] as List)
                  : null,
          medicalHistory: null,
          emergencyContact: profile['emergencyContactName'] as String?,
          emergencyContactPhone: profile['emergencyContactPhone'] as String?,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Persist to 'patients' for this doctor so it shows up in pickers and linking
        final doctorId = currentUser.uid;
        final newId = await PatientService.addPatient(tempPatient, doctorId);

        if (newId == null) {
          _showErrorSnackBar('Failed to create patient record');
          return;
        }

        final created = Patient(
          id: newId,
          name: tempPatient.name,
          age: tempPatient.age,
          gender: tempPatient.gender,
          phoneNumber: tempPatient.phoneNumber,
          address: tempPatient.address,
          email: tempPatient.email,
          dateOfBirth: tempPatient.dateOfBirth,
          bloodGroup: tempPatient.bloodGroup,
          weight: tempPatient.weight,
          height: tempPatient.height,
          allergies: tempPatient.allergies,
          medicalHistory: tempPatient.medicalHistory,
          emergencyContact: tempPatient.emergencyContact,
          emergencyContactPhone: tempPatient.emergencyContactPhone,
          createdAt: tempPatient.createdAt,
          updatedAt: tempPatient.updatedAt,
        );

        setState(() {
          _selectedPatient = created;
          _patientName.text = created.name;
          _patientAge.text = created.age?.toString() ?? '';
          _patientGender = created.gender;
          _patientPhone.text = created.phoneNumber ?? '';
          _patientAddress.text = created.address ?? '';
        });
      } catch (e) {
        _showErrorSnackBar('Failed to process new patient: ${e.toString()}');
      }
    } else if (result is Patient) {
      // Backwards compatibility if a Patient object is ever returned
      setState(() {
        _selectedPatient = result;
        _patientName.text = result.name;
        _patientAge.text = result.age?.toString() ?? '';
        _patientGender = result.gender;
        _patientPhone.text = result.phoneNumber ?? '';
        _patientAddress.text = result.address ?? '';
      });
    }
  }

  /// Show error message
  void _showErrorSnackBar(String message) {
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

  /// Show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
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
          'Review Prescription',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.1 * 255),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.text_snippet,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Extracted Text',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _extractedTextController,
                              decoration: InputDecoration(
                                hintText:
                                    'Extracted prescription text will appear here',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 20,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Prescription text cannot be empty';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Patient section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.1 * 255),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_search,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Patient',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickExistingPatient,
                                    icon: const Icon(Icons.search),
                                    label: const Text('Existing patient'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _createNewPatient,
                                    icon: const Icon(
                                      Icons.person_add,
                                      color: Colors.white,
                                    ),
                                    label: const Text('New patient'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_selectedPatient != null) ...[
                              TextFormField(
                                controller: _patientName,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _patientAge,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Age',
                                        prefixIcon: Icon(Icons.cake_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _patientGender,
                                      decoration: const InputDecoration(
                                        labelText: 'Gender',
                                        prefixIcon: Icon(Icons.wc_outlined),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Male',
                                          child: Text('Male'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Female',
                                          child: Text('Female'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Other',
                                          child: Text('Other'),
                                        ),
                                      ],
                                      onChanged:
                                          (v) => setState(
                                            () => _patientGender = v,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _patientPhone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _patientAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Save button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1 * 255),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePrescription,
                  icon:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Prescription',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
