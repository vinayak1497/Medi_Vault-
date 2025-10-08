import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_buddy/utils/constants.dart';

class DoctorsNearMeScreen extends StatefulWidget {
  const DoctorsNearMeScreen({super.key});

  @override
  State<DoctorsNearMeScreen> createState() => _DoctorsNearMeScreenState();
}

class _DoctorsNearMeScreenState extends State<DoctorsNearMeScreen> {
  GoogleMapController? _mapController; // Make it nullable instead of late
  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';

  // Sample doctor locations (in a real app, these would come from an API)
  final List<Map<String, dynamic>> _doctorLocations = [
    {
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'address': '123 Medical Plaza, Downtown',
      'lat': 12.9720,
      'lng': 77.5950,
    },
    {
      'name': 'Dr. Michael Chen',
      'specialty': 'Pediatrician',
      'address': '456 Health Street, Midtown',
      'lat': 12.9730,
      'lng': 77.5960,
    },
    {
      'name': 'Dr. Emily Rodriguez',
      'specialty': 'Dermatologist',
      'address': '789 Wellness Blvd, Uptown',
      'lat': 12.9740,
      'lng': 77.5970,
    },
    {
      'name': 'Dr. James Wilson',
      'specialty': 'Orthopedic Surgeon',
      'address': '101 Hospital Road, Medical District',
      'lat': 12.9750,
      'lng': 77.5980,
    },
  ];

  Set<Marker> _markers = <Marker>{};

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
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled.';
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
            _errorMessage = 'Location permissions are denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        return;
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _errorMessage = '';
      });

      // Add markers for doctors
      _addDoctorMarkers();

      // Move camera to current location
      _moveCameraToCurrentLocation();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get location: $e';
      });
    }
  }

  void _addDoctorMarkers() {
    Set<Marker> markers = <Marker>{};

    // Add marker for current location
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add markers for doctors
    for (int i = 0; i < _doctorLocations.length; i++) {
      final doctor = _doctorLocations[i];
      markers.add(
        Marker(
          markerId: MarkerId('doctor_$i'),
          position: LatLng(doctor['lat'], doctor['lng']),
          infoWindow: InfoWindow(
            title: doctor['name'],
            snippet: '${doctor['specialty']}\n${doctor['address']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _moveCameraToCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: Constants.defaultZoom,
          ),
        ),
      );
    } else if (_mapController != null) {
      // If we don't have current position, center on default location
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: const LatLng(
              Constants.defaultLatitude,
              Constants.defaultLongitude,
            ),
            zoom: Constants.defaultZoom,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors Near Me'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
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
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: const LatLng(
                    Constants.defaultLatitude,
                    Constants.defaultLongitude,
                  ),
                  zoom: Constants.defaultZoom,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (_currentPosition != null) {
                    _moveCameraToCurrentLocation();
                  }
                },
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
      floatingActionButton:
          _currentPosition != null && _mapController != null
              ? FloatingActionButton(
                onPressed: _moveCameraToCurrentLocation,
                child: const Icon(Icons.my_location),
              )
              : null,
    );
  }
}
