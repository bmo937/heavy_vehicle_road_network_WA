import 'package:roads_map/hive_boxes.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.riverpod.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late Box _box;

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _box.put('themeMode', mode.index);
  }

  Future<void> _initializeHive() async {
    try {
      _box = await Hive.openBox(HiveBoxes.settings);
      final themeModeIndex =
          _box.get('themeMode', defaultValue: ThemeMode.system.index);
      state = ThemeMode.values[themeModeIndex];
    } catch (e) {
      debugPrint('Error initializing settings Hive: $e');
      state = ThemeMode.system;
    }
  }

  @override
  ThemeMode build() {
    _initializeHive();
    return ThemeMode.system; // Default value until Hive is initialized
  }
}

/* @riverpod
class UseHighResolutionImages extends _$UseHighResolutionImages {
  @override
  bool build() {
    // Default to false (use logical pixels)
    return false;
  }

  // Method to toggle high-resolution mode
  void toggle(BuildContext? context) {
    state = !state;
    debugPrint('High-resolution images: $state');

    // In the refactored version, image refresh is handled differently
    // We'll add map image refresh functionality later
  }

  // Method to set a specific value
  void set(bool value, {BuildContext? context}) {
    state = value;
    debugPrint('High-resolution images set to: $state');

    // In the refactored version, image refresh is handled differently
    // We'll add map image refresh functionality later
  }
} */

@riverpod
class MarkerColorNotifier extends _$MarkerColorNotifier {
  late Box _box;
  void setMarkerColor(Color color) {
    state = color;
    _box.put('markerColor', color.toARGB32());
  }

  Future<void> _initializeHive() async {
    try {
      _box = await Hive.openBox(HiveBoxes.settings);
      final colorValue =
          _box.get('markerColor', defaultValue: Colors.red.toARGB32());
      state = Color(colorValue);
    } catch (e) {
      debugPrint('Error initializing marker color Hive: $e');
      state = Colors.red;
    }
  }

  @override
  Color build() {
    _initializeHive();
    return Colors.red; // Default value until Hive is initialized
  }
}
