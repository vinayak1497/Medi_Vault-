import 'package:flutter/material.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  const AppointmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'This is the Appointment Details Screen. You can add logic here to display a specific appointment’s data, including the scanned document and medications.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
