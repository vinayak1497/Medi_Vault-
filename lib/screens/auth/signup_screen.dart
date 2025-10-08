import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/screens/main_app/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  bool _isDataValid = false;

  final Map<String, dynamic> _userData = {
    'fullName': '',
    'email': '',
    'password': '',
    'dateOfBirth': null,
    'gender': '',
    'bloodGroup': '',
    'allergies': [],
    'pastConditions': '',
    'emergencyContactName': '',
    'emergencyContactPhone': '',
  };

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _commonAllergies = ['Pollen', 'Dust mites', 'Peanuts', 'Penicillin', 'Lactose'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updatePage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _checkFormValidity() {
    setState(() {
      _isDataValid = _userData['fullName'].isNotEmpty &&
          _userData['email'].isNotEmpty &&
          _userData['password'].isNotEmpty &&
          _userData['emergencyContactName'].isNotEmpty &&
          _userData['emergencyContactPhone'].isNotEmpty;
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signing up...')),
    );

    try {
      // 1. Create user with email and password
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _userData['email'],
        password: _userData['password'],
      );
      
      final User? user = userCredential.user;

      if (user != null) {
        // 2. Send email verification
        await user.sendEmailVerification();

        // 3. Save additional user data to Firebase Realtime Database
        final databaseRef = FirebaseDatabase.instance.ref('users/${user.uid}');
        await databaseRef.set({
          'fullName': _userData['fullName'],
          'email': _userData['email'],
          'dateOfBirth': _userData['dateOfBirth']?.toIso8601String(),
          'gender': _userData['gender'],
          'bloodGroup': _userData['bloodGroup'],
          'allergies': _userData['allergies'],
          'pastConditions': _userData['pastConditions'],
          'emergencyContactName': _userData['emergencyContactName'],
          'emergencyContactPhone': _userData['emergencyContactPhone'],
        });

        if (mounted) {
          // Redirect to the verification screen after successful sign-up
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerificationScreen(user: user)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign up: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text('Create Account ($_currentPage/3)'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swiping
                onPageChanged: _updatePage,
                children: [
                  _buildCoreAccountPage(),
                  _buildBasicHealthPage(),
                  _buildConditionsPage(),
                  _buildFinalPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      },
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_currentPage < 3)
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DADE2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Next'),
                    ),
                  if (_currentPage == 3)
                    ElevatedButton(
                      onPressed: _isDataValid ? _signUp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreAccountPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Your Account',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _buildTextField('Full Name', Icons.person, (value) => _userData['fullName'] = value),
          const SizedBox(height: 16),
          _buildTextField('Email Address', Icons.email, (value) => _userData['email'] = value),
          const SizedBox(height: 16),
          _buildTextField('Password', Icons.lock, (value) => _userData['password'] = value, obscureText: true),
        ],
      ),
    );
  }

  Widget _buildBasicHealthPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tell Us About Yourself',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _buildDatePickerField('Date of Birth', (value) => _userData['dateOfBirth'] = value),
          const SizedBox(height: 16),
          _buildDropdownField('Gender', _genders, (value) => _userData['gender'] = value),
          const SizedBox(height: 16),
          _buildDropdownField('Blood Group', _bloodGroups, (value) => _userData['bloodGroup'] = value),
        ],
      ),
    );
  }

  Widget _buildConditionsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Medical History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _buildAllergiesCheckboxes(),
          const SizedBox(height: 16),
          _buildTextArea('Any past diseases or chronic conditions?', (value) => _userData['pastConditions'] = value),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Almost Done!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _buildTextField('Emergency Contact Name', Icons.person, (value) => _userData['emergencyContactName'] = value),
          const SizedBox(height: 16),
          _buildTextField('Emergency Contact Phone', Icons.phone, (value) => _userData['emergencyContactPhone'] = value),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helper function for text fields
  Widget _buildTextField(String label, IconData icon, Function(String) onChanged, {bool obscureText = false}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5DADE2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        onChanged(value);
        _checkFormValidity();
      },
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  // Helper function for date picker
  Widget _buildDatePickerField(String label, Function(DateTime) onChanged) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF5DADE2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
            },
    );
  }

  // Helper function for dropdowns
  Widget _buildDropdownField(String label, List<String> items, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  // Helper function for allergies checkboxes
  Widget _buildAllergiesCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Known Allergies'),
        ..._commonAllergies.map((allergy) {
          return CheckboxListTile(
            title: Text(allergy),
            value: _userData['allergies'].contains(allergy),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _userData['allergies'].add(allergy);
                } else {
                  _userData['allergies'].remove(allergy);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // Helper function for text area
  Widget _buildTextArea(String label, Function(String) onChanged) {
    return TextFormField(
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

// Verification Screen to guide the user to their email
class VerificationScreen extends StatelessWidget {
  final User user;
  const VerificationScreen({super.key, required this.user});

  // A StreamBuilder is used to listen for real-time changes to the user's
  // authentication state. Once the user's email is verified, this screen
  // will automatically navigate them to the Home screen without any manual
  // interaction from the user.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.emailVerified) {
          // Email is verified, navigate to the Home screen
          return const HomeScreen();
        }
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 100,
                  color: Color(0xFF5DADE2),
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'A verification link has been sent to ${user.email}. Please click the link to activate your account.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Button to check for verification manually
                ElevatedButton(
                  onPressed: () async {
                    await user.reload();
                    if (user.emailVerified) {
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email not yet verified. Please check your inbox.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5DADE2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('I have verified my email'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
