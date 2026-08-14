import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Glassmorphism Color Tokens
  static const Color bgApp = Color(0xFF0B0F19);
  static const Color bgCard = Color(0xCC0F172A);
  static const Color bgCardHover = Color(0xFF1E293B);
  static const Color borderColor = Color(0x26FFFFFF); // 15% opacity white border

  static const Color emeraldPrimary = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color skyBlueAccent = Color(0xFF38BDF8);
  static const Color amberGold = Color(0xFFF59E0B);
  static const Color amberGoldLight = Color(0xFFFBBF24);
  static const Color purpleCategory = Color(0xFFA855F7);
  static const Color textMuted = Color(0xFFCBD5E1); // Slate-300: Sáng rõ, tương phản cao, không bị mờ

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgApp,
      primaryColor: emeraldPrimary,
      colorScheme: const ColorScheme.dark(
        primary: emeraldPrimary,
        secondary: skyBlueAccent,
        surface: bgCard,
      ),
      useMaterial3: true,
    );

    final fontTextTheme =
        GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      textTheme: fontTextTheme.copyWith(
        bodyLarge: fontTextTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: fontTextTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: fontTextTheme.bodySmall?.copyWith(
          color: textMuted,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: fontTextTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: fontTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
