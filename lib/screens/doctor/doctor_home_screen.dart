import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/screens/doctor/nmc_verification_screen.dart';
import 'package:health_buddy/screens/doctor/minimal_image_to_text_screen.dart';
import 'package:health_buddy/screens/doctor/voice_recording_session_screen.dart';
import 'package:health_buddy/screens/doctor/doctor_appointments_screen.dart';
import 'package:health_buddy/widgets/verification_badge.dart';
import 'package:health_buddy/services/verification_cache_service.dart';
import 'package:health_buddy/services/appointment_service.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final VerificationCacheService _cacheService = VerificationCacheService();
  int _pendingAppointmentsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingAppointments();
  }

  /// Load count of pending appointments
  Future<void> _loadPendingAppointments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final pending = await AppointmentService.getDoctorPendingAppointments(
          user.uid,
        );
        setState(() {
          _pendingAppointmentsCount = pending.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending appointments: $e');
    }
  }

  /// Navigate to voice recording session
  void _navigateToVoiceRecording() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceRecordingSessionScreen(),
      ),
    );
  }

  /// Navigate to minimal image-to-text screen
  void _navigateToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MinimalImageToTextScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: const VerificationBadge()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome, Doctor!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a new session or scan a prescription',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Verification Status Card
            FutureBuilder<bool>(
              future: Future.value(_cacheService.getVerificationStatus()),
              builder: (context, snapshot) {
                final isVerified = snapshot.data ?? false;
                return Card(
                  elevation: 2,
                  color: isVerified ? Colors.green[50] : Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          isVerified ? Icons.verified : Icons.warning,
                          color:
                              isVerified
                                  ? Colors.green[600]
                                  : Colors.orange[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVerified
                                    ? 'NMC Verified'
                                    : 'NMC Verification Pending',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isVerified
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                ),
                              ),
                              Text(
                                isVerified
                                    ? 'Your medical credentials have been verified'
                                    : 'Complete NMC verification to unlock all features',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isVerified)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const NMCVerificationScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Verify Now'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Start Recording Session button
            ElevatedButton.icon(
              onPressed: _navigateToVoiceRecording,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.mic),
              label: const Text(
                'Start Recording Session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // OR divider
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),

            // Scan Prescription button
            OutlinedButton.icon(
              onPressed: _navigateToScanner,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.document_scanner),
              label: const Text(
                'Scan Prescription',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Appointment Requests Section
            _buildAppointmentRequestsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build appointment requests section
  Widget _buildAppointmentRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Appointment Requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_pendingAppointmentsCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pendingAppointmentsCount.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorAppointmentsScreen(),
              ),
            ).then((_) {
              // Refresh pending count when returning
              _loadPendingAppointments();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  _pendingAppointmentsCount > 0
                      ? const Color(0xFFFFC107).withValues(alpha: 0.1 * 255)
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _pendingAppointmentsCount > 0
                        ? const Color(0xFFFFC107)
                        : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        _pendingAppointmentsCount > 0
                            ? const Color(0xFFFFC107)
                            : Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: _pendingAppointmentsCount > 0 ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pendingAppointmentsCount > 0
                            ? 'You have $_pendingAppointmentsCount new request${_pendingAppointmentsCount > 1 ? 's' : ''}'
                            : 'No pending requests',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              _pendingAppointmentsCount > 0
                                  ? const Color(0xFFFFC107)
                                  : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to manage appointments',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
