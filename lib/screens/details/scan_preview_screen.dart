// file: screens/details/scan_preview_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';

class ScanPreviewScreen extends StatelessWidget {
  final String imagePath;
  const ScanPreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Scan')),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}