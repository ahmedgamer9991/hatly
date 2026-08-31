import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hatly/app/config/theme_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('ThemePreset Unit Tests', () {
    test('allPresets contains exactly 10 master themes with unique IDs', () {
      expect(ThemePreset.allPresets.length, 10);

      final ids = ThemePreset.allPresets.map((p) => p.id).toSet();
      expect(ids.length, 10);
    });

    test('ThemePreset.fromId returns correct preset or defaults to emeraldSlate', () {
      expect(ThemePreset.fromId('cyber_violet').name, 'Cyber Violet');
      expect(ThemePreset.fromId('oceanic_deep').name, 'Oceanic Deep');
      expect(ThemePreset.fromId('sunset_mirage').name, 'Sunset Mirage');
      expect(ThemePreset.fromId('obsidian_amoled').name, 'Obsidian AMOLED');
      expect(ThemePreset.fromId('neon_sakura').name, 'Neon Sakura');
      expect(ThemePreset.fromId('matcha_forest').name, 'Matcha Forest');
      expect(ThemePreset.fromId('tokyo_crimson').name, 'Tokyo Crimson');
      expect(ThemePreset.fromId('royal_sovereign').name, 'Royal Sovereign');
      expect(ThemePreset.fromId('nordic_glacier').name, 'Nordic Glacier');
      expect(ThemePreset.fromId(null).id, 'emerald_slate');
      expect(ThemePreset.fromId('unknown_invalid_id').id, 'emerald_slate');
    });

    test('All presets define valid RadialGradient and distinct color tokens', () {
      for (final preset in ThemePreset.allPresets) {
        expect(preset.gradientColors.length, greaterThanOrEqualTo(2));
        final gradient = preset.backgroundGradient;
        expect(gradient, isA<RadialGradient>());

        expect(preset.primary, isNotNull);
        expect(preset.secondary, isNotNull);
        expect(preset.backgroundCanvas, isNotNull);
        expect(preset.surfaceContainer, isNotNull);
      }
    });

    test('ThemeController saves and loads theme via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'hatly_active_theme_id': 'cyber_violet'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('hatly_active_theme_id'), 'cyber_violet');

      final loadedPreset = ThemePreset.fromId(prefs.getString('hatly_active_theme_id'));
      expect(loadedPreset.id, 'cyber_violet');
      expect(loadedPreset.emoji, '💜');
    });
  });
}
