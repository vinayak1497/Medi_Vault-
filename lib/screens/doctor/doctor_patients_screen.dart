import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/screens/common/auth/signup_screen.dart';
import 'package:health_buddy/screens/doctor/doctor_dashboard.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // In a real implementation, you would fetch patients associated with this doctor
        // For now, we'll create some sample data
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        
        setState(() {
          _patients = [
            {
              'name': 'Rajesh Kumar',
              'visitDate': '2023-10-15',
              'recordId': 'rec_001',
            },
            {
              'name': 'Priya Sharma',
              'visitDate': '2023-10-18',
              'recordId': 'rec_002',
            },
            {
              'name': 'Amit Patel',
              'visitDate': '2023-10-20',
              'recordId': 'rec_003',
            },
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load patients: $e';
        _isLoading = false;
      });
    }
  }

  void _registerNewPatient() async {
    // Navigate to patient signup screen with return route to doctor dashboard
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientSignupScreen(
          returnToDoctorDashboard: true,
        ),
      ),
    );
    
    // If patient was successfully registered, refresh the patient list
    if (result == true) {
      _fetchPatients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Patient registered successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  void _viewPatientRecord(Map<String, dynamic> patient) {
    // In a real implementation, you would show the patient's medical records
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Record for ${patient['name']}'),
          content: const Text('This would show the patient\'s medical records in a real implementation.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
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
        title: const Text('Patients'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Patient Records',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_patients.length} patients',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Register New Patient button
            ElevatedButton.icon(
              onPressed: _registerNewPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // Green theme
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text(
                'Register New Patient',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Patients list or loading/error state
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchPatients,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : _patients.isEmpty
                          ? const Center(
                              child: Text(
                                'No patients found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _patients.length,
                              itemBuilder: (context, index) {
                                final patient = _patients[index];
                                return _buildPatientCard(patient);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  patient['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  patient['visitDate'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _viewPatientRecord(patient),
                child: const Text('View Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}