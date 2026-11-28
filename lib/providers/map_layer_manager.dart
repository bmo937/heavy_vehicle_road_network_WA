// Layer management for POI and network layers
import 'dart:async';
import 'dart:convert';

import 'package:roads_map/services/dio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';
import 'package:roads_map/models/menu_assets_notifier.riverpod.dart';
import 'package:roads_map/providers/map_utilities.dart';
import 'package:roads_map/providers/network_refresh_coordinator.dart';
import 'package:roads_map/providers/network_selection_provider.riverpod.dart';
import 'package:roads_map/providers/online_layers.dart';
import 'package:roads_map/services/traffic_services.riverpod.dart';
import 'package:roads_map/services/travel_impact_layer.riverpod.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';
import 'package:roads_map/utils/source_management_utility.dart';

class MapLayerManager {
  final NetworkRefreshCoordinator _refreshCoordinator;
  Future<void> _overlayMutationQueue = Future<void>.value();
  Future<void> _poiMutationQueue = Future<void>.value();
  int _overlayUpdateGeneration = 0;

  MapLayerManager(this._refreshCoordinator);

  /// Force an immediate layer update without waiting for camera movement
  /// This is useful when network selections change or theme changes.
  /// Returns true if the update ran; false if the map was not ready or the
  /// bounds could not be read (network fetch failures are handled, and logged,
  /// by the network layer loader itself).
  Future<bool> forceLayerUpdate(
    MapLibreMapController? mapController,
    bool styleIsLoaded,
    WidgetRef ref,
    Future<bool> Function(BuildContext?, LatLngBounds) updateVisibleLayers,
  ) async {
    if (mapController == null || !styleIsLoaded) {
      debugPrint(
          '❌ Cannot force layer update - map controller or style not ready');
      debugPrint('   Map controller: ${mapController != null ? "✅" : "❌"}');
      debugPrint('   Style loaded: ${styleIsLoaded ? "✅" : "❌"}');
      return false;
    }

    debugPrint('\n🔥 === MapLayerManager: forceLayerUpdate called ===');

    try {
      // Reset the last bounds to force network layer reload regardless of bounds similarity
      debugPrint('🔄 Resetting bounds to force reload...');
      ref.read(lastMapBoundsProvider.notifier).resetBounds();

      // Get current visible bounds
      final visibleBounds = await mapController.getVisibleRegion();
      debugPrint(
          '📍 Forcing layer update for bounds: ${visibleBounds.southwest} to ${visibleBounds.northeast}');

      // Update visible layers immediately
      debugPrint('🔄 Calling updateVisibleLayers...');
      final updated = await updateVisibleLayers(null, visibleBounds);

      if (!updated) return false;
      debugPrint('✅ Force layer update completed');
      return true;
    } catch (e) {
      debugPrint('❌ Error in forceLayerUpdate: $e');
      return false;
    } finally {
      debugPrint('🔥 MapLayerManager: forceLayerUpdate completed\n');
    }
  }

  /// Update any visible layers based on current selection
  Future<bool> updateVisibleLayers(
    BuildContext? context,
    LatLngBounds visibleBounds,
    WidgetRef ref,
    MapLibreMapController? mapController, {
    bool Function()? isCurrent,
  }) async {
    bool current() => isCurrent == null || isCurrent();
    if (mapController == null || !current()) return false;

    debugPrint('\n🔍 === _updateVisibleLayers called ===');

    try {
      var succeeded = true;
      // Check network layer selection
      final networkLayerSelection = ref.read(networkLayerSelectionProvider);
      debugPrint('🌐 Network layer selection: $networkLayerSelection');
      if (networkLayerSelection != null && networkLayerSelection.isNotEmpty) {
        debugPrint('✅ Selected network layer: $networkLayerSelection');
        debugPrint('🔄 Calling _updateNetworkLayer...');
        if (!await _updateNetworkLayer(
            networkLayerSelection, visibleBounds, ref, mapController,
            isCurrent: isCurrent)) {
          succeeded = false;
        }
      } else {
        debugPrint('⚠️ No network layer selected');
      }

      // A newer style/controller change owns the map now.
      if (!current()) return false;

      // Check POI layer selections
      final poiLayerSelections = ref.read(poiLayerSelectionProvider);
      debugPrint('🏛️ POI layer selections: $poiLayerSelections');

      if (poiLayerSelections.isNotEmpty) {
        debugPrint('🔄 Updating POI layer visibility...');
        if (!await _updatePoiLayers(ref, mapController, isCurrent: isCurrent)) {
          succeeded = false;
        }
      } else {
        debugPrint('⚠️ No POI layer selections');
      }
      return succeeded && current();
    } catch (e) {
      debugPrint('❌ Error updating visible layers: $e');
      return false;
    } finally {
      debugPrint('🔍 === _updateVisibleLayers completed ===\n');
    }
  }

