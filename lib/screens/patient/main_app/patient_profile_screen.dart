import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/screens/common/auth/user_type_screen.dart';
import 'package:health_buddy/utils/validators.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);

    try {
      final profile = await AuthService.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _patientData = profile;
        });

        await _loadFamilyMembers();
      }
    } catch (e) {
      print('Error loading patient data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot =
            await FirebaseDatabase.instance
                .ref('patient_profiles/${user.uid}/familyMembers')
                .get();

        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _familyMembers =
                data.entries
                    .map(
                      (e) =>
                          Map<String, dynamic>.from(e.value as Map)
                            ..['id'] = e.key,
                    )
                    .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading family members: $e');
    }
  }

  Future<void> _addFamilyMember(Map<String, dynamic> memberData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newMemberRef =
            FirebaseDatabase.instance
                .ref('patient_profiles/${user.uid}/familyMembers')
                .push();

        await newMemberRef.set({
          ...memberData,
          'addedDate': DateTime.now().toIso8601String(),
        });

        await _loadFamilyMembers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Family member added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding family member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profile & Family',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSettingsBottomSheet,
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xFF666666),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatientData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Patient Profile
              _buildMainPatientProfile(),

              const SizedBox(height: 24),

              // Family Members Section
              _buildFamilyMembersSection(),

              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainPatientProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and name
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientData?['fullName'] ?? 'Patient Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Main Account',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editPatientProfile(_patientData),
                icon: const Icon(Icons.edit_outlined),
                color: const Color(0xFF666666),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Patient Details
          _buildDetailRow(
            Icons.email_outlined,
            'Email',
            _patientData?['email'] ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.cake_outlined,
            'Date of Birth',
            _formatDate(_patientData?['dateOfBirth']),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.person_outline,
            'Gender',
            _patientData?['gender'] ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.opacity_outlined,
            'Blood Group',
            _patientData?['bloodGroup'] ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.warning_outlined,
            'Allergies',
            _formatList(_patientData?['allergies']),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.medical_services_outlined,
            'Past Conditions',
            _patientData?['pastConditions'] ?? 'None',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.contact_phone_outlined,
            'Emergency Contact',
            '${_patientData?['emergencyContactName'] ?? 'N/A'} (${_patientData?['emergencyContactPhone'] ?? 'N/A'})',
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Family Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              '${_familyMembers.length} members',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Family Members List
        ..._familyMembers.map(
          (member) => Container(
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
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        _getGenderIcon(member['gender']),
                        size: 24,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'] ?? 'Family Member',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            '${member['relationship'] ?? 'Family'} • Age ${member['age'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF666666),
                      ),
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editFamilyMember(member);
                        } else if (value == 'delete') {
                          _deleteFamilyMember(member['id']);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Member Details
                Row(
                  children: [
                    Expanded(
                      child: _buildMemberDetail(
                        'Gender',
                        member['gender'] ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildMemberDetail(
                        'Blood Group',
                        member['bloodGroup'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (member['allergies'] != null &&
                    member['allergies'].isNotEmpty)
                  _buildMemberDetail(
                    'Allergies',
                    _formatList(member['allergies']),
                  ),

                if (member['contactNumber'] != null &&
                    member['contactNumber'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildMemberDetail('Contact', member['contactNumber']),
                ],
              ],
            ),
          ),
        ),

        // Add Member Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            onPressed: _showAddFamilyMemberDialog,
            icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
            label: const Text(
              'Add Family Member',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4CAF50)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberDetail(String label, String value) {
    return Column(
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
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  void _showAddFamilyMemberDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final contactController = TextEditingController();
    final allergiesController = TextEditingController();
    String selectedGender = 'Male';
    String selectedRelationship = 'Parent';
    String selectedBloodGroup = 'A+';

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Family Member',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty == true
                                    ? 'Name is required'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      // Age and Gender Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: ageController,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.cake_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              validator:
                                  (value) =>
                                      value?.isEmpty == true
                                          ? 'Age is required'
                                          : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              items:
                                  ['Male', 'Female', 'Other']
                                      .map(
                                        (gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => selectedGender = value!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Relationship
                      DropdownButtonFormField<String>(
                        value: selectedRelationship,
                        decoration: InputDecoration(
                          labelText: 'Relationship',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.family_restroom),
                        ),
                        items:
                            [
                                  'Parent',
                                  'Spouse',
                                  'Child',
                                  'Sibling',
                                  'Grandparent',
                                  'Other',
                                ]
                                .map(
                                  (relationship) => DropdownMenuItem(
                                    value: relationship,
                                    child: Text(relationship),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => selectedRelationship = value!,
                      ),
                      const SizedBox(height: 16),

                      // Blood Group
                      DropdownButtonFormField<String>(
                        value: selectedBloodGroup,
                        decoration: InputDecoration(
                          labelText: 'Blood Group',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.opacity_outlined),
                        ),
                        items:
                            ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                .map(
                                  (bloodGroup) => DropdownMenuItem(
                                    value: bloodGroup,
                                    child: Text(bloodGroup),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => selectedBloodGroup = value!,
                      ),
                      const SizedBox(height: 16),

                      // Contact Number
                      TextFormField(
                        controller: contactController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          hintText: '10-digit phone number',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator:
                            (value) => Validators.validatePhoneNumber(
                              value,
                              required: false,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Allergies
                      TextFormField(
                        controller: allergiesController,
                        decoration: InputDecoration(
                          labelText: 'Allergies (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.warning_outlined),
                          hintText: 'e.g., Peanuts, Milk',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  final memberData = {
                                    'name': nameController.text,
                                    'age': int.parse(ageController.text),
                                    'gender': selectedGender,
                                    'relationship': selectedRelationship,
                                    'bloodGroup': selectedBloodGroup,
                                    'contactNumber': contactController.text,
                                    'allergies':
                                        allergiesController.text
                                            .split(',')
                                            .map((e) => e.trim())
                                            .where((e) => e.isNotEmpty)
                                            .toList(),
                                  };

                                  Navigator.pop(context);
                                  _addFamilyMember(memberData);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Add Member',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _editPatientProfile(Map<String, dynamic>? patient) {
    // TODO: Implement patient profile editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile editing will be available soon')),
    );
  }

  void _editFamilyMember(Map<String, dynamic> member) {
    // TODO: Implement family member editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Family member editing will be available soon'),
      ),
    );
  }

  Future<void> _deleteFamilyMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Family Member'),
            content: const Text(
              'Are you sure you want to delete this family member? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseDatabase.instance
              .ref('patient_profiles/${user.uid}/familyMembers/$memberId')
              .remove();

          await _loadFamilyMembers();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Family member deleted successfully'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting family member: $e')),
          );
        }
      }
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Privacy Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to privacy settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notification Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to notification settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to help
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserTypeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  IconData _getGenderIcon(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return Icons.man;
      case 'female':
        return Icons.woman;
      default:
        return Icons.person;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatList(dynamic listData) {
    if (listData == null) return 'None';
    if (listData is List) {
      return listData.isEmpty ? 'None' : listData.join(', ');
    }
    return listData.toString();
  }
}
