import 'package:flutter/material.dart';
import '../main.dart'; // To access UniDeskApp.themeNotifier
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: UniDeskApp.themeNotifier,
        builder: (context, currentMode, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            children: [
              _buildSectionHeader('Appearance'),
              ListTile(
                title: const Text('App Theme'),
                subtitle: Text(
                  currentMode == ThemeMode.system
                      ? 'System Default'
                      : currentMode == ThemeMode.dark
                      ? 'Dark Mode'
                      : 'Light Mode',
                ),
                trailing: PopupMenuButton<ThemeMode>(
                  initialValue: currentMode,
                  onSelected: (ThemeMode newMode) {
                    UniDeskApp.themeNotifier.value = newMode;
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<ThemeMode>>[
                        const PopupMenuItem<ThemeMode>(
                          value: ThemeMode.light,
                          child: Text('Light Mode'),
                        ),
                        const PopupMenuItem<ThemeMode>(
                          value: ThemeMode.dark,
                          child: Text('Dark Mode'),
                        ),
                        const PopupMenuItem<ThemeMode>(
                          value: ThemeMode.system,
                          child: Text('System Default'),
                        ),
                      ],
                  icon: Icon(
                    currentMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : currentMode == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.brightness_auto,
                  ),
                ),
              ),
              const Divider(),

              _buildSectionHeader('Account'),
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text('Account Settings'),
                subtitle: const Text('Change password or update email'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen(),
                    ),
                  );
                },
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(),

              _buildSectionHeader('Feedback'),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Report a Bug'),
                subtitle: const Text('Experience an issue with the app?'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bug report form coming soon!'),
                    ),
                  );
                },
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(),

              _buildSectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0 (Beta)'),
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
