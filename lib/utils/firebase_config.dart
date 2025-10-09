import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const String projectId = 'health-buddy-app-77329';
  static const String authDomain = 'health-buddy-app-77329.firebaseapp.com';
  static const String databaseUrl =
      'https://health-buddy-app-77329-default-rtdb.firebaseio.com';
  static const String storageBucket =
      'health-buddy-app-77329.firebasestorage.app';

  // Firebase configuration for web/mobile
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpZHThBoCYtZr4Cq6hTP4LUp8oDAOAGXc',
    appId: '1:905527350533:android:bd2019eb3c17ebc812136c',
    messagingSenderId: '905527350533',
    projectId: projectId,
    authDomain: authDomain,
    databaseURL: databaseUrl,
    storageBucket: storageBucket,
  );
}
