# Code Examples: Personalized AI Assistant

## Example 1: Service Initialization

### In ChatbotScreen

```dart
// Check if patient has medical history on startup
Future<void> _checkPersonalizedAvailability() async {
  final hasHistory = await _personalizedAIService.hasPatientHistory();
  if (mounted) {
    setState(() {
      _isPersonalized = hasHistory;
      if (hasHistory) {
        // Add info message about personalized AI
        _messages.add({
          'text':
              '🌟 Personalized AI Mode: I\'ve detected your patient profile with medical history. '
              'I can now provide you with personalized health advice based on your prescriptions '
              'and medical information!',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      }
    });
  }
}
```

### Result
- Automatically detects if user has profile
- Shows badge and welcome message if personalized
- No user action needed

## Example 2: Fetching Prescriptions

### From PersonalizedHealthAIService

```dart
/// Fetch all prescriptions for the current patient
Future<List<Map<String, dynamic>>> _getPatientPrescriptions(
  String patientName,
  String patientId,
) async {
  try {
    debugPrint('🔍 Fetching prescriptions for patient: $patientName ($patientId)');

    final prescriptions = <Map<String, dynamic>>[];

    // Query Firebase prescriptions node
    final snapshot = await _database.ref('prescriptions').get();

    if (snapshot.exists) {
      final data = snapshot.value as Map?;
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            final prescription = Map<String, dynamic>.from(value);
            final rxPatientName = (prescription['patientName'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            final searchPatientName = patientName.toLowerCase().trim();

            // Match by patient name (case-insensitive)
            if (rxPatientName == searchPatientName) {
              prescription['id'] = key;
              prescriptions.add(prescription);
              debugPrint('✅ Found matching prescription: ${prescription['id']}');
            }
          }
        });
      }
    }

    debugPrint('📋 Total prescriptions found: ${prescriptions.length}');
    return prescriptions;
  } catch (e) {
    debugPrint('❌ Error fetching prescriptions: $e');
    return [];
  }
}
```

### What Happens
1. Connects to Firebase `prescriptions/` node
2. Iterates through all prescriptions
3. Matches by patient name (case-insensitive)
4. Returns list of matching prescriptions

## Example 3: Formatting Context for AI

### Prescription Context

```dart
/// Format prescriptions into readable context for AI prompt
String _formatPrescriptionsContext(
  List<Map<String, dynamic>> prescriptions,
  String patientName,
) {
  if (prescriptions.isEmpty) {
    return 'No prescriptions found for $patientName.';
  }

  final buffer = StringBuffer();
  buffer.writeln('PATIENT MEDICAL HISTORY FOR $patientName:');
  buffer.writeln('=' * 60);
  buffer.writeln('Total Prescriptions: ${prescriptions.length}\n');

  for (int i = 0; i < prescriptions.length; i++) {
    final rx = prescriptions[i];
    buffer.writeln('PRESCRIPTION ${i + 1}:');
    buffer.writeln('-' * 40);

    // Add prescription date
    if (rx['prescriptionDate'] != null) {
      buffer.writeln('Date: ${rx['prescriptionDate']}');
    }

    // Add doctor info
    if (rx['doctorName'] != null) {
      buffer.writeln('Doctor: ${rx['doctorName']}');
    }

    // Add diagnosis
    if (rx['diagnosis'] != null && (rx['diagnosis'] as String).isNotEmpty) {
      buffer.writeln('Diagnosis: ${rx['diagnosis']}');
    }

    // Add medications
    if (rx['medications'] != null && rx['medications'] is List) {
      buffer.writeln('\nMedications:');
      final medications = rx['medications'] as List;
      for (var med in medications) {
        if (med is Map) {
          final medName = med['name'] ?? 'Unknown';
          final dose = med['dosage'] ?? '';
          final frequency = med['frequency'] ?? '';
          final duration = med['duration'] ?? '';
          buffer.writeln('  • $medName $dose - $frequency for $duration');
        }
      }
    }

    // Add allergies if present
    if (rx['allergies'] != null && (rx['allergies'] as String).isNotEmpty) {
      buffer.writeln('\nAllergies: ${rx['allergies']}');
    }

    buffer.writeln('');
  }

  buffer.writeln('=' * 60);
  return buffer.toString();
}
```

