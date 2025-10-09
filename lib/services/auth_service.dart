import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

      print(
        '✅ User created successfully in Firebase Auth: ${userCredential.user?.uid}',
      );

      // Step 2: Send email verification
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        print('✅ Email verification sent successfully');
      }

      // Step 3: Save user data to database if provided
      if (userData != null && userCredential.user != null) {
        try {
          final userKey = email.replaceAll('.', ',').replaceAll('@', '_at_');
          final profileData = {
            ...userData,
            'email': email,
            'userType': userType,
            'uid': userCredential.user!.uid,
            'createdAt': ServerValue.timestamp,
            'verified': false,
          };

          await _database
              .child('${userType}_profiles')
              .child(userKey)
              .set(profileData);
          print('✅ User profile saved to database successfully');
        } catch (dbError) {
          print(
            '⚠️ Database save failed, but user account was created: $dbError',
          );
          // Don't throw here - user account was created successfully
          // The profile can be created later
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      // Delete the user if database save failed and user was created
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
          print('🧹 Cleaned up user account due to auth error');
        } catch (cleanupError) {
          print('⚠️ Failed to cleanup user account: $cleanupError');
        }
      }
      rethrow; // Re-throw the original Firebase exception
    } catch (e) {
      print('❌ Unexpected error during registration: $e');
      // Delete the user if it was created but something else failed
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
          print('🧹 Cleaned up user account due to unexpected error');
        } catch (cleanupError) {
          print('⚠️ Failed to cleanup user account: $cleanupError');
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
    await _auth.signOut();
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
}
