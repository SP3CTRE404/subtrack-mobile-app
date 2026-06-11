import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.cobaltBlue,
      scaffoldBackgroundColor: AppColors.lightSurface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.cobaltBlue,
        surface: AppColors.lightSurface,
        onSurface: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pureWhite,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Dark icons for light theme
          statusBarBrightness: Brightness.light,    // For iOS
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.cobaltBlue,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cobaltBlue,
        foregroundColor: Colors.black, // High contrast for neon
      ),
      cardTheme: const CardThemeData(
        color: AppColors.pureWhite, // Brighter card surface
        elevation: 0,
        shadowColor: Color.fromRGBO(0, 0, 0, 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.05), width: 1), // Subtle border
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
        },
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.cobaltBlue,
      scaffoldBackgroundColor: AppColors.trueBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cobaltBlue,
        surface: AppColors.darkSurface,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.trueBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // White icons for dark theme
          statusBarBrightness: Brightness.dark,      // For iOS
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        selectedItemColor: AppColors.cobaltBlue,
        unselectedItemColor: Colors.white70,
        elevation: 10, // Remove elevation so shadows don't block the blur
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cobaltBlue,
        foregroundColor: Colors.black,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
        },
      ),
      useMaterial3: true,
    );
  }
}
