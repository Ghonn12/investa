import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminColors {
  static const primary = Color(0xFF09305B); // Navy Blue
  static const secondary = Color(0xFF3F79B8); // Teal
  static const bg = Color(0xFFF8F9FD); // Abu-abu sangat muda
  static const surface = Colors.white;
  static const text = Color(0xFF1A1C24);
  static const textGrey = Color(0xFF757575);
  static const border = Color(0xFFE0E0E0);
}

class AdminTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AdminColors.bg,
      primaryColor: AdminColors.primary,
      cardColor: AdminColors.surface,

      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AdminColors.text,
        displayColor: AdminColors.text,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AdminColors.text),
        titleTextStyle: TextStyle(
            color: AdminColors.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins'
        ),
      ),

      // Gaya Tombol
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),

      // Gaya Input (Diperbaiki)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.primary, width: 2),
        ),
        // Margin tidak diatur di sini, tapi di widget TextField/Container pembungkusnya
      ),
    );
  }
}