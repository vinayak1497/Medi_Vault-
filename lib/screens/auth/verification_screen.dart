import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/screens/main_app/home_screen.dart';

class VerificationScreen extends StatelessWidget {
  final User user;
  const VerificationScreen({super.key, required this.user});

  // This widget listens for real-time authentication changes.
  // It automatically navigates the user to the Home screen once their email is verified.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.emailVerified) {
          // If the user's email is verified, this will return the HomeScreen.
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
                // This button allows the user to manually check for verification.
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
