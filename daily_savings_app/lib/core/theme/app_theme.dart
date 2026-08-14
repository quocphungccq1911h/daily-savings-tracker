import 'package:flutter/material.dart';

class AppTheme {
  // Dark Glassmorphism Color Tokens
  static const Color bgApp = Color(0xFF0B0F19);
  static const Color bgCard = Color(0xCC0F172A);
  static const Color bgCardHover = Color(0xFF1E293B);
  static const Color borderColor = Color(0x1AFFFFFF);

  static const Color emeraldPrimary = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color skyBlueAccent = Color(0xFF38BDF8);
  static const Color amberGold = Color(0xFFF59E0B);
  static const Color amberGoldLight = Color(0xFFFBBF24);
  static const Color purpleCategory = Color(0xFFA855F7);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgApp,
      primaryColor: emeraldPrimary,
      colorScheme: const ColorScheme.dark(
        primary: emeraldPrimary,
        secondary: skyBlueAccent,
        surface: bgCard,
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }
}
