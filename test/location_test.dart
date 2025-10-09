import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('Location Tests', () {
    test('Check location services availability', () async {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location services enabled: $serviceEnabled');

      if (serviceEnabled) {
        // Check location permissions
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
      }
    });
  });
}
