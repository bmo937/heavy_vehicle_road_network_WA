// Map controller management and initialization
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/providers/map_utilities.dart';
import 'package:roads_map/utils/marker_utilities.riverpod.dart';

class MapControllerManager {
  MapLibreMapController? _mapController;
  bool styleIsLoaded = false;
  double currentZoomLevel = 0;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Getters
  bool get styleLoaded => styleIsLoaded;
  MapLibreMapController? get mapController => _mapController;
  CameraPosition get initialCameraPosition => MapUtilities.initialCameraPosition;

  /// Initialize the map controller when map is created
  Future<void> onMapCreated(MapLibreMapController controller, WidgetRef ref, Function(dynamic, Point<double>, LatLng, String) onFeatureInteraction) async {
    debugPrint('\nMapControllerManager: onMapCreated called');
    _mapController = controller;

    // Set the controller in the provider
    ref.read(mapControllerProvider.notifier).state = controller;

    // Reset style loaded state when map is recreated (e.g., due to theme change)
    styleIsLoaded = false;

    // Add feature tap handler
    _mapController!.onFeatureTapped.add(onFeatureInteraction);
    debugPrint('Added feature tap handler');

    // Move to initial position
    _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(initialCameraPosition),
    );

    debugPrint('MapControllerManager: onMapCreated completed\n');
  }

  /// Handle when map style is loaded
  Future<void> onStyleLoaded(WidgetRef ref, Function() preloadPoiLayers, Function() forceLayerUpdate, Function() markStyleLoaded) async {
    debugPrint('\nMapControllerManager: onStyleLoaded called');
    try {
      if (_mapController == null) {
        debugPrint('Map controller is null in onStyleLoaded');
        return;
      }

      // Mark style as loaded first
      styleIsLoaded = true;

      // Mark the style load time to prevent double-loading
      markStyleLoaded();

      try {
        // Add marker images safely (after style is loaded)
        await MarkerUtilities.addImagesToMap(_mapController!);
        debugPrint('Successfully added marker images to map');
      } catch (imageError) {
        debugPrint('Error adding marker images: $imageError');
      } // Pre-load POI layers with standardized naming and hidden visibility
      await preloadPoiLayers();

      // After style loads (like when theme changes), reload any currently selected layers
      await forceLayerUpdate();

      debugPrint('🎉 onStyleLoaded completed - map is ready with all layers');
    } catch (e) {
      debugPrint('Error in onStyleLoaded: $e');
    } finally {
      debugPrint('MapControllerManager: onStyleLoaded completed\n');
    }
  }

  /// Update current zoom level
  void updateZoomLevel() {
    if (_mapController != null) {
      currentZoomLevel = _mapController!.cameraPosition?.zoom ?? 0;
    }
  }

  /// Force camera position update
  Future<void> animateToPosition(LatLng coordinates, double? zoom) async {
    if (_mapController == null) return;

    final zoomLevel = zoom ?? _mapController!.cameraPosition!.zoom;
    await _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: coordinates,
      zoom: zoomLevel,
    )));
  }
}

// Provider for the map controller
final mapControllerProvider = StateProvider<MapLibreMapController?>((ref) => null);
