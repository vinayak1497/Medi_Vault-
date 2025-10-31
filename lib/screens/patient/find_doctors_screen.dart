import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/services/ai_service.dart';
import 'package:health_buddy/services/appointment_service.dart';
import 'package:health_buddy/services/auth_service.dart';
import 'package:health_buddy/services/gemini_nearby_doctor_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FindDoctorsScreen extends StatefulWidget {
  const FindDoctorsScreen({super.key});

  @override
  State<FindDoctorsScreen> createState() => _FindDoctorsScreenState();
}

class _FindDoctorsScreenState extends State<FindDoctorsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyDoctors = [];
  List<Map<String, dynamic>> _firebaseDoctors = [];
  late GeminiNearbyDoctorService _geminiNearbyDoctorService;

  @override
  void initState() {
    super.initState();
    _geminiNearbyDoctorService = GeminiNearbyDoctorService();
    _tabController = TabController(length: 2, vsync: this);
    _loadDoctors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load nearby doctors and firebase doctors
  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current location
      await _getCurrentLocation();
      // Load nearby doctors from Gemini
      await _getNearbyDoctorsFromGemini();
      // Load doctors from Firebase
      await _loadFirebaseDoctors();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading doctors: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get current device location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          setState(() {
            _currentPosition = lastPosition;
          });
          return;
        }
        throw Exception('Location services disabled');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      setState(() {
        _currentPosition = position;
      });
      debugPrint(
        '📍 Current location: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      rethrow;
    }
  }

  /// Get nearby doctors from Gemini API with patient's exact location
  Future<void> _getNearbyDoctorsFromGemini() async {
    if (_currentPosition == null) return;

    try {
      debugPrint('🔍 Fetching nearby doctors using Gemini AI...');
      final nearbyDoctors = await _geminiNearbyDoctorService
          .getNearbyDoctorsFromGemini(_currentPosition!);

      setState(() {
        _nearbyDoctors = nearbyDoctors;
      });

      if (nearbyDoctors.isNotEmpty) {
        debugPrint(
          '✅ Successfully found ${nearbyDoctors.length} nearby doctors from Gemini',
        );
      } else {
        debugPrint('⚠️ No nearby doctors found in Gemini response');
      }
    } catch (e) {
      debugPrint('❌ Error getting nearby doctors from Gemini: $e');
      setState(() {
        _nearbyDoctors = [];
        _errorMessage = 'Error fetching nearby doctors: ${e.toString()}';
      });
    }
  }

  /// Load doctors from Firebase
  Future<void> _loadFirebaseDoctors() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('doctor_profiles').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final doctors = <Map<String, dynamic>>[];

        data.forEach((key, value) {
          final doctor = Map<String, dynamic>.from(value as Map);
          doctor['doctorId'] = key;
          doctor['source'] = 'firebase';
          doctors.add(doctor);
        });

        setState(() {
          _firebaseDoctors = doctors;
        });
        debugPrint('✅ Found ${doctors.length} Firebase doctors');
      } else {
        setState(() {
          _firebaseDoctors = [];
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading Firebase doctors: $e');
      setState(() {
        _firebaseDoctors = [];
      });
    }
  }

  /// Open Google Maps for a doctor's location
  Future<void> _openMapsLink(String mapsLink) async {
    if (mapsLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maps link not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(mapsLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Call doctor
  Future<void> _callDoctor(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      debugPrint('Error calling doctor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error making call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show appointment booking modal
  void _showBookingModal(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AppointmentBookingModal(
            doctor: doctor,
            onBook: _handleBookAppointment,
          ),
    );
  }

  /// Handle appointment booking
  Future<void> _handleBookAppointment(
    Map<String, dynamic> doctor,
    DateTime date,
    String time,
    String notes,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userProfile = await AuthService.getCurrentUserProfile();
      final patientName = userProfile?['fullName'] ?? 'Patient';

      final appointmentId = await AppointmentService.bookAppointment(
        doctorId: doctor['doctorId'] ?? 'unknown',
        patientId: user.uid,
        patientName: patientName,
        doctorName: doctor['doctorName'] ?? 'Dr. Unknown',
        appointmentDate: date,
        appointmentTime: time,
        notes: notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment booked! ID: $appointmentId'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Find Doctors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4CAF50),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4CAF50),
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Nearby'),
            Tab(icon: Icon(Icons.people), text: 'Registered'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildNearbyDoctorsTab(),
                  _buildRegisteredDoctorsTab(),
                ],
              ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Doctors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDoctors,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Build nearby doctors tab
  Widget _buildNearbyDoctorsTab() {
    if (_nearbyDoctors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_off,
        title: 'No Nearby Doctors Found',
        subtitle: 'Enable location services and try again',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nearbyDoctors.length,
        itemBuilder: (context, index) {
          final doctor = _nearbyDoctors[index];
          return _buildDoctorCard(doctor, isNearby: true);
        },
      ),
    );
  }

  /// Build registered doctors tab
  Widget _buildRegisteredDoctorsTab() {
    if (_firebaseDoctors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off,
        title: 'No Registered Doctors',
        subtitle: 'Check back later for more doctors',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _firebaseDoctors.length,
        itemBuilder: (context, index) {
          final doctor = _firebaseDoctors[index];
          return _buildDoctorCard(doctor, isNearby: false);
        },
      ),
    );
  }

  /// Build doctor card
  Widget _buildDoctorCard(
    Map<String, dynamic> doctor, {
    required bool isNearby,
  }) {
    final clinicName =
        doctor['clinicName'] ?? doctor['clinicHospitalName'] ?? 'Clinic';
    final doctorName =
        doctor['doctorName'] ?? doctor['fullName'] ?? 'Dr. Unknown';
    final contactNumber = doctor['contactNumber'] ?? doctor['phone'] ?? '';
    final openingTime = doctor['openingTime'] ?? '09:00';
    final closingTime = doctor['closingTime'] ?? '18:00';
    final address = doctor['address'] ?? 'Address not provided';
    final specialty = doctor['specialty'] ?? doctor['specialization'] ?? '';
    final mapsLink = doctor['mapsLink'] ?? '';
    final facilityType = doctor['facilityType'] ?? 'Medical Facility';

    return Container(
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with doctor info
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(
                    0xFF4CAF50,
                  ).withValues(alpha: 0.1 * 255),
                  child: Text(
                    doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (specialty.isNotEmpty)
                        Text(
                          specialty,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (facilityType.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getFacilityTypeColor(facilityType)
                                  .withValues(alpha: 0.15 * 255),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              facilityType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getFacilityTypeColor(facilityType),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Clinic info
            _buildInfoRow(
              icon: Icons.local_hospital_outlined,
              label: clinicName,
            ),
            if (address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  label: address,
                ),
              ),

            // Timing
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildInfoRow(
                icon: Icons.schedule,
                label: '$openingTime - $closingTime',
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                if (contactNumber.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _callDoctor(contactNumber),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (contactNumber.isNotEmpty) const SizedBox(width: 8),
                if (mapsLink.isNotEmpty || !isNearby)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openMapsLink(mapsLink),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBookingModal(doctor),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on facility type
  Color _getFacilityTypeColor(String facilityType) {
    final type = facilityType.toLowerCase();
    if (type.contains('private')) {
      return const Color(0xFF2196F3); // Blue
    } else if (type.contains('government') || type.contains('govt')) {
      return const Color(0xFF4CAF50); // Green
    } else if (type.contains('corporate')) {
      return const Color(0xFFFFC107); // Amber
    }
    return Colors.grey;
  }

  /// Build info row
  Widget _buildInfoRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build empty state
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
}

/// Appointment Booking Modal
class AppointmentBookingModal extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final Function(Map<String, dynamic>, DateTime, String, String) onBook;

  const AppointmentBookingModal({
    super.key,
    required this.doctor,
    required this.onBook,
  });

  @override
  State<AppointmentBookingModal> createState() =>
      _AppointmentBookingModalState();
}

class _AppointmentBookingModalState extends State<AppointmentBookingModal> {
  late DateTime _selectedDate;
  late String _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = _timeSlots[0];
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitBooking() async {
    if (_selectedDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onBook(
        widget.doctor,
        _selectedDate,
        _selectedTime,
        _notesController.text,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder:
            (_, controller) => SingleChildScrollView(
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

                    // Title
                    const Text(
                      'Book Appointment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'with Dr. ${widget.doctor['doctorName'] ?? 'Doctor'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Date Selection
                    _buildSectionTitle('Select Date'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Time Selection
                    _buildSectionTitle('Select Time'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _timeSlots.map((time) {
                            final isSelected = _selectedTime == time;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTime = time;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(0xFF4CAF50)
                                          : Colors.grey[100],
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF4CAF50)
                                            : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    _buildSectionTitle('Additional Notes (Optional)'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any concerns or special requests...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4CAF50),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Confirm Booking',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}
