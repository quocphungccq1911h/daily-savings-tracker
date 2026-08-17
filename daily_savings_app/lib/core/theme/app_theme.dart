import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Theme Tokens
  static const Color bgApp = Color(0xFF0B0F19);
  static const Color bgCard = Color(0xCC0F172A);
  static const Color bgCardHover = Color(0xFF1E293B);
  static const Color borderColor = Color(0x26FFFFFF); // 15% opacity white border

  // Light Theme Tokens
  static const Color bgAppLight = Color(0xFFF8FAFC);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgCardHoverLight = Color(0xFFF1F5F9);
  static const Color borderColorLight = Color(0xFFE2E8F0);

  // Accents
  static const Color emeraldPrimary = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF10B981);
  static const Color skyBlueAccent = Color(0xFF0284C7);
  static const Color amberGold = Color(0xFFD97706);
  static const Color amberGoldLight = Color(0xFFF59E0B);
  static const Color purpleCategory = Color(0xFFA855F7);
  static const Color textMuted = Color(0xFFCBD5E1);

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgApp,
      primaryColor: emeraldPrimary,
      cardColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: emeraldPrimary,
        secondary: Color(0xFF38BDF8),
        surface: Color(0xFF0F172A),
      ),
      useMaterial3: true,
    );

    final fontTextTheme = GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme);

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

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgAppLight,
      primaryColor: emeraldPrimary,
      cardColor: bgCardLight,
      colorScheme: const ColorScheme.light(
        primary: emeraldPrimary,
        secondary: skyBlueAccent,
        surface: bgCardLight,
      ),
      useMaterial3: true,
    );

    final fontTextTheme = GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      textTheme: fontTextTheme.copyWith(
        bodyLarge: fontTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: fontTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        bodySmall: fontTextTheme.bodySmall?.copyWith(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        titleMedium: fontTextTheme.titleMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
        titleLarge: fontTextTheme.titleLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
