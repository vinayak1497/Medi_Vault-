import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, 'Home', context),
            _buildNavItem(1, Icons.chat_bubble_outline, 'Chat', context),
            _buildNavItem(2, Icons.camera_alt_rounded, 'Scanner', context),
            _buildNavItem(
              3,
              Icons.local_hospital_outlined,
              'AI Doctors',
              context,
            ), // Updated label
            _buildNavItem(4, Icons.account_balance, 'Schemes', context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    BuildContext context,
  ) {
    bool isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: isSelected ? 80 : 60,
        height: isSelected ? 80 : 60,
        margin: EdgeInsets.only(top: isSelected ? 0 : 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
