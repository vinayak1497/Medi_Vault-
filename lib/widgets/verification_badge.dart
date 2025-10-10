import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:health_buddy/screens/doctor/nmc_verification_screen.dart';
import 'package:health_buddy/services/auth_service.dart';

class VerificationBadge extends StatefulWidget {
  const VerificationBadge({super.key});

  @override
  State<VerificationBadge> createState() => _VerificationBadgeState();
}

class _VerificationBadgeState extends State<VerificationBadge> {
  bool _isVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        final DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child('doctors')
            .child(user.uid);

        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _isVerified =
                userData['verified'] == true || userData['nmcVerified'] == true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isVerified = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error checking verification status: $e');
      setState(() {
        _isVerified = false;
        _isLoading = false;
      });
    }
  }

  void _navigateToVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NMCVerificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isVerified ? null : _navigateToVerification,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isVerified ? Colors.green[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isVerified ? Colors.green[400]! : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isVerified ? Icons.verified : Icons.warning,
              size: 16,
              color: _isVerified ? Colors.green[700] : Colors.orange[700],
            ),
            const SizedBox(width: 4),
            Text(
              _isVerified ? 'Verified' : 'Not Verified',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isVerified ? Colors.green[700] : Colors.orange[700],
              ),
            ),
            if (!_isVerified) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: Colors.orange[700],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
