import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_buddy/models/prescription.dart';
import 'package:health_buddy/models/patient.dart';
import 'package:health_buddy/services/doctor_service.dart';
import 'package:health_buddy/services/patient_service.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/services/prescription_data_cache_service.dart';

/// Prescription form screen for doctors to review and edit extracted prescription data
/// Allows editing all prescription template fields and saving to Firebase
class PrescriptionFormScreen extends StatefulWidget {
  final Prescription prescription;

  const PrescriptionFormScreen({super.key, required this.prescription});

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Medical Information Controllers (Patient info comes from selected patient)
  late TextEditingController _currentSymptomsController;
  late TextEditingController _diagnosisController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _allergiesController;
  late TextEditingController _vitalSignsController;

  // Prescription Details Controllers
  late TextEditingController _instructionsController;
  late TextEditingController _precautionsController;
  late TextEditingController _followUpController;
  late TextEditingController _notesController;

  // Form state
  PrescriptionStatus _selectedStatus = PrescriptionStatus.active;
  List<MedicationItem> _medications = [];
  bool _isSaving = false;

  // Patient management
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _isLoadingPatients = false;

  // Animation controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Initialize controllers with extracted data
    _initializeControllers();

    // Load patients for dropdown
    _loadPatients();

    // Start animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _disposeControllers();
    super.dispose();
  }

  /// Initialize text controllers with prescription data
  ///
  /// This method now uses a two-tier approach:
  /// 1. Check cache for complete prescription data (preferred)
  /// 2. Fall back to widget parameters if cache is unavailable
  ///
  /// This ensures data persists even if navigation temporarily breaks the reference
  void _initializeControllers() {
    // Get cache service instance
    final cacheService = PrescriptionDataCacheService();

    // Debug print cache contents
    cacheService.debugPrintCacheContents();

    // Try to get cached prescription
    final cachedPrescription = cacheService.getCachedPrescription();
    final prescriptionToUse = cachedPrescription ?? widget.prescription;

    // Detailed logging of data source and content
    if (cachedPrescription != null) {
      debugPrint('''
✓ [Form] Using cached prescription data:
- Medications: ${cachedPrescription.medications.length}
- Symptoms: ${cachedPrescription.currentSymptoms ?? 'None'}
- Diagnosis: ${cachedPrescription.diagnosis ?? 'None'}
- Instructions: ${cachedPrescription.instructions ?? 'None'}
''');
    } else {
      debugPrint('''
⚠️ [Form] Using widget prescription data:
- Medications: ${widget.prescription.medications.length}
- Symptoms: ${widget.prescription.currentSymptoms ?? 'None'}
- Diagnosis: ${widget.prescription.diagnosis ?? 'None'}
- Instructions: ${widget.prescription.instructions ?? 'None'}
''');
    }

    // Patient information will come from selected patient, not controllers

    _currentSymptomsController = TextEditingController(
      text: prescriptionToUse.currentSymptoms ?? '',
    );
    _diagnosisController = TextEditingController(
      text: prescriptionToUse.diagnosis ?? '',
    );
    _medicalHistoryController = TextEditingController(
      text: prescriptionToUse.medicalHistory ?? '',
    );
    _allergiesController = TextEditingController(
      text: prescriptionToUse.allergies ?? '',
    );
    _vitalSignsController = TextEditingController(
      text: prescriptionToUse.vitalSigns ?? '',
    );

    _instructionsController = TextEditingController(
      text: prescriptionToUse.instructions ?? '',
    );
    _precautionsController = TextEditingController(
      text: prescriptionToUse.precautions ?? '',
    );
    _followUpController = TextEditingController(
      text: prescriptionToUse.followUpInstructions ?? '',
    );
    _notesController = TextEditingController(
      text: prescriptionToUse.doctorNotes ?? '',
    );

    _selectedStatus = prescriptionToUse.status;
    _medications = List.from(prescriptionToUse.medications);

    // Debug output: Show what we loaded
    debugPrint(
      '📋 [Form] Loaded ${_medications.length} medications, '
      'symptoms: ${_currentSymptomsController.text.isNotEmpty ? (_currentSymptomsController.text.length > 30 ? "${_currentSymptomsController.text.substring(0, 30)}..." : _currentSymptomsController.text) : "empty"}, '
      'diagnosis: ${_diagnosisController.text.isNotEmpty ? (_diagnosisController.text.length > 30 ? "${_diagnosisController.text.substring(0, 30)}..." : _diagnosisController.text) : "empty"}',
    );
  }

  /// Dispose all text controllers
  void _disposeControllers() {
    // Patient controllers removed - info comes from selected patient
    _currentSymptomsController.dispose();
    _diagnosisController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _vitalSignsController.dispose();
    _instructionsController.dispose();
    _precautionsController.dispose();
    _followUpController.dispose();
    _notesController.dispose();
  }

  /// Load patients for dropdown selection
  Future<void> _loadPatients() async {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) return;

    setState(() {
      _isLoadingPatients = true;
    });

    try {
      final patients = await PatientService.getPatientsByDoctor(
        currentUser.uid,
      );

      // If no patients exist, add some sample patients
      if (patients.isEmpty) {
        await PatientService.addSamplePatients(currentUser.uid);
        final updatedPatients = await PatientService.getPatientsByDoctor(
          currentUser.uid,
        );
        setState(() {
          _patients = updatedPatients;
        });
      } else {
        setState(() {
          _patients = patients;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading patients: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  /// Save prescription to Firebase
  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    if (_medications.isEmpty) {
      _showErrorSnackBar('Please add at least one medication');
      return;
    }

    if (_selectedPatient == null) {
      _showErrorSnackBar('Please select a patient');
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

        // Patient Information - from selected patient
        patientName: _selectedPatient!.name,
        patientAge: _selectedPatient!.age,
        patientGender: _selectedPatient!.gender,
        patientWeight: _selectedPatient!.weight,
        patientPhone: _selectedPatient!.phoneNumber,
        patientAddress: _selectedPatient!.address,

        // Medical Information
        currentSymptoms:
            _currentSymptomsController.text.trim().isNotEmpty
                ? _currentSymptomsController.text.trim()
                : null,
        diagnosis:
            _diagnosisController.text.trim().isNotEmpty
                ? _diagnosisController.text.trim()
                : null,
        medicalHistory:
            _medicalHistoryController.text.trim().isNotEmpty
                ? _medicalHistoryController.text.trim()
                : null,
        allergies:
            _allergiesController.text.trim().isNotEmpty
                ? _allergiesController.text.trim()
                : null,
        vitalSigns:
            _vitalSignsController.text.trim().isNotEmpty
                ? _vitalSignsController.text.trim()
                : null,

        // Prescription Details
        medications: _medications,
        instructions:
            _instructionsController.text.trim().isNotEmpty
                ? _instructionsController.text.trim()
                : null,
        precautions:
            _precautionsController.text.trim().isNotEmpty
                ? _precautionsController.text.trim()
                : null,
        followUpInstructions:
            _followUpController.text.trim().isNotEmpty
                ? _followUpController.text.trim()
                : null,
        doctorNotes:
            _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,

        // Status and metadata
        status: _selectedStatus,
        prescriptionDate: DateTime.now(),
        createdAt: widget.prescription.createdAt ?? DateTime.now(),
        extractedText: widget.prescription.extractedText,
      );

      // Save to Firebase
      await DoctorService.savePrescription(updatedPrescription);

      setState(() {
        _isSaving = false;
      });

      _showSuccessSnackBar('Prescription saved successfully!');

      // ✓ Clear cache after successful save to prevent stale data on next navigation
      PrescriptionDataCacheService().clearCache();
      debugPrint('✓ [Form] Prescription saved and cache cleared');

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

  /// Add new medication
  void _addMedication() {
    setState(() {
      _medications.add(
        MedicationItem(
          name: '',
          genericName: '',
          strength: '',
          dosageForm: DosageForm.tablet,
          frequency: DosageFrequency.onceDaily,
          duration: '',
          instructions: '',
        ),
      );
    });
  }

  /// Remove medication
  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
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
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: Form(
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
                      // Patient Selection Dropdown
                      _buildPatientSelection(),
                      const SizedBox(height: 16),

                      // Patient Information Display (from selected patient)
                      _buildSelectedPatientInfo(),

                      const SizedBox(height: 16),

                      // Medical Information Section
                      _buildSectionCard(
                        'Medical Information',
                        Icons.medical_services,
                        [
                          _buildTextFormField(
                            controller: _currentSymptomsController,
                            label: 'Current Symptoms',
                            icon: Icons.sentiment_dissatisfied,
                            maxLines: 3,
                          ),

                          _buildTextFormField(
                            controller: _diagnosisController,
                            label: 'Diagnosis',
                            icon: Icons.assignment,
                            maxLines: 2,
                          ),

                          _buildTextFormField(
                            controller: _medicalHistoryController,
                            label: 'Medical History',
                            icon: Icons.history,
                            maxLines: 3,
                          ),

                          _buildTextFormField(
                            controller: _allergiesController,
                            label: 'Allergies',
                            icon: Icons.warning,
                            maxLines: 2,
                          ),

                          _buildTextFormField(
                            controller: _vitalSignsController,
                            label: 'Vital Signs',
                            icon: Icons.favorite,
                            maxLines: 2,
                            hintText: 'BP, Pulse, Temperature, etc.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Medications Section
                      _buildMedicationsSection(),

                      const SizedBox(height: 16),

                      // Instructions Section
                      _buildSectionCard('Instructions & Notes', Icons.notes, [
                        _buildTextFormField(
                          controller: _instructionsController,
                          label: 'General Instructions',
                          icon: Icons.info,
                          maxLines: 3,
                        ),

                        _buildTextFormField(
                          controller: _precautionsController,
                          label: 'Precautions',
                          icon: Icons.warning_amber,
                          maxLines: 2,
                        ),

                        _buildTextFormField(
                          controller: _followUpController,
                          label: 'Follow-up Instructions',
                          icon: Icons.event_repeat,
                          maxLines: 2,
                        ),

                        _buildTextFormField(
                          controller: _notesController,
                          label: 'Doctor Notes',
                          icon: Icons.note_add,
                          maxLines: 3,
                        ),

                        DropdownButtonFormField<PrescriptionStatus>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: const Icon(Icons.flag),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items:
                              PrescriptionStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.displayName),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                        ),
                      ]),

                      const SizedBox(height: 20),
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
      ),
    );
  }

  /// Build patient selection dropdown
  Widget _buildPatientSelection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.people,
                    color: const Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Patient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _isLoadingPatients
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2E7D32),
                    ),
                  ),
                )
                : DropdownButtonFormField<Patient>(
                  decoration: InputDecoration(
                    labelText: 'Patient *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedPatient,
                  hint: const Text('Choose a patient for this prescription'),
                  items:
                      _patients.map((patient) {
                        return DropdownMenuItem<Patient>(
                          value: patient,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                patient.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (patient.age != null || patient.gender != null)
                                Text(
                                  '${patient.age ?? 'Unknown'} years • ${patient.gender ?? 'Unknown'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (Patient? patient) {
                    setState(() {
                      _selectedPatient = patient;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a patient';
                    }
                    return null;
                  },
                ),

            if (_selectedPatient != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${_selectedPatient!.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                          if (_selectedPatient!.phoneNumber != null)
                            Text(
                              'Phone: ${_selectedPatient!.phoneNumber}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build selected patient information display
  Widget _buildSelectedPatientInfo() {
    if (_selectedPatient == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Patient Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Patient details in a neat layout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  _buildPatientDetailRow(
                    Icons.person_outline,
                    'Name',
                    _selectedPatient!.name,
                  ),
                  if (_selectedPatient!.age != null)
                    _buildPatientDetailRow(
                      Icons.cake_outlined,
                      'Age',
                      '${_selectedPatient!.age} years',
                    ),
                  if (_selectedPatient!.gender != null)
                    _buildPatientDetailRow(
                      Icons.wc_outlined,
                      'Gender',
                      _selectedPatient!.gender!,
                    ),
                  if (_selectedPatient!.phoneNumber != null)
                    _buildPatientDetailRow(
                      Icons.phone_outlined,
                      'Phone',
                      _selectedPatient!.phoneNumber!,
                    ),
                  if (_selectedPatient!.weight != null)
                    _buildPatientDetailRow(
                      Icons.monitor_weight_outlined,
                      'Weight',
                      '${_selectedPatient!.weight} kg',
                    ),
                  if (_selectedPatient!.address != null &&
                      _selectedPatient!.address!.isNotEmpty)
                    _buildPatientDetailRow(
                      Icons.location_on_outlined,
                      'Address',
                      _selectedPatient!.address!,
                    ),
                  if (_selectedPatient!.bloodGroup != null)
                    _buildPatientDetailRow(
                      Icons.bloodtype_outlined,
                      'Blood Group',
                      _selectedPatient!.bloodGroup!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build patient detail row
  Widget _buildPatientDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  /// Build section card widget
  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF4CAF50), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build medications section
  Widget _buildMedicationsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medication,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Medications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_medications.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No medications added. Click "Add" to include medications.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._medications.asMap().entries.map((entry) {
                final index = entry.key;
                final medication = entry.value;
                return _buildMedicationCard(medication, index);
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Build individual medication card
  Widget _buildMedicationCard(MedicationItem medication, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          medication.name.isNotEmpty
              ? medication.name
              : 'Medication ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle:
            medication.strength.isNotEmpty ? Text(medication.strength) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.expand_more),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeMedication(index),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  initialValue: medication.name,
                  decoration: InputDecoration(
                    labelText: 'Medication Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _medications[index] = medication.copyWith(name: value);
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Medication name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: medication.strength,
                        decoration: InputDecoration(
                          labelText: 'Strength',
                          hintText: 'e.g., 500mg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _medications[index] = medication.copyWith(
                              strength: value,
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<DosageForm>(
                        value: medication.dosageForm,
                        decoration: InputDecoration(
                          labelText: 'Form',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items:
                            DosageForm.values.map((form) {
                              return DropdownMenuItem(
                                value: form,
                                child: Text(form.displayName),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _medications[index] = medication.copyWith(
                                dosageForm: value,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<DosageFrequency>(
                        value: medication.frequency,
                        decoration: InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items:
                            DosageFrequency.values.map((frequency) {
                              return DropdownMenuItem(
                                value: frequency,
                                child: Text(frequency.displayName),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _medications[index] = medication.copyWith(
                                frequency: value,
                              );
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextFormField(
                        initialValue: medication.duration,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          hintText: 'e.g., 7 days',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _medications[index] = medication.copyWith(
                              duration: value,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextFormField(
                  initialValue: medication.instructions,
                  decoration: InputDecoration(
                    labelText: 'Special Instructions',
                    hintText: 'e.g., Take after meals',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    setState(() {
                      _medications[index] = medication.copyWith(
                        instructions: value,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build text form field widget
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
