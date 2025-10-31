import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/screens/common/auth/splash_screen.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'dart:async';

class VerificationScreen extends StatefulWidget {
  final User user;
  // When true, pop back to previous screen with the verified user's profile map as result
  final bool popOnVerified;
  const VerificationScreen({
    super.key,
    required this.user,
    this.popOnVerified = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _checkTimer;
  bool _isChecking = false;
  bool _canResend = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();

    // Start periodic check for email verification
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _checkTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    try {
      await widget.user.reload();
      if (widget.user.emailVerified && mounted) {
        _checkTimer?.cancel();
        HapticFeedback.mediumImpact();

        // Add a success feedback before navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Email verified successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate after a brief delay to show the success message
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          if (widget.popOnVerified) {
            // Fetch the latest user profile to return upwards
            final profile = await AuthService.getCurrentUserProfile();
            if (mounted) {
              Navigator.pop(context, profile);
            }
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SplashScreen()),
            );
          }
        }
      }
    } catch (e) {
      // Handle any errors silently during periodic checks
    }
  }

  Future<void> _manualCheck() async {
    setState(() {
      _isChecking = true;
    });

    HapticFeedback.lightImpact();

    try {
      await widget.user.reload();
      if (widget.user.emailVerified) {
        if (mounted) {
          _checkTimer?.cancel();
          HapticFeedback.mediumImpact();
          if (widget.popOnVerified) {
            final profile = await AuthService.getCurrentUserProfile();
            if (mounted) {
              Navigator.pop(context, profile);
            }
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SplashScreen()),
            );
          }
        }
      } else {
        if (mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Email not yet verified. Please check your inbox.',
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Error checking verification status.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });

    HapticFeedback.lightImpact();

    try {
      await widget.user.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.email, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Verification email sent successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Start cooldown timer
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCooldown > 0) {
          setState(() {
            _resendCooldown--;
          });
        } else {
          setState(() {
            _canResend = true;
          });
          timer.cancel();
        }
      });
    } catch (e) {
      setState(() {
        _canResend = true;
        _resendCooldown = 0;
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Failed to send verification email.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // This widget listens for real-time authentication changes and provides a modern UI.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.emailVerified) {
          // Auto-navigation will be handled by the periodic check
          return const SplashScreen();
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // Animated Email Icon
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.1 * 255),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withValues(alpha: 0.3 * 255),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mark_email_unread_outlined,
                                  size: 60,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E3A59),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        const Text(
                          'We\'ve sent a verification link to',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Email address
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.1 * 255),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFF4CAF50,
                              ).withValues(alpha: 0.3 * 255),
                            ),
                          ),
                          child: Text(
                            widget.user.email ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E3A59),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Instructions
                        const Text(
                          'Please check your email and click the verification link to activate your account.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Manual Check Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isChecking ? null : _manualCheck,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isChecking
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'I\'ve Verified My Email',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Resend Email Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.help_outline,
                                    color: Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Didn\'t receive the email?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Check your spam folder or request a new verification email.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed:
                                      _canResend
                                          ? _resendVerificationEmail
                                          : null,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color:
                                            _canResend
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _canResend
                                        ? 'Resend Verification Email'
                                        : 'Resend in ${_resendCooldown}s',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _canResend
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Auto-check indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Automatically checking verification status...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Back to Login
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
