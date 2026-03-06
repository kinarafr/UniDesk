import 'package:flutter/material.dart';
import '../main.dart'; // To access UniDeskApp.themeNotifier
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListenableBuilder(
        listenable: UniDeskApp.settings,
        builder: (context, _) {
          final currentMode = UniDeskApp.settings.themeMode;
          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildSectionGroup(context, 'Appearance', [
                _buildSettingTile(
                  context,
                  title: 'App Theme',
                  subtitle: currentMode == ThemeMode.system
                      ? 'System Default'
                      : currentMode == ThemeMode.dark
                      ? 'Dark Mode'
                      : 'Light Mode',
                  icon: currentMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : currentMode == ThemeMode.light
                      ? Icons.light_mode_outlined
                      : Icons.brightness_auto_outlined,
                  iconColor: Colors.amber,
                  onTap: () => _showThemeSelector(context, currentMode),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionGroup(context, 'Accessibility', [
                _buildSettingSwitch(
                  context,
                  title: 'High Contrast',
                  subtitle: 'Enhance visibility',
                  icon: Icons.contrast,
                  iconColor: Colors.blue,
                  value: UniDeskApp.settings.isHighContrast,
                  onChanged: (bool value) {
                    UniDeskApp.settings.updateHighContrast(value);
                  },
                ),
                _buildSettingSwitch(
                  context,
                  title: 'Reduce Motion',
                  subtitle: 'Minimal animations',
                  icon: Icons.motion_photos_off_outlined,
                  iconColor: Colors.purple,
                  value: UniDeskApp.settings.isReduceMotion,
                  onChanged: (bool value) {
                    UniDeskApp.settings.updateReduceMotion(value);
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionGroup(context, 'Account & Feedback', [
                _buildSettingTile(
                  context,
                  title: 'Account Settings',
                  subtitle: 'Security and profile information',
                  icon: Icons.manage_accounts_outlined,
                  iconColor: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingTile(
                  context,
                  title: 'Report a Bug',
                  subtitle: 'Help us improve the app',
                  icon: Icons.bug_report_outlined,
                  iconColor: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bug report form coming soon!'),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionGroup(context, 'About', [
                _buildSettingTile(
                  context,
                  title: 'App Version',
                  subtitle: '1.0.0 (Beta)',
                  icon: Icons.info_outline,
                  iconColor: Colors.grey,
                ),
              ]),
              const SizedBox(height: 48),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionGroup(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              int idx = entry.key;
              Widget child = entry.value;
              return Column(
                children: [
                  child,
                  if (idx < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 70,
                      endIndent: 20,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
      onTap: onTap,
    );
  }

  Widget _buildSettingSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: iconColor,
      ),
    );
  }

  void _showThemeSelector(BuildContext context, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose Theme',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildThemeOption(
                context,
                title: 'Light Mode',
                icon: Icons.light_mode_outlined,
                mode: ThemeMode.light,
                isSelected: currentMode == ThemeMode.light,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                context,
                title: 'Dark Mode',
                icon: Icons.dark_mode_outlined,
                mode: ThemeMode.dark,
                isSelected: currentMode == ThemeMode.dark,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                context,
                title: 'System Default',
                icon: Icons.brightness_auto_outlined,
                mode: ThemeMode.system,
                isSelected: currentMode == ThemeMode.system,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        UniDeskApp.settings.updateThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.amber.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.amber : Colors.grey[600]),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.amber[800] : null,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}
