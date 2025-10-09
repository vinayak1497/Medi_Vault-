# Health Buddy

A comprehensive health management Flutter application with AI chatbot, doctor locator, and government schemes information.

## Features

- User authentication and profile management
- AI-powered health chatbot using Google Gemini API
- AI-powered doctor finder with location services
- Doctor locator with Google Maps integration
- Government health schemes information
- Medical record scanning and OCR
- Appointment scheduling
- Medication reminders

## Getting Started

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Android Studio or VS Code
- Firebase account
- Google Maps API key
- Google Gemini API key

### Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd health_buddy
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Create a new Firebase project at https://console.firebase.google.com/
   - Add an Android app to your Firebase project
   - Download the `google-services.json` file and place it in `android/app/`
   - Add an iOS app to your Firebase project (if needed)
   - Download the `GoogleService-Info.plist` file and place it in `ios/Runner/`

4. **Google Maps Setup:**
   - Get a Google Maps API key from Google Cloud Console
   - Enable the Maps SDK for Android and/or iOS
   - Add your API key to:
     - Android: `android/app/src/main/AndroidManifest.xml`
     - iOS: `ios/Runner/AppDelegate.swift`

5. **Gemini API Setup:**
   - Go to https://aistudio.google.com/
   - Sign in with your Google account
   - Create a new API key from the "API Key" section
   - Copy the API key
   - Add your API key to `lib/utils/constants.dart`:
     ```dart
     static const String apiKey = 'YOUR_ACTUAL_GEMINI_API_KEY_HERE';
     ```
   - **Important**: Never commit your actual API key to version control

6. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/              # Data models
├── screens/             # UI screens
│   ├── ai_doctors_screen.dart     # AI-powered doctor finder
│   ├── doctors_near_me_screen.dart # Original map-based doctor locator
├── services/            # Business logic and API services
├── utils/               # Utility functions and constants
└── widgets/             # Reusable UI components
```

## Dependencies

- `firebase_core`: Firebase core functionality
- `firebase_auth`: User authentication
- `firebase_database`: Realtime database
- `firebase_storage`: File storage
- `google_maps_flutter`: Google Maps integration
- `geolocator`: Location services
- `http`: HTTP client for API requests
- `url_launcher`: Opening URLs
- `image_picker`: Picking images from gallery/camera
- `google_mlkit_text_recognition`: OCR functionality

## New Features

### AI Doctor Finder
The app now includes an AI-powered doctor finder that uses your current location to find nearby doctors. This feature:
- Automatically detects your current location
- Uses the Gemini API to find relevant doctors near you
- Displays doctor information in an easy-to-read card format
- Includes doctor names, specialties, addresses, contact information, and distances

To use this feature:
1. Navigate to the "AI Doctors" tab in the bottom navigation
2. Grant location permissions when prompted
3. The app will automatically find doctors near you
4. View doctor details in the card-based list

## Troubleshooting

### API Key Issues
If you're seeing "API key configuration" errors:
1. Make sure you have created a valid Gemini API key at https://aistudio.google.com/
2. Ensure the API key is correctly placed in `lib/utils/constants.dart`
3. Check that the API key has not expired
4. Verify that you have enabled the Generative Language API in Google Cloud Console

### Common Error Messages
- "API key is missing": The apiKey field in constants.dart is empty
- "API key authentication failed": The API key is invalid or expired
- "Access forbidden": The API key doesn't have proper permissions

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.