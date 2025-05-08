import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'chat_screen.dart';
// import 'my_stats_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutScreen(),
    const ChatScreen(),
    // const MyStatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Основной экран
          _screens[_selectedIndex],

          // Кастомная навигационная панель
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: _buildCustomNavBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E1E1E),
            Color(0xFF121212),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: -3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBarItem(0, Icons.home_outlined, Icons.home, 'Home'),
          _buildNavBarItem(1, Icons.fitness_center_outlined,
              Icons.fitness_center, 'Workout'),
          _buildNavBarItem(
              2, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[600],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
