// Path: lib/theme.dart
import 'package:flutter/material.dart';

class SpaceTheme {
  // --- DARK MODE PALETTE ---
  static const Color darkBg = Color(0xFF0B0E14); 
  static const Color darkCard = Color(0xFF161C26); 
  static const Color darkText = Color(0xFFF0F2F5); 
  static const Color astralGold = Color(0xFFE2B76E); 
  static const Color darkMuted = Color(0xFF8E9AA8); 

  // --- LIGHT MODE PALETTE ---
  static const Color lightBg = Color(0xFFF5F7FA); 
  static const Color lightCard = Colors.white; 
  static const Color lightText = Color(0xFF1A1F26); 
  static const Color cosmicBlue = Color(0xFF2A4365); 
  static const Color lightMuted = Color(0xFF627182); 

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: astralGold,
      fontFamily: 'Sans-Serif',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 26.0, color: astralGold, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 20.0, color: darkText, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15.0, color: darkText),
        bodyMedium: TextStyle(fontSize: 13.0, color: darkMuted),
      ),
      cardColor: darkCard,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        labelStyle: const TextStyle(color: darkMuted, fontSize: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: darkMuted.withAlpha(50))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: astralGold, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: astralGold,
          foregroundColor: darkBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: cosmicBlue,
      fontFamily: 'Sans-Serif',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 26.0, color: cosmicBlue, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 20.0, color: lightText, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15.0, color: lightText),
        bodyMedium: TextStyle(fontSize: 13.0, color: lightMuted),
      ),
      cardColor: lightCard,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        labelStyle: const TextStyle(color: lightMuted, fontSize: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: lightMuted.withAlpha(50))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cosmicBlue, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cosmicBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Image Helper Component
  static Widget renderImage(String path, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http')) {
      return Image.network(
        path, 
        height: height, 
        width: width, 
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.withAlpha(50),
          child: const Icon(Icons.broken_image, size: 40),
        ),
      );
    } else {
      return Image.asset(
        path, 
        height: height, 
        width: width, 
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.withAlpha(50),
          child: const Icon(Icons.shopping_bag, size: 40),
        ),
      );
    }
  }
}