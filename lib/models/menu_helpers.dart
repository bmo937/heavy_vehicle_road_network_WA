import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:roads_map/providers/network_selection_provider.riverpod.dart';

part 'menu_helpers.g.dart';

// Constants for Hive storage
const String pointsOfInterestBoxName = 'pointsOfInterestBox';
const String roadNetworksBoxName = 'roadNetworksBox';
const String visibilityKey = 'layer_visibility';

// Providers for managing layer selections

// Points of Interest layer selection provider
@riverpod
class PointsOfInterestSelectionNotifier extends _$PointsOfInterestSelectionNotifier {
  @override
  Map<String, bool> build() {
    // Load the initial state from Hive on initialization
    return _loadInitialState();
  }

  Map<String, bool> _loadInitialState() {
    try {
      final box = Hive.isBoxOpen(pointsOfInterestBoxName) ? Hive.box(pointsOfInterestBoxName) : Hive.box('selectedPoiLayerBox');
      final map = <String, bool>{};

      // Load from pointsOfInterestBoxName first
      for (final key in box.keys) {
        if (key is String && key.endsWith(visibilityKey)) {
          final layerName = key.replaceAll('_$visibilityKey', '');
          final isVisible = box.get(key) ?? false;
          map[layerName] = isVisible;
        }
      }

      // If no data was found, try the secondary box
      if (map.isEmpty && Hive.isBoxOpen('selectedPoiLayerBox')) {
        final altBox = Hive.box('selectedPoiLayerBox');
        for (final key in altBox.keys) {
          if (key is String) {
            map[key] = altBox.get(key) ?? false;
          }
        }
      }

      debugPrint('Loaded POI state from Hive: ${map.entries.length} entries');
      return map;
    } catch (e) {
      debugPrint('Error loading POI state from Hive: $e');
      return {};
    }
  }

  Future<void> toggleLayer(String layerName, bool isSelected) async {
    state = {...state, layerName: isSelected};
  }

  Future<void> clearSelection() async {
    state = {};
  }
}

// Road Networks layer selection provider
@riverpod
class RoadNetworkSelectionNotifier extends _$RoadNetworkSelectionNotifier {
  @override
  String? build() {
    return null;
  }

  void selectNetwork(String networkName) {
    state = networkName;
  }

  void clearSelection() {
    state = null;
  }
}

/// Master toggle providers for each menu type
@riverpod
class PointsOfInterestMasterToggle extends _$PointsOfInterestMasterToggle {
  @override
  bool build() {
    return false;
  }

  void toggle(bool value) {
    state = value;
  }
}

@riverpod
class RoadNetworksMasterToggle extends _$RoadNetworksMasterToggle {
  @override
  bool build() {
    return false;
  }

  void toggle(bool value) {
    state = value;
  }
}

/// Provider to store previously visible POIs
@riverpod
class PreviouslyVisiblePOI extends _$PreviouslyVisiblePOI {
  @override
  Set<String> build() {
    return {};
  }

  void addLayer(String layerName) {
    state = {...state, layerName};
  }

  void clear() {
    state = {};
  }
}

/// Provider to store previously selected road network
@riverpod
class PreviouslySelectedRoadNetwork extends _$PreviouslySelectedRoadNetwork {
  @override
  String? build() {
    return null;
  }

  void setNetwork(String networkName) {
    state = networkName;
  }

  void clear() {
    state = null;
  }
}

// Helper functions for loading saved selections
Future<void> loadSavedSelections(WidgetRef ref) async {
  await loadSavedPointsOfInterest(ref);
  await loadSavedRoadNetwork(ref);
}

Future<void> loadSavedPointsOfInterest(WidgetRef ref) async {
  try {
    // Open both Hive boxes
    final box = await Hive.openBox(pointsOfInterestBoxName);
    final selectedPoiBox = Hive.isBoxOpen('selectedPoiLayerBox') ? Hive.box('selectedPoiLayerBox') : await Hive.openBox('selectedPoiLayerBox');

    final poiSelectionNotifier = ref.read(pointsOfInterestSelectionNotifierProvider.notifier);
    final poiLayerSelectionNotifier = ref.read(poiLayerSelectionProvider.notifier);

    // Track visibility for master toggle
    bool anyVisible = false;

    // Find all saved POI visibility settings from primary box
    for (final key in box.keys) {
      if (key is String && key.endsWith(visibilityKey)) {
        final layerName = key.replaceAll('_$visibilityKey', '');
        final isVisible = box.get(key) ?? false;

        // Update both providers regardless of visibility
        await poiSelectionNotifier.toggleLayer(layerName, isVisible);
        await poiLayerSelectionNotifier.toggleLayer(layerName, isVisible);

        // Mirror to the other box for consistency
        await selectedPoiBox.put(layerName, isVisible);

        if (isVisible) {
          anyVisible = true;
          debugPrint('Restored visibility of POI layer: $layerName');
        }
      }
    }

    // Check the other box for any additional layers
    for (final key in selectedPoiBox.keys) {
      if (key is String) {
        final isVisible = selectedPoiBox.get(key) ?? false;
        final boxKey = '${key}_$visibilityKey';

        // Only process if not already processed above
        if (!box.containsKey(boxKey)) {
          await poiSelectionNotifier.toggleLayer(key, isVisible);
          await poiLayerSelectionNotifier.toggleLayer(key, isVisible);

          // Mirror to main box
          await box.put(boxKey, isVisible);

          if (isVisible) {
            anyVisible = true;
            debugPrint('Restored visibility from secondary box: $key');
          }
        }
      }
    }

    // Update master toggle based on any visible layer
    ref.read(pointsOfInterestMasterToggleProvider.notifier).toggle(anyVisible);

    // Force a refresh of the UI
    ref.invalidate(pointsOfInterestSelectionNotifierProvider);
  } catch (e) {
    debugPrint('Error loading saved POI visibility: $e');
  }
}

Future<void> loadSavedRoadNetwork(WidgetRef ref) async {
  try {
    final box = await Hive.openBox(roadNetworksBoxName);
    final selectedNetwork = box.get(visibilityKey) as String?;

    if (selectedNetwork != null) {
      // Update both providers for consistency
      ref.read(roadNetworkSelectionNotifierProvider.notifier).selectNetwork(selectedNetwork);
      ref.read(networkLayerSelectionProvider.notifier).selectLayer(selectedNetwork);
    }
  } catch (e) {
    debugPrint('Error loading saved road network: $e');
  }
}
