import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Remove any non-digit characters except + for international numbers
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanedNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Show a snackbar if call cannot be made
      // Note: We don't have context here, so this is just for reference
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor profile card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clinic name
                    if (doctor['clinic'] != null)
                      Text(
                        doctor['clinic'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (doctor['clinic'] != null) const SizedBox(height: 8),

                    // Doctor name and specialty
                    Text(
                      doctor['name'] ?? 'Unknown Doctor',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['specialty'] ?? 'General Practitioner',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['address'] ?? 'Address not available',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    // Distance
                    if (doctor['distance'] != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${doctor['distance']} away',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    if (doctor['distance'] != null) const SizedBox(height: 16),

                    // Contact button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (doctor['phone'] != null) {
                            _makePhoneCall(doctor['phone']);
                          } else {
                            // Show a message if no phone number is available
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone number not available'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.call),
                        label: Text(
                          doctor['phone'] ?? 'No phone number available',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reviews section
            const Text(
              'Patient Reviews',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),

            // Sample reviews
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(radius: 20, child: Icon(Icons.person)),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rajesh Kumar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Professional and caring service. Highly recommended!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(radius: 20, child: Icon(Icons.person)),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priya Sharma',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Icon(
                                  Icons.star_half,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Great experience with prompt service and expert care.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
