import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/screens/common/auth/user_type_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? _doctorData;
  bool _isLoading = true;
  
  // Professional color scheme - White and Green theme
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color dangerRed = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doctorData = await AuthService.getCurrentUserProfile();
      setState(() {
        _doctorData = doctorData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      final confirmed = await _showLogoutConfirmation();
      if (confirmed == true) {
        await AuthService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const UserTypeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryGreen),
            onPressed: _loadDoctorData,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            )
          : _doctorData == null
              ? _buildNoDataWidget()
              : _buildProfileContent(),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Profile Data Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact support for assistance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDoctorData,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildPersonalInfoCard(),
          const SizedBox(height: 16),
          _buildProfessionalInfoCard(),
          const SizedBox(height: 16),
          _buildContactInfoCard(),
          const SizedBox(height: 24),
          _buildSignOutButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final fullName = _doctorData?['fullName'] ?? _doctorData?['name'] ?? 'Doctor';
    final degree = _doctorData?['degree'] ?? 'Medical Professional';
    final isVerified = _doctorData?['nmcVerified'] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen, accentGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            degree,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green[700] : Colors.orange[700],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.pending,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isVerified ? 'Verified' : 'Pending Verification',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildInfoCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildEditableInfoRow('Full Name', _doctorData?['fullName'] ?? _doctorData?['name'], 'fullName'),
        _buildEditableInfoRow('Biography', _doctorData?['biography'], 'biography'),
        _buildEditableInfoRow('Degree', _doctorData?['degree'], 'degree'),
        _buildEditableInfoRow('Doctor ID', _doctorData?['doctorId'], 'doctorId'),
      ],
    );
  }

  Widget _buildProfessionalInfoCard() {
    return _buildInfoCard(
      title: 'Professional Information',
      icon: Icons.work_outline,
      children: [
        _buildEditableInfoRow('License Number', _doctorData?['licenseNumber'], 'licenseNumber'),
        _buildEditableInfoRow('Clinic Name', _doctorData?['clinicName'], 'clinicName'),
        _buildEditableInfoRow('Hospital', _doctorData?['hospital'], 'hospital'),
        _buildEditableInfoRow('Consultation Fee', '₹${_doctorData?['consultationFee']?.toString() ?? '0'}', 'consultationFee'),
        _buildInfoRow('Patient Count', _doctorData?['patientCount']?.toString() ?? '0'),
        _buildInfoRow('Rating', '${_doctorData?['rating']?.toString() ?? '0'}/5'),
      ],
    );
  }

  Widget _buildContactInfoCard() {
    return _buildInfoCard(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        _buildInfoRow('Email', _doctorData?['email']),
        _buildEditableInfoRow('Phone Number', _doctorData?['phoneNumber'], 'phoneNumber'),
        _buildEditableInfoRow('Address', _doctorData?['address'], 'address'),
        _buildInfoRow('Account Created', _formatDate(_doctorData?['createdAt'])),
        _buildInfoRow('Profile Complete', _doctorData?['profileComplete'] == true ? 'Yes' : 'No'),
        _buildInfoRow('NMC Verified', _doctorData?['nmcVerified'] == true ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: lightGreen, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: darkGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.isNotEmpty == true ? value! : 'Not provided',
              style: TextStyle(
                fontSize: 14,
                color: value?.isNotEmpty == true ? Colors.black87 : Colors.grey[500],
                fontWeight: value?.isNotEmpty == true ? FontWeight.w400 : FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: dangerRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: dangerRed.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, String? value, String fieldKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value?.isNotEmpty == true ? value! : 'Not provided',
                    style: TextStyle(
                      fontSize: 14,
                      color: value?.isNotEmpty == true ? Colors.black87 : Colors.grey[500],
                      fontWeight: value?.isNotEmpty == true ? FontWeight.w400 : FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _editField(label, fieldKey, value ?? ''),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editField(String label, String fieldKey, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Edit $label',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryGreen, width: 2),
                ),
                hintText: fieldKey == 'phoneNumber' ? '10-digit phone number' : null,
              ),
              maxLines: fieldKey == 'biography' ? 3 : 1,
              keyboardType: fieldKey == 'phoneNumber' ? TextInputType.phone : null,
              inputFormatters: fieldKey == 'phoneNumber' ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ] : null,
              validator: (value) {
                if (fieldKey == 'phoneNumber' && value != null && value.isNotEmpty) {
                  // Remove all non-digits
                  String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanedValue.length != 10) {
                    return 'Phone number must be exactly 10 digits';
                  }
                  // Check if it starts with valid digits (not 0 or 1)
                  if (cleanedValue.startsWith('0') || cleanedValue.startsWith('1')) {
                    return 'Phone number cannot start with 0 or 1';
                  }
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(controller.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result != currentValue) {
      await _updateField(fieldKey, result);
    }
  }

  Future<void> _updateField(String fieldKey, String newValue) async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                SizedBox(width: 16),
                Text('Updating...'),
              ],
            ),
            backgroundColor: primaryGreen,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Update in Firebase
      await FirebaseDatabase.instance
          .ref()
          .child('doctors')
          .child(user.uid)
          .update({fieldKey: fieldKey == 'consultationFee' ? int.tryParse(newValue) ?? 0 : newValue});

      // Update local data
      setState(() {
        _doctorData?[fieldKey] = fieldKey == 'consultationFee' ? int.tryParse(newValue) ?? 0 : newValue;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Updated successfully!'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating: $e'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Not available';
    
    try {
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(
        timestamp is int ? timestamp : int.parse(timestamp.toString())
      );
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}