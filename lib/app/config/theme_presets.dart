import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines an immutable design theme preset for Hatly.
class ThemePreset {
  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final Color primary;
  final Color secondary;
  final Color backgroundCanvas;
  final Color surfaceContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color errorRed;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final Alignment gradientCenter;
  final double gradientRadius;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.backgroundCanvas,
    required this.surfaceContainer,
    this.textPrimary = const Color(0xFFF8FAFC),
    this.textSecondary = const Color(0xFF94A3B8),
    this.errorRed = const Color(0xFFFFB4AB),
    required this.gradientColors,
    this.gradientStops = const [0.0, 0.5, 1.0],
    this.gradientCenter = const Alignment(-0.8, -0.9),
    this.gradientRadius = 1.3,
  });

  /// Computed RadialGradient for scaffold and list backgrounds.
  Gradient get backgroundGradient => RadialGradient(
        center: gradientCenter,
        radius: gradientRadius,
        colors: gradientColors,
        stops: gradientStops,
      );

  /// Generates the complete Material 3 [ThemeData] for this preset.
  ThemeData get themeData {
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
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surfaceContainer,
        error: errorRed,
        onSurface: textPrimary,
        onPrimary: _computeOnPrimary(primary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.sora(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x66FFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.sora(color: textSecondary, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.sora(color: const Color(0xB394A3B8)),
        prefixIconColor: primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: _computeOnPrimary(primary),
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
        selectedColor: primary.withValues(alpha: 0.2),
        secondarySelectedColor: primary,
        labelStyle: GoogleFonts.sora(color: textPrimary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.sora(color: primary, fontWeight: FontWeight.bold),
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

  static Color _computeOnPrimary(Color color) {
    // Return dark text on bright primaries, white on dark primaries for WCAG AA
    final luminance = color.computeLuminance();
    return luminance > 0.4 ? const Color(0xFF041E12) : const Color(0xFFFFFFFF);
  }

  // ==========================================
  // 10 EXPERT CURATED THEME PRESETS
  // ==========================================

  /// 1. Emerald Slate (Default)
  static const emeraldSlate = ThemePreset(
    id: 'emerald_slate',
    name: 'Emerald Slate',
    subtitle: 'Fresh & Modern Fintech',
    emoji: '🌿',
    primary: Color(0xFF64DD91),
    secondary: Color(0xFF45DFA4),
    backgroundCanvas: Color(0xFF081425),
    surfaceContainer: Color(0xFF152031),
    gradientColors: [
      Color(0xFF11253E),
      Color(0xFF081425),
      Color(0xFF040E1F),
    ],
  );

  /// 2. Cyber Violet
  static const cyberViolet = ThemePreset(
    id: 'cyber_violet',
    name: 'Cyber Violet',
    subtitle: 'Futuristic Neon Indigo',
    emoji: '💜',
    primary: Color(0xFFC084FC),
    secondary: Color(0xFFA855F7),
    backgroundCanvas: Color(0xFF130626),
    surfaceContainer: Color(0xFF220D40),
    gradientColors: [
      Color(0xFF2A114C),
      Color(0xFF130626),
      Color(0xFF090214),
    ],
  );

  /// 3. Oceanic Deep
  static const oceanicDeep = ThemePreset(
    id: 'oceanic_deep',
    name: 'Oceanic Deep',
    subtitle: 'Bioluminescent Cyan',
    emoji: '🌊',
    primary: Color(0xFF38BDF8),
    secondary: Color(0xFF0EA5E9),
    backgroundCanvas: Color(0xFF06172B),
    surfaceContainer: Color(0xFF0F2642),
    gradientColors: [
      Color(0xFF0E3054),
      Color(0xFF06172B),
      Color(0xFF020B16),
    ],
  );

  /// 4. Sunset Mirage
  static const sunsetMirage = ThemePreset(
    id: 'sunset_mirage',
    name: 'Sunset Mirage',
    subtitle: 'Sunburst Amber & Copper',
    emoji: '🌅',
    primary: Color(0xFFFBBF24),
    secondary: Color(0xFFF59E0B),
    backgroundCanvas: Color(0xFF200C05),
    surfaceContainer: Color(0xFF35160A),
    gradientColors: [
      Color(0xFF421808),
      Color(0xFF200C05),
      Color(0xFF0F0502),
    ],
  );

  /// 5. Obsidian AMOLED
  static const obsidianAmoled = ThemePreset(
    id: 'obsidian_amoled',
    name: 'Obsidian AMOLED',
    subtitle: 'True Black & Emerald',
    emoji: '🖤',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF34D399),
    backgroundCanvas: Color(0xFF000000),
    surfaceContainer: Color(0xFF121214),
    gradientColors: [
      Color(0xFF1E1E22),
      Color(0xFF09090B),
      Color(0xFF000000),
    ],
  );

  /// 6. Neon Sakura
  static const neonSakura = ThemePreset(
    id: 'neon_sakura',
    name: 'Neon Sakura',
    subtitle: 'Vivid Pink Rose Quartz',
    emoji: '🌸',
    primary: Color(0xFFF472B6),
    secondary: Color(0xFFEC4899),
    backgroundCanvas: Color(0xFF1D0613),
    surfaceContainer: Color(0xFF330D23),
    gradientColors: [
      Color(0xFF400E2C),
      Color(0xFF1D0613),
      Color(0xFF0C0208),
    ],
  );

  /// 7. Matcha Forest
  static const matchaForest = ThemePreset(
    id: 'matcha_forest',
    name: 'Matcha Forest',
    subtitle: 'Calming Organic Green',
    emoji: '🍵',
    primary: Color(0xFF86EFAC),
    secondary: Color(0xFF4ADE80),
    backgroundCanvas: Color(0xFF0B190E),
    surfaceContainer: Color(0xFF152E1B),
    gradientColors: [
      Color(0xFF1C3A24),
      Color(0xFF0B190E),
      Color(0xFF030A05),
    ],
  );

  /// 8. Tokyo Crimson
  static const tokyoCrimson = ThemePreset(
    id: 'tokyo_crimson',
    name: 'Tokyo Crimson',
    subtitle: 'Smoked Velvet & Coral',
    emoji: '⚡',
    primary: Color(0xFFF87171),
    secondary: Color(0xFFEF4444),
    backgroundCanvas: Color(0xFF1A0A0C),
    surfaceContainer: Color(0xFF2E1216),
    gradientColors: [
      Color(0xFF3B161B),
      Color(0xFF1A0A0C),
      Color(0xFF0B0304),
    ],
  );

  /// 9. Royal Sovereign
  static const royalSovereign = ThemePreset(
    id: 'royal_sovereign',
    name: 'Royal Sovereign',
    subtitle: 'Imperial Gold & Amethyst',
    emoji: '👑',
    primary: Color(0xFFFACC15),
    secondary: Color(0xFFEAB308),
    backgroundCanvas: Color(0xFF110E38),
    surfaceContainer: Color(0xFF1F1A57),
    gradientColors: [
      Color(0xFF28216E),
      Color(0xFF110E38),
      Color(0xFF060517),
    ],
  );

  /// 10. Nordic Glacier
  static const nordicGlacier = ThemePreset(
    id: 'nordic_glacier',
    name: 'Nordic Glacier',
    subtitle: 'Frosted Arctic Slate',
    emoji: '🧊',
    primary: Color(0xFF67E8F9),
    secondary: Color(0xFF22D3EE),
    backgroundCanvas: Color(0xFF0F1820),
    surfaceContainer: Color(0xFF1A2A38),
    gradientColors: [
      Color(0xFF223647),
      Color(0xFF0F1820),
      Color(0xFF060B10),
    ],
  );

  /// All 10 available themes in order.
  static const List<ThemePreset> allPresets = [
    emeraldSlate,
    cyberViolet,
    oceanicDeep,
    sunsetMirage,
    obsidianAmoled,
    neonSakura,
    matchaForest,
    tokyoCrimson,
    royalSovereign,
    nordicGlacier,
  ];

  static ThemePreset fromId(String? id) {
    if (id == null) return emeraldSlate;
    return allPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => emeraldSlate,
    );
  }
}
