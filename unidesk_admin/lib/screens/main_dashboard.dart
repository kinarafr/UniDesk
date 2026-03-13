import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_login_screen.dart';
import '../core/app_theme.dart';
import '../widgets/ticket_notification_overlay.dart';
import 'dashboard_views/home_view.dart';
import 'dashboard_views/tickets_view.dart';
import 'dashboard_views/users_view.dart';
import 'dashboard_views/settings_view.dart';
import 'dart:async';
import '../widgets/admin_profile_button.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  StreamSubscription<QuerySnapshot>? _ticketSubscription;
  final List<Map<String, dynamic>> _activeNotifications = [];

  @override
  void initState() {
    super.initState();
    _listenForNewTickets();
  }

  void _listenForNewTickets() {
    _ticketSubscription = FirebaseFirestore.instance
        .collection('tickets')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt != null &&
                DateTime.now().difference(createdAt.toDate()).inSeconds < 10) {
              _showNotification(data, change.doc.id);
            }
          }
        }
      }
    });
  }

  void _showNotification(Map<String, dynamic> data, String docId) {
    if (!mounted) return;
    setState(() {
      _activeNotifications.add({'data': data, 'id': docId, 'key': UniqueKey()});
    });
  }

  void _removeNotification(Key key) {
    if (!mounted) return;
    setState(() {
      _activeNotifications.removeWhere((n) => n['key'] == key);
    });
  }

  @override
  void dispose() {
    _ticketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(theme, isDark),
          Expanded(
            child: Row(
              children: [
                _buildNavigationRail(isDark),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildNotificationStack(),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/logos/unidesk_logo.png', height: 40),
              const SizedBox(width: 12),
              Text('UniDesk', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? AppTheme.pastelBlue : theme.primaryColor)),
            ],
          ),
          const AdminProfileButton(),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(bool isDark) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
        NavigationRailDestination(icon: Icon(Icons.confirmation_number_outlined), selectedIcon: Icon(Icons.confirmation_number), label: Text('Tickets')),
        NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
        NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
      ],
      trailing: Expanded(child: Align(alignment: Alignment.bottomCenter, child: _buildLogoutButton(isDark))),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: IconButton(
        icon: const Icon(Icons.logout, color: Colors.red),
        onPressed: () => _confirmLogout(isDark),
      ),
    );
  }

  void _confirmLogout(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
            },
            child: const Text('Yes, Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0: return HomeView(onTabSwitch: (i) => setState(() => _selectedIndex = i));
      case 1: return const TicketsView();
      case 2: return const UsersView();
      case 3: return const SettingsView();
      default: return HomeView(onTabSwitch: (i) => setState(() => _selectedIndex = i));
    }
  }

  Widget? _buildNotificationStack() {
    if (_activeNotifications.isEmpty) return null;
    return Stack(
      children: _activeNotifications.map((n) => TicketNotificationOverlay(
        key: n['key'],
        ticketData: n['data'],
        ticketId: n['id'],
        onDismiss: () => _removeNotification(n['key']),
        onViewTicket: (data, id) => setState(() => _selectedIndex = 1),
      )).toList(),
    );
  }
}

