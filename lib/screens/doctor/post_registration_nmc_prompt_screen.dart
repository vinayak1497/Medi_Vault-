import 'package:flutter/material.dart';
import 'package:health_buddy/screens/doctor/doctor_dashboard.dart';
import 'package:health_buddy/screens/doctor/nmc_verification_screen.dart';

class PostRegistrationNMCPromptScreen extends StatelessWidget {
  final Map<String, dynamic>? doctorData;

  const PostRegistrationNMCPromptScreen({super.key, this.doctorData});

  // Green theme colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color paleGreen = Color(0xFFE8F5E8);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                paleGreen.withValues(alpha: 0.3 * 255),
                Colors.white,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Success illustration
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.3 * 255),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome message
                const Text(
                  '🎉 Welcome to Health Buddy!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Your account has been successfully created and verified.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // NMC Verification prompt card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1 * 255),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lightGreen.withValues(alpha: 0.1 * 255),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.security,
                          size: 32,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Verify your medical credentials through the National Medical Commission (NMC) to gain patient trust and unlock premium features.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Benefits list
                      _buildBenefitItem(
                        icon: Icons.verified,
                        text: 'Get verified doctor badge',
                        color: primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        icon: Icons.people,
                        text: 'Build patient trust',
                        color: primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        icon: Icons.star,
                        text: 'Access premium features',
                        color: primaryGreen,
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Action buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Verify Now button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGreen, lightGreen],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.3 * 255),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => NMCVerificationScreen(
                                    doctorData: doctorData,
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Verify My Credentials',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skip for now button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorDashboard(),
                          ),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Skip for Now',
                        style: TextStyle(
                          fontSize: 16,
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note
                    Text(
                      'You can verify your credentials later from your profile',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1 * 255),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
