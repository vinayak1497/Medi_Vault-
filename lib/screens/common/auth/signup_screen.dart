import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/screens/common/auth/verification_screen.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  final bool returnToDoctorDashboard;

  const SignupScreen({super.key, this.returnToDoctorDashboard = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

// Alias for better naming from doctor's perspective
class PatientSignupScreen extends SignupScreen {
  const PatientSignupScreen({super.key, bool returnToDoctorDashboard = false})
    : super(returnToDoctorDashboard: returnToDoctorDashboard);
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _formKeys = [
    GlobalKey<FormState>(), // Step 1
    GlobalKey<FormState>(), // Step 2
    GlobalKey<FormState>(), // Step 3
  ];

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _pastConditionsController =
      TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedBloodGroup;
  List<String> _selectedAllergies = [];

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];
  final List<String> _commonAllergies = [
    'Pollen',
    'Dust mites',
    'Pet dander',
    'Peanuts',
    'Tree nuts',
    'Shellfish',
    'Eggs',
    'Milk',
    'Soy',
    'Wheat',
    'Penicillin',
    'Aspirin',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _pastConditionsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      HapticFeedback.lightImpact();

      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });

        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        _progressController.animateTo((_currentStep + 1) / 3);
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();

      setState(() {
        _currentStep--;
      });

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _progressController.animateTo((_currentStep + 1) / 3);
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _signUp() async {
    if (!_formKeys[_currentStep].currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      // Prepare user data for the AuthService
      final userData = {
        'fullName': _fullNameController.text.trim(),
        'dateOfBirth': _selectedDate?.toIso8601String(),
        'gender': _selectedGender,
        'bloodGroup': _selectedBloodGroup,
        'allergies': _selectedAllergies,
        'pastConditions': _pastConditionsController.text.trim(),
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim(),
      };

      // Use AuthService to register the user with proper data structure
      final UserCredential userCredential =
          await AuthService.registerWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            userType: 'patient',
            userData: userData,
          );

      final User? user = userCredential.user;

      if (user != null && mounted) {
        HapticFeedback.mediumImpact();

        // Navigate to verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(user: user),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();

        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists for this email.';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address.';
            break;
          default:
            errorMessage = e.message ?? 'An error occurred during signup.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            _buildHeader(),

            // Form content
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [_buildStep1(), _buildStep2(), _buildStep3()],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF2E3A59),
                ),
                onPressed:
                    _currentStep > 0
                        ? _previousStep
                        : () => Navigator.pop(context),
              ),
              const Spacer(),
              Text(
                'Create Account',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3A59),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),

          const SizedBox(height: 24),

          // Progress indicator
          Column(
            children: [
              Row(
                children: [
                  _buildProgressDot(0),
                  _buildProgressLine(0),
                  _buildProgressDot(1),
                  _buildProgressLine(1),
                  _buildProgressDot(2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _currentStep >= 0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Personal',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _currentStep >= 1
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Emergency',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _currentStep >= 2
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFE5E7EB),
      ),
      child:
          isActive
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Center(
                child: Text(
                  '${step + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
    );
  }

  Widget _buildProgressLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFE5E7EB),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Let\'s get started',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3A59),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your account to access personalized healthcare',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 32),

            // Full Name
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: Validators.validateFullName,
            ),
            const SizedBox(height: 20),

            // Email
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 20),

            // Password
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF6B7280),
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 20),

            // Confirm Password
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF6B7280),
                ),
                onPressed:
                    () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
              ),
              validator:
                  (value) => Validators.validatePasswordConfirmation(
                    value,
                    _passwordController.text,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3A59),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help us personalize your healthcare experience',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 32),

            // Date of Birth
            _buildDateField(),
            const SizedBox(height: 20),

            // Gender
            _buildDropdownField(
              label: 'Gender',
              value: _selectedGender,
              items: _genders,
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 20),

            // Blood Group
            _buildDropdownField(
              label: 'Blood Group',
              value: _selectedBloodGroup,
              items: _bloodGroups,
              onChanged: (value) => setState(() => _selectedBloodGroup = value),
            ),
            const SizedBox(height: 20),

            // Allergies
            _buildAllergiesSection(),
            const SizedBox(height: 20),

            // Past Conditions
            _buildTextField(
              controller: _pastConditionsController,
              label: 'Past Medical Conditions (Optional)',
              icon: Icons.medical_services_outlined,
              maxLines: 3,
              validator: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contact',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3A59),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide an emergency contact for your safety',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 32),

            // Emergency Contact Name
            _buildTextField(
              controller: _emergencyNameController,
              label: 'Emergency Contact Name',
              icon: Icons.person_outline,
              validator:
                  (value) => Validators.validateRequired(
                    value,
                    'emergency contact name',
                  ),
            ),
            const SizedBox(height: 20),

            // Emergency Contact Phone
            _buildTextField(
              controller: _emergencyPhoneController,
              label: 'Emergency Contact Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: Validators.validatePhoneNumber,
            ),
            const SizedBox(height: 32),

            // Terms and Privacy
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: const Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Your data is secure',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By creating an account, you agree to our Terms of Service and Privacy Policy. Your medical information is encrypted and secure.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(
                const Duration(days: 6570),
              ), // ~18 years
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme.copyWith(primary: const Color(0xFF4CAF50)),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF9FAFB),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select your date of birth',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        _selectedDate != null
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF9CA3AF),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: 'Select $label',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Known Allergies (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF9FAFB),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select any allergies you have:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _commonAllergies.map((allergy) {
                      final isSelected = _selectedAllergies.contains(allergy);
                      return FilterChip(
                        label: Text(allergy),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAllergies.add(allergy);
                            } else {
                              _selectedAllergies.remove(allergy);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF4CAF50),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color:
                              isSelected
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE5E7EB),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : _currentStep == 2
                      ? _signUp
                      : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        _currentStep == 2 ? 'Create Account' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 16),
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text(
                'Previous',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