  /// Update the network layer based on selection
  Future<bool> _updateNetworkLayer(
    String layerName,
    LatLngBounds visibleBounds,
    WidgetRef ref,
    MapLibreMapController mapController, {
    bool Function()? isCurrent,
  }) async {
    debugPrint('Updating network layer: $layerName');

    try {
      // Get menu assets
      final menuAssetsProvider = ref.read(menuAssetsNotifierProvider);
      final menuAssets = menuAssetsProvider.value;

      if (menuAssets == null) {
        debugPrint('Menu assets not available yet');
        return false;
      } // Initialize loading notifier and bounds notifier (will be used in loadNetworkLayerData call)

      // Search in group members of each top-level layer
      for (final parentLayer in menuAssets.layers) {
        if (parentLayer.groupMembers == null ||
            parentLayer.groupMembers!.isEmpty) {
          continue;
        }

        // Check if this layer's group members contain our target
        for (final member in parentLayer.groupMembers!) {
          if (member.name == layerName) {
            debugPrint(
                'Found layer in group members: ${parentLayer.name} > ${member.name}');
            // Use the online_layers.dart helper to load the layer
            final loaded = await loadNetworkLayerData(
              mapController: mapController,
              member: member,
              visibleBounds: visibleBounds,
              activeLayerNotifier: ref.read(activeOnlineLayerProvider.notifier),
              loadingNotifier: ref.read(onlineLayerLoadingProvider.notifier),
              lastBoundsNotifier: ref.read(lastMapBoundsProvider.notifier),
              refreshCoordinator: _refreshCoordinator,
            );
            return loaded && (isCurrent == null || isCurrent());
          }
        }
      }

      throw Exception('Layer not found: $layerName');
    } catch (e) {
      debugPrint('Error updating network layer: $e');
      return false;
    }
  }

  /// Update POI layers visibility based on selections (using pre-loaded layers)
  Future<bool> _updatePoiLayers(
    WidgetRef ref,
    MapLibreMapController mapController, {
    bool Function()? isCurrent,
  }) async {
    final previous = _poiMutationQueue;
    final done = Completer<void>();
    _poiMutationQueue = done.future;
    try {
      await previous;
      if (isCurrent != null && !isCurrent()) return false;
      debugPrint('🏪 Updating POI layer visibility based on selections');
      var succeeded = true;

      // Process each POI layer selection
      for (final entry in ref.read(poiLayerSelectionProvider).entries) {
        if (isCurrent != null && !isCurrent()) return false;
        final layerName = entry.key;
        var isVisible = entry.value;
        if (_isSpecialOverlay(layerName)) continue;

        // Use standardized layer naming for POI members
        final layerId = LayerNamingUtility.getPoiMemberLayerId(layerName);

        try {
          // Check if layer exists before setting visibility
          final layerIds = await mapController.getLayerIds();
          if (isCurrent != null && !isCurrent()) return false;
          isVisible = ref.read(poiLayerSelectionProvider)[layerName] ?? false;
          if (layerIds.contains(layerId)) {
            debugPrint(
                '🏪 Set POI layer visibility: $layerName ($layerId) = $isVisible');
            await mapController.setLayerVisibility(layerId, isVisible);
          } else if (isVisible) {
            debugPrint(
                '❌ Selected POI layer is missing: $layerName ($layerId)');
            succeeded = false;
          } else {
            debugPrint('⚠️ POI layer not found: $layerName ($layerId)');
          }
        } catch (e) {
          debugPrint('❌ Error setting POI layer visibility for $layerName: $e');
          succeeded = false;
        }
      }

      debugPrint('✅ POI layer visibility updates completed');
      return succeeded && (isCurrent == null || isCurrent());
    } catch (e) {
      debugPrint('❌ Error updating POI layers: $e');
      return false;
    } finally {
      done.complete();
    }
  }

