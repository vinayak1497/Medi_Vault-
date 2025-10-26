import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for handling camera operations and image selection
/// Provides camera capture, gallery selection, and permission management
class CameraService {
  static final ImagePicker _picker = ImagePicker();
  static List<CameraDescription>? _cameras;

  /// Initialize camera service and get available cameras
  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  /// Get list of available cameras
  static List<CameraDescription>? get cameras => _cameras;

  /// Check and request camera permissions
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check and request storage permissions (simplified version)
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Try photos permission first (works for Android 13+)
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      // Fallback to storage permission (works for older Android)
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true; // For other platforms
  }

  /// Check if camera and storage permissions are granted (simplified)
  static Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    bool storageGranted = true;

    if (Platform.isAndroid) {
      // Check both permission types and accept either one
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;
      storageGranted =
          (photosStatus.isGranted || photosStatus.isLimited) ||
          storageStatus.isGranted;
    }

    return cameraStatus.isGranted && storageGranted;
  }

  /// Check and request photos permissions (for iOS)
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  /// Capture image using device camera
  static Future<File?> captureFromCamera() async {
    try {
      // Request camera permission
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Reduce quality for faster processing
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing from camera: $e');
      rethrow;
    }
  }

  /// Pick image from device gallery
  static Future<File?> pickFromGallery() async {
    try {
      // Request storage/photos permission
      bool hasPermission = false;
      if (Platform.isIOS) {
        hasPermission = await requestPhotosPermission();
      } else {
        hasPermission = await requestStoragePermission();
      }

      if (!hasPermission) {
        throw Exception(
          'Storage permission denied. Please grant permission in app settings to select images from gallery.',
        );
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      rethrow;
    }
  }

  /// Save image to app's document directory
  static Future<File> saveImageToAppDirectory(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final prescriptionDir = Directory(
        path.join(appDir.path, 'prescriptions'),
      );

      // Create directory if it doesn't exist
      if (!await prescriptionDir.exists()) {
        await prescriptionDir.create(recursive: true);
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final newFileName = 'prescription_$timestamp$extension';
      final savedFile = File(path.join(prescriptionDir.path, newFileName));

      // Copy image to app directory
      await imageFile.copy(savedFile.path);

      return savedFile;
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }

  /// Delete image file from device
  static Future<void> deleteImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image file: $e');
    }
  }

  /// Get image file size in MB
  static Future<double> getImageSize(File imageFile) async {
    try {
      final bytes = await imageFile.length();
      return bytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('Error getting image size: $e');
      return 0.0;
    }
  }

  /// Compress image if it's too large
  static Future<File> compressImageIfNeeded(
    File imageFile, {
    double maxSizeMB = 5.0,
  }) async {
    try {
      final currentSize = await getImageSize(imageFile);

      if (currentSize <= maxSizeMB) {
        return imageFile;
      }

      // If image is too large, reduce quality
      final compressedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Reduce quality for compression
      );

      if (compressedImage != null) {
        return File(compressedImage.path);
      }

      return imageFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }

  /// Show image source selection dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Select Prescription Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Choose how to add the prescription image',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),

              // Camera option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () async {
                  try {
                    final file = await captureFromCamera();
                    if (context.mounted) {
                      Navigator.pop(context, file);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context, null);
                    }
                  }
                },
              ),

              // Gallery option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Upload Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Choose existing photo from gallery'),
                onTap: () async {
                  try {
                    final file = await pickFromGallery();
                    if (context.mounted) {
                      Navigator.pop(context, file);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context, null);
                    }
                  }
                },
              ),

              // Test Image option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.science,
                    color: Color(0xFFFF9800),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Use Test Image',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Select a sample prescription for testing',
                ),
                onTap: () async {
                  try {
                    final file = await showTestImageDialog(context);
                    if (context.mounted) {
                      Navigator.pop(context, file);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context, null);
                    }
                  }
                },
              ),

              const SizedBox(height: 16),

              // Cancel button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  /// Check if device has camera
  static Future<bool> hasCamera() async {
    try {
      if (_cameras == null) {
        await initialize();
      }
      return _cameras?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get camera resolution
  static Future<Size?> getCameraResolution() async {
    try {
      if (_cameras == null || _cameras!.isEmpty) {
        return null;
      }

      // Return resolution of first camera (usually rear camera)
      final camera = _cameras!.first;
      return Size(
        camera.sensorOrientation.toDouble(),
        camera.sensorOrientation.toDouble(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate image file
  static bool isValidImage(File imageFile) {
    final extension = path.extension(imageFile.path).toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp'];
    return validExtensions.contains(extension);
  }

  /// Get image metadata
  static Future<Map<String, dynamic>> getImageMetadata(File imageFile) async {
    try {
      final stat = await imageFile.stat();
      final size = await getImageSize(imageFile);

      return {
        'filePath': imageFile.path,
        'fileName': path.basename(imageFile.path),
        'fileSize': '${size.toStringAsFixed(2)} MB',
        'createdAt': stat.modified.toIso8601String(),
        'isValid': isValidImage(imageFile),
      };
    } catch (e) {
      return {'error': e.toString(), 'isValid': false};
    }
  }

  /// Check if storage permission is granted (simplified version)
  static Future<bool> hasStoragePermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    } else {
      // Check both permission types and accept either one
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;
      return (photosStatus.isGranted || photosStatus.isLimited) ||
          storageStatus.isGranted;
    }
  }

  /// Load a test prescription image from assets for testing
  static Future<File?> loadTestImage(
    BuildContext context,
    String assetPath,
  ) async {
    try {
      // Load image from assets
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = path.basename(assetPath);
      final File tempFile = File(path.join(tempDir.path, 'test_$fileName'));

      // Write bytes to temporary file
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      debugPrint('Error loading test image: $e');
      return null;
    }
  }

  /// Show test image selection dialog
  static Future<File?> showTestImageDialog(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Test Prescription',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a sample prescription for testing',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Test Image 1
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Color(0xFFFF9800),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Sample Prescription 1',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Hospital prescription with medications'),
                onTap: () async {
                  final file = await loadTestImage(
                    context,
                    'assets/test_images/sample_prescription_1.png',
                  );
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),

              // Test Image 2
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Color(0xFF9C27B0),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Sample Prescription 2',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Clinic prescription with handwritten notes',
                ),
                onTap: () async {
                  final file = await loadTestImage(
                    context,
                    'assets/test_images/sample_prescription_2.jpeg',
                  );
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Cancel button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  /// Show permission settings dialog
  static Future<void> showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs access to your photos to select prescription images. Please grant permission in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
