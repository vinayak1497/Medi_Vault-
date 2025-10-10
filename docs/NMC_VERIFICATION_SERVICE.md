# NMC Doctor Verification Service

A complete Flutter service integration for verifying doctor credentials through the National Medical Commission (NMC) API using RapidAPI.

## 🚀 Features

- **Complete API Integration**: Ready-to-use service with RapidAPI NMC verification
- **Null Safety**: Full Dart 3+ null safety support
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Input Validation**: Built-in validation for all input parameters
- **Service Status**: Check if the verification service is available
- **UI Components**: Ready-to-use Flutter screens for verification
- **Examples**: Complete usage examples and documentation

## 📋 API Details

- **Provider**: RapidAPI NMC Doctor Verification
- **Base URL**: `https://mci-nmc-doctor-verification.p.rapidapi.com`
- **Endpoint**: `/verify_with_source`
- **Method**: POST
- **Authentication**: RapidAPI Key + Application ID

### Required Headers
```dart
{
  'Content-Type': 'application/json',
  'x-rapidapi-key': '48879e077emshf88696708204d88p189a60jsnf35db2bfa4ea',
  'x-rapidapi-host': 'mci-nmc-doctor-verification.p.rapidapi.com',
  'application-id': 'default-application_11124376',
}
```

## 🏗️ Project Structure

```
lib/
├── models/
│   └── nmc_verification.dart          # Data models for requests/responses
├── services/
│   └── nmc_verification_service.dart  # Main service class
└── screens/
    └── doctor/
        ├── nmc_verification_screen.dart         # User interface
        └── nmc_verification_example_screen.dart # Usage examples
```

## 📦 Dependencies

Make sure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.2.2  # For API requests
  flutter: ^3.7.2
```

## 🔧 Usage

### Basic Usage

```dart
import 'package:health_buddy/services/nmc_verification_service.dart';

// Simple verification with required fields only
final result = await NMCVerificationService.verifyDoctor(
  fullName: 'Dr. John Doe',
  registrationNumber: 'MH12345',
  state: 'Maharashtra',
);

if (result.isVerified) {
  print('✅ Doctor is verified!');
  print('Name: ${result.doctorDetails?.fullName}');
  print('Qualification: ${result.doctorDetails?.qualification}');
} else {
  print('❌ Verification failed: ${result.message}');
}
```

### Detailed Verification

```dart
// Verification with all optional fields for better accuracy
final result = await NMCVerificationService.verifyDoctor(
  fullName: 'Dr. Priya Sharma',
  registrationNumber: 'KA67890',
  state: 'Karnataka',
  fatherName: 'Mr. Suresh Sharma',        // Optional
  specialization: 'Cardiology',           // Optional
  yearOfRegistration: '2018',             // Optional
);
```

### Input Validation

```dart
// Validate input before making API call
final validationError = NMCVerificationService.validateInput(
  fullName: fullNameController.text,
  registrationNumber: registrationController.text,
  state: selectedState,
);

if (validationError != null) {
  // Show error message to user
  showSnackBar(validationError);
  return;
}
```

### Service Availability Check

```dart
// Check if the service is available before making requests
final isAvailable = await NMCVerificationService.isServiceAvailable();

if (!isAvailable) {
  showSnackBar('Verification service is currently unavailable');
  return;
}
```

## 🎨 UI Integration

### Adding to Doctor Dashboard

The NMC verification is already integrated into the doctor home screen as a card:

```dart
// In doctor_home_screen.dart
Card(
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NMCVerificationScreen(),
        ),
      );
    },
    child: // ... card content
  ),
)
```

### Standalone Verification Screen

Navigate to the verification screen from anywhere in your app:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NMCVerificationScreen(),
  ),
);
```

## 📊 Response Format

### Successful Verification Response

```dart
NMCVerificationResult(
  isVerified: true,
  status: 'verified',
  message: 'Doctor verification successful',
  doctorDetails: DoctorDetails(
    fullName: 'Dr. John Doe',
    registrationNumber: 'MH12345',
    state: 'Maharashtra',
    stateMedicalCouncil: 'Maharashtra Medical Council',
    registrationDate: '2018-01-15',
    qualification: 'MBBS, MD',
    fatherName: 'Richard Doe',
    address: '123 Medical Street, Mumbai',
    isActive: true,
  ),
)
```

