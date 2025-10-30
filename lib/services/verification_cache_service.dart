import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service to cache verification status throughout the app session
class VerificationCacheService {
  static final VerificationCacheService _instance =
      VerificationCacheService._internal();

  // Private cache variables
  bool? _cachedVerificationStatus;
  bool _isInitialized = false;

  VerificationCacheService._internal();

  factory VerificationCacheService() {
    return _instance;
  }

  /// Initialize verification cache when app starts
  /// This should be called once in the app's main or splash screen
  Future<void> initializeCache() async {
    if (_isInitialized) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _fetchAndCacheVerificationStatus();
        _isInitialized = true;
        debugPrintVerification('✅ Verification cache initialized');
      }
    } catch (e) {
      debugPrintVerification('❌ Error initializing cache: $e');
    }
  }

  /// Fetch and cache verification status from Firebase
  Future<void> _fetchAndCacheVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _cachedVerificationStatus = false;
        return;
      }

      final snapshot =
          await FirebaseDatabase.instance.ref('doctors/${user.uid}').get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final verified = userData['verified'] == true;
        final nmcVerified = userData['nmcVerified'] == true;

        debugPrintVerification(
          '📊 Firebase verification fields: verified=$verified, nmcVerified=$nmcVerified',
        );

        _cachedVerificationStatus = verified || nmcVerified;
      } else {
        _cachedVerificationStatus = false;
      }

      debugPrintVerification(
        '📦 Verification status cached: $_cachedVerificationStatus',
      );
    } catch (e) {
      debugPrintVerification('❌ Error fetching verification status: $e');
      _cachedVerificationStatus = false;
    }
  }

  /// Get cached verification status (returns immediately, no Firebase call)
  bool getVerificationStatus() {
    return _cachedVerificationStatus ?? false;
  }

  /// Force refresh verification status (only when needed)
  Future<void> refreshVerificationStatus() async {
    await _fetchAndCacheVerificationStatus();
    debugPrintVerification('🔄 Verification status refreshed');
  }

  /// Clear cache on logout
  void clearCache() {
    _cachedVerificationStatus = null;
    _isInitialized = false;
    debugPrintVerification('🗑️  Verification cache cleared');
  }

  /// Check if cache is initialized
  bool isInitialized() => _isInitialized;

  /// Debug print helper
  static void debugPrintVerification(String message) {
    print('🔐 [VerificationCache] $message');
  }
}
