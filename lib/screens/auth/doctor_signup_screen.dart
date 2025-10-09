import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/screens/auth/doctor_login_screen.dart';
import 'package:health_buddy/screens/auth/email_verification_screen.dart';
import 'package:health_buddy/services/auth_service.dart';

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

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _doctorIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        'specialization': _specializationController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'doctorId': _doctorIdController.text.trim(),
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
      appBar: AppBar(
        title: const Text('Doctor Signup'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Doctor Registration',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please fill in your details to register as a doctor',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Name field
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Specialization field
                  _buildTextField(
                    controller: _specializationController,
                    label: 'Specialization',
                    hint: 'e.g., Cardiologist, Pediatrician',
                    icon: Icons.local_hospital,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your specialization';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Hospital field
                  _buildTextField(
                    controller: _hospitalController,
                    label: 'Hospital/Clinic',
                    hint: 'Enter your hospital or clinic name',
                    icon: Icons.business,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your hospital or clinic name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Doctor ID field
                  _buildTextField(
                    controller: _doctorIdController,
                    label: 'Doctor ID/Registration Number',
                    hint: 'Enter your valid doctor registration number',
                    icon: Icons.badge,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your doctor ID or registration number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'Enter your professional email',
                    icon: Icons.email,
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
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Create a strong password (min 6 characters)',
                    icon: Icons.lock,
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
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Signup button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Register as Doctor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),

                  const SizedBox(height: 20),

                  // Login option
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorLoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
