import 'package:flutter/material.dart';
import 'package:health_buddy/screens/main_app/home_screen.dart';
import 'package:health_buddy/screens/main_app/scanner_screen.dart';
import 'package:health_buddy/screens/main_app/profile_screen.dart';
import 'package:health_buddy/screens/chat/chatbot_screen.dart';
import 'package:health_buddy/screens/doctors_near_me_screen.dart';
import 'package:health_buddy/screens/gov_schemes_screen.dart';
import 'package:health_buddy/screens/ai_doctors_screen.dart'; // Added AI Doctors screen
import 'package:health_buddy/widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    ChatbotScreen(),
    ScannerScreen(),
    AIDoctorsScreen(), // Replaced DoctorsNearMeScreen with AIDoctorsScreen
    GovSchemesScreen(),
  ];

  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to maintain bottom nav consistency
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
