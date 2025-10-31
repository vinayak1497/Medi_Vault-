import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/screens/doctor/post_registration_nmc_prompt_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String userType;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.userType,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  String _message = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    debugPrint('🔍 Checking verification status...');

    final user = AuthService.getCurrentUser();
    if (user != null) {
      // Reload user to get the latest verification status
      await user.reload();
      final updatedUser = AuthService.getCurrentUser();

      debugPrint('📧 User email: ${user.email}');
      debugPrint('✅ Email verified: ${updatedUser?.emailVerified}');

      if (updatedUser?.emailVerified == true) {
        setState(() {
          _message = '🎉 Email verified successfully! Welcome to Health Buddy!';
          _isError = false;
        });

        // Show success message and redirect
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email verified! Welcome to Health Buddy!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Auto redirect to NMC verification prompt after a short delay
          Future.delayed(const Duration(seconds: 2), () async {
            if (mounted) {
              // Get user data from Firebase
              Map<String, dynamic>? doctorData;
              try {
                final user = AuthService.getCurrentUser();
                debugPrint(
                  '🔍 Email Verification - Current user: ${user?.uid}',
                );

                if (user != null) {
                  final DatabaseReference userRef = FirebaseDatabase.instance
                      .ref()
                      .child('doctors') // Updated path to match AuthService
                      .child(user.uid);
                  final snapshot = await userRef.get();
                  debugPrint('📊 Firebase snapshot exists: ${snapshot.exists}');

                  if (snapshot.exists) {
                    doctorData = Map<String, dynamic>.from(
                      snapshot.value as Map,
                    );
                    debugPrint('📋 Fetched doctor data: $doctorData');
                    debugPrint('👤 Name from Firebase: ${doctorData['name']}');
                    debugPrint(
                      '🆔 Doctor ID from Firebase: ${doctorData['doctorId']}',
                    );
                  } else {
                    debugPrint('❌ No doctor data found in Firebase');
                  }
                } else {
                  debugPrint('❌ No current user found');
                }
              } catch (e) {
                debugPrint('❌ Error fetching user data: $e');
              }

              // Navigate to NMC verification prompt with doctor data
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder:
                      (context) => PostRegistrationNMCPromptScreen(
                        doctorData: doctorData,
                      ),
                ),
                (route) => false, // Remove all previous routes
              );
            }
          });
        }
      } else {
        setState(() {
          _message =
              '📧 Please check your email and click the verification link to complete registration.\n\nIf you don\'t see the email, check your spam folder.';
          _isError = false;
        });
      }
    } else {
      debugPrint('❌ No user found');
      setState(() {
        _message = '❌ No user session found. Please try signing up again.';
        _isError = true;
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
      _message = '';
      _isError = false;
    });

    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        // Reload user to get latest status
        await user.reload();
        final updatedUser = AuthService.getCurrentUser();

        if (updatedUser?.emailVerified == true) {
          setState(() {
            _isLoading = false;
            _message = '✅ Your email is already verified! You can proceed.';
            _isError = false;
          });
          return;
        }

        // Send verification email
        await user.sendEmailVerification();
        debugPrint('📧 Verification email resent to: ${user.email}');

        setState(() {
          _isLoading = false;
          _message =
              '📧 Verification email sent again! Please check your inbox and spam folder.';
          _isError = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📧 Verification email sent!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _message = '❌ No user session found. Please try signing up again.';
          _isError = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase error resending email: ${e.code} - ${e.message}');
      setState(() {
        _isLoading = false;
        _message = 'Failed to resend email: ${e.message}';
        _isError = true;
      });
    } catch (e) {
      debugPrint('❌ Error resending email: $e');
      setState(() {
        _isLoading = false;
        _message = 'Failed to resend email. Please try again.';
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We sent a verification link to:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_message.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _isError
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color:
                          _isError
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _resendEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Resend Email'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : _checkVerificationStatus,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Check Verification Status'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Login'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Note: Check your spam folder if you don\'t see the email.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
