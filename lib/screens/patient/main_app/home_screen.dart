import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/screens/common/chat/chatbot_screen.dart';
import 'package:health_buddy/screens/common/details/appointment_details_screen.dart';
import 'package:health_buddy/screens/patient/doctors_near_me_screen.dart';
import 'package:health_buddy/screens/patient/gov_schemes_screen.dart';
import 'package:health_buddy/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  User? _currentUser;
  Map<String, dynamic>? _activeFamilyMember;
  List<Map<String, dynamic>> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null && DatabaseService.isAuthenticated) {
      _fetchFamilyMembers();
    } else {
      // Set default data if not authenticated
      setState(() {
        _familyMembers = [
          {
            'name': _currentUser?.displayName ?? 'User',
            'id': _currentUser?.uid ?? '',
            'isPrimary': true,
          },
        ];
        if (_familyMembers.isNotEmpty) {
          _activeFamilyMember = _familyMembers[0];
        }
      });
    }
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      // Check if user is authenticated and email is verified
      if (_currentUser == null || !_currentUser!.emailVerified) {
        print('User not authenticated or email not verified');
        return;
      }

      final userRef = _dbRef.child('users/${_currentUser!.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        final familyProfiles =
            userData['family_profiles'] as Map<dynamic, dynamic>?;

        final List<Map<String, dynamic>> members = [];
        members.add({
          'name': userData['fullName'] ?? 'User',
          'id': _currentUser!.uid,
          'isPrimary': true,
        });

        if (familyProfiles != null) {
          familyProfiles.forEach((key, value) {
            members.add({'name': value['name'], 'id': key, 'isPrimary': false});
          });
        }

        setState(() {
          _familyMembers = members;
          _activeFamilyMember = members[0];
        });
      } else {
        // User data doesn't exist, create default family member
        setState(() {
          _familyMembers = [
            {
              'name': _currentUser!.displayName ?? 'User',
              'id': _currentUser!.uid,
              'isPrimary': true,
            },
          ];
          _activeFamilyMember = _familyMembers[0];
        });
      }
    } catch (e) {
      print('Error fetching family members: $e');
      // Set default family member if there's an error
      setState(() {
        _familyMembers = [
          {
            'name': _currentUser?.displayName ?? 'User',
            'id': _currentUser?.uid ?? '',
            'isPrimary': true,
          },
        ];
        _activeFamilyMember = _familyMembers[0];
      });
    }
  }

  void _showFamilySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                _familyMembers.map((member) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member['name']),
                    onTap: () {
                      setState(() {
                        _activeFamilyMember = member;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 180,
        leading: GestureDetector(
          onTap: _showFamilySelector,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.person, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activeFamilyMember?['name'] ?? 'Loading...',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Your Dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Appointments Widget
            _buildHomeCard(
              context,
              icon: Icons.calendar_today,
              title: 'My Appointments',
              subtitle: 'Upcoming visits and schedule',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentDetailsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // AI Chatbot Widget
            _buildHomeCard(
              context,
              icon: Icons.smart_toy_outlined,
              title: 'Ask My Health AI',
              subtitle: 'Get answers from your records',
              onTap: () {
                // Navigate to chatbot screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Find a Doctor Widget
            _buildHomeCard(
              context,
              icon: Icons.local_hospital_outlined,
              title: 'Find a Doctor',
              subtitle: 'Locate a specialist near you',
              onTap: () {
                // Navigate to doctors near me screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorsNearMeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // GOV Schemes Widget
            _buildHomeCard(
              context,
              icon: Icons.account_balance,
              title: 'Gov Schemes',
              subtitle: 'Check eligibility and apply',
              onTap: () {
                // Navigate to government schemes screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GovSchemesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Health Tips Widget
            _buildHomeCard(
              context,
              icon: Icons.lightbulb_outline,
              title: 'Health Tip',
              subtitle: 'Stay hydrated for better health!',
              onTap: () {}, // Add navigation later
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // TODO: Implement voice command logic
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }
}

Widget _buildHomeCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Icon(icon, size: 40, color: const Color(0xFF5DADE2)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ],
      ),
    ),
  );
}
