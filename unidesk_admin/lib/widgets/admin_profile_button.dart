import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../screens/admin_login_screen.dart';

class AdminProfileButton extends StatelessWidget {
  const AdminProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.pastelBlue : Theme.of(context).primaryColor;

    return PopupMenuButton<String>(
      tooltip: 'Profile',
      child: CircleAvatar(
        backgroundColor: primaryColor.withOpacity(0.1),
        child: Text(
          user?.email?.substring(0, 1).toUpperCase() ?? 'A',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            user?.email ?? 'Admin',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (val) async {
        if (val == 'logout') {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            );
          }
        }
      },
    );
  }
}
