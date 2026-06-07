import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:roads_map/providers/settings_notifier.riverpod.dart';

import 'constants.dart';

part 'map_style_service.riverpod.g.dart';

class MapStyleService {
  static String get lightStyleUrl => "https://api.maptiler.com/maps/backdrop/style.json?$mApiKey";

  static String get darkStyleUrl => "https://api.maptiler.com/maps/backdrop-dark/style.json?$mApiKey";

  static String getInitialMapStyle() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark ? darkStyleUrl : lightStyleUrl;
  }
}

@riverpod
class ThemeStyle extends _$ThemeStyle {
  void updateStyle(ThemeMode themeMode) {
    if (themeMode == ThemeMode.dark) {
      state = "https://api.maptiler.com/maps/backdrop-dark/style.json?$mApiKey";
    } else if (themeMode == ThemeMode.light) {
      state = "https://api.maptiler.com/maps/backdrop/style.json?$mApiKey";
    } else {
      final brightness = PlatformDispatcher.instance.platformBrightness;
      state = brightness == Brightness.dark ? "https://api.maptiler.com/maps/backdrop-dark/style.json?$mApiKey" : "https://api.maptiler.com/maps/backdrop/style.json?$mApiKey";
    }
  }

  @override
  String build() {
    final brightness = PlatformDispatcher.instance.platformBrightness;
    return brightness == Brightness.dark ? "https://api.maptiler.com/maps/backdrop-dark/style.json?$mApiKey" : "https://api.maptiler.com/maps/backdrop/style.json?$mApiKey";
  }
}

@riverpod
class MapTheme extends _$MapTheme {
  String getStyleForThemeMode(ThemeMode themeMode, Brightness platformBrightness) {
    if (themeMode == ThemeMode.dark) {
      return MapStyleService.darkStyleUrl;
    } else if (themeMode == ThemeMode.light) {
      return MapStyleService.lightStyleUrl;
    } else {
      // For ThemeMode.system, use platform brightness
      return platformBrightness == Brightness.dark ? MapStyleService.darkStyleUrl : MapStyleService.lightStyleUrl;
    }
  }

  @override
  String build() {
    // Listen to the current theme mode from SettingsNotifier
    final themeMode = ref.watch(settingsNotifierProvider);

    // Watch platform brightness changes - this will trigger rebuilds when brightness changes
    final platformBrightness = ref.watch(platformBrightnessProvider);

    final style = getStyleForThemeMode(themeMode, platformBrightness);
    debugPrint('🎨 MAP THEME BUILD: ThemeMode=$themeMode, Brightness=$platformBrightness, Style=${style.contains('dark') ? 'DARK' : 'LIGHT'}');

    return style;
  }
}

@riverpod
class PlatformBrightness extends _$PlatformBrightness {
  @override
  Brightness build() {
    // Set up a listener for platform brightness changes
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    // Listen for brightness changes
    void onPlatformBrightnessChanged() {
      final newBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      debugPrint('🌟 PLATFORM BRIGHTNESS CHANGED: $brightness -> $newBrightness');
      if (newBrightness != state) {
        state = newBrightness;
      }
    }

    // Add listener for platform brightness changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = onPlatformBrightnessChanged;

    debugPrint('🌟 PLATFORM BRIGHTNESS INITIAL: $brightness');
    return brightness;
  }
}
