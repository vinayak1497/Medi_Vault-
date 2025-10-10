import 'package:flutter/material.dart';
import 'package:health_buddy/screens/common/chat/chatbot_screen.dart';
import 'package:health_buddy/screens/patient/doctors_near_me_screen.dart';
import 'package:health_buddy/screens/patient/gov_schemes_screen.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/services/database_service.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _familyMembers = [];
  String? _selectedMemberName;
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
          _selectedMemberName = profile['fullName'] ?? 'Me';
        });

        // Load family members
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
      if (!DatabaseService.isAuthenticated) {
        print('User not authenticated, skipping family members load');
        setState(() {
          _familyMembers = [
            {'name': 'You', 'relationship': 'Self', 'id': 'self'},
          ];
          _selectedMemberName = 'You';
        });
        return;
      }

      final familyMembers = await DatabaseService.getFamilyMembers();

      // Add the current user as primary member
      final user = DatabaseService.currentUser;
      final members = [
        {
          'name': user?.displayName ?? 'You',
          'relationship': 'Self',
          'id': user?.uid ?? 'self',
          'isPrimary': true,
        },
        ...familyMembers,
      ];

      setState(() {
        _familyMembers = members;
        _selectedMemberName = members.first['name'];
      });
    } catch (e) {
      print('Error loading family members: $e');
      // Set default data on error
      setState(() {
        _familyMembers = [
          {'name': 'You', 'relationship': 'Self', 'id': 'self'},
        ];
        _selectedMemberName = 'You';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPatientData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Profile Switcher
                _buildHeader(),

                // Quick Actions Grid
                _buildQuickActions(),

                // Upcoming Appointments
                _buildUpcomingAppointments(),

                // AI Assistant Card
                _buildAIAssistantCard(),

                // Health Insights
                _buildHealthInsights(),

                const SizedBox(height: 100), // Bottom padding for navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Switcher (Instagram-like)
          GestureDetector(
            onTap: _showProfileSwitcher,
            child: Row(
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                  child: Text(
                    (_selectedMemberName != null &&
                            _selectedMemberName!.isNotEmpty)
                        ? _selectedMemberName![0].toUpperCase()
                        : 'M',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name with dropdown arrow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedMemberName ?? 'Select Member',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF666666),
                            size: 20,
                          ),
                        ],
                      ),
                      Text(
                        _selectedMemberName ==
                                (_patientData?['fullName'] ?? 'Me')
                            ? 'Main Account'
                            : 'Family Member',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Notifications icon
                IconButton(
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Welcome Message
          Text(
            'Good ${_getGreeting()}, ${_getFirstName()}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How are you feeling today?',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'AI Health Chat',
                  subtitle: 'Ask questions',
                  color: const Color(0xFF4CAF50),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatbotScreen(),
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.mic_outlined,
                  title: 'Voice Chat',
                  subtitle: 'Quick voice note',
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    // TODO: Implement voice chat
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.local_hospital_outlined,
                  title: 'Find Doctor',
                  subtitle: 'Nearby doctors',
                  color: const Color(0xFFFF9800),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorsNearMeScreen(),
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.account_balance_outlined,
                  title: 'Gov Schemes',
                  subtitle: 'Health benefits',
                  color: const Color(0xFF9C27B0),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GovSchemesScreen(),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all appointments
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // No appointments placeholder
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No upcoming appointments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Book your next checkup',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health AI Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get instant answers to your health questions',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start Chat',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInsights() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          // Health tip card
          Container(
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF2196F3),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Daily Health Tip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Stay hydrated! Aim for 8 glasses of water daily to maintain optimal health and energy levels.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSwitcher() {
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
                    'Switch Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // Main patient
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                    child: Text(
                      (_patientData?['fullName'] ?? 'M')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(_patientData?['fullName'] ?? 'Main Account'),
                  subtitle: const Text('Main Account'),
                  trailing:
                      _selectedMemberName == (_patientData?['fullName'] ?? 'Me')
                          ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                          )
                          : null,
                  onTap: () {
                    setState(() {
                      _selectedMemberName = _patientData?['fullName'] ?? 'Me';
                    });
                    Navigator.pop(context);
                  },
                ),
                // Family members
                ..._familyMembers.map(
                  (member) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        (member['name'] ?? 'F')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(member['name'] ?? 'Family Member'),
                    subtitle: Text('Age: ${member['age'] ?? 'N/A'}'),
                    trailing:
                        _selectedMemberName == member['name']
                            ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4CAF50),
                            )
                            : null,
                    onTap: () {
                      setState(() {
                        _selectedMemberName = member['name'];
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _getFirstName() {
    if (_selectedMemberName == null || _selectedMemberName!.isEmpty) {
      return 'there';
    }

    final parts = _selectedMemberName!.split(' ');
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'there';
  }
}
