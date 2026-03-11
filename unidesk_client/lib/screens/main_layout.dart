import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUserStatus('online');
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserStatus('offline');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateUserStatus('online');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _updateUserStatus('offline');
    }
  }

  Future<void> _updateUserStatus(String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'status': status});
      } catch (e) {
        // Ignore errors if document doesn't exist
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.black;
    const navIconColor = Colors.white;

    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          user != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
              : null,
      builder: (context, snapshot) {
        String? batch;
        if (snapshot.hasData && snapshot.data!.exists) {
          batch = (snapshot.data!.data() as Map<String, dynamic>)['batch'];
        }

        final List<Widget> screens = [
          HomeScreen(onNavigateToTimetable: () => _navigateToTab(1)),
          TimetableScreen(batch: batch),
          ServicesScreen(onBackPressed: () => _navigateToTab(0)),
          MyRequestsScreen(onBackPressed: () => _navigateToTab(0)),
          const ProfileScreen(),
        ];

        return Scaffold(
          extendBody: true, // Allows body to extend behind bottom nav
          body: Stack(
            children: [
              // Main Content
              Positioned.fill(child: screens[_currentIndex]),

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
      },
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
