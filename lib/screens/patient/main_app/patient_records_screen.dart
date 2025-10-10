import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _medicalRecords = [];
  List<Map<String, dynamic>> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load medical records
        final recordsSnapshot =
            await FirebaseDatabase.instance
                .ref('patient_profiles/${user.uid}/medicalRecords')
                .get();

        if (recordsSnapshot.exists) {
          final recordsData = Map<String, dynamic>.from(
            recordsSnapshot.value as Map,
          );
          setState(() {
            _medicalRecords =
                recordsData.entries
                    .map((e) => Map<String, dynamic>.from(e.value as Map))
                    .toList()
                  ..sort(
                    (a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''),
                  );
          });
        }

        // Load prescriptions
        final prescriptionsSnapshot =
            await FirebaseDatabase.instance
                .ref('patient_profiles/${user.uid}/prescriptions')
                .get();

        if (prescriptionsSnapshot.exists) {
          final prescriptionsData = Map<String, dynamic>.from(
            prescriptionsSnapshot.value as Map,
          );
          setState(() {
            _prescriptions =
                prescriptionsData.entries
                    .map((e) => Map<String, dynamic>.from(e.value as Map))
                    .toList()
                  ..sort(
                    (a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''),
                  );
          });
        }
      }
    } catch (e) {
      print('Error loading records: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Medical Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4CAF50),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF4CAF50),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Timeline'),
                Tab(text: 'Prescriptions'),
                Tab(text: 'Documents'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimelineTab(),
          _buildPrescriptionsTab(),
          _buildDocumentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordDialog,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Record',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_medicalRecords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.timeline,
        title: 'No Medical Records',
        subtitle: 'Your visit history will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicalRecords.length,
        itemBuilder: (context, index) {
          final record = _medicalRecords[index];
          final isLast = index == _medicalRecords.length - 1;

          return _buildTimelineItem(record, isLast);
        },
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> record, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Record content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        record['title'] ?? 'Medical Visit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        record['date'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (record['doctor'] != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Dr. ${record['doctor']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (record['diagnosis'] != null) ...[
                    Text(
                      record['diagnosis'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _viewRecord(record),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _shareRecord(record),
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Share'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prescriptions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medical_services_outlined,
        title: 'No Prescriptions',
        subtitle: 'Your prescribed medications will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = _prescriptions[index];
          return _buildPrescriptionCard(prescription);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  prescription['medicationName'] ?? 'Medication',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  prescription['status'] ?? 'Active',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            prescription['dosage'] ?? 'No dosage specified',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                prescription['frequency'] ?? 'As needed',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Dr. ${prescription['prescribedBy'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _setMedicationReminder(prescription),
                  icon: const Icon(Icons.notifications_outlined, size: 16),
                  label: const Text('Set Reminder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                    foregroundColor: const Color(0xFF4CAF50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _sharePrescription(prescription),
                icon: const Icon(Icons.share_outlined),
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDocumentCategory('Lab Reports', Icons.science_outlined, [
            'Blood Test - Oct 2025',
            'X-Ray - Sep 2025',
          ]),
          const SizedBox(height: 16),
          _buildDocumentCategory('Prescriptions', Icons.receipt_long_outlined, [
            'Prescription - Oct 2025',
            'Prescription - Sep 2025',
          ]),
          const SizedBox(height: 16),
          _buildDocumentCategory('Insurance', Icons.security_outlined, [
            'Insurance Card',
            'Claims History',
          ]),
        ],
      ),
    );
  }

  Widget _buildDocumentCategory(
    String title,
    IconData icon,
    List<String> documents,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all documents in category
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _downloadDocument(doc),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Medical Record'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Choose how you want to add a medical record:')],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Open camera for document scan
                },
                child: const Text('Scan Document'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Manual entry form
                },
                child: const Text('Manual Entry'),
              ),
            ],
          ),
    );
  }

  void _viewRecord(Map<String, dynamic> record) {
    // TODO: Implement record viewing
  }

  void _shareRecord(Map<String, dynamic> record) {
    // TODO: Implement record sharing
  }

  void _setMedicationReminder(Map<String, dynamic> prescription) {
    // TODO: Implement medication reminder
  }

  void _sharePrescription(Map<String, dynamic> prescription) {
    // TODO: Implement prescription sharing
  }

  void _downloadDocument(String document) {
    // TODO: Implement document download
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
