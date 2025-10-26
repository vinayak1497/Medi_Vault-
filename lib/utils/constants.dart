class Constants {
  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946;
  static const double defaultZoom = 12.0;

  // Your Gemini API key for Vision API access
  // NOTE: We recommend storing this securely (env/remote config).
  // Project: projects/770304478127 (Medi_Buddy_real)
  static const String apiKey = "AIzaSyB3nik48KUeXleFifmlfqqojn2FtV4jYYY";

  // Gemini API Configuration
  // Single endpoint: v1beta/models/gemini-2.0-flash:generateContent
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 60);
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration rateLimitDelay = Duration(milliseconds: 500);
  // Client-side throttle to avoid hitting server-side per-minute quota
  static const int maxRequestsPerMinute = 2; // keep low to prevent 429

  // App Info
  static const String appName = 'Health Buddy';
}
