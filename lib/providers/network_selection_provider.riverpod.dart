import 'package:roads_map/hive_boxes.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_selection_provider.riverpod.g.dart';

/// Provider to track POI layer selections using Riverpod annotation
@riverpod
class PoiLayerSelection extends _$PoiLayerSelection {
  /// Toggle a layer's visibility
  Future<void> toggleLayer(String layerName, bool value) async {
    final box = Hive.box(HiveBoxes.selectedPoiLayer);
    await box.put(layerName, value);

    // Also save to legacy box for cross-compatibility
    if (Hive.isBoxOpen(HiveBoxes.pointsOfInterest)) {
      final legacyBox = Hive.box(HiveBoxes.pointsOfInterest);
      await legacyBox.put('${layerName}_layer_visibility', value);
    }

    // Update the state with the new value
    state = {
      ...state,
      layerName: value,
    };
    debugPrint('PoiLayerSelection toggled $layerName to $value');
  }

  Map<String, bool> _loadInitialPoiState() {
    try {
      // Try the primary box first
      final box = Hive.box(HiveBoxes.selectedPoiLayer);
      final map = <String, bool>{};

      // Load from primary box
      for (final key in box.keys) {
        if (key is String) {
          map[key] = box.get(key, defaultValue: false);
        }
      }

      // If the primary box is empty, try loading from the legacy box
      if (map.isEmpty && Hive.isBoxOpen(HiveBoxes.pointsOfInterest)) {
        final legacyBox = Hive.box(HiveBoxes.pointsOfInterest);
        for (final key in legacyBox.keys) {
          if (key is String && key.toString().endsWith('_layer_visibility')) {
            final layerName = key.toString().replaceAll('_layer_visibility', '');
            map[layerName] = legacyBox.get(key, defaultValue: false);
          }
        }
      }

      debugPrint('PoiLayerSelection loaded ${map.length} entries from Hive');
      return map;
    } catch (e) {
      debugPrint('Error loading POI state in PoiLayerSelection: $e');
      return {};
    }
  }

  @override
  Map<String, bool> build() {
    return _loadInitialPoiState();
  }
}

/// Provider to track network layer selection using Riverpod annotation
@riverpod
class NetworkLayerSelection extends _$NetworkLayerSelection {
  /// Set the selected network layer
  Future<void> selectLayer(String? layerName) async {
    debugPrint('\n🔄 NetworkLayerSelection.selectLayer called with: $layerName');
    debugPrint('📦 Previous state: $state');

    final box = Hive.box(HiveBoxes.selectedLayer); // Ensure this box is opened

    if (layerName == null) {
      await box.delete('selectedLayer');
      debugPrint('🗑️ Deleted selectedLayer from Hive');
    } else {
      await box.put('selectedLayer', layerName);
      debugPrint('💾 Selected network layer saved to Hive: $layerName');
    }

    // Update the state with the new selection
    state = layerName;
    debugPrint('🎯 New state: $state');
    debugPrint('✅ NetworkLayerSelection.selectLayer completed\n');
  }

  String? _loadInitialNetworkState() {
    final box = Hive.box(HiveBoxes.selectedLayer); // Ensure this box is opened
    return box.get('selectedLayer');
  }

  @override
  String? build() {
    return _loadInitialNetworkState();
  }
}