  /// Add a symbol layer to the map
  Future<void> addSymbolLayer(
    String sourceId,
    String layerId,
    String layerName,
    MapLibreMapController mapController,
  ) async {
    await mapController.addSymbolLayer(
      sourceId,
      layerId,
      SymbolLayerProperties(
        iconImage: MapUtilities.getIconImage(layerName),
        iconSize: MapUtilities.structuresIconSize(sourceId),
        iconAllowOverlap: true,
      ),
      belowLayerId: 'Continent labels',
    );
  }

  /// Pre-load POI layers with standardized naming convention and hidden visibility.
  ///
  /// Returns true only if every POI member with a URL was added. Stops (and
  /// returns false) as soon as [isCurrent] reports the style/controller changed,
  /// so a stale restoration never adds sources to a newer style.
  Future<bool> preloadPoiLayers(
      WidgetRef ref, MapLibreMapController? mapController,
      {bool Function()? isCurrent}) async {
    if (mapController == null) return false;
    bool stale() => isCurrent != null && !isCurrent();
    debugPrint('\n🏪 === PRELOADING POI LAYERS ===');

    var allLoaded = true;
    try {
      // Get POI layers from menu assets
      final menuAssets = await ref.read(menuAssetsNotifierProvider.future);
      if (stale()) return false;

      debugPrint('✅ Menu assets loaded, processing POI layers');

      // Find POI layers (stopping places)
      final poiLayers = menuAssets.layers
          .where((layer) =>
              layer.listMenu == ListMenu.pointsOfInterest &&
              layer.groupMembers != null)
          .toList();

      for (final layer in poiLayers) {
        if (layer.groupMembers == null) continue;

        debugPrint('🏪 Processing POI group: ${layer.name}');
        for (final member in layer.groupMembers!) {
          if (stale()) return false;
          if (_isSpecialOverlay(member.name)) continue;
          if (!await _preloadPoiMember(member, mapController,
              isCurrent: isCurrent)) {
            allLoaded = false;
          }
        }
      }

      debugPrint('✅ POI layers preloading completed');
      return allLoaded && !stale();
    } catch (e) {
      debugPrint('❌ Error preloading POI layers: $e');
      return false;
    }
  }

