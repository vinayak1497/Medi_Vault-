# Setting up Gemini API for Health Buddy

## How to get a free Gemini API key

1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Click on "Get API key" 
4. Create a new API key for your project
5. Copy the API key

## How to configure the API key in the app

1. Open `lib/utils/constants.dart`
2. Replace `'YOUR_GEMINI_API_KEY_HERE'` with your actual API key:
   ```dart
   static const String geminiApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

## Using the free tier

Google offers a free tier for Gemini API with limited usage:
- Up to 60 requests per minute
- Up to 1500 requests per day

For development and testing purposes, this should be sufficient.

## Note on security

In a production app, you should never hardcode API keys in the source code. Instead:
1. Use environment variables
2. Store keys on a secure backend server
3. Implement proper authentication

For this demo app, we're using direct API key integration for simplicity.