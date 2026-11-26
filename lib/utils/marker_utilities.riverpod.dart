import 'package:roads_map/hive_boxes.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'marker_utilities.riverpod.g.dart';

class MarkerUtilities {
  static const String _imageAssetPath = 'assets/image_assets.json';
  static const String _hiveBoxName = HiveBoxes.markerImages;
  static const String _versionKey = 'marker_images_version';
  static Map<String, Uint8List>? _imageCache;
  static double? _cachedVersion;

  /// Loads all image assets from JSON and converts them to Uint8List
  static Future<Map<String, Uint8List>> loadImageAssets() async {
    // Return cached images if already loaded
    if (_imageCache != null) {
      return _imageCache!;
    }

    try {
      // Check if we need to reload due to version change
      bool needsReload = await _checkVersionAndReload();

      if (!needsReload) {
        // Try to load from Hive cache
        Map<String, Uint8List>? cachedImages = await _loadFromHive();
        if (cachedImages != null && cachedImages.isNotEmpty) {
          _imageCache = cachedImages;
          debugPrint('Loaded ${cachedImages.length} images from Hive cache');
          return cachedImages;
        }
      }

      // Process JSON in isolate if no cache or version changed
      final String jsonString = await rootBundle.loadString(_imageAssetPath);
      final Map<String, Uint8List> result = await _processJsonInIsolate(jsonString);

      // Store in cache for future use
      _imageCache = result;
      await _saveToHive(result);

      return result;
    } catch (e, stackTrace) {
      debugPrint('Error loading image assets: $e');
      debugPrint('Stack trace: $stackTrace');
      return {};
    }
  }

