// file: screens/main_app/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock data for demonstration
  final List<String> _familyMembers = ['Papa', 'Mama', 'Son'];
  final List<Map<String, String>> _medicationReminders = [
    {'name': 'Amlodipine', 'time': '9:00 AM'},
    {'name': 'Metformin', 'time': '8:00 PM'},
  ];

  /// Signs the current user out of Firebase.
  /// The AuthWrapper in main.dart will automatically handle the navigation
  /// back to the AuthScreen after the user is signed out.
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'My Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            // User Info Card
            _buildInfoCard(
              context,
              title: 'User Info',
              content: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? 'No Email',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 16),
            // Family Members Widget
            _buildInfoCard(
              context,
              title: 'My Family',
              content: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _familyMembers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _familyMembers.length) {
                      return GestureDetector(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFF5DADE2),
                                child: Icon(Icons.add, color: Colors.white),
                              ),
                              SizedBox(height: 4),
                              Text('Add New', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(height: 4),
                          Text(_familyMembers[index],
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Medication Reminders Widget
            _buildInfoCard(
              context,
              title: 'Medication Reminders',
              content: Column(
                children: _medicationReminders.map((med) {
                  return ListTile(
                    leading: const Icon(Icons.medical_services),
                    title: Text(med['name']!),
                    trailing: Text(med['time']!),
                  );
                }).toList(),
              ),
              trailing: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add New'),
              ),
            ),
            const SizedBox(height: 24),
            // Logout Button
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title, required Widget content, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
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
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}