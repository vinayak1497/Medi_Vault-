import 'package:flutter/material.dart';
import 'package:health_buddy/services/nmc_verification_service.dart';
import 'package:health_buddy/models/nmc_verification.dart';

/// Example screen showing how to use the NMC Verification Service
/// This demonstrates the basic usage patterns for integrating the service
class NMCVerificationExampleScreen extends StatefulWidget {
  const NMCVerificationExampleScreen({super.key});

  @override
  State<NMCVerificationExampleScreen> createState() =>
      _NMCVerificationExampleScreenState();
}

class _NMCVerificationExampleScreenState
    extends State<NMCVerificationExampleScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Ready to verify doctor credentials';

  /// Example 1: Simple verification with required fields only
  Future<void> _simpleVerificationExample() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running simple verification example...';
    });

    try {
      // Example: Verify a doctor with minimum required information
      final result = await NMCVerificationService.verifyDoctor(
        fullName: 'Dr. Rajesh Kumar',
        registrationNumber: 'MH12345',
        state: 'Maharashtra',
      );

      setState(() {
        _statusMessage =
            result.isVerified
                ? '✅ Simple verification successful!'
                : '❌ Simple verification failed: ${result.message}';
      });

      _showResultDialog(result, 'Simple Verification Result');
    } catch (e) {
      setState(() {
        _statusMessage = '💥 Error in simple verification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Example 2: Detailed verification with all optional fields
  Future<void> _detailedVerificationExample() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running detailed verification example...';
    });

    try {
      // Example: Verify a doctor with all available information
      final result = await NMCVerificationService.verifyDoctor(
        fullName: 'Dr. Priya Sharma',
        registrationNumber: 'KA67890',
        state: 'Karnataka',
        fatherName: 'Mr. Suresh Sharma',
        specialization: 'Cardiology',
        yearOfRegistration: '2018',
      );

      setState(() {
        _statusMessage =
            result.isVerified
                ? '✅ Detailed verification successful!'
                : '❌ Detailed verification failed: ${result.message}';
      });

      _showResultDialog(result, 'Detailed Verification Result');
    } catch (e) {
      setState(() {
        _statusMessage = '💥 Error in detailed verification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Example 3: Input validation example
  Future<void> _inputValidationExample() async {
    setState(() {
      _statusMessage = 'Testing input validation...';
    });

    // Example: Test validation with invalid input
    final validationError = NMCVerificationService.validateInput(
      fullName: 'A', // Too short
      registrationNumber: 'XX', // Too short
      state: 'Invalid State', // Not in the list
    );

    setState(() {
      _statusMessage =
          validationError != null
              ? '🔍 Validation caught error: $validationError'
              : '✅ Validation passed';
    });

    // Show validation result
    _showSimpleDialog(
      'Input Validation Example',
      validationError ?? 'All inputs are valid!',
    );
  }

  /// Example 4: Service availability check
  Future<void> _serviceAvailabilityExample() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking service availability...';
    });

    try {
      final isAvailable = await NMCVerificationService.isServiceAvailable();

      setState(() {
        _statusMessage =
            isAvailable
                ? '🟢 NMC Verification service is available'
                : '🔴 NMC Verification service is not available';
      });

      _showSimpleDialog(
        'Service Availability Check',
        isAvailable
            ? 'The NMC Verification service is currently available and ready to use.'
            : 'The NMC Verification service is currently unavailable. Please try again later.',
      );
    } catch (e) {
      setState(() {
        _statusMessage = '💥 Error checking service availability: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Show verification result in a dialog
  void _showResultDialog(NMCVerificationResult result, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status
                Row(
                  children: [
                    Icon(
                      result.isVerified ? Icons.check_circle : Icons.error,
                      color: result.isVerified ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: result.isVerified ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Message
                Text('Message: ${result.message}'),

                // Doctor details if available
                if (result.doctorDetails != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Doctor Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...{
                        'Name': result.doctorDetails!.fullName,
                        'Registration No.':
                            result.doctorDetails!.registrationNumber,
                        'State': result.doctorDetails!.state,
                        'Medical Council':
                            result.doctorDetails!.stateMedicalCouncil,
                        'Registration Date':
                            result.doctorDetails!.registrationDate,
                        'Qualification': result.doctorDetails!.qualification,
                        'Father\'s Name': result.doctorDetails!.fatherName,
                        'Address': result.doctorDetails!.address,
                        'Status':
                            result.doctorDetails!.isActive != null
                                ? (result.doctorDetails!.isActive!
                                    ? 'Active'
                                    : 'Inactive')
                                : null,
                      }.entries
                      .where(
                        (entry) =>
                            entry.value != null && entry.value!.isNotEmpty,
                      )
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text('${entry.key}: ${entry.value}'),
                        ),
                      ),
                ],

                // Error code if available
                if (result.errorCode != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error Code: ${result.errorCode}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show simple dialog with message
  void _showSimpleDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NMC Verification Examples'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.code,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'NMC Verification Service Examples',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap any example below to see how the NMC verification service works',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  if (_isLoading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(_statusMessage)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Example 1: Simple Verification
            _buildExampleCard(
              title: '1. Simple Verification',
              description:
                  'Verify with only required fields (name, registration number, state)',
              icon: Icons.verified_user,
              onTap: _isLoading ? null : _simpleVerificationExample,
            ),
            const SizedBox(height: 12),

            // Example 2: Detailed Verification
            _buildExampleCard(
              title: '2. Detailed Verification',
              description:
                  'Verify with all optional fields included for better accuracy',
              icon: Icons.assignment,
              onTap: _isLoading ? null : _detailedVerificationExample,
            ),
            const SizedBox(height: 12),

            // Example 3: Input Validation
            _buildExampleCard(
              title: '3. Input Validation',
              description: 'Test input validation with invalid data',
              icon: Icons.rule,
              onTap: _inputValidationExample,
            ),
            const SizedBox(height: 12),

            // Example 4: Service Check
            _buildExampleCard(
              title: '4. Service Availability',
              description: 'Check if the NMC verification service is available',
              icon: Icons.wifi_protected_setup,
              onTap: _isLoading ? null : _serviceAvailabilityExample,
            ),
            const SizedBox(height: 20),

            // Code Example
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code Example:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('''// Basic usage in your Flutter app:
final result = await NMCVerificationService.verifyDoctor(
  fullName: 'Dr. John Doe',
  registrationNumber: 'MH12345',
  state: 'Maharashtra',
);

if (result.isVerified) {
  print('Doctor is verified!');
  print('Name: \${result.doctorDetails?.fullName}');
} else {
  print('Verification failed: \${result.message}');
}''', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color:
                    onTap != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onTap != null ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: onTap != null ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_arrow,
                color:
                    onTap != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
