import 'package:flutter/material.dart';
import 'dart:async';
import 'package:medivault_ai/screens/common/auth/user_type_screen.dart';
import 'package:medivault_ai/screens/doctor/doctor_dashboard.dart';
import 'package:medivault_ai/screens/patient/main_app/patient_main_screen.dart';
import 'package:medivault_ai/services/auth_service.dart';
import 'package:medivault_ai/services/verification_cache_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationState();
  }

  Future<void> _checkAuthenticationState() async {
    // Wait for 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Get current user first
      final currentUser = AuthService.getCurrentUser();
      debugPrint('👤 Current Firebase user: ${currentUser?.uid ?? 'null'}');
      debugPrint('📧 Current user email: ${currentUser?.email ?? 'null'}');
      debugPrint('✅ Email verified: ${currentUser?.emailVerified ?? false}');

      // Check if user is logged in
      final isLoggedIn = await AuthService.isUserLoggedInAndVerified();
      debugPrint('🔐 User logged in and verified: $isLoggedIn');

      if (isLoggedIn && currentUser != null) {
        // Get user type to determine which dashboard to show
        final userType = await AuthService.getCurrentUserType();
        debugPrint('👤 User type detected: $userType');

        // Additional validation - check if user profile actually exists
        final userProfile = await AuthService.getCurrentUserProfile();
        debugPrint('📋 User profile exists: ${userProfile != null}');
        debugPrint('📋 Profile data: ${userProfile?.toString() ?? 'null'}');

        if (userType == 'doctor' && userProfile != null) {
          // Initialize verification cache for doctor dashboard
          debugPrint('🔐 Initializing verification cache...');
          await VerificationCacheService().initializeCache();
          debugPrint('✅ Verification cache initialized');

          // Navigate to doctor dashboard
          debugPrint('🏥 Navigating to Doctor Dashboard');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DoctorDashboard()),
            );
          }
        } else if (userProfile != null) {
          // For ANY user with a profile (patient or unclear type) -> NEW PatientMainScreen
          debugPrint(
            '👨‍⚕️ USER HAS PROFILE - Navigating to NEW Patient Dashboard (PatientMainScreen)',
          );
          debugPrint('🔥 FORCING NEW PATIENT UI FOR ALL NON-DOCTOR USERS!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PatientMainScreen()),
          );
        } else {
          // User type is null or profile doesn't exist, go to user type selection
          debugPrint(
            '❓ Invalid user type or missing profile, going to user type selection',
          );
          // Sign out the invalid user
          await AuthService.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserTypeScreen()),
          );
        }
      } else {
        // User not logged in or not verified, go to user type selection
        debugPrint(
          '🚪 User not logged in or not verified, going to user type selection',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserTypeScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking authentication state: $e');
      // On error, go to user type selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserTypeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/app_logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            // App name
            const Text(
              'Health Buddy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              'Your Health, Our Priority',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 40),
            // Temporary debug logout button
            TextButton(
              onPressed: () async {
                await AuthService.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserTypeScreen(),
                  ),
                );
              },
              child: const Text(
                'Reset Login (Debug)',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
