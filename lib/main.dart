import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/common/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure Firebase Auth settings for better error handling
  if (kDebugMode) {
    // Only for development - disable App Check in debug mode
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      forceRecaptchaFlow: false,
    );
  }

  // Load saved language
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('app_locale_code');
  final country = prefs.getString('app_locale_country');
  final initialLocale =
      code != null
          ? Locale(code, (country?.isEmpty ?? true) ? null : country)
          : null;

  runApp(MyApp(initialLocale: initialLocale));
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  const MyApp({super.key, this.initialLocale});

  static final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale_code', locale.languageCode);
    await prefs.setString('app_locale_country', locale.countryCode ?? '');
    localeNotifier.value = locale;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    MyApp.localeNotifier.value = widget.initialLocale;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: MyApp.localeNotifier,
      builder: (_, locale, __) {
        return MaterialApp(
          title: 'MediVault AI',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5DADE2),
              primary: const Color(0xFF5DADE2),
              secondary: const Color(0xFF4CAF50),
              surface: const Color(0xFFF5F5F5),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            fontFamily: 'Poppins',
            useMaterial3: true,
          ),
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('mr')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
