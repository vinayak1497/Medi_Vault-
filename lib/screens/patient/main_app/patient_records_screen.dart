import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:medivault_ai/services/auth_service.dart';
import 'package:medivault_ai/services/database_service.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _prescriptions = [];
  List<String> _patientNames = [];

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  /// Load patient names (main + family members) and fetch matching prescriptions
  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('👤 Loading prescriptions for user UID: ${user.uid}');

        // Get main patient profile name
        final profile = await AuthService.getCurrentUserProfile();
        final mainPatientName = profile?['fullName'] ?? '';

        debugPrint('📋 Profile data: $profile');
        debugPrint('👤 Main patient name: $mainPatientName');

        if (mainPatientName.isNotEmpty) {
          _patientNames.add(mainPatientName);
        }

        // Get family members' names
        final familyMembers = await DatabaseService.getFamilyMembers();
        debugPrint('👨‍👩‍👧‍👦 Family members count: ${familyMembers.length}');

        for (final member in familyMembers) {
          final name = member['name']?.toString().trim() ?? '';
          debugPrint('  └─ Family member: $name');
          if (name.isNotEmpty && !_patientNames.contains(name)) {
            _patientNames.add(name);
          }
        }

        debugPrint('🔍 Final patient names to search: $_patientNames');

        // Fetch all prescriptions from Firebase
        await _fetchPrescriptionsForPatients();
      }
    } catch (e) {
      debugPrint('❌ Error loading patient info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patient data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Fetch prescriptions from Firebase and filter by patient names
  Future<void> _fetchPrescriptionsForPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      debugPrint('🔍 Current user UID: ${user.uid}');
      debugPrint('🔍 Patient names to match: $_patientNames');

      // Try primary path first: patient_profiles/{uid}/prescriptions
      final prescriptionsSnapshot1 =
          await FirebaseDatabase.instance
              .ref('patient_profiles/${user.uid}/prescriptions')
              .get();

      final allPrescriptions = <Map<String, dynamic>>[];

      if (prescriptionsSnapshot1.exists) {
        debugPrint(
          '✅ Found prescriptions in patient_profiles/${user.uid}/prescriptions',
        );
        final data = Map<String, dynamic>.from(
          prescriptionsSnapshot1.value as Map,
        );

        data.forEach((key, value) {
          final rx = Map<String, dynamic>.from(value as Map);
          rx['id'] = key; // Store prescription ID for reference

          // Check if prescription patientName matches any in our list
          final rxPatientName = (rx['patientName'] ?? '').toString().trim();
          if (_patientNames.any(
            (name) => name.toLowerCase() == rxPatientName.toLowerCase(),
          )) {
            allPrescriptions.add(rx);
          }
        });
      } else {
        debugPrint(
          'ℹ️ No prescriptions found in patient_profiles/${user.uid}/prescriptions',
        );
      }

      // Fallback: check root prescriptions node
      if (allPrescriptions.isEmpty) {
        debugPrint('🔍 Checking root prescriptions node...');
        final prescriptionsSnapshot2 =
            await FirebaseDatabase.instance.ref('prescriptions').get();

        if (prescriptionsSnapshot2.exists) {
          debugPrint('✅ Found prescriptions in root prescriptions node');
          final data = Map<String, dynamic>.from(
            prescriptionsSnapshot2.value as Map,
          );

          data.forEach((key, value) {
            final rx = Map<String, dynamic>.from(value as Map);
            rx['id'] = key; // Store prescription ID for reference

            // Check if prescription patientName matches any in our list
            final rxPatientName = (rx['patientName'] ?? '').toString().trim();
            debugPrint(
              '📋 Checking prescription: patientName=$rxPatientName against $_patientNames',
            );

            if (_patientNames.any(
              (name) => name.toLowerCase() == rxPatientName.toLowerCase(),
            )) {
              debugPrint('✅ MATCHED! Adding prescription for $rxPatientName');
              allPrescriptions.add(rx);
            }
          });
        } else {
          debugPrint('❌ No prescriptions found in root prescriptions node');
        }
      }

      // Sort by date (newest first)
      allPrescriptions.sort((a, b) {
        final dateA = _parseDate(a['createdAt']);
        final dateB = _parseDate(b['createdAt']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _prescriptions = allPrescriptions;
      });

      debugPrint(
        '✅ Loaded ${_prescriptions.length} prescriptions for ${_patientNames.length} patients',
      );
    } catch (e) {
      debugPrint('❌ Error fetching prescriptions: $e');
      throw Exception('Failed to load prescriptions: $e');
    }
  }

  /// Parse date from various formats
  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is int) return DateTime.fromMillisecondsSinceEpoch(dateValue);
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Prescriptions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildPrescriptionsTab(),
    );
  }

  /// Build prescriptions tab with list
  Widget _buildPrescriptionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prescriptions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medical_services_outlined,
        title: 'No Prescriptions',
        subtitle:
            'Your prescriptions will appear here once a doctor creates one for you',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrescriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = _prescriptions[index];
          return _buildPrescriptionListCard(prescription);
        },
      ),
    );
  }

  /// Build professional prescription list card
  Widget _buildPrescriptionListCard(Map<String, dynamic> prescription) {
    final patientName = prescription['patientName'] ?? 'Unknown';
    final doctorName = prescription['doctorName'] ?? 'Dr. Unknown';
    final createdAt = _parseDate(prescription['createdAt']);
    final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    return GestureDetector(
      onTap: () => _showPrescriptionDetail(prescription),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1 * 255),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.05 * 255),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with doctor and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rx: Prescription',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dr. $doctorName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF4CAF50,
                      ).withValues(alpha: 0.1 * 255),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Patient name
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'For: $patientName',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Extracted text preview
              if (prescription['extractedText'] != null &&
                  prescription['extractedText'].toString().isNotEmpty) ...[
                Text(
                  'Preview:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Text(
                    (prescription['extractedText'] as String)
                            .substring(
                              0,
                              (prescription['extractedText'] as String).length >
                                      100
                                  ? 100
                                  : (prescription['extractedText'] as String)
                                      .length,
                            )
                            .replaceAll('\n', ' ') +
                        '...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // View Details button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPrescriptionDetail(prescription),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _sharePrescription(prescription),
                    icon: const Icon(Icons.share_outlined),
                    color: Colors.blue,
                    tooltip: 'Share',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show professional prescription detail modal
  void _showPrescriptionDetail(Map<String, dynamic> prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: _buildPrescriptionDetailView(prescription, controller),
                ),
          ),
    );
  }

  /// Build professional medical report-style prescription detail
  Widget _buildPrescriptionDetailView(
    Map<String, dynamic> prescription,
    ScrollController controller,
  ) {
    final doctorName =
        prescription['doctorName'] ?? prescription['prescribedBy'] ?? 'Unknown';
    final patientName = prescription['patientName'] ?? 'Unknown';
    final createdAt = _parseDate(prescription['createdAt']);
    final dateStr =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    final extractedText = prescription['extractedText'] ?? '';

    return SingleChildScrollView(
      controller: controller,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Professional header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.05 * 255),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2 * 255),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRESCRIPTION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. $doctorName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Medical Professional',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date of Prescription',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Patient section
            _buildDetailSection(
              label: 'PATIENT INFORMATION',
              children: [
                _buildDetailRow(
                  icon: Icons.person,
                  label: 'Name',
                  value: patientName,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Prescription details section
            _buildDetailSection(
              label: 'PRESCRIPTION DETAILS',
              children: [
                if (prescription['status'] != null)
                  _buildDetailRow(
                    icon: Icons.check_circle,
                    label: 'Status',
                    value: prescription['status'],
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Extracted prescription text (main content)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEDICATIONS & INSTRUCTIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    extractedText.isEmpty
                        ? 'No prescription text available'
                        : extractedText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sharePrescription(prescription),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: Color(0xFF4CAF50),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prescription saved'),
                          backgroundColor: Color(0xFF4CAF50),
                        ),
                      );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build detail section header
  Widget _buildDetailSection({
    required String label,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// Build detail row with icon
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build empty state widget
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

  /// Share prescription via available methods
  void _sharePrescription(Map<String, dynamic> prescription) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
