import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health_buddy/services/ai_service.dart';

class AIDoctorsScreen extends StatefulWidget {
  const AIDoctorsScreen({super.key});

  @override
  State<AIDoctorsScreen> createState() => _AIDoctorsScreenState();
}

class _AIDoctorsScreenState extends State<AIDoctorsScreen> {
  final AIService _aiService = AIService();
  Position? _currentPosition;
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _doctors = [];
  bool _locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFindDoctors();
  }

  Future<void> _getCurrentLocationAndFindDoctors() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _doctors = [];
      });

      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Location services are disabled. Please enable location services to find nearby doctors.';
        });
        return;
      }

      // Check location permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _locationPermissionDenied = true;
            _errorMessage =
                'Location permissions are denied. Please grant location permissions to find nearby doctors.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _locationPermissionDenied = true;
          _errorMessage =
              'Location permissions are permanently denied. Please enable location permissions in app settings to find nearby doctors.';
        });
        return;
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Find nearby doctors using AI
      await _findNearbyDoctors(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get location: $e';
      });
    }
  }

  Future<void> _findNearbyDoctors(double latitude, double longitude) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _doctors = [];
      });

      final aiResponse = await _aiService.findNearbyDoctors(
        latitude,
        longitude,
      );

      // Try to parse the response as JSON
      try {
        final jsonResponse = jsonDecode(aiResponse);

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('error')) {
          setState(() {
            _isLoading = false;
            _errorMessage = jsonResponse['error'];
          });
          return;
        }

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('doctors')) {
          final doctorsList = jsonResponse['doctors'] as List;
          setState(() {
            _doctors = List<Map<String, dynamic>>.from(doctorsList);
            _isLoading = false;
          });
        } else {
          // If not JSON, treat as error message
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Received unexpected response format from AI service. Please try again.';
          });
        }
      } catch (jsonError) {
        // If JSON parsing fails, treat as error message
        setState(() {
          _isLoading = false;
          _errorMessage =
              aiResponse.isNotEmpty
                  ? aiResponse
                  : 'Failed to parse response from AI service. Please check your internet connection and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to find doctors: $e. Please check your internet connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doctor Finder'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _getCurrentLocationAndFindDoctors,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentPosition != null)
                Text(
                  'Finding doctors near you...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                _buildErrorWidget()
              else if (_doctors.isNotEmpty)
                _buildDoctorsList()
              else
                _buildInitialWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _locationPermissionDenied ? Icons.location_disabled : Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocationAndFindDoctors,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialWidget() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Find doctors near you with AI assistance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocationAndFindDoctors,
              child: const Text('Find Doctors Near Me'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          return _buildDoctorCard(doctor);
        },
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1 * 255),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? 'Unknown Doctor',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        doctor['specialty'] ?? 'General Practitioner',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (doctor['address'] != null)
              _buildInfoRow(Icons.location_on, doctor['address']),
            if (doctor['phone'] != null)
              _buildInfoRow(Icons.phone, doctor['phone']),
            if (doctor['distance'] != null)
              _buildInfoRow(Icons.directions, '${doctor['distance']} away'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
