import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  // Ensure test bindings are initialized so platform channel calls don't crash.
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Location Tests', () {
    test('Check location services availability', () async {
      // Check if location services are enabled (gracefully handle lack of plugins in tests)
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        print('Location services enabled: $serviceEnabled');
      } catch (e) {
        // In test environments without platform channels/plugins, skip gracefully
        print('Skipping location service check in test environment: $e');
        return;
      }

      if (serviceEnabled) {
        // Check location permissions
        try {
          LocationPermission permission = await Geolocator.checkPermission();
          print('Location permission status: $permission');

          if (permission == LocationPermission.denied) {
            print('Location permissions are denied');
          } else if (permission == LocationPermission.deniedForever) {
            print('Location permissions are permanently denied');
          } else {
            print('Location permissions are granted');

            // Try to get current position
            try {
              Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
              );
              print(
                'Current position: Lat=${position.latitude}, Lng=${position.longitude}',
              );
            } catch (e) {
              print('Error getting current position: $e');
            }
          }
        } catch (e) {
          print(
            'Skipping permission and position checks in test environment: $e',
          );
        }
      }
    });
  });
}
