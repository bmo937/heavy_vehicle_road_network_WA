import 'package:roads_map/hive_boxes.dart';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';

part 'menu_assets_notifier.riverpod.g.dart';

const String layersBoxName = HiveBoxes.layers;
const String layersKey = 'layers_data';
const String lastUpdateKey = 'last_update';
const String versionKey = 'current_version';
// const String cimVersionKey = 'cim_version';
// const String selectedFiltersKey = 'selected_filters';
// const String filterCacheKey = 'filter_cache';

// DEVELOPMENT TOGGLE: Set _forceRebuildMenuAssets to true to force rebuild of menu assets from file
const bool _forceRebuildMenuAssets = true;

// Static cache to hold the initialized MenuAssets instance
MenuAssets? _cachedMenuAssets;

// Function to run in isolate for parsing JSON
Future<MenuAssets> _parseJsonInIsolate(List<dynamic> args) async {
  final String jsonString = args[0];

  try {
    // Parse the JSON string into a Map
    final jsonData = jsonDecode(jsonString);

    // Convert the Map to MenuAssets
    return MenuAssets.fromJson(jsonData);
  } catch (e) {
    throw Exception('Error parsing JSON in isolate: $e');
  }
}

@riverpod
class MenuAssetsNotifier extends _$MenuAssetsNotifier {
  final String menuAssetsPath = 'assets/menu_assets.json';
  Future<MenuAssets> getMenuAssetsData() async {
    // DEVELOPMENT: Check if force rebuild is enabled
    if (_forceRebuildMenuAssets) {
      debugPrint(
          '🔄 FORCE REBUILD: Loading menu assets from file (toggle enabled)');
      // Clear memory cache
      _cachedMenuAssets = null;
      // Clear Hive cache by removing stored data
      try {
        final box = await _getHiveBox();
        await box.delete(layersKey);
        await box.delete(lastUpdateKey);
        await box.delete(versionKey);
        debugPrint('🗑️ Cleared cached data from Hive');
      } catch (e) {
        debugPrint('Warning: Could not clear Hive cache: $e');
      }
      return await _loadMenuAssetsFromFile();
    }

    // Check if we already have a cached instance and return it immediately
    if (_cachedMenuAssets != null) {
      debugPrint('Using cached MenuAssets instance from memory');
      return _cachedMenuAssets!;
    }

    try {
      final box = await _getHiveBox();
      final lastUpdate = box.get(lastUpdateKey);
      final storedVersion = box.get(versionKey);
      final jsonDataString = box.get(layersKey);

      debugPrint(
          'Hive data check: lastUpdate=${lastUpdate != null}, storedVersion=$storedVersion, jsonData=${jsonDataString != null}');

      // Check if we have stored data and it's not too old
      bool hasValidStoredData = jsonDataString != null && storedVersion != null;
      bool dataIsFresh = lastUpdate != null &&
          DateTime.now()
                  .difference(DateTime.parse(lastUpdate.toString()))
                  .inDays <
              1;

      // If we have valid cached data and it's fresh, use it
      if (hasValidStoredData && dataIsFresh) {
        debugPrint('Using fresh cached data (less than 1 day old)');
        try {
          // Parse JSON in isolate for better performance
          final menuAssets =
              await _parseJsonInBackground(jsonDataString.toString());

          // Cache in memory
          _cachedMenuAssets = menuAssets;

          return menuAssets;
        } catch (e) {
          debugPrint('Error parsing cached data: ${e.toString()}');
          // Fall through to asset fetch if parsing fails
        }
      }

      // If we reach here, we need to fetch from assets
      debugPrint('No valid cached data, loading from assets');
      return await _loadMenuAssetsFromFile();
    } catch (e) {
      debugPrint('Error in getMenuAssetsData: ${e.toString()}');
      // Fallback to loading from assets
      return await _loadMenuAssetsFromFile();
    }
  }

