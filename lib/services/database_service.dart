import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user is authenticated and email is verified
  static bool get isAuthenticated {
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  /// Get current authenticated user
  static User? get currentUser {
    final user = _auth.currentUser;
    return (user != null && user.emailVerified) ? user : null;
  }

  /// Safely read data from database with authentication check
  static Future<DataSnapshot?> safeRead(String path) async {
    try {
      if (!isAuthenticated) {
        debugPrint('❌ Authentication required to read from: $path');
        return null;
      }

      final snapshot = await _database.child(path).get();
      debugPrint('✅ Successfully read from: $path');
      return snapshot;
    } catch (e) {
      debugPrint('❌ Error reading from $path: $e');
      return null;
    }
  }

  /// Safely write data to database with authentication check
  static Future<bool> safeWrite(String path, dynamic data) async {
    try {
      if (!isAuthenticated) {
        debugPrint('❌ Authentication required to write to: $path');
        return false;
      }

      await _database.child(path).set(data);
      debugPrint('✅ Successfully wrote to: $path');
      return true;
    } catch (e) {
      debugPrint('❌ Error writing to $path: $e');
      return false;
    }
  }

  /// Get user profile data safely
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final snapshot = await safeRead('users/${user.uid}');
      if (snapshot != null && snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
    }
    return null;
  }

  /// Get patient profile data safely
  static Future<Map<String, dynamic>?> getPatientProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final snapshot = await safeRead('patient_profiles/${user.uid}');
      if (snapshot != null && snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint('Error getting patient profile: $e');
    }
    return null;
  }

  /// Get family members safely
  static Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      // First try to get from patient_profiles
      var snapshot = await safeRead(
        'patient_profiles/${user.uid}/familyMembers',
      );

      if (snapshot == null || !snapshot.exists) {
        // Fallback to users table
        snapshot = await safeRead('users/${user.uid}/family_profiles');
      }

      if (snapshot != null && snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries
            .map(
              (e) => {
                'id': e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting family members: $e');
    }
    return [];
  }

  /// Add family member safely
  static Future<bool> addFamilyMember(Map<String, dynamic> memberData) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final memberId =
          _database
              .child('patient_profiles/${user.uid}/familyMembers')
              .push()
              .key;
      if (memberId != null) {
        return await safeWrite(
          'patient_profiles/${user.uid}/familyMembers/$memberId',
          memberData,
        );
      }
    } catch (e) {
      debugPrint('Error adding family member: $e');
    }
    return false;
  }

  /// Listen to authentication changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign out safely
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
    }
  }

  /// Show authentication error dialog
  static void showAuthError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Authentication Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Check if user needs to verify email
  static bool get needsEmailVerification {
    final user = _auth.currentUser;
    return user != null && !user.emailVerified;
  }

  /// Send email verification
  static Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
    } catch (e) {
      debugPrint('Error sending email verification: $e');
    }
    return false;
  }
}
