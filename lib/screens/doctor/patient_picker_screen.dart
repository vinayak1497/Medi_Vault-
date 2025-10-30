import 'package:flutter/material.dart';
import 'package:health_buddy/models/patient.dart';
import 'package:health_buddy/services/patient_service.dart';

class PatientPickerScreen extends StatefulWidget {
  const PatientPickerScreen({super.key});

  @override
  State<PatientPickerScreen> createState() => _PatientPickerScreenState();
}

class _PatientPickerScreenState extends State<PatientPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients([String query = '']) async {
    // Show all registered patients so doctors can select existing users
    setState(() => _loading = true);
    final results = await PatientService.searchAllPatients(query);
    setState(() {
      _patients = results;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    _loadPatients(_searchController.text.trim());
  }

  void _select(Patient patient) {
    Navigator.pop(context, patient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Patient'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name... ',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _patients.isEmpty
                    ? const Center(child: Text('No patients found'))
                    : ListView.separated(
                      itemCount: _patients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = _patients[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF4CAF50),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            [
                              if (p.age != null) '${p.age} yrs',
                              if (p.gender != null) p.gender!,
                              if (p.phoneNumber != null) p.phoneNumber!,
                            ].join(' • '),
                          ),
                          onTap: () => _select(p),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
