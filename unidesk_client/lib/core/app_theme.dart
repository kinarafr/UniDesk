import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class AppTheme {
  // Navigation Helper
  static Future<T?> showAppModalBottomSheet<T>({
    required BuildContext context,
    required Widget builder,
    bool isScrollControlled = true,
  }) {
    final reduceMotion = UniDeskApp.settings.isReduceMotion;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      enableDrag: !reduceMotion,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      // In Flutter 3.x, some animations can be skipped by setting the theme
      // but for specific ModalBottomSheet animation, duration is hardcoded.
      // We can use a custom PageRoute if needed, but for now enableDrag is a start.
      // Actually, we can use a custom transition builder or just zero duration if we use showGeneralDialog.
      builder: (context) => builder,
    );
  }

  // Light Theme Colors
  static const Color primaryLight = Colors.black;
  static const Color backgroundLight = Color(
    0xFFF3F4F6,
  ); // Off-white/gray background
  static const Color surfaceLight = Colors.white;
  static const Color textLight = Colors.black87;

  // Pastel Action Colors
  static const Color pastelBlue = Color(0xFFE0F2FE);
  static const Color pastelGreen = Color(0xFFDCFCE7);
  static const Color pastelYellow = Color(0xFFFEF9C3);
  static const Color pastelPurple = Color(0xFFF3E8FF);
  static const Color pastelOrange = Color(0xFFFFEDD5);

  // Dark Theme Colors
  static const Color primaryDark = Colors.white;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  // Dark Theme Colors (continued)
  static const Color textDark = Colors.white70;

  // High Contrast Colors - Light
  static const Color hcBackgroundLight = Colors.white;
  static const Color hcTextLight = Colors.black;
  static const Color hcPrimaryLight = Colors.black;

  // High Contrast Colors - Dark
  static const Color hcBackgroundDark = Colors.black;
  static const Color hcTextDark = Colors.white;
  static const Color hcPrimaryDark = Colors.white;

  // Pastel Action Colors (Dark Mode variations - slightly muted)
  static const Color pastelBlueDark = Color(0xFF1E3A8A);
  static const Color pastelGreenDark = Color(0xFF14532D);
  static const Color pastelYellowDark = Color(0xFF713F12);
  static const Color pastelPurpleDark = Color(0xFF581C87);
  static const Color pastelOrangeDark = Color(0xFF7C2D12);

  static ThemeData getTheme({
    required bool isDark,
    required bool isHighContrast,
    required bool reduceMotion,
  }) {
    final Brightness brightness = isDark ? Brightness.dark : Brightness.light;
    final Color bgColor = isHighContrast
        ? (isDark ? hcBackgroundDark : hcBackgroundLight)
        : (isDark ? backgroundDark : backgroundLight);
    final Color surfaceColor = isHighContrast
        ? (isDark ? hcBackgroundDark : hcBackgroundLight)
        : (isDark ? surfaceDark : surfaceLight);
    final Color primaryColor = isHighContrast
        ? (isDark ? hcPrimaryDark : hcPrimaryLight)
        : (isDark ? primaryDark : primaryLight);
    final Color textColor = isHighContrast
        ? (isDark ? hcTextDark : hcTextLight)
        : (isDark ? textDark : textLight);

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        background: bgColor,
        surface: surfaceColor,
        onBackground: textColor,
        onSurface: textColor,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme:
          GoogleFonts.interTextTheme(
            ThemeData(brightness: brightness).textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.inter(
              fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.w800,
              color: textColor,
              letterSpacing: -1.0,
            ),
            displayMedium: GoogleFonts.inter(
              fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
            displaySmall: GoogleFonts.inter(
              fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w700,
              color: textColor,
            ),
            headlineLarge: GoogleFonts.inter(
              fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w700,
              color: textColor,
            ),
            headlineMedium: GoogleFonts.inter(
              fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w700,
              color: textColor,
            ),
            titleLarge: GoogleFonts.inter(
              fontWeight: isHighContrast ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
            ),
            bodyLarge: GoogleFonts.inter(
              fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
            bodyMedium: GoogleFonts.inter(
              fontWeight: isHighContrast ? FontWeight.w500 : FontWeight.w400,
              color: textColor,
            ),
          ),
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.bold,
          color: primaryColor,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: isHighContrast
            ? textColor.withOpacity(0.7)
            : Colors.grey,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: isHighContrast ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: isHighContrast
              ? BorderSide(color: textColor, width: 2)
              : BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: isHighContrast
              ? BorderSide(color: textColor, width: 2)
              : BorderSide.none,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark
              ? (isHighContrast ? Colors.black : backgroundDark)
              : surfaceColor,
          elevation: isHighContrast ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: isHighContrast
                ? BorderSide(color: textColor, width: 2)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: isHighContrast
              ? BorderSide(color: textColor, width: 2)
              : BorderSide(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1,
                ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: isHighContrast
              ? BorderSide(color: textColor, width: 1)
              : BorderSide(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1,
                ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(
            color: primaryColor,
            width: isHighContrast ? 3 : 2,
          ),
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: reduceMotion
              ? const NoTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: reduceMotion
              ? const NoTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: reduceMotion
              ? const NoTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: reduceMotion
              ? const NoTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: reduceMotion
              ? const NoTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get lightTheme =>
      getTheme(isDark: false, isHighContrast: false, reduceMotion: false);
  static ThemeData get darkTheme =>
      getTheme(isDark: true, isHighContrast: false, reduceMotion: false);
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