### Output Format
```
PATIENT MEDICAL HISTORY FOR Vinayak Kundar:
============================================================
Total Prescriptions: 1

PRESCRIPTION 1:
----------------------------------------
Date: 2024-12-15
Doctor: Dr. Ashok Patil
Diagnosis: Infection
Chief Complaint: Fever, cough

Medications:
  • Amoxicillin 500mg - Twice daily for 7 days

Allergies: Aspirin
Precautions: Take with food
Follow-up: Contact if symptoms persist

============================================================
```

## Example 4: Building Enhanced Prompt

### For Gemini API

```dart
// Build the enhanced prompt with context
final contextPrompt = '''
You are a professional healthcare AI assistant specifically trained to provide personalized health advice to patients.

PATIENT CONTEXT:
Patient Name: $patientName

$prescriptionsContext
$medicalContext

PATIENT QUESTION: $userQuery

Based on the patient's medical history, prescriptions, and current health profile provided above, 
answer their health question in a friendly, personalized manner.

IMPORTANT GUIDELINES:
1. Always be empathetic and use the patient's name when appropriate
2. Reference specific medications, conditions, or allergies from their history when relevant
3. Provide context about their prescriptions when answering medication-related questions
4. Consider their past medical conditions and allergies in your response
5. Be concise but thorough
6. If the question is serious or urgent, recommend consulting their doctor
7. Always emphasize that you're providing general guidance, not medical diagnosis
8. For medication questions, specifically reference which doctor prescribed it and when

RESPONSE FORMAT:
- Start with a personalized greeting if appropriate
- Answer their specific question with context from their history
- If referencing prescriptions, mention the doctor's name and approximate date
- End with supportive advice or encouragement to follow up with their doctor if needed
''';
```

## Example 5: Sending to Gemini API

### Main Personalized Message Method

```dart
/// Send a personalized message using patient data context
Future<String> sendPersonalizedMessage(String userQuery) async {
  try {
    if (userQuery.trim().isEmpty) {
      return 'Please enter a valid question.';
    }

    // Step 1: Get current user
    final user = _auth.currentUser;
    if (user == null) {
      return 'Please log in to use personalized health assistant.';
    }

    debugPrint('🔐 Getting personalized response for user: ${user.uid}');

    // Step 2: Get patient profile
    final profileSnapshot = await _database.ref('users/${user.uid}').get();
    if (!profileSnapshot.exists) {
      return 'Patient profile not found. Please complete your profile setup.';
    }

    final profileData = profileSnapshot.value as Map?;
    if (profileData == null) {
      return 'Unable to retrieve patient profile.';
    }

    final patientName = profileData['fullName'] ?? 'Patient';

    // Step 3: Fetch data in parallel
    final prescriptions = await _getPatientPrescriptions(patientName, user.uid);
    final medicalInfo = await _getPatientMedicalInfo(user.uid);

    // Step 4: Format context
    final prescriptionsContext = _formatPrescriptionsContext(prescriptions, patientName);
    final medicalContext = _formatMedicalInfoContext(medicalInfo);

    // Step 5: Build enhanced prompt (as shown in Example 4)
    final contextPrompt = '''
You are a professional healthcare AI assistant...
[prompt building code]
''';

    debugPrint('📤 Sending personalized message to Gemini...');

    // Step 6: Send to Gemini API
    final Uri url = Uri.parse(_baseUrl);
    final response = await http
        .post(
          url,
          headers: _getAuthHeaders(),
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text': contextPrompt,
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    // Step 7: Parse response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null &&
          data['candidates'][0]['content']['parts'].isNotEmpty) {
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        debugPrint('✅ Personalized response received from Gemini');
        return text.trim();
      }
    }

    return 'Unable to generate personalized response. Please try again or consult with your healthcare provider.';
  } catch (e) {
    debugPrint('❌ Error in personalized message: $e');
    return 'I encountered an error while generating your personalized response. Please check your internet connection and try again.';
  }
}
```

## Example 6: Message Routing in ChatbotScreen

### Dynamic AI Service Selection

