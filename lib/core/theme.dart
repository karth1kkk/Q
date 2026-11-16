// lib/core/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Tailwind Green Palette
  static const Color primaryGreen = Color(0xFF16A34A); // green-600
  static const Color lightGreen = Color(0xFFDCFCE7); // green-100
  static const Color bgGray = Color(0xFFF9FAFB); // gray-50
  static const Color textDark = Color(0xFF111827); // gray-900
  static const Color textGray = Color(0xFF6B7280); // gray-500

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: bgGray,
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textGray,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}