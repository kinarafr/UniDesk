import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter/scheduler.dart';
import 'core/app_theme.dart';
import 'screens/admin_login_screen.dart';
import 'screens/main_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable offline persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const UniDeskAdminApp());
}

class UniDeskAdminApp extends StatelessWidget {
  const UniDeskAdminApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  // High contrast mode toggle
  static final ValueNotifier<bool> highContrastNotifier = ValueNotifier(false);

  // Reduce motion toggle
  static final ValueNotifier<bool> reduceMotionNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: reduceMotionNotifier,
          builder: (_, bool reduceMotion, _) {
            final pageTransitionsTheme = reduceMotion
                ? PageTransitionsTheme(
                    builders: {
                      for (var platform in TargetPlatform.values)
                        platform: const Fade50msPageTransitionsBuilder(),
                    },
                  )
                : null;

            var currentLightTheme = pageTransitionsTheme != null
                ? AppTheme.lightTheme.copyWith(
                    pageTransitionsTheme: pageTransitionsTheme,
                  )
                : AppTheme.lightTheme;
            var currentDarkTheme = pageTransitionsTheme != null
                ? AppTheme.darkTheme.copyWith(
                    pageTransitionsTheme: pageTransitionsTheme,
                  )
                : AppTheme.darkTheme;

            if (reduceMotion) {
              final reduction = ThemeData(
                splashFactory: NoSplash.splashFactory,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                expansionTileTheme: ExpansionTileThemeData(
                  expansionAnimationStyle: AnimationStyle(
                    duration: const Duration(milliseconds: 50),
                    reverseDuration: const Duration(milliseconds: 50),
                  ),
                ),
                // Material 3 Switch/Checkbox/Radio
                checkboxTheme: CheckboxThemeData(
                  fillColor: WidgetStateProperty.resolveWith((states) => null),
                ),
              );

              currentLightTheme = currentLightTheme.copyWith(
                splashFactory: reduction.splashFactory,
                hoverColor: reduction.hoverColor,
                highlightColor: reduction.highlightColor,
                expansionTileTheme: reduction.expansionTileTheme,
              );
              currentDarkTheme = currentDarkTheme.copyWith(
                splashFactory: reduction.splashFactory,
                hoverColor: reduction.hoverColor,
                highlightColor: reduction.highlightColor,
                expansionTileTheme: reduction.expansionTileTheme,
              );
            }

            // Apply global animation speed reduction
            timeDilation = reduceMotion ? 0.1 : 1.0;

            return MaterialApp(
              title: 'UniDesk Dashboard',
              theme: currentLightTheme,
              darkTheme: currentDarkTheme,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: reduceMotion),
                  child: child!,
                );
              },
              themeMode: currentMode,
              home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasData) {
                    return const MainDashboard();
                  }
                  return const AdminLoginScreen();
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Shows a dialog that respects the Reduce Motion setting.
  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor = Colors.black54,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) {
    if (reduceMotionNotifier.value) {
      return showGeneralDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor ?? Colors.black54,
        barrierLabel: barrierLabel ?? 'Dismiss',
        transitionDuration: const Duration(milliseconds: 50),
        pageBuilder: (context, animation, secondaryAnimation) {
          final widget = builder(context);
          return useSafeArea ? SafeArea(child: widget) : widget;
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
      );
    }
  }
}

class Fade50msPageTransitionsBuilder extends PageTransitionsBuilder {
  const Fade50msPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // We use a curve that completes very quickly to mimic 50ms
    // or at least feels like it.
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(
          0.0,
          0.2,
          curve: Curves.linear,
        ), // 20% of 300ms is ~60ms
      ),
      child: child,
    );
  }
}
