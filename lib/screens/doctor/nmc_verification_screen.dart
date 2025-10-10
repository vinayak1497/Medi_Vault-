import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/models/nmc_verification.dart';
import 'package:health_buddy/services/nmc_verification_service.dart';
import 'package:health_buddy/screens/doctor/nmc_verification_example_screen.dart';
import 'package:health_buddy/screens/doctor/doctor_dashboard.dart';
import 'package:health_buddy/services/auth_service.dart';

class NMCVerificationScreen extends StatefulWidget {
  final Map<String, dynamic>? doctorData;

  const NMCVerificationScreen({super.key, this.doctorData});

  @override
  State<NMCVerificationScreen> createState() => _NMCVerificationScreenState();
}

class _NMCVerificationScreenState extends State<NMCVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isLoading = false;
  NMCVerificationResult? _verificationResult;
  bool _showOptionalFields = false;
  bool _isPreFilled = false;

  @override
  void initState() {
    super.initState();
    _prefillFormWithDoctorData();
  }

  void _prefillFormWithDoctorData() {
    final doctorData = widget.doctorData;
    print('🔍 NMC Screen - Doctor data received: $doctorData');

    if (doctorData != null) {
      print('� Name field: ${doctorData['name']}');
      print('🆔 Doctor ID field: ${doctorData['doctorId']}');
      print('🏥 Specialization field: ${doctorData['specialization']}');

      _fullNameController.text = doctorData['name'] ?? '';
      _registrationNumberController.text = doctorData['doctorId'] ?? '';
      _specializationController.text = doctorData['specialization'] ?? '';
      _isPreFilled = true;
      _showOptionalFields = true; // Show optional fields since we have data

      print('✅ Form pre-filled - isPreFilled: $_isPreFilled');
      print('📄 Name controller: ${_fullNameController.text}');
      print(
        '📄 Registration controller: ${_registrationNumberController.text}',
      );
    } else {
      print('❌ No doctor data received - form will be empty');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _registrationNumberController.dispose();
    _fatherNameController.dispose();
    _specializationController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _verifyDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate input using service validation
    final validationError = NMCVerificationService.validateInput(
      fullName: _fullNameController.text,
      registrationNumber: _registrationNumberController.text,
      state: 'All States', // Default since we removed state field
    );

    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _verificationResult = null;
    });

    try {
      final result = await NMCVerificationService.verifyDoctor(
        fullName: _fullNameController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        state: 'All States', // Default since we removed state field
        fatherName:
            _fatherNameController.text.trim().isEmpty
                ? null
                : _fatherNameController.text.trim(),
        specialization:
            _specializationController.text.trim().isEmpty
                ? null
                : _specializationController.text.trim(),
        yearOfRegistration:
            _yearController.text.trim().isEmpty
                ? null
                : _yearController.text.trim(),
      );

      setState(() {
        _verificationResult = result;
      });

      if (result.isVerified) {
        _showSnackBar('✅ Doctor verification successful!', isError: false);
      } else {
        _showSnackBar('❌ ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Verification failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  Future<void> _proceedToDashboard() async {
    try {
      // Update user verification status in Firebase
      final user = AuthService.getCurrentUser();
      if (user != null) {
        final DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child('doctors')
            .child(user.uid);

        await userRef.update({
          'verified': true,
          'verificationDate': ServerValue.timestamp,
          'nmcVerified': true,
        });

        print('✅ User verification status updated in Firebase');
      }

      // Navigate to dashboard
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DoctorDashboard()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('❌ Error updating verification status: $e');
      // Still navigate to dashboard even if update fails
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DoctorDashboard()),
          (route) => false,
        );
      }
    }
  }

  void _clearForm() {
    _fullNameController.clear();
    _registrationNumberController.clear();
    _fatherNameController.clear();
    _specializationController.clear();
    _yearController.clear();
    setState(() {
      _verificationResult = null;
      _showOptionalFields = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NMC Doctor Verification'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NMCVerificationExampleScreen(),
                ),
              );
            },
            tooltip: 'View Examples',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Verify Medical Registration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Verify doctor credentials through National Medical Commission (NMC)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pre-filled data banner
              if (_isPreFilled) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Form pre-filled with your registration data. Fields are locked for verification.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Required Fields
              const Text(
                'Required Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Full Name Field
              TextFormField(
                controller: _fullNameController,
                readOnly: _isPreFilled,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: _isPreFilled ? null : 'Dr. John Doe',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: _isPreFilled,
                  fillColor: _isPreFilled ? Colors.grey[100] : null,
                  suffixIcon:
                      _isPreFilled
                          ? Icon(Icons.lock, color: Colors.grey[600])
                          : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Registration Number Field
              TextFormField(
                controller: _registrationNumberController,
                readOnly: _isPreFilled,
                decoration: InputDecoration(
                  labelText: 'Registration Number *',
                  hintText: _isPreFilled ? null : 'MH12345',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  filled: _isPreFilled,
                  fillColor: _isPreFilled ? Colors.grey[100] : null,
                  suffixIcon:
                      _isPreFilled
                          ? Icon(Icons.lock, color: Colors.grey[600])
                          : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Registration number is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Registration number must be at least 3 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 20),

              // Optional Fields Toggle
              if (!_isPreFilled)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Optional Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showOptionalFields = !_showOptionalFields;
                        });
                      },
                      icon: Icon(
                        _showOptionalFields
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      label: Text(_showOptionalFields ? 'Hide' : 'Show'),
                    ),
                  ],
                ),

              // Optional Fields
              if (_showOptionalFields) ...[
                const SizedBox(height: 12),

                // Father's Name Field
                TextFormField(
                  controller: _fatherNameController,
                  readOnly: _isPreFilled,
                  decoration: InputDecoration(
                    labelText: 'Father\'s Name (Optional)',
                    hintText: _isPreFilled ? null : 'Richard Doe',
                    prefixIcon: Icon(Icons.family_restroom),
                    border: OutlineInputBorder(),
                    filled: _isPreFilled,
                    fillColor: _isPreFilled ? Colors.grey[100] : null,
                    suffixIcon:
                        _isPreFilled
                            ? Icon(Icons.lock, color: Colors.grey[600])
                            : null,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Specialization Field
                TextFormField(
                  controller: _specializationController,
                  readOnly: _isPreFilled,
                  decoration: InputDecoration(
                    labelText: 'Specialization (Optional)',
                    hintText: _isPreFilled ? null : 'Cardiology',
                    prefixIcon: Icon(Icons.medical_services),
                    border: OutlineInputBorder(),
                    filled: _isPreFilled,
                    fillColor: _isPreFilled ? Colors.grey[100] : null,
                    suffixIcon:
                        _isPreFilled
                            ? Icon(Icons.lock, color: Colors.grey[600])
                            : null,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Year of Registration Field
                TextFormField(
                  controller: _yearController,
                  readOnly: _isPreFilled,
                  decoration: InputDecoration(
                    labelText: 'Year of Registration (Optional)',
                    hintText: _isPreFilled ? null : '2020',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    filled: _isPreFilled,
                    fillColor: _isPreFilled ? Colors.grey[100] : null,
                    suffixIcon:
                        _isPreFilled
                            ? Icon(Icons.lock, color: Colors.grey[600])
                            : null,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final year = int.tryParse(value);
                      if (year == null ||
                          year < 1950 ||
                          year > DateTime.now().year) {
                        return 'Please enter a valid year (1950-${DateTime.now().year})';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyDoctor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Verifying...'),
                          ],
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified),
                            SizedBox(width: 8),
                            Text(
                              'Verify Doctor',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
              ),
              const SizedBox(height: 24),

              // Verification Result
              if (_verificationResult != null)
                _buildVerificationResult(_verificationResult!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationResult(NMCVerificationResult result) {
    return Card(
      elevation: 4,
      color: result.isVerified ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isVerified ? Icons.check_circle : Icons.error,
                  color: result.isVerified ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.isVerified
                        ? 'Verification Successful'
                        : 'Verification Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          result.isVerified
                              ? Colors.green[800]
                              : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Status: ${result.status.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(result.message, style: const TextStyle(fontSize: 14)),

            // Show doctor details if available
            if (result.doctorDetails != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              const Text(
                'Doctor Information:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _buildDetailRow('Name', result.doctorDetails!.fullName),
              _buildDetailRow(
                'Registration No.',
                result.doctorDetails!.registrationNumber,
              ),
              _buildDetailRow('State', result.doctorDetails!.state),
              _buildDetailRow(
                'Medical Council',
                result.doctorDetails!.stateMedicalCouncil,
              ),
              _buildDetailRow(
                'Registration Date',
                result.doctorDetails!.registrationDate,
              ),
              _buildDetailRow(
                'Qualification',
                result.doctorDetails!.qualification,
              ),
              _buildDetailRow(
                'Father\'s Name',
                result.doctorDetails!.fatherName,
              ),
              _buildDetailRow('Address', result.doctorDetails!.address),

              if (result.doctorDetails!.isActive != null)
                _buildDetailRow(
                  'Status',
                  result.doctorDetails!.isActive! ? 'Active' : 'Inactive',
                ),
            ],

            // Show error code if available
            if (result.errorCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error Code: ${result.errorCode}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ],

            // Dashboard button if verification successful
            if (result.isVerified) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _proceedToDashboard(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.dashboard),
                  label: const Text(
                    'Proceed to Dashboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
