import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_presets.dart';

const String _kActiveThemePrefKey = 'hatly_active_theme_id';

/// StateNotifier that manages the active [ThemePreset] and saves selection to [SharedPreferences].
class ThemeController extends StateNotifier<ThemePreset> {
  ThemeController() : super(ThemePreset.emeraldSlate) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_kActiveThemePrefKey);
      if (savedId != null) {
        state = ThemePreset.fromId(savedId);
      }
    } catch (_) {
      // Fallback silently to default emerald slate on error
    }
  }

  Future<void> setTheme(ThemePreset preset) async {
    state = preset;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveThemePrefKey, preset.id);
    } catch (_) {}
  }
}

/// Provider for managing and mutating the active theme preset.
final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemePreset>((ref) {
  return ThemeController();
});

/// Convenience provider for reading the current active [ThemePreset].
final activeThemeProvider = Provider<ThemePreset>((ref) {
  return ref.watch(themeControllerProvider);
});

/// Convenience provider for reading the current active background [Gradient].
final activeGradientProvider = Provider<Gradient>((ref) {
  return ref.watch(activeThemeProvider).backgroundGradient;
});
