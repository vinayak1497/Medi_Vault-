import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/screens/doctor/doctor_login_screen.dart';
import 'package:health_buddy/screens/common/auth/email_verification_screen.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/models/nmc_verification.dart';

class DoctorSignupStep2Screen extends StatefulWidget {
  final Map<String, dynamic> step1Data;

  const DoctorSignupStep2Screen({super.key, required this.step1Data});

  @override
  State<DoctorSignupStep2Screen> createState() =>
      _DoctorSignupStep2ScreenState();
}

class _DoctorSignupStep2ScreenState extends State<DoctorSignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedState = '';

  // Green theme colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color paleGreen = Color(0xFFE8F5E8);

  @override
  void dispose() {
    _hospitalController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required data from step 1
    if (widget.step1Data['name']?.isEmpty ?? true) {
      setState(() {
        _errorMessage =
            'Professional information is incomplete. Please go back and complete all fields.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating your doctor account...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      debugPrint('🚀 Starting doctor registration for: $email');

      // Combine step 1 and step 2 data with comprehensive doctor profile
      final doctorData = {
        // Professional Information (from step 1)
        'fullName': widget.step1Data['name'] ?? '',
        'name': widget.step1Data['name'] ?? '', // Keep both for compatibility
        'specialization': widget.step1Data['specialization'] ?? '',
        'degree': widget.step1Data['degree'] ?? '',
        'doctorId': widget.step1Data['doctorId'] ?? '',
        'registrationNumber':
            widget.step1Data['doctorId'] ?? '', // Alias for NMC verification
        'yearsOfExperience': widget.step1Data['yearsOfExperience'] ?? '',

        // Contact & Practice Information (from step 2)
        'email': email,
        'hospital': _hospitalController.text.trim(),
        'clinicName': _hospitalController.text.trim(), // Alias
        'state': _selectedState,

        // Account metadata
        'userType': 'doctor',
        'accountCreated': ServerValue.timestamp,
        'verified': false,
        'nmcVerified': false,
        'profileComplete': true,
        'isActive': true,

        // Additional professional fields (can be updated later)
        'phoneNumber': '',
        'address': '',
        'licenseNumber': widget.step1Data['doctorId'] ?? '',
        'consultationFee': 0,
        'availableHours': {},
        'patientCount': 0,
        'rating': 0.0,
        'biography': '',
      };

      debugPrint('📋 Doctor data to be saved: $doctorData');

      // Register user with email and password
      await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        userType: 'doctor',
        userData: doctorData,
      );

      debugPrint('✅ Doctor registration successful for: $email');
      debugPrint(
        '💾 All doctor data saved to Firebase Realtime Database under "doctors" node',
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Account created successfully! Please verify your email.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to email verification
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    EmailVerificationScreen(email: email, userType: 'doctor'),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      setState(() {
        switch (e.code) {
          case 'weak-password':
            _errorMessage =
                'Password is too weak. Please use at least 6 characters.';
            break;
          case 'email-already-in-use':
            _errorMessage = 'An account with this email already exists.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          default:
            _errorMessage =
                e.message ?? 'Registration failed. Please try again.';
        }
      });
    } catch (e) {
      debugPrint('❌ General Error: $e');
      setState(() {
        _errorMessage =
            'Registration failed. Please check your internet connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              'Step 2 of 2',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: 1.0,
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
                  'Contact & Practice Details',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your profile with contact information',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Hospital/Clinic Field
                TextFormField(
                  controller: _hospitalController,
                  decoration: InputDecoration(
                    labelText: 'Hospital/Clinic Name *',
                    hintText: 'Apollo Hospital',
                    prefixIcon: const Icon(
                      Icons.local_hospital,
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Hospital/Clinic name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Hospital/Clinic name must be at least 2 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                // State Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedState.isEmpty ? null : _selectedState,
                  decoration: InputDecoration(
                    labelText: 'State *',
                    prefixIcon: const Icon(
                      Icons.location_on,
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
                  isExpanded:
                      true, // prevent text overflow when prefix/suffix present
                  selectedItemBuilder:
                      (context) =>
                          IndianStates.states
                              .map(
                                (s) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    s,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                  items:
                      IndianStates.states.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(
                            state,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      return 'Please select a state';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    hintText: 'doctor@example.com',
                    prefixIcon: const Icon(Icons.email, color: primaryGreen),
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
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Minimum 6 characters',
                    prefixIcon: const Icon(Icons.lock, color: primaryGreen),
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
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Complete Registration Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Complete Registration',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.check_circle),
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
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorLoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
