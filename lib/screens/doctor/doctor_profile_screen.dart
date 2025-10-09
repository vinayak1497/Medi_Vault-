import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? _doctorData;
  bool _isLoading = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
    _loadThemePreference();
  }

  Future<void> _loadDoctorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot =
            await _dbRef
                .child('doctor_profiles')
                .child(user.email!.replaceAll('.', ','))
                .get();

        if (snapshot.exists) {
          setState(() {
            _doctorData = Map<String, dynamic>.from(snapshot.value as Map);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to splash screen
      Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveThemePreference(value);

    // Show a message about restarting the app for theme changes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme preference saved. Restart app to see changes.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Doctor Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your profile and settings',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Profile Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _doctorData == null
                        ? const Center(
                          child: Text(
                            'No profile data found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header
                            Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Icon(
                                    Icons.local_hospital,
                                    size: 40,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _doctorData!['name'] ?? 'Doctor Name',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _doctorData!['specialization'] ??
                                            'Specialization',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Profile Details
                            const Divider(),
                            const SizedBox(height: 15),

                            _buildProfileDetail(
                              icon: Icons.email,
                              label: 'Email',
                              value: _doctorData!['email'] ?? 'Not provided',
                            ),
                            const SizedBox(height: 15),

                            _buildProfileDetail(
                              icon: Icons.business,
                              label: 'Hospital/Clinic',
                              value: _doctorData!['hospital'] ?? 'Not provided',
                            ),
                            const SizedBox(height: 15),

                            _buildProfileDetail(
                              icon: Icons.badge,
                              label: 'Doctor ID',
                              value: _doctorData!['doctorId'] ?? 'Not provided',
                            ),
                            const SizedBox(height: 15),

                            _buildProfileDetail(
                              icon: Icons.calendar_today,
                              label: 'Member Since',
                              value: _formatTimestamp(
                                _doctorData!['createdAt'],
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            const SizedBox(height: 30),

            // Settings Section
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Dark Mode Toggle
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: _isDarkMode,
                    onChanged: _toggleDarkMode,
                    secondary: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(height: 0),

                  // Logout Button
                  ListTile(
                    title: const Text('Logout'),
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text(
                              'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _logout();
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Not available';

    try {
      // If it's already a formatted string
      if (timestamp is String) return timestamp;

      // If it's a timestamp number
      if (timestamp is int) {
        final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.day}/${date.month}/${date.year}';
      }

      return timestamp.toString();
    } catch (e) {
      return 'Not available';
    }
  }
}
