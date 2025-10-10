import 'package:flutter/material.dart';
import 'package:health_buddy/models/medical_data.dart';
import 'package:health_buddy/screens/doctor/doctor_signup_step2_screen.dart';
import 'package:health_buddy/screens/doctor/doctor_login_screen.dart';

class DoctorSignupStep1Screen extends StatefulWidget {
  const DoctorSignupStep1Screen({super.key});

  @override
  State<DoctorSignupStep1Screen> createState() =>
      _DoctorSignupStep1ScreenState();
}

class _DoctorSignupStep1ScreenState extends State<DoctorSignupStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _doctorIdController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();

  String _selectedSpecialization = '';
  String _selectedDegree = '';
  List<String> _filteredSpecializations =
      MedicalSpecializations.specializations;
  bool _showSpecializationDropdown = false;

  // Green theme colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color paleGreen = Color(0xFFE8F5E8);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _doctorIdController.dispose();
    _yearsOfExperienceController.dispose();
    super.dispose();
  }

  void _filterSpecializations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSpecializations = MedicalSpecializations.specializations;
        _showSpecializationDropdown = false;
      } else {
        _filteredSpecializations =
            MedicalSpecializations.specializations
                .where(
                  (spec) => spec.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
        _showSpecializationDropdown = _filteredSpecializations.isNotEmpty;
      }
    });
  }

  void _proceedToNextStep() {
    if (_formKey.currentState!.validate()) {
      // Prepare step 1 data
      final step1Data = {
        'name': _nameController.text.trim(),
        'specialization':
            _selectedSpecialization.isNotEmpty
                ? _selectedSpecialization
                : _specializationController.text.trim(),
        'degree': _selectedDegree,
        'doctorId': _doctorIdController.text.trim(),
        'yearsOfExperience': _yearsOfExperienceController.text.trim(),
      };

      // Navigate to step 2 with data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorSignupStep2Screen(step1Data: step1Data),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Step 1 of 2',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: 0.5,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your medical credentials',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Full Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Dr. John Doe',
                    prefixIcon: const Icon(Icons.person, color: primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: paleGreen,
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
                const SizedBox(height: 20),

                // Doctor ID Field
                TextFormField(
                  controller: _doctorIdController,
                  decoration: InputDecoration(
                    labelText: 'Medical Registration Number *',
                    hintText: 'MH12345',
                    prefixIcon: const Icon(Icons.badge, color: primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: paleGreen,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Medical registration number is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Registration number must be at least 3 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 20),

                // Medical Degree Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedDegree.isEmpty ? null : _selectedDegree,
                  decoration: InputDecoration(
                    labelText: 'Medical Degree *',
                    prefixIcon: const Icon(Icons.school, color: primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: paleGreen,
                  ),
                  items:
                      MedicalDegrees.degrees.map((String degree) {
                        return DropdownMenuItem<String>(
                          value: degree,
                          child: Text(degree),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDegree = newValue ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your medical degree';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Specialization Field with Dropdown
                Column(
                  children: [
                    TextFormField(
                      controller: _specializationController,
                      decoration: InputDecoration(
                        labelText: 'Specialization *',
                        hintText: 'Search or type your specialization',
                        prefixIcon: const Icon(
                          Icons.medical_services,
                          color: primaryGreen,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryGreen,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: paleGreen,
                      ),
                      onChanged: (value) {
                        _filterSpecializations(value);
                        setState(() {
                          _selectedSpecialization = '';
                        });
                      },
                      validator: (value) {
                        if ((value == null || value.trim().isEmpty) &&
                            _selectedSpecialization.isEmpty) {
                          return 'Specialization is required';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    if (_showSpecializationDropdown) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredSpecializations.length,
                          itemBuilder: (context, index) {
                            final specialization =
                                _filteredSpecializations[index];
                            return ListTile(
                              title: Text(specialization),
                              onTap: () {
                                setState(() {
                                  _selectedSpecialization = specialization;
                                  _specializationController.text =
                                      specialization;
                                  _showSpecializationDropdown = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Years of Experience Field
                TextFormField(
                  controller: _yearsOfExperienceController,
                  decoration: InputDecoration(
                    labelText: 'Years of Experience *',
                    hintText: '5',
                    prefixIcon: const Icon(Icons.work, color: primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: paleGreen,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Years of experience is required';
                    }
                    final years = int.tryParse(value.trim());
                    if (years == null || years < 0 || years > 70) {
                      return 'Please enter a valid number of years (0-70)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _proceedToNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already registered? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorLoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Please login!',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