  /// Restores selected travel-impact and road-incident overlays, which are
  /// driven by POI selections but are not part of [preloadPoiLayers].
  /// Returns true if every selected overlay was restored.
  Future<bool> restoreSelectedOverlays(
      WidgetRef ref, MapLibreMapController mapController,
      {bool Function()? isCurrent}) async {
    final generation = ++_overlayUpdateGeneration;
    bool stale() =>
        (isCurrent != null && !isCurrent()) ||
        generation != _overlayUpdateGeneration;
    Map<String, bool> selections = ref.read(poiLayerSelectionProvider);
    var ok = true;

    Map<String, dynamic>? travelImpactData;
    if ((selections['Rav Impacts'] ?? false) ||
        (selections['OSOM Impacts'] ?? false)) {
      try {
        travelImpactData = await ref.read(fetchGeoJsonDataProvider.future);
        if (stale()) return false;
      } catch (e) {
        if (stale()) return false;
        debugPrint('❌ Error fetching travel impact layers: $e');
        ok = false;
      }
    }

    Map<String, dynamic>? incidentsData;
    if (selections['Road Incidents'] ?? false) {
      try {
        incidentsData = await ref.read(fetchIncidentsDataProvider.future);
        if (stale()) return false;
      } catch (e) {
        if (stale()) return false;
        debugPrint('❌ Error fetching road incidents layer: $e');
        ok = false;
      }
    }

    final previous = _overlayMutationQueue;
    final done = Completer<void>();
    _overlayMutationQueue = done.future;
    try {
      await previous;
      if (stale()) return false;
      selections = ref.read(poiLayerSelectionProvider);
      final ravActive = selections['Rav Impacts'] ?? false;
      final osomActive = selections['OSOM Impacts'] ?? false;
      if (ravActive || osomActive) {
        if (travelImpactData == null) {
          ok = false;
        } else {
          final processed = processGeoJsonData({
            'data': travelImpactData,
            'toggleRAV': ravActive,
            'toggleOSOM': osomActive
          });
          await displayTravelImpactLayer(mapController, processed);
          if (stale()) return false;
          await setTravelImpactLayerVisibility(mapController, true);
        }
      } else {
        await removeTravelImpactLayers(mapController);
      }
      if (stale()) return false;

      selections = ref.read(poiLayerSelectionProvider);
      if (selections['Road Incidents'] ?? false) {
        if (incidentsData == null) {
          ok = false;
        } else {
          await displayIncidentsLayer(mapController, incidentsData);
          if (stale()) return false;
          await setIncidentsLayerVisibility(mapController, true);
        }
      } else {
        await removeIncidentsLayers(mapController);
      }
      return ok && !stale();
    } catch (e) {
      debugPrint('❌ Error restoring selected overlays: $e');
      return false;
    } finally {
      done.complete();
    }
  }

  bool _isSpecialOverlay(String name) =>
      name == 'Rav Impacts' ||
      name == 'OSOM Impacts' ||
      name == 'Road Incidents';

  /// Pre-load a specific POI member layer. Returns true if it was added (or has nothing to add).
  Future<bool> _preloadPoiMember(
      GroupMember member, MapLibreMapController mapController,
      {bool Function()? isCurrent}) async {
    if (member.url == null || member.url!.isEmpty) return true;

    try {
      debugPrint('   🔄 Preloading POI member: ${member.name}');

      // Use standardized naming for POI sources and layers
      final sourceId = LayerNamingUtility.getPoiMemberSourceId(member.name);
      final layerId = LayerNamingUtility.getPoiMemberLayerId(member.name);

      // Download and parse GeoJSON data
      final dio = buildAppDio();
      final response = await dio.get(member.url!);
      if (isCurrent != null && !isCurrent()) return false;

      // Parse response data
      dynamic jsonData;
      if (response.data is String) {
        jsonData = jsonDecode(response.data);
      } else {
        jsonData = response.data;
      }

      // Use safe source management to prevent race conditions
      await SourceManagementUtility.safeAddGeoJsonSource(
        mapController,
        sourceId,
        jsonData,
      );
      if (isCurrent != null && !isCurrent()) return false;

      // Add symbol layer with visibility set to false using safe layer addition
      final symbolProperties = SymbolLayerProperties(
        iconImage: MapUtilities.getIconImage(member.name),
        iconSize: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          10,
          0.8,
          15,
          1.2,
          18,
          1.8,
        ],
        iconAnchor: 'center',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        visibility: 'none', // Start hidden
      );

      await SourceManagementUtility.safeAddLayer(
        mapController,
        sourceId,
        layerId,
        symbolProperties,
        belowLayerId: 'Continent labels',
      );

      // SourceManagementUtility swallows add failures, so confirm the layer exists.
      final added = (await mapController.getLayerIds()).contains(layerId);
      debugPrint(added
          ? '   ✅ Preloaded POI layer: ${member.name}'
          : '   ❌ POI layer missing after add: ${member.name}');
      return added;
    } catch (e) {
      debugPrint('   ❌ Error preloading POI member ${member.name}: $e');
      return false;
    }
  }
}
