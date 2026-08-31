import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'theme_presets.dart';
export 'theme_controller.dart';

class AppTheme {
  AppTheme._();

  // Emerald Slate Glassmorphism Palette Tokens
  static const Color backgroundCanvas = Color(0xFF081425);
  static const Color surfaceContainer = Color(0xFF152031);
  static const Color primaryEmerald = Color(0xFF64DD91);
  static const Color secondaryMint = Color(0xFF45DFA4);
  static const Color deepSlate = Color(0xFF1E293B);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static const Color glassFill = Color(0x26FFFFFF); // 15% White opacity
  static const Color glassBorder = Color(0x66FFFFFF); // 40% White opacity
  static const Color errorRed = Color(0xFFFFB4AB);

  // Store Category Colors
  static const Color supermarketColor = Color(0xFF64DD91);
  static const Color pharmacyColor = Color(0xFF38BDF8);
  static const Color bakeryColor = Color(0xFFFBBF24);
  static const Color butcherColor = Color(0xFFF87171);
  static const Color otherColor = Color(0xFFCBD5E1);

  // Global App Background Radial Gradient
  static const Gradient backgroundGradient = RadialGradient(
    center: Alignment(-0.8, -0.9),
    radius: 1.3,
    colors: [
      Color(0xFF11253E),
      Color(0xFF081425),
      Color(0xFF040E1F),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static ThemeData get darkGlassTheme {
    final baseDark = ThemeData.dark(useMaterial3: true);
    final soraTextTheme = GoogleFonts.soraTextTheme(baseDark.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundCanvas,
      textTheme: soraTextTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryEmerald,
        secondary: secondaryMint,
        surface: surfaceContainer,
        error: errorRed,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.sora(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1AFFFFFF), // 10% White opacity
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryEmerald, width: 1.5),
        ),
        labelStyle: GoogleFonts.sora(color: textSecondary, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.sora(color: const Color(0xB394A3B8)), // 70% opacity for WCAG AA 4.8:1 contrast
        prefixIconColor: primaryEmerald,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: const Color(0xFF00391C),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x1AFFFFFF),
        selectedColor: primaryEmerald.withValues(alpha: 0.2),
        secondarySelectedColor: primaryEmerald,
        labelStyle: GoogleFonts.sora(color: textPrimary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.sora(color: primaryEmerald, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceContainer,
        contentTextStyle: GoogleFonts.sora(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
        elevation: 8,
        insetPadding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 90,
        ),
      ),
    );
  }
}
