import 'package:flutter/material.dart';
import 'package:unidesk_admin/main.dart';
import 'package:unidesk_admin/core/app_theme.dart';
import 'package:unidesk_admin/services/backup_service.dart';
import 'package:unidesk_admin/services/restore_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildThemeSection(context),
            const SizedBox(height: 16),
            _buildAccessibilitySection(context),
            const SizedBox(height: 16),
            _buildBackupSection(context),
            const SizedBox(height: 16),
            _buildRestoreSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: UniDeskAdminApp.themeNotifier,
        builder: (context, currentMode, _) {
          final isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
          final primaryColor = isDark ? AppTheme.pastelBlue : Theme.of(context).primaryColor;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Display', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Choose light, dark, or system theme'),
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(
                    currentMode == ThemeMode.system ? Icons.brightness_auto : (isDark ? Icons.dark_mode : Icons.light_mode),
                    color: primaryColor,
                  ),
                ),
                trailing: DropdownButton<ThemeMode>(
                  value: currentMode,
                  onChanged: (newMode) => UniDeskAdminApp.themeNotifier.value = newMode!,
                  items: const [
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccessibilitySection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Accessibility', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: UniDeskAdminApp.highContrastNotifier,
            builder: (context, val, _) => SwitchListTile(
              title: const Text('High Contrast Mode'),
              value: val,
              onChanged: (v) => UniDeskAdminApp.highContrastNotifier.value = v,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: UniDeskAdminApp.reduceMotionNotifier,
            builder: (context, val, _) => SwitchListTile(
              title: const Text('Reduce Motion'),
              value: val,
              onChanged: (v) => UniDeskAdminApp.reduceMotionNotifier.value = v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: const Text('Backup Data', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Download a copy of all users, tickets, and notifications as a ZIP file'),
        leading: const Icon(Icons.cloud_download_outlined, color: Colors.blue),
        trailing: _isBackingUp 
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: () => _handleBackup(context),
              child: const Text('Download'),
            ),
      ),
    );
  }

  Widget _buildRestoreSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: const Text('Restore Data', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Upload a previous backup ZIP file to restore Firestore data'),
        leading: const Icon(Icons.cloud_upload_outlined, color: Colors.green),
        trailing: _isRestoring
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: () => _handleRestore(context),
              child: const Text('Upload'),
            ),
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    setState(() => _isBackingUp = true);
    try {
      await BackupService.exportAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup downloaded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    setState(() => _isRestoring = true);
    try {
      await RestoreService.importData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data restored successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }
}
