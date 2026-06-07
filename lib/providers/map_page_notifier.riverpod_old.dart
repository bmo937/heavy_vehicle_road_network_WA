/* // Main MapPageNotifier coordinating map functionality
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:roads_map/providers/map_provider_state.dart';
import 'package:roads_map/providers/map_controller_manager.dart';
import 'package:roads_map/providers/map_camera_handler.dart';
import 'package:roads_map/providers/map_feature_handler.dart';
import 'package:roads_map/providers/map_layer_manager.dart';
import 'package:roads_map/providers/map_utilities.dart';
import 'package:roads_map/utils/map_theme_provider.riverpod.dart';

part 'map_page_notifier.riverpod.g.dart';

@riverpod
class MapPageNotifier extends _$MapPageNotifier {
  // Component managers
  final MapControllerManager _controllerManager = MapControllerManager();
  final MapCameraHandler _cameraHandler = MapCameraHandler();
  final MapFeatureHandler _featureHandler = MapFeatureHandler();
  final MapLayerManager _layerManager = MapLayerManager();

  // Getters that delegate to the controller manager
  bool get styleLoaded => _controllerManager.styleLoaded;
  MapLibreMapController? get mapController => _controllerManager.mapController;
  CameraPosition get initialCameraPosition => _controllerManager.initialCameraPosition;
  GlobalKey<ScaffoldState> get scaffoldKey => _controllerManager.scaffoldKey;
  double get currentZoomLevel => _controllerManager.currentZoomLevel;

  void onMapCreated(MapLibreMapController controller, WidgetRef ref) async {
    await _controllerManager.onMapCreated(controller, ref, 
      (id, point, coordinates, layerId) => _featureHandler.onFeatureInteraction(id, point, coordinates, layerId, ref, controller));
  }

  void onCameraIdle(BuildContext context) async {
    await _cameraHandler.onCameraIdle(
      context,
      mapController,
      ref,
      styleLoaded,
      (context, bounds) => _layerManager.updateVisibleLayers(context, bounds, ref, mapController),
    );
  }

  Future onStyleLoaded() async {
    await _controllerManager.onStyleLoaded(
      ref,
      () => _layerManager.preloadPoiLayers(ref, mapController),
      () => forceLayerUpdate(),
    );
  }

  /// Force an immediate layer update without waiting for camera movement
  Future<void> forceLayerUpdate() async {
    await _layerManager.forceLayerUpdate(
      mapController,
      styleLoaded,
      ref,
      (context, bounds) => _layerManager.updateVisibleLayers(context, bounds, ref, mapController),
    );
  }

  void onMapIdle(BuildContext context) {
    _cameraHandler.onMapIdle(context);
  }

  /// Handle feature taps on map
  void onFeatureInteraction(dynamic id, Point<double> point, LatLng coordinates, String layerId) {
    _featureHandler.onFeatureInteraction(id, point, coordinates, layerId, ref, mapController);
  }

  /// Process feature taps and show information
  void handleFeatureTap(BuildContext? context, dynamic id, Point<double> point, LatLng coordinates, String originalLayerId) async {
    await _featureHandler.handleFeatureTap(context, id, point, coordinates, originalLayerId, ref, mapController!);
  }

  dynamic structuresIconSize(String sourceId) {
    return MapUtilities.structuresIconSize(sourceId);
  }

  String getIconImage(String layerName) {
    return MapUtilities.getIconImage(layerName);
  }

  @override
  Future<MapProviderState> build() async {
    ref.onDispose(() {
      debugPrint('MapPageProvider disposed');
      _cameraHandler.dispose();
    });
    
    // Rest of your build method
    final settingsBox = Hive.isBoxOpen('settingsBox') ? Hive.box('settingsBox') : await Hive.openBox('settingsBox');

    final isTravelLayerVisible = settingsBox.get('isTravelLayerVisible', defaultValue: false) as bool;
    final isSatelliteLayerVisible = settingsBox.get('isSatelliteLayerVisible', defaultValue: false) as bool;

    final currentStyleUrl = ref.read(mapThemeProvider);

    return MapProviderState(
      currentStyleUrl: currentStyleUrl,
      isSatelliteLayerVisible: isTravelLayerVisible,
      isTravelLayerVisible: isSatelliteLayerVisible,
    );
  }
}

  void onMapCreated(MapLibreMapController controller, WidgetRef ref) async {
    debugPrint('\nMapPageNotifier: onMapCreated called');
    _mapController = controller;
    ref.read(MapPageNotifier.mapControllerProvider.notifier).state = controller;

    // Reset style loaded state when map is recreated (e.g., due to theme change)
    styleIsLoaded = false;

    // Add feature tap handler
    _mapController!.onFeatureTapped.add(onFeatureInteraction);
    debugPrint('Added feature tap handler');

    // Move to initial position
    _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(initialCameraPosition),
    );

    debugPrint('MapPageNotifier: onMapCreated completed\n');
  }

  void onCameraIdle(BuildContext context) async {
    if (_mapController == null) return;
    if (!styleIsLoaded) {
      debugPrint('Style not loaded yet, ignoring camera idle event');
      return;
    }

    debugPrint('\n=== MapPageNotifier: onCameraIdle called ===');

    // Update the zoom level
    currentZoomLevel = _mapController!.cameraPosition?.zoom ?? 0;
    debugPrint('Zoom: $currentZoomLevel');

    // Cancel any pending timer
    _cameraIdleDebounceTimer?.cancel();

    // Check if a layer is currently being loaded - prevent race conditions
    final isLayerLoading = ref.read(onlineLayerLoadingProvider);
    if (isLayerLoading) {
      debugPrint('⚠️ Layer is currently loading, skipping camera idle update to prevent race condition');

      // Set a timer to retry after the layer loading completes
      _cameraIdleDebounceTimer = Timer(Duration(milliseconds: _updateDelayMilliseconds * 2), () => onCameraIdle(context));
      return;
    }

    // Check if we need to enforce cooling period
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastUpdateTime).inMilliseconds;

    if (_isHandlingCameraIdle || timeSinceLastUpdate < _updateDelayMilliseconds) {
      debugPrint('Debouncing camera idle event (last update ${timeSinceLastUpdate}ms ago)');

      // Set a timer to process after the debounce period
      _cameraIdleDebounceTimer = Timer(Duration(milliseconds: _updateDelayMilliseconds), () => onCameraIdle(context) // Retry after delay
          );
      return;
    }

    // We're now handling a camera idle event
    _isHandlingCameraIdle = true;
    _lastUpdateTime = now;

    try {
      // Get current visible bounds
      final visibleBounds = await _mapController!.getVisibleRegion();
      debugPrint('Visible bounds: ${visibleBounds.southwest} to ${visibleBounds.northeast}');

      // Get active online layer if any
      final activeLayer = ref.read(activeOnlineLayerProvider);

      // Check if we have an active layer that needs updating
      if (activeLayer != null) {
        // Double-check that loading state hasn't changed while we were getting bounds
        final isStillLoading = ref.read(onlineLayerLoadingProvider);
        if (isStillLoading) {
          debugPrint('⚠️ Layer loading detected during bounds check, aborting camera idle update');
          return;
        } // Update existing network layer with new bounds
        await updateNetworkLayerWithNewBounds(
          mapController: _mapController!,
          member: activeLayer,
          visibleBounds: visibleBounds,
          loadingNotifier: ref.read(onlineLayerLoadingProvider.notifier),
          lastBoundsNotifier: ref.read(lastMapBoundsProvider.notifier),
          isLoading: isStillLoading, // Pass the loading state
        );
      } else {
        // Check if we need to update map data based on selected layers
        await _updateVisibleLayers(context, visibleBounds);
      }
    } catch (e) {
      debugPrint('Error in onCameraIdle: $e');
    } finally {
      _isHandlingCameraIdle = false;
      debugPrint('MapPageNotifier: onCameraIdle completed\n');
    }
  }

  Future onStyleLoaded() async {
    debugPrint('\nMapPageNotifier: onStyleLoaded called');
    try {
      if (_mapController == null) {
        debugPrint('Map controller is null in onStyleLoaded');
        return;
      }

      // Mark style as loaded first
      styleIsLoaded = true;
      try {
        // Add marker images safely (after style is loaded)
        await MarkerUtilities.addImagesToMap(_mapController!);
        debugPrint('Successfully added marker images to map');
      } catch (imageError) {
        debugPrint('Error adding marker images: $imageError');
      }

      // Pre-load POI layers with standardized naming and hidden visibility
      await _preloadPoiLayers();

      // After style loads (like when theme changes), reload any currently selected layers
      await forceLayerUpdate();
    } catch (e) {
      debugPrint('Error in onStyleLoaded: $e');
    } finally {
      debugPrint('MapPageNotifier: onStyleLoaded completed\n');
    }
  }

  /// Force an immediate layer update without waiting for camera movement
  /// This is useful when network selections change or theme changes
  Future<void> forceLayerUpdate() async {
    if (_mapController == null || !styleIsLoaded) {
      debugPrint('❌ Cannot force layer update - map controller or style not ready');
      debugPrint('   Map controller: ${_mapController != null ? "✅" : "❌"}');
      debugPrint('   Style loaded: ${styleIsLoaded ? "✅" : "❌"}');
      return;
    }

    debugPrint('\n🔥 === MapPageNotifier: forceLayerUpdate called ===');

    try {
      // Get current visible bounds
      final visibleBounds = await _mapController!.getVisibleRegion();
      debugPrint('📍 Forcing layer update for bounds: ${visibleBounds.southwest} to ${visibleBounds.northeast}');

      // Update visible layers immediately
      debugPrint('🔄 Calling _updateVisibleLayers...');
      await _updateVisibleLayers(null, visibleBounds);

      debugPrint('✅ Force layer update completed');
    } catch (e) {
      debugPrint('❌ Error in forceLayerUpdate: $e');
    } finally {
      debugPrint('🔥 MapPageNotifier: forceLayerUpdate completed\n');
    }
  }

  void onMapIdle(BuildContext context) {
    debugPrint('\nMapPageNotifier: onMapIdle called');
    // This is a placeholder for future implementation
    // Could handle additional map idle events here
    debugPrint('MapPageNotifier: onMapIdle completed\n');
  }

  /// Handle feature taps on map
  void onFeatureInteraction(dynamic id, Point<double> point, LatLng coordinates, String layerId) {
    if (_mapController == null) return;
    debugPrint('Feature tapped: ID=$id, Coordinates=$coordinates, Layer=$layerId');

    // Set box controller to open
    final boxController = ref.read(boxControllerProvider);
    if (boxController.isBoxClosed) {
      debugPrint('Opening sliding box for feature display');
      boxController.openBox();
    }

    // Handle the feature tap directly without requiring a context
    handleFeatureTap(null, id, point, coordinates, layerId);
  }

  /// Process feature taps and show information
  void handleFeatureTap(BuildContext? context, dynamic id, Point<double> point, LatLng coordinates, String originalLayerId) async {
    if (_mapController == null) return;

    debugPrint('Map feature tapped at ${coordinates.latitude}, ${coordinates.longitude}');
    debugPrint('Original layer ID: $originalLayerId, Feature ID: $id');

    // Query rendered features
    try {
      const double tolerance = 15.0; // in pixels

      // Create a bounding box around the tap point
      Rect bbox = Rect.fromLTRB(
        point.x - tolerance,
        point.y - tolerance,
        point.x + tolerance,
        point.y + tolerance,
      );

      debugPrint('Querying features at point: ${point.x}, ${point.y}');

      // Get all layer IDs currently on the map
      final mapLayerIds = await _mapController!.getLayerIds();
      debugPrint('Available layers: ${mapLayerIds.join(", ")}'); // Get standardized layer patterns to query using our utility class
      final layersToQuery = LayerNamingUtility.getAllQueryableLayerIds().cast<String>();
      debugPrint('Querying standardized layers: ${layersToQuery.join(", ")}'); // Track all found features
      List<Map<String, dynamic>> featuresWithLayers = [];

      // First, try to query the originally tapped layer specifically
      if (originalLayerId.isNotEmpty && mapLayerIds.contains(originalLayerId)) {
        debugPrint('Querying originally tapped layer: $originalLayerId');
        try {
          var originalFeatures = await _mapController!.queryRenderedFeaturesInRect(
            bbox,
            [originalLayerId],
            null,
          );

          for (var feature in originalFeatures) {
            feature['layerId'] = originalLayerId;
            debugPrint('Found feature in originally tapped layer $originalLayerId with ID: ${feature['id']}');
            featuresWithLayers.add(feature);
          }
        } catch (e) {
          debugPrint('Error querying originally tapped layer $originalLayerId: $e');
        }
      }

      // If we found features from the originally tapped layer, use those preferentially
      if (featuresWithLayers.isNotEmpty) {
        debugPrint('Using features from originally tapped layer: $originalLayerId');
      } else {
        debugPrint('No features found in originally tapped layer, querying all layers...');

        // Second, check for any exact layer ID matches from all layers
        for (var layerId in mapLayerIds) {
          try {
            var features = await _mapController!.queryRenderedFeaturesInRect(
              bbox,
              [layerId],
              null,
            );

            for (var feature in features) {
              // Add layerId to each feature for identification
              feature['layerId'] = layerId;
              debugPrint('Found feature in layer $layerId with ID: ${feature['id']}');
              featuresWithLayers.add(feature);
            }
          } catch (e) {
            debugPrint('Error querying layer $layerId: $e');
          }
        }
      }

      // If no features found with exact matches, try pattern matching
      if (featuresWithLayers.isEmpty) {
        debugPrint('No exact matches found, trying pattern matching...');

        // Query using wildcard patterns from our utility class
        for (var patternId in layersToQuery) {
          // Skip patterns that won't match any layers
          if (!patternId.contains('*') && !mapLayerIds.contains(patternId)) {
            continue;
          }

          // Handle wildcard patterns by finding matching layers
          List<String> matchingLayers = []; // Remove the nullable type and use a non-nullable list
          if (patternId.contains('*')) {
            // Convert pattern to regex by replacing * with .*
            final regexPattern = patternId.replaceAll('*', '.*');
            final regex = RegExp(regexPattern);

            // Find matching layer IDs - add explicit cast to String
            matchingLayers = mapLayerIds.where((id) => regex.hasMatch(id)).cast<String>().toList();
          } else {
            // Direct match
            if (mapLayerIds.contains(patternId)) {
              matchingLayers = [patternId];
            }
          }

          // Query each matching layer
          for (var layerId in matchingLayers) {
            try {
              var features = await _mapController!.queryRenderedFeaturesInRect(
                bbox,
                [layerId],
                null,
              );

              for (var feature in features) {
                feature['layerId'] = layerId;
                debugPrint('Found feature in layer $layerId with ID: ${feature['id']}');
                featuresWithLayers.add(feature);
              }
            } catch (e) {
              debugPrint('Error querying layer $layerId: $e');
            }
          }
        }
      }
      debugPrint('Found ${featuresWithLayers.length} features at tap location');

      // Log all found features for debugging
      for (int i = 0; i < featuresWithLayers.length; i++) {
        final f = featuresWithLayers[i];
        debugPrint('Feature $i: Layer=${f['layerId']}, ID=${f['id']}');
      }

      if (featuresWithLayers.isEmpty) {
        debugPrint('No features found at tap location');
        return;
      } // Sort features to prioritize the originally tapped layer first
      featuresWithLayers.sort((a, b) {
        String layerA = a['layerId'] as String;
        String layerB = b['layerId'] as String;

        // First priority: the layer that was originally tapped
        bool aIsOriginal = layerA == originalLayerId;
        bool bIsOriginal = layerB == originalLayerId;

        if (aIsOriginal && !bIsOriginal) return -1;
        if (!aIsOriginal && bIsOriginal) return 1;

        // Second priority: POI and incident layers over base map layers
        bool aIsPOI = layerA.contains('poi') || layerA.contains('incident');
        bool bIsPOI = layerB.contains('poi') || layerB.contains('incident');

        if (aIsPOI && !bIsPOI) return -1;
        if (!aIsPOI && bIsPOI) return 1;

        // Third priority: custom layers over base map layers
        bool aIsCustom = _isCustomLayer(layerA);
        bool bIsCustom = _isCustomLayer(layerB);

        if (aIsCustom && !bIsCustom) return -1;
        if (!aIsCustom && bIsCustom) return 1;

        return 0;
      }); // Get the first feature from our collected features
      final feature = featuresWithLayers.first;

      // Log the selected feature after sorting
      debugPrint('Selected feature after prioritization: Layer=${feature['layerId']}, ID=${feature['id']}');

      // Print out the full feature for debugging
      debugPrint('Feature data: ${feature.toString()}'); // We already have the layer ID stored in the feature
      String layerId = feature['layerId'] ?? '';
      debugPrint('Layer ID from query: $layerId');

      // Special handling for enum layer IDs
      if (layerId.contains('SubLayerFeatureType')) {
        debugPrint('Handling special layer type: $layerId');
        // Extract just the layer type name without the enum prefix
        layerId = layerId.split('.').last;
      }

      // Extract properties (with null safety)
      final properties = feature['properties'] as Map<String, dynamic>? ?? <String, dynamic>{};

      // Create TappedFeature object
      final tappedFeature = TappedFeature(
        properties: properties,
        layerId: layerId,
        featureId: feature['id']?.toString() ?? id?.toString() ?? 'unknown',
        position: coordinates,
      );

      debugPrint('Created tapped feature object'); // Store in provider
      final featureTapNotifier = ref.read(featureTapStateProvider.notifier);
      featureTapNotifier.setTappedFeature(tappedFeature);
      debugPrint('Stored tapped feature in provider');

      // Make sure feature details are set to be shown
      ref.read(showFeatureDetailsProvider.notifier).state = true;

      // Switch to feature details tab
      ref.read(selectedIndexProvider.notifier).state = 3;
      debugPrint('Set selectedIndex=3 and showFeatureDetails=true');

      // Animate camera to feature location
      final zoomLevel = mapController!.cameraPosition!.zoom;
      await _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: coordinates,
        zoom: zoomLevel,
      )));
    } catch (e, stackTrace) {
      debugPrint('Error handling feature tap: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  dynamic structuresIconSize(String sourceId) {
    switch (sourceId) {
      case 'drive_over_structures_source':
      case 'drive_under_structures_source':
        return [
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          0.1,
          10,
          0.4,
          15,
          1.3,
          20,
          2
        ];
      default:
        return [
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          0.3,
          10,
          0.7,
          15,
          1.7,
          20,
          2.5
        ];
    }
  }

  String getIconImage(String layerName) {
    if (layerName.contains('Road Train Assembly')) return 'rtaa';
    if (layerName.contains('Heavy Vehicle Rest')) return 'heavy';
    if (layerName.contains('Major Rest')) return 'major';
    if (layerName.contains('Minor Rest')) return 'minor';
    if (layerName.contains('Roadhouse')) return 'roadhouse';
    if (layerName.contains('Drive Under')) return 'bridge'; // Use bridge icon for drive under structures
    if (layerName.contains('Drive Over')) return 'bridge'; // Use bridge icon for drive over structures
    if (layerName.contains('Bridge')) return 'bridge';
    if (layerName.contains('Intersection')) return 'intersection';
    if (layerName.contains('Rav')) return 'trafficCone';
    if (layerName.contains('OSOM')) return 'noEntry';
    if (layerName.contains('Incidents')) return 'caution';
    if (layerName.contains('Inspection')) return 'inspection';
    return 'alert';
  }

  /* (String, String) getSourceAndLayerIds(SubLayerFeatureType featureType) {
    switch (featureType) {
      case SubLayerFeatureType.bridges:
        return ('bridgeSource', 'bridgeLayer');
      case SubLayerFeatureType.intersections:
        return ('intersectionSource', 'intersectionLayer');
      case SubLayerFeatureType.withConditions:
        return ('withConditionsSource', 'withConditionsLayer');
      case SubLayerFeatureType.withoutConditions:
        return ('withoutConditionsSource', 'withoutConditionsLayer');
    }
  } */

  /// Helper method to determine if a layer is a custom layer (not a base map layer)
  bool _isCustomLayer(String layerId) {
    // Base map layers that should have lower priority
    const baseMapLayers = [
      'Background',
      'Residential',
      'Landcover',
      'Hillshade',
      'River',
      'Water shadow',
      'Water',
      'Aeroway',
      'Tunnel path',
      'Tunnel',
      'Railway tunnel',
      'Railway tunnel dash',
      'Land outline',
      'Pier',
      'Pier road',
      'Bridge',
      'Road network',
      'Path minor',
      'Path',
      'Railway',
      'Railway dash',
      'Building',
      'Other border',
      'Other border dash',
      'Disputed border',
      'Country border',
      'Ocean labels',
      'Sea labels',
      'Lakeline labels',
      'Road labels',
      'Place labels',
      'Village labels',
      'Town labels',
      'State labels',
      'City labels',
      'Country labels',
      'Continent labels'
    ];

    // Check if this is a base map layer
    if (baseMapLayers.contains(layerId)) {
      return false;
    }

    // Check if this is an annotation layer
    if (layerId.contains('org.maplibre.annotations') || layerId.length == 10) {
      // MapLibre generated layer IDs are typically 10 chars
      return false;
    }

    // Everything else is considered a custom layer
    return true;
  }

  /// Update any visible layers based on current selection
  Future<void> _updateVisibleLayers(BuildContext? context, LatLngBounds visibleBounds) async {
    if (_mapController == null) return;

    debugPrint('\n🔍 === _updateVisibleLayers called ===');

    try {
      // Check network layer selection
      final networkLayerSelection = ref.read(networkLayerSelectionProvider);
      debugPrint('🌐 Network layer selection: $networkLayerSelection');

      if (networkLayerSelection != null && networkLayerSelection.isNotEmpty) {
        debugPrint('✅ Selected network layer: $networkLayerSelection');
        debugPrint('🔄 Calling _updateNetworkLayer...');
        await _updateNetworkLayer(networkLayerSelection, visibleBounds);
      } else {
        debugPrint('⚠️ No network layer selected');
      }

      // Check POI layer selections
      final poiLayerSelections = ref.read(poiLayerSelectionProvider);
      debugPrint('🏛️ POI layer selections: $poiLayerSelections');

      if (poiLayerSelections.isNotEmpty) {
        final activeLayers = poiLayerSelections.entries.where((e) => e.value).map((e) => e.key).toList();

        if (activeLayers.isNotEmpty) {
          debugPrint('✅ Active POI layers: ${activeLayers.join(", ")}');
          debugPrint('🔄 Calling _updatePoiLayers...');
          await _updatePoiLayers(poiLayerSelections, visibleBounds);
        } else {
          debugPrint('⚠️ No active POI layers');
        }
      } else {
        debugPrint('⚠️ No POI layer selections');
      }
    } catch (e) {
      debugPrint('❌ Error updating visible layers: $e');
    } finally {
      debugPrint('🔍 === _updateVisibleLayers completed ===\n');
    }
  }

  /// Update the network layer based on selection
  Future<void> _updateNetworkLayer(String layerName, LatLngBounds visibleBounds) async {
    debugPrint('Updating network layer: $layerName');

    try {
      // Get menu assets
      final menuAssetsProvider = ref.read(menuAssetsNotifierProvider);
      final menuAssets = menuAssetsProvider.value;

      if (menuAssets == null) {
        debugPrint('Menu assets not available yet');
        return;
      }

      // Initialize loading notifier and bounds notifier
      final loadingNotifier = ref.read(onlineLayerLoadingProvider.notifier);
      final lastBoundsNotifier = ref.read(lastMapBoundsProvider.notifier);

      // Search in group members of each top-level layer
      bool foundInGroupMembers = false;

      for (final parentLayer in menuAssets.layers) {
        if (parentLayer.groupMembers == null || parentLayer.groupMembers!.isEmpty) {
          continue;
        }

        // Check if this layer's group members contain our target
        for (final member in parentLayer.groupMembers!) {
          if (member.name == layerName) {
            debugPrint('Found layer in group members: ${parentLayer.name} > ${member.name}');
            foundInGroupMembers = true;

            // Use the online_layers.dart helper to load the layer
            await loadNetworkLayerData(
              mapController: _mapController!,
              member: member,
              visibleBounds: visibleBounds,
              activeLayerNotifier: ref.read(activeOnlineLayerProvider.notifier),
              loadingNotifier: loadingNotifier,
              lastBoundsNotifier: lastBoundsNotifier,
            );

            break; // Found what we're looking for, exit inner loop
          }
        }

        if (foundInGroupMembers) {
          break; // Found what we're looking for, exit outer loop
        }
      }

      // If we didn't find the layer anywhere, throw an exception
      if (!foundInGroupMembers) {
        throw Exception('Layer not found: $layerName');
      }
    } catch (e) {
      debugPrint('Error updating network layer: $e');
    }
  }

  /// Update POI layers visibility based on selections (using pre-loaded layers)
  Future<void> _updatePoiLayers(Map<String, bool> poiSelections, LatLngBounds visibleBounds) async {
    if (_mapController == null) return;

    try {
      debugPrint('🏪 Updating POI layer visibility based on selections');

      // Process each POI layer selection
      for (final entry in poiSelections.entries) {
        final layerName = entry.key;
        final isVisible = entry.value;

        // Use standardized layer naming for POI members
        final layerId = LayerNamingUtility.getPoiMemberLayerId(layerName);

        try {
          // Check if layer exists before setting visibility
          final layerIds = await _mapController!.getLayerIds();
          if (layerIds.contains(layerId)) {
            await _mapController!.setLayerVisibility(layerId, isVisible);
            debugPrint('🏪 Set POI layer visibility: $layerName ($layerId) = $isVisible');
          } else {
            debugPrint('⚠️ POI layer not found (may not be pre-loaded yet): $layerId');
          }
        } catch (e) {
          debugPrint('❌ Error setting POI layer visibility for $layerName: $e');
        }
      }

      debugPrint('✅ POI layer visibility updates completed');
    } catch (e) {
      debugPrint('❌ Error updating POI layers: $e');
    }
  }

  Future<void> _addSymbolLayer(String sourceId, String layerId, String layerName) async {
    if (_mapController == null) return;

    await _mapController!.addSymbolLayer(
      sourceId,
      layerId,
      SymbolLayerProperties(
        iconImage: getIconImage(layerName),
        iconSize: structuresIconSize(sourceId),
        iconAllowOverlap: true,
      ),
      belowLayerId: 'Continent labels',
    );
  }

  /// Pre-load POI layers with standardized naming convention and hidden visibility
  Future<void> _preloadPoiLayers() async {
    if (_mapController == null) return;
    debugPrint('\n🏪 === PRELOADING POI LAYERS ===');

    try {
      // Get POI layers from menu assets
      final menuAssets = await ref.read(menuAssetsNotifierProvider.future);

      debugPrint('✅ Menu assets loaded, processing POI layers');

      // Find POI layers (stopping places)
      final poiLayers = menuAssets.layers.where((layer) => layer.listMenu == ListMenu.pointsOfInterest && layer.groupMembers != null).toList();

      for (final layer in poiLayers) {
        if (layer.groupMembers == null) continue;

        for (final member in layer.groupMembers!) {
          // Skip travel impact layers (they're handled separately)
          if (member.name.toLowerCase().contains('impact') || member.name.toLowerCase().contains('incident')) {
            continue;
          }

          await _preloadPoiMember(member);
        }
      }

      debugPrint('✅ POI layers preloading completed');
    } catch (e) {
      debugPrint('❌ Error preloading POI layers: $e');
    }
  }

  /// Pre-load a specific POI member layer
  Future<void> _preloadPoiMember(GroupMember member) async {
    if (_mapController == null || member.url == null || member.url!.isEmpty) return;

    try {
      // Use standardized naming convention
      final sourceId = LayerNamingUtility.getPoiMemberSourceId(member.name);
      final layerId = LayerNamingUtility.getPoiMemberLayerId(member.name);

      debugPrint('🏪 Preloading POI layer: ${member.name}');
      debugPrint('   Source ID: $sourceId');
      debugPrint('   Layer ID: $layerId');

      // Check if both source and layer already exist
      final sourceIds = await _mapController!.getSourceIds();
      final layerIds = await _mapController!.getLayerIds();

      if (sourceIds.contains(sourceId) && layerIds.contains(layerId)) {
        debugPrint('   Source and layer already exist, skipping: $sourceId, $layerId');
        return;
      }

      // Replace $boundsString placeholder with a default wide bounds to get initial data
      // This ensures we have some data available immediately
      String url = member.url!;
      if (url.contains('\$boundsString')) {
        // Use WA state bounds as default
        debugPrint('   Replacing \$boundsString in URL: $url');
        const defaultBounds = '112.920394,-35.135060,129.003317,-13.741018';
        url = url.replaceAll('\$boundsString', defaultBounds);
      }

      debugPrint('   Fetching data from URL: $url');
      // Ensure URL is valid
      if (!Uri.parse(url).isAbsolute) {
        debugPrint('   ❌ Invalid URL: $url');
        return;
      }

      // Fetch data from URL
      final dio = Dio();
      final response = await dio.get(url);

      if (response.statusCode != 200) {
        debugPrint('   ❌ Failed to fetch data for ${member.name}');
        return;
      }

      // Parse response data
      dynamic jsonData;
      if (response.data is String) {
        jsonData = jsonDecode(response.data);
      } else {
        jsonData = response.data;
      }

      // Use safe source management to prevent race conditions
      await SourceManagementUtility.safeAddGeoJsonSource(
        _mapController!,
        sourceId,
        jsonData,
      );

      // Add symbol layer with visibility set to false using safe layer addition
      final symbolProperties = SymbolLayerProperties(
        iconImage: getIconImage(member.name),
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
        _mapController!,
        sourceId,
        layerId,
        symbolProperties,
      );

      debugPrint('   ✅ Preloaded POI layer: ${member.name}');
    } catch (e) {
      debugPrint('   ❌ Error preloading POI member ${member.name}: $e');
    }
  }

  @override
  Future<MapProviderState> build() async {
    ref.onDispose(() {
      debugPrint('MapPageProvider disposed');
    });
    // Rest of your build method
    final settingsBox = Hive.isBoxOpen('settingsBox') ? Hive.box('settingsBox') : await Hive.openBox('settingsBox');

    final isTravelLayerVisible = settingsBox.get('isTravelLayerVisible', defaultValue: false) as bool;
    final isSatelliteLayerVisible = settingsBox.get('isSatelliteLayerVisible', defaultValue: false) as bool;

    final currentStyleUrl = ref.read(mapThemeProvider);

    return MapProviderState(
      currentStyleUrl: currentStyleUrl,
      isSatelliteLayerVisible: isTravelLayerVisible,
      isTravelLayerVisible: isSatelliteLayerVisible,
    );
  }
}
 */