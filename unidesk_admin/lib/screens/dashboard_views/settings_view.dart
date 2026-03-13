import 'package:flutter/material.dart';
import 'package:unidesk_admin/main.dart';
import 'package:unidesk_admin/core/app_theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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
            _buildMaintenanceSection(context),
            const SizedBox(height: 16),
            const DataImportCard(),
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

  Widget _buildMaintenanceSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: const Text('Data Health Check', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Verify data integrity and fix common issues'),
        leading: const Icon(Icons.build_circle_outlined, color: Colors.orange),
        trailing: ElevatedButton(
          onPressed: () => _runHealthCheck(context),
          child: const Text('Run'),
        ),
      ),
    );
  }

  Future<void> _runHealthCheck(BuildContext context) async {
    // Basic implementation of the health check logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Running Health Check...')));
    // ... Health check logic from main_dashboard ...
  }
}

class DataImportCard extends StatefulWidget {
  const DataImportCard({super.key});

  @override
  State<DataImportCard> createState() => _DataImportCardState();
}

class _DataImportCardState extends State<DataImportCard> {
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data Import', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            TextField(controller: _batchController, decoration: const InputDecoration(labelText: 'Batch')),
            TextField(controller: _jsonController, maxLines: 5, decoration: const InputDecoration(labelText: 'JSON')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () {
                // Import logic
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }
}
