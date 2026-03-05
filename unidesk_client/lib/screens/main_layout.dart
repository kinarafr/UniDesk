import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'timetable_screen.dart';
import 'services_screen.dart';
import 'profile_screen.dart';
import 'my_requests_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateToTimetable: () => _navigateToTab(1)),
      const TimetableScreen(),
      ServicesScreen(onBackPressed: () => _navigateToTab(0)),
      MyRequestsScreen(onBackPressed: () => _navigateToTab(0)),
      const ProfileScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache key images for performance
    precacheImage(const AssetImage('assets/logos/NIBM_White.png'), context);
    precacheImage(const AssetImage('assets/logos/NIBM_Black.png'), context);
    precacheImage(const AssetImage('assets/images/web_dev.jpg'), context);
    precacheImage(const AssetImage('assets/images/cine.png'), context);
    precacheImage(const AssetImage('assets/images/motion.png'), context);
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.black;
    final navIconColor = Colors.white;

    return Scaffold(
      extendBody: true, // Allows body to extend behind bottom nav
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(child: _screens[_currentIndex]),

          // Floating Bottom Navigation Bar
          Positioned(
            left: 32,
            right: 32,
            bottom: 32,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: navBgColor,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    Icons.home_outlined,
                    Icons.home,
                    0,
                    navIconColor,
                  ),
                  _buildNavItem(
                    Icons.calendar_today_outlined,
                    Icons.calendar_today,
                    1,
                    navIconColor,
                  ),

                  // Center highlighted button for 'Requests'
                  GestureDetector(
                    onTap: () {
                      _navigateToTab(2);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: navBgColor, size: 28),
                    ),
                  ),

                  _buildNavItem(
                    Icons.confirmation_number_outlined,
                    Icons.confirmation_number,
                    3,
                    navIconColor,
                  ),
                  _buildNavItem(
                    Icons.person_outline,
                    Icons.person,
                    4,
                    navIconColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData unselectedIcon,
    IconData selectedIcon,
    int index,
    Color color,
  ) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: color.withOpacity(isSelected ? 1.0 : 0.5),
            size: 28,
          ),
          if (isSelected)
            Positioned(
              bottom: -8,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
      onPressed: () => _navigateToTab(index),
    );
  }
}
