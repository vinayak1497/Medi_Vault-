import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/screens/doctor/nmc_verification_screen.dart';
import 'package:health_buddy/widgets/verification_badge.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _transcribedText = '';
  String _editedText = '';
  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _checkVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child('doctors')
            .child(user.uid);

        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          return userData['verified'] == true ||
              userData['nmcVerified'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking verification status: $e');
      return false;
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult:
            (result) => setState(() {
              _transcribedText = result.recognizedWords;
              _editedText = result.recognizedWords;
            }),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Processing image...';
      });

      try {
        // Process the image with ML Kit
        final inputImage = InputImage.fromFilePath(pickedFile.path);
        final textRecognizer = TextRecognizer(
          script: TextRecognitionScript.latin,
        );
        final RecognizedText recognizedText = await textRecognizer.processImage(
          inputImage,
        );

        String extractedText = '';
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            extractedText += '${line.text}\n';
          }
        }

        setState(() {
          _transcribedText = extractedText;
          _editedText = extractedText;
          _isProcessing = false;
        });

        // Show preview dialog
        _showPreviewDialog();
      } catch (e) {
        setState(() {
          _isProcessing = false;
          _processingMessage = 'Error processing image: $e';
        });
      }
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Preview & Edit'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit the extracted text:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController()..text = _editedText,
                        onChanged: (value) {
                          setState(() {
                            _editedText = value;
                          });
                        },
                        maxLines: 8,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Edit extracted text here...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Key Information:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    _buildKeyInfoField('Symptoms:', Icons.local_hospital),
                    _buildKeyInfoField('Diagnosis:', Icons.assignment),
                    _buildKeyInfoField('Medicines:', Icons.medication),
                    _buildKeyInfoField('Dosage:', Icons.format_list_numbered),
                    _buildKeyInfoField('Advice:', Icons.comment),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveToPatientRecord();
                  },
                  child: const Text('Save to Patient Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildKeyInfoField(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _saveToPatientRecord() async {
    // In a real implementation, you would save to a specific patient's record
    // For now, we'll just show a success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: const VerificationBadge()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome, Doctor!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a new session or scan a prescription',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Verification Status Card
            FutureBuilder<bool>(
              future: _checkVerificationStatus(),
              builder: (context, snapshot) {
                final isVerified = snapshot.data ?? false;
                return Card(
                  elevation: 2,
                  color: isVerified ? Colors.green[50] : Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          isVerified ? Icons.verified : Icons.warning,
                          color:
                              isVerified
                                  ? Colors.green[600]
                                  : Colors.orange[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVerified
                                    ? 'NMC Verified'
                                    : 'NMC Verification Pending',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isVerified
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                ),
                              ),
                              Text(
                                isVerified
                                    ? 'Your medical credentials have been verified'
                                    : 'Complete NMC verification to unlock all features',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isVerified)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const NMCVerificationScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Verify Now'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Start Recording Session button
            ElevatedButton.icon(
              onPressed: _isListening ? _stopListening : _startListening,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(
                _isListening ? 'Stop Recording' : 'Start Recording Session',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Transcribed text display
            if (_transcribedText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _transcribedText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Processing indicator
            if (_isProcessing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 10),
                  Text(_processingMessage),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // OR divider
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),

            // Scan Prescription button
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'Scan Prescription',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
