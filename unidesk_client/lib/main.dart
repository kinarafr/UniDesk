import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/settings_controller.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final settingsController = SettingsController();
  await settingsController.loadSettings();

  runApp(UniDeskApp(settingsController: settingsController));
}

class UniDeskApp extends StatelessWidget {
  final SettingsController settingsController;

  const UniDeskApp({super.key, required this.settingsController});

  static late SettingsController settings;

  @override
  Widget build(BuildContext context) {
    settings = settingsController;

    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, _) {
        final isDarkMode =
            settingsController.themeMode == ThemeMode.dark ||
            (settingsController.themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        return MaterialApp(
          title: 'UniDesk',
          theme: AppTheme.getTheme(
            isDark: isDarkMode,
            isHighContrast: settingsController.isHighContrast,
            reduceMotion: settingsController.isReduceMotion,
          ),
          themeMode: settingsController.themeMode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return const MainLayout();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