### Failed Verification Response

```dart
NMCVerificationResult(
  isVerified: false,
  status: 'not_found',
  message: 'No doctor found with the provided credentials',
  errorCode: 'DOCTOR_NOT_FOUND',
)
```

## ⚠️ Error Handling

The service handles various error scenarios:

### Network Errors
- **Connection timeout**: 30-second timeout with user-friendly message
- **No internet**: Detects network issues and provides guidance
- **Server errors**: Handles 5xx errors with retry suggestions

### API Errors
- **400 Bad Request**: Invalid input parameters
- **401 Unauthorized**: API key issues (handled internally)
- **429 Rate Limited**: Too many requests warning
- **404 Not Found**: Service endpoint issues

### Input Validation Errors
- **Empty fields**: Required field validation
- **Invalid state**: Must be valid Indian state
- **Short inputs**: Minimum length requirements

## 🏛️ Indian States Support

The service includes all Indian states and union territories:

```dart
// Available in IndianStates.states
[
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
  'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh',
  'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra',
  'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
  'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  // Union Territories
  'Andaman and Nicobar Islands', 'Chandigarh', 
  'Dadra and Nagar Haveli and Daman and Diu', 'Delhi',
  'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
]
```

## 🧪 Testing

Run the example screen to test all service features:

1. Open the NMC Verification Screen
2. Tap the code icon (</>) in the app bar
3. Try different examples:
   - Simple verification
   - Detailed verification  
   - Input validation
   - Service availability check

## 🔒 Security Notes

- API keys are included in the service for demonstration
- In production, consider storing sensitive keys securely
- The service uses HTTPS for secure data transmission
- No sensitive data is stored locally

## 🎯 Integration Steps

1. **Copy Files**: Add the service files to your project
   ```
   lib/models/nmc_verification.dart
   lib/services/nmc_verification_service.dart
   lib/screens/doctor/nmc_verification_screen.dart
   ```

2. **Add Dependencies**: Ensure `http: ^1.2.2` is in pubspec.yaml

3. **Import Service**: Import where needed
   ```dart
   import 'package:health_buddy/services/nmc_verification_service.dart';
   ```

4. **Use Service**: Call the verification method
   ```dart
   final result = await NMCVerificationService.verifyDoctor(...);
   ```

## 📱 Flutter Button Integration Example

```dart
ElevatedButton(
  onPressed: () async {
    // Show loading
    setState(() => isLoading = true);
    
    try {
      final result = await NMCVerificationService.verifyDoctor(
        fullName: fullNameController.text,
        registrationNumber: regNumberController.text,
        state: selectedState,
      );
      
      if (result.isVerified) {
        // Success handling
        showSuccessDialog('Doctor verified successfully!');
      } else {
        // Failure handling
        showErrorDialog(result.message);
      }
      
    } catch (e) {
      showErrorDialog('Verification failed: $e');
    } finally {
      setState(() => isLoading = false);
    }
  },
  child: isLoading 
    ? CircularProgressIndicator() 
    : Text('Verify Doctor'),
)
```

## 🚀 Ready to Use!

The NMC verification service is now fully integrated into your Health Buddy app:

1. ✅ **Service Class**: `NMCVerificationService` with all methods
2. ✅ **Data Models**: `NMCVerificationRequest`, `NMCVerificationResult`, `DoctorDetails`
3. ✅ **UI Screen**: Complete verification interface with form validation
4. ✅ **Integration**: Added to doctor dashboard home screen
5. ✅ **Examples**: Interactive examples screen for testing
6. ✅ **Error Handling**: Comprehensive error management
7. ✅ **Documentation**: Complete usage guide

Navigate to **Doctor Dashboard → Home → NMC Verification** to start using the service!

## 🛠️ Troubleshooting

### Common Issues

1. **BAD_REQUEST Error**: Check input validation and ensure all required fields are filled
2. **Network Error**: Verify internet connection and API endpoint availability
3. **Authentication Error**: API key and application ID are pre-configured
4. **State Not Found**: Ensure the state name exactly matches the Indian states list

### Debug Mode

The service includes extensive logging. Check your Flutter debug console for detailed request/response information when issues occur.

---

**Ready to verify doctor credentials with confidence! 🏥✅**