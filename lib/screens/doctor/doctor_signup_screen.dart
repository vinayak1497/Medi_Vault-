import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/screens/doctor/doctor_login_screen.dart';
import 'package:health_buddy/screens/common/auth/email_verification_screen.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/models/medical_data.dart';
import 'package:health_buddy/models/nmc_verification.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _doctorIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedSpecialization = '';
  String _selectedDegree = '';
  String _selectedState = '';
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
    _hospitalController.dispose();
    _doctorIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _yearsOfExperienceController.dispose();
    super.dispose();
  }

  void _onSpecializationTextChanged(String value) {
    setState(() {
      _filteredSpecializations = MedicalSpecializations.searchSpecializations(
        value,
      );
      _showSpecializationDropdown =
          value.isNotEmpty && _filteredSpecializations.isNotEmpty;
    });
  }

  void _selectSpecialization(String specialization) {
    setState(() {
      _selectedSpecialization = specialization;
      _specializationController.text = specialization;
      _showSpecializationDropdown = false;
    });
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('🚀 Starting doctor registration for: $email');

      // Prepare doctor data
      final doctorData = {
        'name': _nameController.text.trim(),
        'specialization':
            _selectedSpecialization.isNotEmpty
                ? _selectedSpecialization
                : _specializationController.text.trim(),
        'degree': _selectedDegree,
        'hospital': _hospitalController.text.trim(),
        'doctorId': _doctorIdController.text.trim(),
        'yearsOfExperience': _yearsOfExperienceController.text.trim(),
        'state': _selectedState,
      };

      // Register user with email and password
      final userCredential = await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        userType: 'doctor',
        userData: doctorData,
      );

      print(
        '✅ Registration completed successfully for: ${userCredential.user?.email}',
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Registration successful! Please check your email to verify your account.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to verification screen after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EmailVerificationScreen(
                      email: email,
                      userType: 'doctor',
                    ),
              ),
            );
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      print('❌ Unexpected error during signup: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in instead.';
      case 'operation-not-allowed':
        return 'Registration is currently disabled. Please contact support.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many registration attempts. Please wait a few minutes and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';
      case 'unknown':
        return 'Registration completed but there was an issue saving your profile. You can still log in.';
      default:
        return 'Registration failed with error: $errorCode. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  paleGreen.withOpacity(0.3),
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Header with medical icon
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGreen.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Doctor Registration',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Join our medical community',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Name field
                    _buildModernTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Dr. John Doe',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Degree dropdown
                    _buildDegreeDropdown(),
                    const SizedBox(height: 20),

                    // Specialization field with search
                    _buildSpecializationField(),
                    const SizedBox(height: 20),

                    // Years of Experience
                    _buildModernTextField(
                      controller: _yearsOfExperienceController,
                      label: 'Years of Experience',
                      hint: 'e.g., 5',
                      icon: Icons.trending_up,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final years = int.tryParse(value);
                          if (years == null || years < 0 || years > 60) {
                            return 'Please enter valid years (0-60)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Hospital field
                    _buildModernTextField(
                      controller: _hospitalController,
                      label: 'Hospital/Clinic',
                      hint: 'Apollo Hospital',
                      icon: Icons.business_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your hospital or clinic name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Doctor ID field
                    _buildModernTextField(
                      controller: _doctorIdController,
                      label: 'Medical Registration Number',
                      hint: 'MH12345',
                      icon: Icons.badge_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your medical registration number';
                        }
                        if (value.length < 3) {
                          return 'Registration number must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // State dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedState.isEmpty ? null : _selectedState,
                        decoration: InputDecoration(
                          labelText: 'State of Registration *',
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: primaryGreen.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          labelStyle: TextStyle(
                            color: primaryGreen.withOpacity(0.8),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items:
                            IndianStates.states.map((String state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(
                                  state,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedState = newValue ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your state of registration';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email field
                    _buildModernTextField(
                      controller: _emailController,
                      label: 'Professional Email',
                      hint: 'doctor@hospital.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!AuthService.isValidEmail(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    _buildModernTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Create a strong password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Register button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGreen, lightGreen],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Register as Doctor',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DoctorLoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDegreeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDegree.isEmpty ? null : _selectedDegree,
        decoration: InputDecoration(
          labelText: 'Medical Degree',
          prefixIcon: Icon(Icons.school_outlined, color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
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
    );
  }

  Widget _buildSpecializationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _specializationController,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Medical Specialization',
              hintText: 'Start typing to search...',
              prefixIcon: Icon(
                Icons.medical_services_outlined,
                color: primaryGreen,
              ),
              suffixIcon:
                  _specializationController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _specializationController.clear();
                            _selectedSpecialization = '';
                            _showSpecializationDropdown = false;
                          });
                        },
                      )
                      : Icon(Icons.arrow_drop_down, color: primaryGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryGreen, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: _onSpecializationTextChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select or enter your specialization';
              }
              return null;
            },
          ),
        ),
        if (_showSpecializationDropdown && _filteredSpecializations.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  _filteredSpecializations.length > 5
                      ? 5
                      : _filteredSpecializations.length,
              itemBuilder: (context, index) {
                final specialization = _filteredSpecializations[index];
                return ListTile(
                  title: Text(
                    specialization,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => _selectSpecialization(specialization),
                  dense: true,
                  hoverColor: paleGreen.withOpacity(0.5),
                );
              },
            ),
          ),
      ],
    );
  }
}
