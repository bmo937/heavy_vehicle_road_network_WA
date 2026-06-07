// Feature interaction handling for map taps and queries
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/providers/map_utilities.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';
import 'package:roads_map/widgets/feature_display/feature_display_providers.dart';
import 'package:roads_map/widgets/navigation_widget/navigation_widget.dart';

class MapFeatureHandler {
  /// Check if a layer should be skipped for feature tapping
  bool _shouldSkipLayer(String layerId) {
    // Skip without conditions layer
    return layerId == LayerNamingUtility.WITHOUT_CONDITIONS_LAYER || layerId.toLowerCase().contains('withoutconditions') || layerId.toLowerCase().contains('without_conditions');
  }

  /// Handle feature taps on map
  void onFeatureInteraction(
    dynamic id,
    Point<double> point,
    LatLng coordinates,
    String layerId,
    WidgetRef ref,
    MapLibreMapController? mapController,
  ) async {
    if (mapController == null) return;
    debugPrint('Feature tapped: ID=$id, Coordinates=$coordinates, Layer=$layerId');

    // Handle the feature tap and check if it was processed
    final wasProcessed = await handleFeatureTap(null, id, point, coordinates, layerId, ref, mapController);

    // Only open the box if a feature was actually processed
    if (wasProcessed) {
      final boxController = ref.read(boxControllerProvider);
      if (boxController.isBoxClosed) {
        debugPrint('Opening sliding box for feature display');
        boxController.openBox();
      }
    }
  }

  /// Process feature taps and show information
  /// Returns true if a feature was processed, false if skipped
  Future<bool> handleFeatureTap(
    BuildContext? context,
    dynamic id,
    Point<double> point,
    LatLng coordinates,
    String originalLayerId,
    WidgetRef ref,
    MapLibreMapController mapController,
  ) async {
    debugPrint('Map feature tapped at ${coordinates.latitude}, ${coordinates.longitude}');
    debugPrint('Original layer ID: $originalLayerId, Feature ID: $id');

    // Check if the originally tapped layer should be skipped
    if (originalLayerId.isNotEmpty && _shouldSkipLayer(originalLayerId)) {
      debugPrint('Ignoring tap on without conditions layer: $originalLayerId');
      return false;
    }

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
      final mapLayerIds = await mapController.getLayerIds();
      debugPrint('Available layers: ${mapLayerIds.join(", ")}');

      // Get standardized layer patterns to query using our utility class
      final layersToQuery = LayerNamingUtility.getAllQueryableLayerIds().cast<String>();
      debugPrint('Querying standardized layers: ${layersToQuery.join(", ")}');

      // Track all found features
      List<Map<String, dynamic>> featuresWithLayers = []; // First, try to query the originally tapped layer specifically
      if (originalLayerId.isNotEmpty && mapLayerIds.contains(originalLayerId)) {
        // Skip without conditions layer
        if (_shouldSkipLayer(originalLayerId)) {
          debugPrint('Skipping without conditions layer: $originalLayerId');
        } else {
          debugPrint('Querying originally tapped layer: $originalLayerId');
          try {
            var originalFeatures = await mapController.queryRenderedFeaturesInRect(
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
      }

      // If we found features from the originally tapped layer, use those preferentially
      if (featuresWithLayers.isNotEmpty) {
        debugPrint('Using features from originally tapped layer: $originalLayerId');
      } else {
        debugPrint('No features found in originally tapped layer, querying all layers...'); // Second, check for any exact layer ID matches from all layers
        for (var layerId in mapLayerIds) {
          // Skip without conditions layer
          if (_shouldSkipLayer(layerId)) {
            debugPrint('Skipping without conditions layer: $layerId');
            continue;
          }

          try {
            var features = await mapController.queryRenderedFeaturesInRect(
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
          List<String> matchingLayers = [];
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
          } // Query each matching layer
          for (var layerId in matchingLayers) {
            // Skip without conditions layer
            if (_shouldSkipLayer(layerId)) {
              debugPrint('Skipping without conditions layer: $layerId');
              continue;
            }

            try {
              var features = await mapController.queryRenderedFeaturesInRect(
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
        return false;
      }

      // Sort features to prioritize the originally tapped layer first
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
        bool aIsCustom = MapUtilities.isCustomLayer(layerA);
        bool bIsCustom = MapUtilities.isCustomLayer(layerB);

        if (aIsCustom && !bIsCustom) return -1;
        if (!aIsCustom && bIsCustom) return 1;

        return 0;
      });

      // Get the first feature from our collected features
      final feature = featuresWithLayers.first;

      // Log the selected feature after sorting
      debugPrint('Selected feature after prioritization: Layer=${feature['layerId']}, ID=${feature['id']}');

      // Print out the full feature for debugging
      debugPrint('Feature data: ${feature.toString()}');

      // We already have the layer ID stored in the feature
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

      debugPrint('Created tapped feature object');

      // Store in provider
      final featureTapNotifier = ref.read(featureTapStateProvider.notifier);
      featureTapNotifier.setTappedFeature(tappedFeature);
      debugPrint('Stored tapped feature in provider');

      // Make sure feature details are set to be shown
      ref.read(showFeatureDetailsProvider.notifier).state = true;

      // Switch to feature details tab
      ref.read(selectedIndexProvider.notifier).state = 3;
      debugPrint('Set selectedIndex=3 and showFeatureDetails=true'); // Animate camera to feature location
      final zoomLevel = mapController.cameraPosition!.zoom;
      await mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: coordinates,
        zoom: zoomLevel,
      )));

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error handling feature tap: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