  // Parse JSON in background using isolate
  // Parse JSON in background using isolate - improved version
  Future<MenuAssets> _parseJsonInBackground(String jsonString) async {
    // Create a single receive port
    final receivePort = ReceivePort();
    Isolate? isolate;

    try {
      // Spawn the isolate with a static function reference
      isolate = await Isolate.spawn(
          _isolateParseJson, [jsonString, receivePort.sendPort]);

      // Wait for the result
      final result = await receivePort.first;

      // Check if the result is an error
      if (result is String && result.startsWith('ERROR:')) {
        throw Exception(result.substring(6));
      }

      return result as MenuAssets;
    } catch (e) {
      debugPrint('Isolate error: $e');
      // Fallback to parsing in main thread
      final jsonData = jsonDecode(jsonString);
      return MenuAssets.fromJson(jsonData);
    } finally {
      // Always clean up
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
    }
  }

  // Static method to run in isolate
  static void _isolateParseJson(List<dynamic> args) {
    final String jsonString = args[0];
    final SendPort sendPort = args[1];

    try {
      final jsonData = jsonDecode(jsonString);
      final menuAssets = MenuAssets.fromJson(jsonData);
      sendPort.send(menuAssets);
    } catch (e) {
      sendPort.send('ERROR: $e');
    }
  }

  // Helper to get the Hive box, making sure it's open
  Future<Box> _getHiveBox() async {
    try {
      if (Hive.isBoxOpen(layersBoxName)) {
        return Hive.box(layersBoxName);
      } else {
        return await Hive.openBox(layersBoxName);
      }
    } catch (e) {
      debugPrint('Error opening Hive box: ${e.toString()}');
      throw Exception('Failed to open Hive box: ${e.toString()}');
    }
  }

  /// DEVELOPMENT METHOD: Manually clear all menu assets cache
  /// This forces a fresh reload from assets on next access
  Future<void> clearMenuAssetsCache() async {
    debugPrint('🗑️ Manually clearing menu assets cache...');

    // Clear memory cache
    _cachedMenuAssets = null;

    // Clear Hive cache
    try {
      final box = await _getHiveBox();
      await box.delete(layersKey);
      await box.delete(lastUpdateKey);
      await box.delete(versionKey);
      debugPrint('✅ Menu assets cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing Hive cache: $e');
      throw Exception('Failed to clear menu assets cache: $e');
    }
  }

  Future<MenuAssets> _loadMenuAssetsFromFile() async {
    try {
      // Load the JSON file from assets
      debugPrint('Loading menu assets from file: $menuAssetsPath');
      final jsonString = await rootBundle.loadString(menuAssetsPath);

      // Use isolate to parse JSON for better performance
      final menuAssets = await _parseJsonInBackground(jsonString);

      // Cache the MenuAssets instance in memory
      _cachedMenuAssets = menuAssets;

      // Store in Hive for future use
      final box = await _getHiveBox();
      await box.put(layersKey, jsonString);
      await box.put(versionKey, menuAssets.menuVersion);
      await box.put(lastUpdateKey, DateTime.now().toIso8601String());

      debugPrint(
          'Successfully loaded menu assets with version: ${menuAssets.menuVersion}');
      return menuAssets;
    } catch (e) {
      debugPrint('Error loading menu assets from file: ${e.toString()}');
      throw Exception('Failed to load menu assets: ${e.toString()}');
    }
  }

  @override
  Future<MenuAssets> build() async {
    // If we already have a cached instance, return it immediately
    if (_cachedMenuAssets != null) {
      debugPrint('Using cached MenuAssets instance from memory in build()');
      return _cachedMenuAssets!;
    }

    debugPrint(
        'Building MenuAssetsNotifier, loading menu assets in background');
    return await getMenuAssetsData();
  }
}

// Simpler version of the provider for direct access
@riverpod
Future<MenuAssets> menuAssets(Ref ref) async {
  return await ref.watch(menuAssetsNotifierProvider.future);
}
