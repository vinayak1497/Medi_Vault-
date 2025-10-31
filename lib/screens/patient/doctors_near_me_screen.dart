import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medivault_ai/services/ai_service.dart';
import 'dart:convert';
import 'package:medivault_ai/screens/patient/doctor_details_screen.dart';

class DoctorsNearMeScreen extends StatefulWidget {
  const DoctorsNearMeScreen({super.key});

  @override
  State<DoctorsNearMeScreen> createState() => _DoctorsNearMeScreenState();
}

class _DoctorsNearMeScreenState extends State<DoctorsNearMeScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';
  final AIService _aiService = AIService();

  // Doctor locations (will be populated from AI service or sample data)
  List<Map<String, dynamic>> _doctorLocations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // On emulator, location services might appear disabled
        // Let's try to get last known position as fallback
        print('Location services appear disabled, trying last known position');
        try {
          Position? lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            print(
              'Using last known position: ${lastPosition.latitude}, ${lastPosition.longitude}',
            );
            setState(() {
              _currentPosition = lastPosition;
            });
            await _getDoctorsNearLocation();
            setState(() {
              _isLoading = false;
              _errorMessage = '';
            });
            return;
          }
        } catch (e) {
          print('Error getting last known position: $e');
        }

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Location services are disabled. Please enable location services in your device settings.';
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
            _errorMessage =
                'Location permissions are denied. Please grant location permissions in app settings.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Location permissions are permanently denied. Please grant location permissions in app settings.';
        });
        return;
      }

      // Get current position with timeout
      print('Requesting current position...');
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      print(
        'Current position obtained: Lat=${position.latitude}, Lng=${position.longitude}',
      );

      // Check if this looks like a default emulator location
      if (_isDefaultEmulatorLocation(position)) {
        print(
          'Detected default emulator location. Consider using manual location input for Mumbai.',
        );
      }

      setState(() {
        _currentPosition = position;
      });

      // Get doctors near current location
      await _getDoctorsNearLocation();

      setState(() {
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to get location: ${e.toString()}. This might be because you\'re using an emulator with default location settings.';
      });

      // Provide Mumbai coordinates as fallback for testing
      if (e.toString().contains('timeout') ||
          e.toString().contains('location')) {
        //_showLocationHelpDialog();
      }
    }
  }

  /// Check if the position looks like a default emulator location
  bool _isDefaultEmulatorLocation(Position position) {
    // Common default emulator locations
    const defaultLocations = [
      // Mountain View, CA (common emulator default)
      {'lat': 37.4219983, 'lng': -122.084},
      // Googleplex
      {'lat': 37.422, 'lng': -122.0841},
    ];

    for (var loc in defaultLocations) {
      if ((position.latitude - loc['lat']!).abs() < 0.001 &&
          (position.longitude - loc['lng']!).abs() < 0.001) {
        return true;
      }
    }
    return false;
  }

  /// Show help dialog for location issues
  void _showLocationHelpDialog() {
    // This is just for debugging - in a real app, you might want to remove this
    // or make it only appear in debug mode
    print('Showing location help dialog');
  }

  Future<void> _getDoctorsNearLocation() async {
    if (_currentPosition == null) return;

    try {
      // Show loading state
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print(
        'Searching for doctors near: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );

      // Add timeout to prevent hanging
      final aiResponse = await _aiService
          .findNearbyDoctors(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          )
          .timeout(const Duration(seconds: 30));

      print('AI Response: $aiResponse'); // Debug print

      // Parse the JSON response
      final data = jsonDecode(aiResponse);

      if (data['doctors'] != null && data['doctors'] is List) {
        print('Doctors found: ${data['doctors'].length}'); // Debug print

        setState(() {
          _doctorLocations = List<Map<String, dynamic>>.from(data['doctors']);
          _isLoading = false;
        });
      } else if (data['error'] != null) {
        print('AI service error: ${data['error']}');
        setState(() {
          _errorMessage = data['error'];
          _isLoading = false;
        });
      } else {
        print('Unexpected response format');
        setState(() {
          _errorMessage = 'Unexpected response format from AI service';
          _isLoading = false;
        });
      }
    } on TimeoutException catch (_) {
      print('Request timed out');
      setState(() {
        _errorMessage =
            'Request timed out. Please check your internet connection and try again.';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading doctors: $e'); // Debug print
      setState(() {
        _errorMessage = 'Failed to load doctors: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Provide sample doctor data as fallback - now returns empty list
  List<Map<String, dynamic>> _getSampleDoctors() {
    return []; // Return empty list instead of sample data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors Near Me'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.location_searching),
            onPressed: _showManualLocationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getDoctorsNearLocation,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load doctors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage.contains('API key')) ...[
                      const Text(
                        'Please check README.md for instructions on how to configure your Gemini API key.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_errorMessage.contains('endpoint not found')) ...[
                      const Text(
                        'The API endpoint may be incorrect. Please check lib/services/ai_service.dart for the correct model name.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Try Again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showManualLocationDialog,
                      child: const Text('Enter Location Manually'),
                    ),
                  ],
                ),
              )
              : _buildDoctorList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _useMumbaiLocation,
        icon: const Icon(Icons.location_city),
        label: const Text('Mumbai'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Use Mumbai coordinates for testing
  void _useMumbaiLocation() {
    setState(() {
      _currentPosition = Position(
        latitude: 19.0760,
        longitude: 72.8777,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    });
    _getDoctorsNearLocation();
  }

  /// Show dialog to enter location manually
  void _showManualLocationDialog() {
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();

    // Pre-fill with Mumbai coordinates for easy testing
    if (_currentPosition == null) {
      latitudeController.text = '19.0760';
      longitudeController.text = '72.8777';
    } else {
      latitudeController.text = _currentPosition!.latitude.toString();
      longitudeController.text = _currentPosition!.longitude.toString();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g., 19.0760',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g., 72.8777',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (latitudeController.text.isNotEmpty &&
                    longitudeController.text.isNotEmpty) {
                  double? lat = double.tryParse(latitudeController.text);
                  double? lng = double.tryParse(longitudeController.text);

                  if (lat != null && lng != null) {
                    setState(() {
                      _currentPosition = Position(
                        latitude: lat,
                        longitude: lng,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        altitudeAccuracy: 0,
                        heading: 0,
                        headingAccuracy: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      );
                    });
                    Navigator.of(context).pop();
                    _getDoctorsNearLocation();
                  }
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorList() {
    if (_doctorLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No doctors found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find any doctors in your area.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            if (_currentPosition != null) ...[
              const SizedBox(height: 16),
              Text(
                'Location: Lat ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng ${_currentPosition!.longitude.toStringAsFixed(4)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Refresh Location'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with location info
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentPosition != null
                      ? 'Doctors near you (Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)})'
                      : 'Doctors within 3 km radius',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${_doctorLocations.length} found',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),

        // Doctors list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _doctorLocations.length,
            itemBuilder: (context, index) {
              final doctor = _doctorLocations[index];
              return _buildDoctorCard(doctor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to doctor details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailsScreen(doctor: doctor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic name
              Text(
                doctor['clinic'] ?? 'Clinic Name',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // Doctor name
              Text(
                doctor['name'] ?? 'Doctor Name',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              // Specialty
              Text(
                doctor['specialty'] ?? 'General Practitioner',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),

              // Distance and rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doctor['distance'] ?? 'Distance unknown',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (doctor['reviews'] != null)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          doctor['reviews'].toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_city, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doctor['address'] ?? 'Address not available',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
