import 'package:flutter/material.dart';
import 'package:medivault_ai/services/ai_service.dart';
import 'package:medivault_ai/services/personalized_health_ai_service.dart';
import 'dart:async';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final AIService _aiService = AIService();
  final PersonalizedHealthAIService _personalizedAIService =
      PersonalizedHealthAIService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isPersonalized = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          'Hello! I\'m your MediVault AI assistant powered by Gemini. I can help you with health-related questions. What would you like to know?',
      'isUser': false,
      'timestamp': DateTime.now(),
    },
  ];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _checkPersonalizedAvailability();
  }

  Future<void> _checkPersonalizedAvailability() async {
    final hasHistory = await _personalizedAIService.hasPatientHistory();
    if (mounted) {
      setState(() {
        _isPersonalized = hasHistory;
        if (hasHistory) {
          // Add info message about personalized AI
          _messages.add({
            'text':
                '🌟 Personalized AI Mode: I\'ve detected your patient profile with medical history. I can now provide you with personalized health advice based on your prescriptions and medical information!',
            'isUser': false,
            'timestamp': DateTime.now(),
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty || _isSending) return;

    final message = _textController.text.trim();
    _textController.clear();

    // Add user message
    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isSending = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      String aiResponse;

      // Use personalized AI if available
      if (_isPersonalized) {
        aiResponse = await _personalizedAIService
            .sendPersonalizedMessage(message)
            .timeout(const Duration(seconds: 30));
      } else {
        // Fall back to regular AI service
        aiResponse = await _aiService
            .sendMessage(message)
            .timeout(const Duration(seconds: 30));
      }

      // Add AI response
      if (mounted) {
        setState(() {
          _messages.add({
            'text': aiResponse,
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isSending = false;
        });
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _messages.add({
            'text':
                'Sorry, the request timed out. Please check your internet connection and try again.',
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isSending = false;
        });
      }
    } catch (e) {
      String errorMessage = 'Sorry, I encountered an error: ${e.toString()}. ';
      if (e.toString().contains('API key')) {
        errorMessage +=
            'Please check your Gemini API key configuration in lib/utils/constants.dart. See README.md for instructions.';
      } else if (e.toString().contains('endpoint not found')) {
        errorMessage +=
            'The API endpoint may be incorrect. Please check lib/services/ai_service.dart for the correct model name.';
      } else {
        errorMessage += 'Please check your internet connection and try again.';
      }

      if (mounted) {
        setState(() {
          _messages.add({
            'text': errorMessage,
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isSending = false;
        });
      }
    }

    // Scroll to bottom
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Health AI Assistant'),
            if (_isPersonalized)
              Text(
                '🌟 Personalized Mode',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Loading indicator when sending
          if (_isSending)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text('AI is typing...'),
                ],
              ),
            ),
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1 * 255),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask a health-related question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'];
    final text = message['text'];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1 * 255),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
