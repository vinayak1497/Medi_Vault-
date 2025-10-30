import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Register user with email and password
  static Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String userType, // 'doctor' or 'patient'
    Map<String, dynamic>? userData,
  }) async {
    UserCredential? userCredential;

    try {
      // Step 1: Create user with email and password
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint(
        '✅ User created successfully in Firebase Auth: ${userCredential.user?.uid}',
      );

      // Step 2: Send email verification
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        debugPrint('✅ Email verification sent successfully');
      }

      // Step 3: Save user data to database if provided
      if (userData != null && userCredential.user != null) {
        try {
          debugPrint('🔐 User authenticated: ${userCredential.user!.uid}');
          debugPrint(
            '📧 Email verified: ${userCredential.user!.emailVerified}',
          );

          final profileData = {
            ...userData,
            'email': email,
            'userType': userType,
            'uid': userCredential.user!.uid,
            'createdAt': ServerValue.timestamp,
            'verified': false,
          };

          // Save to both users collection and specific profile collection for consistency
          final uid = userCredential.user!.uid;

          // 1. Save to main users collection (for authentication checks)
          debugPrint('💾 Saving to users/$uid');
          await _database.child('users').child(uid).set(profileData);

          // 2. Save to specific profile collection based on user type
          final specificPath =
              userType == 'doctor' ? 'doctor_profiles' : 'patient_profiles';
          debugPrint('� Saving to $specificPath/$uid');
          await _database.child(specificPath).child(uid).set(profileData);

          debugPrint(
            '✅ User profile saved to database successfully in both locations',
          );
        } catch (dbError) {
          debugPrint(
            '⚠️ Database save failed, but user account was created: $dbError',
          );
          if (dbError.toString().contains('permission')) {
            debugPrint('🚫 FIREBASE DATABASE RULES ISSUE:');
            debugPrint('   Go to Firebase Console > Realtime Database > Rules');
            debugPrint('   Update rules to allow authenticated users access');
            debugPrint(
              '   Required: {".read": "auth != null", ".write": "auth != null"}',
            );
          }
          // Don't throw here - user account was created successfully
          // The profile can be created later
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth error: ${e.code} - ${e.message}');
      // Delete the user if database save failed and user was created
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
          debugPrint('🧹 Cleaned up user account due to auth error');
        } catch (cleanupError) {
          debugPrint('⚠️ Failed to cleanup user account: $cleanupError');
        }
      }
      rethrow; // Re-throw the original Firebase exception
    } catch (e) {
      debugPrint('❌ Unexpected error during registration: $e');
      // Delete the user if it was created but something else failed
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
          debugPrint('🧹 Cleaned up user account due to unexpected error');
        } catch (cleanupError) {
          debugPrint('⚠️ Failed to cleanup user account: $cleanupError');
        }
      }
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during registration',
      );
    }
  }

  // Generate a temporary password for the user
  static String generateTemporaryPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    String password = '';
    for (int i = 0; i < 12; i++) {
      password += chars[(random + i) % chars.length];
    }
    return password;
  }

  // Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Check if email is valid
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile({
    required String email,
    required String userType,
  }) async {
    try {
      final userKey = email.replaceAll('.', ',').replaceAll('@', '_at_');
      final snapshot =
          await _database.child('${userType}_profiles').child(userKey).get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Update user verification status
  static Future<void> updateUserVerification({
    required String email,
    required String userType,
    required bool verified,
  }) async {
    try {
      final userKey = email.replaceAll('.', ',').replaceAll('@', '_at_');
      await _database.child('${userType}_profiles').child(userKey).update({
        'verified': verified,
      });
    } catch (e) {
      throw Exception('Failed to update verification: ${e.toString()}');
    }
  }

  // Get current user type from database
  static Future<String?> getCurrentUserType() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      // Check in doctors collection first
      final doctorSnapshot =
          await _database.child('doctors').child(user.uid).get();
      if (doctorSnapshot.exists) {
        final data = Map<String, dynamic>.from(doctorSnapshot.value as Map);
        return data['userType'] ?? 'doctor';
      }

      // Check in patient_profiles collection
      final patientSnapshot =
          await _database.child('patient_profiles').child(user.uid).get();
      if (patientSnapshot.exists) {
        final data = Map<String, dynamic>.from(patientSnapshot.value as Map);
        return data['userType'] ?? 'patient';
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting user type: $e');
      return null;
    }
  }

  // Get current user profile data
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        debugPrint('❌ No current user');
        return null;
      }

      if (!user.emailVerified) {
        debugPrint('❌ User email not verified');
        return null;
      }

      debugPrint('🔍 Looking for user profile for UID: ${user.uid}');

      // Check in users collection first (main profile data)
      try {
        final userSnapshot =
            await _database.child('users').child(user.uid).get();
        if (userSnapshot.exists) {
          debugPrint('✅ Found profile in users collection');
          return Map<String, dynamic>.from(userSnapshot.value as Map);
        }
      } catch (e) {
        debugPrint('❌ Error accessing users collection: $e');
      }

      // Check in patient_profiles collection
      try {
        final patientSnapshot =
            await _database.child('patient_profiles').child(user.uid).get();
        if (patientSnapshot.exists) {
          debugPrint('✅ Found profile in patient_profiles collection');
          return Map<String, dynamic>.from(patientSnapshot.value as Map);
        }
      } catch (e) {
        debugPrint('❌ Error accessing patient_profiles collection: $e');
      }

      // Check in doctor_profiles collection (corrected path)
      try {
        final doctorSnapshot =
            await _database.child('doctor_profiles').child(user.uid).get();
        if (doctorSnapshot.exists) {
          debugPrint('✅ Found profile in doctor_profiles collection');
          return Map<String, dynamic>.from(doctorSnapshot.value as Map);
        }
      } catch (e) {
        debugPrint('❌ Error accessing doctor_profiles collection: $e');
      }

      debugPrint('❌ No profile found in any collection');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }

  // Check if user is logged in and verified
  static Future<bool> isUserLoggedInAndVerified() async {
    try {
      final user = getCurrentUser();
      if (user == null) return false;

      // Check if user's email is verified
      if (!user.emailVerified) {
        debugPrint('❌ User email not verified');
        return false;
      }

      // Check if user has a valid profile in the database
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null) {
        debugPrint('❌ User profile not found in database');
        return false;
      }

      // Check if user has a valid user type
      final userType = await getCurrentUserType();
      if (userType == null || (userType != 'doctor' && userType != 'patient')) {
        debugPrint('❌ Invalid or missing user type: $userType');
        return false;
      }

      debugPrint('✅ User is properly logged in and verified');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      return false;
    }
  }

  // Clear invalid authentication state
  static Future<void> clearInvalidAuthState() async {
    try {
      final user = getCurrentUser();
      if (user != null) {
        // Check if user has valid profile
        final userProfile = await getCurrentUserProfile();
        final userType = await getCurrentUserType();

        if (userProfile == null ||
            userType == null ||
            (userType != 'doctor' && userType != 'patient')) {
          debugPrint('🧹 Clearing invalid authentication state');
          await signOut();
        }
      }
    } catch (e) {
      debugPrint('❌ Error clearing invalid auth state: $e');
      // Sign out anyway to be safe
      await signOut();
    }
  }
}
