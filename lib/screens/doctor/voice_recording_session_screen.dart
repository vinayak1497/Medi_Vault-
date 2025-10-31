import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:health_buddy/models/prescription.dart';
import 'package:health_buddy/screens/doctor/simple_prescription_form_screen.dart';
import 'package:health_buddy/services/ai_service.dart';
import 'package:health_buddy/services/auth_service.dart';

/// Voice Recording Session Screen
/// Allows doctor to record audio, transcribe it to text, and convert to prescription
class VoiceRecordingSessionScreen extends StatefulWidget {
  const VoiceRecordingSessionScreen({super.key});

  @override
  State<VoiceRecordingSessionScreen> createState() =>
      _VoiceRecordingSessionScreenState();
}

class _VoiceRecordingSessionScreenState
    extends State<VoiceRecordingSessionScreen>
    with WidgetsBindingObserver {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AIService _aiService = AIService();

  // State variables
  bool _isRecording = false;
  bool _isProcessing = false;
  String _audioPath = '';
  String _transcribedText = '';
  Duration _recordingDuration = Duration.zero;
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeRecorder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioRecorder.dispose();
    super.dispose();
  }

  /// Initialize audio recorder
  Future<void> _initializeRecorder() async {
    try {
      final isRecorderReady = await _audioRecorder.hasPermission();
      if (!isRecorderReady) {
        if (!mounted) return;
        _showErrorSnackBar('Microphone permission is required');
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to initialize recorder: $e');
      Navigator.pop(context);
    }
  }

  /// Start recording audio
  Future<void> _startRecording() async {
    try {
      // Check permission
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showErrorSnackBar('Microphone permission denied');
        return;
      }

      // Get documents directory for storing audio
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${dir.path}/$fileName';

      // Start recording
      await _audioRecorder.start(
        RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _audioPath = filePath;
        _recordingDuration = Duration.zero;
        _transcribedText = '';
      });

      // Update timer every 100ms
      _updateTimer();
    } catch (e) {
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  /// Update recording duration
  void _updateTimer() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration =
              _recordingDuration + const Duration(milliseconds: 100);
        });
        _updateTimer();
      }
    });
  }

  /// Stop recording audio
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _audioPath = path ?? '';
      });

      if (_audioPath.isNotEmpty) {
        // Automatically transcribe
        await _transcribeAudio();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  /// Transcribe audio to text using Gemini
  Future<void> _transcribeAudio() async {
    if (_audioPath.isEmpty) {
      _showErrorSnackBar('No audio file found');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Transcribing audio...';
    });

    try {
      final file = File(_audioPath);
      if (!await file.exists()) {
        _showErrorSnackBar('Audio file not found');
        setState(() => _isProcessing = false);
        return;
      }

      // Use AIService to transcribe audio
      final result = await _aiService.transcribeAudio(_audioPath);

      if (!mounted) return;

      final transcribedText = result['text'] as String?;
      final error = result['error'] as String?;

      if (error != null) {
        _showErrorSnackBar('Transcription error: $error');
        setState(() => _isProcessing = false);
        return;
      }

      if (transcribedText == null || transcribedText.trim().isEmpty) {
        _showErrorSnackBar('No audio detected. Please try again.');
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _transcribedText = transcribedText;
        _processingMessage = 'Formatting prescription...';
      });

      // Format the transcribed text
      await _formatTranscription();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Transcription failed: $e');
      setState(() => _isProcessing = false);
    }
  }

  /// Format transcribed text into prescription format
  Future<void> _formatTranscription() async {
    if (_transcribedText.isEmpty) {
      _showErrorSnackBar('No transcription available');
      setState(() => _isProcessing = false);
      return;
    }

    setState(() {
      _processingMessage = 'Finalizing prescription...';
    });

    try {
      // Format using AI service
      final formatted = await _aiService.normalizePrescriptionText(
        _transcribedText,
      );

      final finalText = formatted.isNotEmpty ? formatted : _transcribedText;

      // Create prescription object
      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        _showErrorSnackBar('Please login to continue');
        setState(() => _isProcessing = false);
        return;
      }

      final prescription = Prescription(
        doctorId: currentUser.uid,
        createdAt: DateTime.now(),
        originalImagePath: _audioPath,
        extractedText: finalText,
        status: PrescriptionStatus.draft,
      );

      if (!mounted) return;

      // Clean up audio file
      try {
        await File(_audioPath).delete();
      } catch (e) {
        debugPrint('Failed to delete audio file: $e');
      }

      setState(() => _isProcessing = false);

      // Navigate to prescription form
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  SimplePrescriptionFormScreen(prescription: prescription),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Formatting failed: $e');
      setState(() => _isProcessing = false);
    }
  }

  /// Format duration display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (_isRecording) {
          await _stopRecording();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          title: const Text(
            'Voice Recording Session',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Recording Status Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2E7D32),
                        const Color(0xFF43A047),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Recording indicator
                      if (_isRecording)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const SizedBox.expand(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        Icon(
                          _transcribedText.isNotEmpty
                              ? Icons.check_circle
                              : Icons.mic,
                          size: 48,
                          color: Colors.white,
                        ),
                      const SizedBox(height: 16),
                      // Recording status text
                      Text(
                        _isRecording
                            ? 'Recording in Progress'
                            : _transcribedText.isNotEmpty
                            ? 'Transcription Complete'
                            : 'Ready to Record',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Duration or status
                      Text(
                        _isRecording
                            ? _formatDuration(_recordingDuration)
                            : _isProcessing
                            ? _processingMessage
                            : _transcribedText.isNotEmpty
                            ? 'Ready to proceed'
                            : 'Start recording to begin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Record/Stop Button
              if (!_isProcessing) ...[
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor:
                        _isRecording ? Colors.red : const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: Icon(
                    _isRecording ? Icons.stop_circle : Icons.mic,
                    size: 28,
                  ),
                  label: Text(
                    _isRecording ? 'Stop Recording' : 'Start Recording',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Processing indicator
              if (_isProcessing) ...[
                Column(
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _processingMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // Transcribed text section
              if (_transcribedText.isNotEmpty && !_isProcessing) ...[
                const SizedBox(height: 16),
                const Text(
                  'Transcribed Text',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Text(
                    _transcribedText,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Proceed button
                ElevatedButton.icon(
                  onPressed: () async {
                    // Navigate to prescription form
                    final currentUser = AuthService.getCurrentUser();
                    if (currentUser == null) {
                      _showErrorSnackBar('Please login to continue');
                      return;
                    }

                    final prescription = Prescription(
                      doctorId: currentUser.uid,
                      createdAt: DateTime.now(),
                      originalImagePath: _audioPath,
                      extractedText: _transcribedText,
                      status: PrescriptionStatus.draft,
                    );

                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SimplePrescriptionFormScreen(
                              prescription: prescription,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 24),
                  label: const Text(
                    'Proceed to Prescription Form',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                // Record Again button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _transcribedText = '';
                      _recordingDuration = Duration.zero;
                      _audioPath = '';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Record Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],

              // Tips section
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recording Tips',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Speak clearly and at a moderate pace\n'
                      '• Minimize background noise\n'
                      '• Include patient details, diagnosis, and medicines\n'
                      '• Take a breath between sentences\n'
                      '• You can review and edit before saving',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
