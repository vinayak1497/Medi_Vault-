import 'package:flutter/material.dart';
import 'package:health_buddy/screens/common/chat/chatbot_screen.dart';
import 'package:health_buddy/screens/patient/find_doctors_screen.dart';
import 'package:health_buddy/screens/patient/gov_schemes_screen.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/services/database_service.dart';
import 'package:health_buddy/services/appointment_service.dart';

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
  List<Map<String, dynamic>> _upcomingAppointments = [];
  bool _appointmentsLoading = false;

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

        // Load upcoming appointments
        await _loadUpcomingAppointments(profile['uid']);
      }
    } catch (e) {
      debugPrint('Error loading patient data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Safely return the first uppercase letter of a name, with a fallback
  String _initial(String? name, {String fallback = 'M'}) {
    if (name == null) return fallback;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.characters.first.toUpperCase();
  }

  // Responsive helpers
  double _spacing(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final s = w * 0.04; // 4% of width
    return s.clamp(8.0, 24.0);
  }

  EdgeInsets _pagePadding(BuildContext context) {
    final s = _spacing(context);
    return EdgeInsets.symmetric(horizontal: s, vertical: s);
  }

  int _gridCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 4; // tablets landscape / large
    if (w >= 600) return 3; // tablets portrait / foldables
    return 2; // phones
  }

  Future<void> _loadFamilyMembers() async {
    try {
      if (!DatabaseService.isAuthenticated) {
        debugPrint('User not authenticated, skipping family members load');
        setState(() {
          _familyMembers = [
            {'name': 'You', 'relationship': 'Self', 'id': 'self'},
          ];
          _selectedMemberName = 'You';
        });
        return;
      }

      final familyMembers = await DatabaseService.getFamilyMembers();

      // Normalize, filter out null/empty names, and dedupe by name
      final seen = <String>{};
      final cleaned = <Map<String, dynamic>>[];
      for (final m in familyMembers) {
        final name = (m['name'] ?? '').toString().trim();
        if (name.isEmpty) continue; // drop the 'null' / empty entries
        if (seen.add(name)) {
          cleaned.add({...m, 'name': name});
        }
      }

      // Add the current user as primary member at the top
      final user = DatabaseService.currentUser;
      final primaryName = (user?.displayName ?? 'You').toString().trim();
      final primary = {
        'name': primaryName.isEmpty ? 'You' : primaryName,
        'relationship': 'Self',
        'id': user?.uid ?? 'self',
        'isPrimary': true,
      };

      final members = [primary, ...cleaned];

      setState(() {
        _familyMembers = members;
        // Keep selection if still valid; otherwise fallback to primary
        final names = members.map((e) => (e['name'] ?? '').toString()).toSet();
        if (_selectedMemberName == null ||
            !names.contains(_selectedMemberName)) {
          _selectedMemberName = primary['name'] as String;
        }
      });
    } catch (e) {
      debugPrint('Error loading family members: $e');
      // Set default data on error
      setState(() {
        _familyMembers = [
          {'name': 'You', 'relationship': 'Self', 'id': 'self'},
        ];
        _selectedMemberName = 'You';
      });
    }
  }

  /// Load upcoming appointments for the patient
  Future<void> _loadUpcomingAppointments(String? patientId) async {
    if (patientId == null) return;

    try {
      setState(() => _appointmentsLoading = true);

      final appointments = await AppointmentService.getPatientAppointments(
        patientId,
      );

      // Filter only upcoming appointments (pending or accepted status)
      final upcoming =
          appointments.where((apt) {
            final status = apt['status'] ?? '';
            return status == 'pending' || status == 'accepted';
          }).toList();

      // Sort by date (upcoming first)
      upcoming.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['appointmentDate'] ?? '');
          final dateB = DateTime.parse(b['appointmentDate'] ?? '');
          return dateA.compareTo(dateB);
        } catch (_) {
          return 0;
        }
      });

      setState(() {
        _upcomingAppointments = upcoming;
        _appointmentsLoading = false;
      });

      debugPrint('✅ Loaded ${upcoming.length} upcoming appointments');
    } catch (e) {
      debugPrint('❌ Error loading appointments: $e');
      setState(() => _appointmentsLoading = false);
    }
  }

  /// Get color based on appointment status
  Color _getAppointmentStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange; // Yellow for pending
      case 'accepted':
        return Colors.green; // Green for accepted
      case 'rejected':
        return Colors.red; // Red for rejected
      case 'cancelled':
        return Colors.grey; // Grey for cancelled
      default:
        return Colors.grey;
    }
  }

  /// Get status text
  String _getAppointmentStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _spacing(context);
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
                SizedBox(height: s),

                // Quick Actions Grid
                _buildQuickActions(),
                SizedBox(height: s),

                // Upcoming Appointments
                _buildUpcomingAppointments(),
                SizedBox(height: s),

                // AI Assistant Card
                _buildAIAssistantCard(),
                SizedBox(height: s),

                // Health Insights
                _buildHealthInsights(),
                SizedBox(height: s * 4), // Bottom padding for navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final s = _spacing(context);
    return Container(
      padding: EdgeInsets.all(s),
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
                  radius: 20 + (s - 8) * 0.25, // slightly scale with spacing
                  backgroundColor: const Color(
                    0xFF4CAF50,
                  ).withValues(alpha: 0.1 * 255),
                  child: Text(
                    _initial(_selectedMemberName, fallback: 'M'),
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(width: s * 0.6),
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
                          SizedBox(width: s * 0.2),
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

          SizedBox(height: s),

          // Welcome Message
          Text(
            'Good ${_getGreeting()}, ${_getFirstName()}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: s * 0.25),
          Text(
            'How are you feeling today?',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final s = _spacing(context);
    final actions = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'AI Health Chat',
        'subtitle': 'Ask questions',
        'color': const Color(0xFF4CAF50),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatbotScreen()),
            ),
      },
      {
        'icon': Icons.mic_outlined,
        'title': 'Voice Chat',
        'subtitle': 'Quick voice note',
        'color': const Color(0xFF2196F3),
        'onTap': () {},
      },
      {
        'icon': Icons.local_hospital_outlined,
        'title': 'Find Doctor',
        'subtitle': 'Nearby doctors',
        'color': const Color(0xFFFF9800),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FindDoctorsScreen(),
              ),
            ),
      },
      {
        'icon': Icons.account_balance_outlined,
        'title': 'Gov Schemes',
        'subtitle': 'Health benefits',
        'color': const Color(0xFF9C27B0),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GovSchemesScreen()),
            ),
      },
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(s, s, s, 0),
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
          SizedBox(height: s * 0.8),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = _gridCount(context);
              return GridView.builder(
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: s * 0.6,
                  mainAxisSpacing: s * 0.6,
                  // Make tiles taller to prevent any overflow on compact devices
                  childAspectRatio: 0.95,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final a = actions[index];
                  return _buildActionCard(
                    icon: a['icon'] as IconData,
                    title: a['title'] as String,
                    subtitle: a['subtitle'] as String,
                    color: a['color'] as Color,
                    onTap: a['onTap'] as VoidCallback,
                  );
                },
              );
            },
          ),
          SizedBox(height: s),
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
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 112),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1 * 255),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1 * 255),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    final s = _spacing(context);

    // Show loading state
    if (_appointmentsLoading) {
      return Container(
        margin: EdgeInsets.fromLTRB(s, 0, s, 0),
        padding: EdgeInsets.all(s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1 * 255),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: s),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(s, 0, s, 0),
      padding: EdgeInsets.all(s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1 * 255),
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
          SizedBox(height: s * 0.8),

          // Show appointments if available
          if (_upcomingAppointments.isEmpty)
            Container(
              padding: EdgeInsets.all(s),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2 * 255),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 40 + (s - 8) * 0.5,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: s * 0.6),
                  Text(
                    'No upcoming appointments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: s * 0.25),
                  Text(
                    'Book your next checkup',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _upcomingAppointments.length,
              separatorBuilder: (_, __) => SizedBox(height: s * 0.6),
              itemBuilder: (context, index) {
                final appointment = _upcomingAppointments[index];
                final status = appointment['status'] ?? 'pending';
                final statusColor = _getAppointmentStatusColor(status);
                final statusText = _getAppointmentStatusText(status);
                final doctorName = appointment['doctorName'] ?? 'Dr. Unknown';
                final appointmentDate = appointment['appointmentDate'] ?? '';
                final appointmentTime = appointment['appointmentTime'] ?? '';
                final reason = appointment['reason'] ?? '';

                // Parse date
                DateTime? parsedDate;
                try {
                  parsedDate = DateTime.parse(appointmentDate);
                } catch (_) {
                  parsedDate = null;
                }

                final dateString =
                    parsedDate != null
                        ? '${parsedDate.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][parsedDate.month - 1]} ${parsedDate.year}'
                        : 'Unknown date';

                return Container(
                  padding: EdgeInsets.all(s * 0.8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15 * 255),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              doctorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: s * 0.4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: s * 0.6,
                              vertical: s * 0.3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15 * 255),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3 * 255),
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: s * 0.5),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: s * 0.4),
                          Text(
                            dateString,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (appointmentTime.isNotEmpty) ...[
                            SizedBox(width: s * 0.8),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: s * 0.4),
                            Text(
                              appointmentTime,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (reason.isNotEmpty) ...[
                        SizedBox(height: s * 0.5),
                        Text(
                          'Reason: $reason',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantCard() {
    final s = _spacing(context);
    return Container(
      margin: EdgeInsets.fromLTRB(s, 0, s, 0),
      padding: EdgeInsets.all(s),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3 * 255),
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
                width: 44 + (s - 8) * 0.5,
                height: 44 + (s - 8) * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2 * 255),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: s * 0.8),
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
          SizedBox(height: s * 0.8),
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
                  color: Colors.grey.withValues(alpha: 0.1 * 255),
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
                        color: const Color(
                          0xFF2196F3,
                        ).withValues(alpha: 0.1 * 255),
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
                    backgroundColor: const Color(
                      0xFF4CAF50,
                    ).withValues(alpha: 0.1 * 255),
                    child: Text(
                      _initial(_patientData?['fullName'], fallback: 'M'),
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
                // Family members (already cleaned)
                ..._familyMembers.skip(1).map((member) {
                  final age = member['age'];
                  final ageText =
                      (age != null && age.toString().trim().isNotEmpty)
                          ? Text('Age: ${age.toString().trim()}')
                          : null;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1 * 255),
                      child: Text(
                        _initial(member['name'] as String?, fallback: 'F'),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text((member['name'] ?? 'Family Member') as String),
                    subtitle: ageText,
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
                  );
                }),
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