  /// Check if the JSON version has changed and needs a reload
  static Future<bool> _checkVersionAndReload() async {
    try {
      // Load the JSON to check the version
      final String jsonString = await rootBundle.loadString(_imageAssetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Get the version from JSON
      final double jsonVersion = (jsonData['version'] is int) ? (jsonData['version'] as int).toDouble() : jsonData['version'] as double;

      if (_cachedVersion == null) {
        // Load the cached version from Hive
        final versionBox = Hive.isBoxOpen(HiveBoxes.settings) ? Hive.box(HiveBoxes.settings) : await Hive.openBox(HiveBoxes.settings);

        _cachedVersion = versionBox.get(_versionKey) as double?;
      }

      // If version changed or no cached version, update and return true to reload
      if (_cachedVersion == null || _cachedVersion != jsonVersion) {
        debugPrint('Version changed from ${_cachedVersion ?? "none"} to $jsonVersion, reloading images');

        // Update the cached version in Hive
        final versionBox = Hive.isBoxOpen(HiveBoxes.settings) ? Hive.box(HiveBoxes.settings) : await Hive.openBox(HiveBoxes.settings);

        await versionBox.put(_versionKey, jsonVersion);
        _cachedVersion = jsonVersion;

        // Clear the old cache if version changed
        if (_cachedVersion != null) {
          await _clearCache();
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking version: $e');
      return false;
    }
  }

  /// Clear the image cache from Hive
  static Future<void> _clearCache() async {
    final box = Hive.isBoxOpen(_hiveBoxName) ? Hive.box<Uint8List>(_hiveBoxName) : await Hive.openBox<Uint8List>(_hiveBoxName);

    await box.clear();
    _imageCache = null;
    debugPrint('Cleared image cache');
  }

  /// Load images from Hive
  static Future<Map<String, Uint8List>?> _loadFromHive() async {
    try {
      final box = Hive.isBoxOpen(_hiveBoxName) ? Hive.box<Uint8List>(_hiveBoxName) : await Hive.openBox<Uint8List>(_hiveBoxName);

      if (box.isEmpty) {
        return null;
      }

      final Map<String, Uint8List> result = {};

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          result[key.toString()] = data;
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error loading from Hive: $e');
      return null;
    }
  }

  /// Save images to Hive
  static Future<void> _saveToHive(Map<String, Uint8List> images) async {
    try {
      final box = Hive.isBoxOpen(_hiveBoxName) ? Hive.box<Uint8List>(_hiveBoxName) : await Hive.openBox<Uint8List>(_hiveBoxName);

      await box.clear(); // Clear any existing data

      for (var entry in images.entries) {
        await box.put(entry.key, entry.value);
      }

      debugPrint('Saved ${images.length} images to Hive');
    } catch (e) {
      debugPrint('Error saving to Hive: $e');
    }
  }

  static Future<Map<String, Uint8List>> _processJsonInIsolate(String jsonString) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_parseJsonInIsolate, [receivePort.sendPort, jsonString]);

    // Wait for the result from the isolate
    final Map<String, Uint8List> result = await receivePort.first;
    debugPrint('Received ${result.length} processed images from isolate');
    return result;
  }

  /// The function that runs in the isolate to parse the JSON
  static void _parseJsonInIsolate(List<dynamic> args) {
    final SendPort sendPort = args[0];
    final String jsonString = args[1];

    try {
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic>? imageData = jsonData['image_assets'] as Map<String, dynamic>?;

      if (imageData == null) {
        sendPort.send(<String, Uint8List>{});
        return;
      }

      final Map<String, Uint8List> result = {};

      // Process each image in the JSON
      imageData.forEach((key, value) {
        try {
          if (value is Map && value.containsKey('image') && value['image'] is Map && value['image'].containsKey('data')) {
            final String base64Data = value['image']['data'] as String;
            final Uint8List imageBytes = base64Decode(base64Data);
            result[key] = imageBytes;

            // Also store by id if present, for easier lookup
            if (value.containsKey('id')) {
              result[value['id']] = imageBytes;
            }
          } else {
            debugPrint('Skipping image $key: Incomplete data structure');
          }
        } catch (e) {
          debugPrint('Error processing image $key: $e');
        }
      });

      sendPort.send(result);
    } catch (e) {
      debugPrint('Error parsing JSON: $e');
      sendPort.send(<String, Uint8List>{});
    }
  }

  /// Get an image by ID
  static Uint8List? getImageById(String id) {
    return _imageCache?[id];
  }

  /// Debug method to check image availability
  static Future<void> checkImageAvailability(List<String> imageIds) async {
    try {
      final imageData = await loadImageAssets();

      debugPrint('\n=== Image Availability Check ===');
      for (final id in imageIds) {
        final available = imageData.containsKey(id);
        debugPrint('${available ? "✓" : "✗"} Image "$id": ${available ? "Available" : "NOT FOUND"}');
      }
      debugPrint('=== End of Check ===\n');
    } catch (e) {
      debugPrint('Error checking image availability: $e');
    }
  }

  /// Adds the marker images to the current style (a style reload drops them).
  /// Decoded bytes come from the in-memory/Hive cache, so repeated calls only
  /// re-register images with MapLibre. Returns true only if every image was added.
  static Future<bool> addImagesToMap(MapLibreMapController mapController) async {
    try {
      final imageData = await loadImageAssets();
      if (imageData.isEmpty) {
        debugPrint('Warning: No marker images loaded from assets');
        return false;
      }

      int successCount = 0;
      for (final entry in imageData.entries) {
        try {
          await mapController.addImage(entry.key, entry.value);
          successCount++;
        } catch (e) {
          debugPrint('Error adding image to map: ${entry.key}, error: $e');
        }
      }

      debugPrint('Successfully added $successCount/${imageData.length} marker images to map');
      return successCount == imageData.length;
    } catch (e) {
      debugPrint('Error in addImagesToMap: $e');
      return false;
    }
  }
}

/// A custom adapter for Uint8List to work with Hive
class Uint8ListAdapter extends TypeAdapter<Uint8List> {
  @override
  final int typeId = 0;

  @override
  Uint8List read(BinaryReader reader) {
    final length = reader.readInt();
    return reader.readByteList(length);
  }

  @override
  void write(BinaryWriter writer, Uint8List obj) {
    writer.writeInt(obj.length);
    writer.writeByteList(obj);
  }
}

/// Riverpod provider for marker images
@riverpod
class MarkerImages extends _$MarkerImages {
  @override
  Future<Map<String, Uint8List>> build() async {
    return MarkerUtilities.loadImageAssets();
  }

  /// Get a specific image by its id
  Uint8List? getImageById(String id) {
    final images = state.valueOrNull;
    if (images != null && images.containsKey(id)) {
      return images[id];
    }
    return null;
  }
}

/// Extension on MapLibreMapController to simplify adding marker images
extension MapControllerExtension on MapLibreMapController {
  /// Add all marker images from the assets
  Future<void> addMarkerImages() async {
    await MarkerUtilities.addImagesToMap(this);
  }
}