```dart
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

  _scrollToBottom();

  try {
    String aiResponse;
    
    // CHOOSE AI SERVICE BASED ON PERSONALIZATION
    if (_isPersonalized) {
      // Use personalized AI with patient context
      debugPrint('🌟 Using PersonalizedHealthAIService...');
      aiResponse = await _personalizedAIService
          .sendPersonalizedMessage(message)
          .timeout(const Duration(seconds: 30));
    } else {
      // Fall back to regular AI
      debugPrint('📱 Using regular AIService...');
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
          'text': 'Sorry, the request timed out. Please check your internet connection and try again.',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isSending = false;
      });
    }
  } catch (e) {
    // Error handling (as shown in previous code)
  }

  _scrollToBottom();
}
```

## Example 7: Real Patient Conversation Flow

### Step-by-Step Example

```
1. USER TYPES:
   "What medications am I taking?"

2. APP DETECTS:
   _isPersonalized = true (patient has profile)

3. APP FETCHES:
   Firebase prescriptions/ → Found: Amoxicillin 500mg
   Firebase users/{uid} → Found: Allergies: Aspirin, Peanuts

4. APP FORMATS CONTEXT:
   ```
   PATIENT MEDICAL HISTORY FOR Vinayak Kundar:
   ============================================================
   
   PRESCRIPTION 1:
   Date: 2024-12-15
   Doctor: Dr. Ashok Patil
   Diagnosis: Infection
   
   Medications:
     • Amoxicillin 500mg - Twice daily for 7 days
   
   Allergies: Aspirin, Peanuts
   Precautions: Take with food
   ```

5. APP BUILDS PROMPT:
   ```
   "You are a professional healthcare AI assistant...
   
    PATIENT CONTEXT:
    Patient Name: Vinayak Kundar
    
    PATIENT MEDICAL HISTORY FOR Vinayak Kundar:
    [formatted context from step 4]
    
    PATIENT MEDICAL PROFILE:
    Blood Group: B+
    Past Conditions: Nausea
    Allergies: Aspirin, Peanuts
    
    PATIENT QUESTION: What medications am I taking?
    
    Based on the patient's medical history..."
   ```

6. APP SENDS TO GEMINI:
   POST https://generativelanguage.googleapis.com/v1beta/...
   Content: [prompt from step 5]

7. GEMINI RESPONDS:
   ```
   "Hi Vinayak! 👋
   
    Based on your prescription from Dr. Ashok Patil, 
    you're currently taking:
    
    📋 **Amoxicillin 500mg**
    - Frequency: Twice daily
    - Duration: 7 days
    - Reason: To treat your infection
    
    ⚠️ Important Notes:
    - Take with food to avoid nausea (you have a history of this)
    - Avoid Aspirin (you're allergic) - don't take any pain relievers with it
    - Complete the full 7-day course even if you feel better
    
    Feel free to ask if you have any other questions! 💚"
   ```

8. UI DISPLAYS:
   Message appears in chat bubble with personalized content
```

## Example 8: Error Handling

### Graceful Degradation

```dart
// If personalization fails, fall back to regular AI
try {
  // Try to get personalized response
  final prescriptions = await _getPatientPrescriptions(name, uid);
  final medicalInfo = await _getPatientMedicalInfo(uid);
  
  if (prescriptions.isEmpty && medicalInfo.isEmpty) {
    // No data found, fall back to regular AI
    debugPrint('⚠️ No patient data found, using regular AI');
    return await _aiService.sendMessage(userQuery);
  }
  
  // Continue with personalized response
} catch (e) {
  // Firebase error or any other error
  debugPrint('❌ Personalization failed: $e');
  
  // Fall back to regular AI
  return await _aiService.sendMessage(userQuery);
}
```

## Example 9: Firebase Security Rules

### Recommended Setup

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        ".validate": "newData.hasChildren(['fullName', 'bloodGroup'])"
      }
    },
    "prescriptions": {
      "$id": {
        ".read": "root.child('users').child(auth.uid).exists()",
        ".write": "root.child('users').child(auth.uid).child('userType').val() === 'doctor'",
        ".validate": "newData.hasChildren(['patientName', 'doctorId'])"
      }
    }
  }
}
```

This ensures:
- Patients can read their own profile
- Doctors can write prescriptions
- Only authenticated users can read prescriptions
- Essential fields are always present

## Example 10: Usage in UI

### ChatbotScreen AppBar with Badge

```dart
AppBar(
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
```

---

These code examples show exactly how the personalized AI system works from start to finish! 🎉
