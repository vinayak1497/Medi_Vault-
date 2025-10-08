# Health Buddy Setup Guide

## Overview

Health Buddy is a comprehensive health management application built with Flutter. This guide will help you set up and configure the application properly.

## Prerequisites

Before setting up the project, ensure you have the following installed:
- Flutter SDK (3.7.2 or higher)
- Android Studio or VS Code with Flutter plugins
- Firebase account
- Google Cloud account for Maps and AI services

## Firebase Configuration

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app to your project:
   - Package name: `com.example.health_buddy`
   - Download `google-services.json` and place it in `android/app/`
3. Add an iOS app to your project (if needed):
   - Bundle ID: `com.example.healthBuddy`
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`
4. Enable the following Firebase services:
   - Authentication (Email/Password)
   - Realtime Database
   - Storage

## Google Maps Integration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if building for iOS)
4. Create an API key:
   - Go to "Credentials" > "Create Credentials" > "API Key"
   - Restrict the key to the Maps SDK
5. Add the API key to your project:
   - Android: Add to `android/app/src/main/AndroidManifest.xml`
   - iOS: Add to `ios/Runner/AppDelegate.swift`

## Gemini AI Integration

1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Create an API key for Gemini
3. Add the API key to `lib/utils/constants.dart`:
   ```dart
   static const String geminiApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

## Running the Application

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Troubleshooting

### Common Issues

1. **Missing google-services.json**: Ensure the file is in the correct location (`android/app/`)

2. **Google Maps not working**: 
   - Check that your API key is correctly configured
   - Ensure the Maps SDK is enabled in Google Cloud Console
   - Verify that your API key is unrestricted or properly restricted

3. **Firebase errors**:
   - Make sure you've enabled the required Firebase services
   - Check that your configuration files are properly placed

4. **Gemini API not responding**:
   - Verify your API key is correct
   - Check that you haven't exceeded usage limits
   - Ensure your API key has the necessary permissions

### Building for Release

For Android:
```bash
flutter build apk
```

For iOS:
```bash
flutter build ios
```

## Additional Configuration

### Environment Variables

For sensitive information, consider using environment variables:
- Create a `.env` file in the root directory
- Add your keys:
  ```
  GEMINI_API_KEY=your_actual_key_here
  GOOGLE_MAPS_API_KEY=your_actual_key_here
  ```
- Use the `flutter_config` package to read these values

### Customization

You can customize the app by modifying:
- Theme colors in `lib/utils/constants.dart`
- Default locations in `lib/utils/constants.dart`
- UI components in `lib/widgets/`
- Business logic in `lib/services/`

## Support

For issues or questions, please:
1. Check the existing issues on the repository
2. Create a new issue with detailed information
3. Include error messages and steps to reproduce