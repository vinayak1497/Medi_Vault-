import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/screens/doctor/doctor_login_screen.dart';
import 'package:health_buddy/screens/doctor/doctor_dashboard.dart';

class DoctorVerificationScreen extends StatefulWidget {
  final String? email;

  const DoctorVerificationScreen({super.key, this.email});

  @override
  State<DoctorVerificationScreen> createState() =>
      _DoctorVerificationScreenState();
}

class _DoctorVerificationScreenState extends State<DoctorVerificationScreen> {
  bool _isVerifying = false;
  String _verificationMessage =
      'Please check your email for the verification link.';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Check if the app was opened from an email link
    _checkForEmailLink();
  }

  Future<void> _checkForEmailLink() async {
    try {
      if (FirebaseAuth.instance.isSignInWithEmailLink(Uri.base.toString())) {
        setState(() {
          _isVerifying = true;
          _verificationMessage = 'Verifying your email...';
        });

        // Complete sign in
        final email = widget.email ?? await _retrieveEmail();
        if (email != null) {
          final userCredential = await FirebaseAuth.instance
              .signInWithEmailLink(
                email: email,
                emailLink: Uri.base.toString(),
              );

          if (userCredential.user != null) {
            setState(() {
              _isVerifying = false;
              _verificationMessage = 'Email verified successfully!';
            });

            // Navigate to doctor dashboard after a short delay
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorDashboard(),
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Verification failed: $e';
      });
    }
  }

  Future<String?> _retrieveEmail() async {
    // In a real app, you might want to store this in secure storage
    // For now, we'll just return the email passed from the previous screen
    return widget.email;
  }

  Future<void> _resendVerification() async {
    if (widget.email == null) return;

    setState(() {
      _isVerifying = true;
      _verificationMessage = 'Resending verification link...';
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: widget.email!,
        actionCodeSettings: ActionCodeSettings(
          // Use the default Firebase auth domain
          url: 'https://health-buddy-44a4a.firebaseapp.com',
          handleCodeInApp: true,
        ),
      );

      setState(() {
        _isVerifying = false;
        _verificationMessage =
            'Verification link resent! Please check your email.';
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Failed to resend verification: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.email, size: 80, color: Colors.blue),
              const SizedBox(height: 30),
              const Text(
                'Check Your Email',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _verificationMessage,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Email display
              if (widget.email != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.email!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Error message
              if (_errorMessage.isNotEmpty) ...[
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Loading indicator
              if (_isVerifying) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
              ],

              // Resend button
              ElevatedButton(
                onPressed: _isVerifying ? null : _resendVerification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Resend Verification Link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // Back to login
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorLoginScreen(),
                    ),
                  );
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
