// ==========================================================================
// AeroQuiz UI Theme Config (Aesthetic Dark Obsidian & Glassmorphism)
// ==========================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AeroTheme {
  // Theme Colors
  static const Color obsidianBg = Color(0xFF0B0F19);
  static const Color obsidianCard = Color(0xBB111827);
  static const Color obsidianCardSolid = Color(0xFF111827);
  static const Color borderSideColor = Color(0x14FFFFFF);
  static const Color borderHoverColor = Color(0x26FFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Dynamic Accents
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryIndigoHover = Color(0xFF4F46E5);
  static const Color primaryIndigoGlow = Color(0x266366F1);
  static const Color primaryIndigoBg = Color(0x1A6366F1);

  static const Color correctEmerald = Color(0xFF10B981);
  static const Color correctEmeraldGlow = Color(0x2610B981);
  static const Color correctEmeraldBg = Color(0x1410B981);

  static const Color incorrectRose = Color(0xFFF43F5E);
  static const Color incorrectRoseGlow = Color(0x26F43F5E);
  static const Color incorrectRoseBg = Color(0x14F43F5E);

  static const Color alertAmber = Color(0xFFF59E0B);
  static const Color alertAmberBg = Color(0x14F59E0B);

  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoBlueBg = Color(0x143B82F6);

  static const Color violetAccent = Color(0xFF8B5CF6);
  static const Color violetAccentBg = Color(0x148B5CF6);

  // Glassmorphic Card Border Decoration
  static BoxDecoration glassCardDecoration({
    Color color = obsidianCard,
    double radius = 16.0,
    bool isGlow = false,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: borderSideColor, width: 1.0),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: isGlow ? primaryIndigoGlow : Colors.black.withOpacity(0.35),
          blurRadius: isGlow ? 24.0 : 16.0,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Root ThemeData config
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: obsidianBg,
      cardColor: obsidianCardSolid,
      primaryColor: primaryIndigo,
      hintColor: textMuted,
      dividerColor: borderSideColor,
      dialogBackgroundColor: obsidianCardSolid,

      // Apply Google Fonts
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme.copyWith(
          bodyLarge: const TextStyle(color: textPrimary, fontSize: 16.0, fontWeight: FontWeight.normal),
          bodyMedium: const TextStyle(color: textSecondary, fontSize: 14.0, fontWeight: FontWeight.normal),
          titleLarge: GoogleFonts.outfit(
            color: textPrimary,
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.02,
          ),
          titleMedium: GoogleFonts.outfit(
            color: textPrimary,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // App bar styling
      appBarTheme: const AppBarTheme(
        backgroundColor: obsidianBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Text input overrides
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14.0),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: borderSideColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primaryIndigo, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: incorrectRose, width: 1.0),
        ),
      ),
    );
  }
}
