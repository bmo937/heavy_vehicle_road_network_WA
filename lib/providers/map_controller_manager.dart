// Map controller management and initialization
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/providers/map_utilities.dart';

class MapControllerManager {
  MapLibreMapController? _mapController;
  bool styleIsLoaded = false;
  double currentZoomLevel = 0;
  Function(dynamic, Point<double>, LatLng, String)? _featureTapListener;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Getters
  bool get styleLoaded => styleIsLoaded;
  MapLibreMapController? get mapController => _mapController;
  CameraPosition get initialCameraPosition => MapUtilities.initialCameraPosition;

  /// Initialize the map controller when map is created
  Future<void> onMapCreated(MapLibreMapController controller, WidgetRef ref, Function(dynamic, Point<double>, LatLng, String) onFeatureInteraction) async {
    debugPrint('\nMapControllerManager: onMapCreated called');
    _detachFeatureTapListener();
    _mapController = controller;

    // Set the controller in the provider
    ref.read(mapControllerProvider.notifier).state = controller;

    // Reset style loaded state when map is recreated (e.g., due to theme change)
    styleIsLoaded = false;

    // Add feature tap handler
    _featureTapListener = onFeatureInteraction;
    controller.onFeatureTapped.add(onFeatureInteraction);
    debugPrint('Added feature tap handler');

    // Move to initial position
    _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(initialCameraPosition),
    );

    debugPrint('MapControllerManager: onMapCreated completed\n');
  }

  void _detachFeatureTapListener() {
    final listener = _featureTapListener;
    if (listener != null) {
      _mapController?.onFeatureTapped.remove(listener);
      _featureTapListener = null;
    }
  }

  /// Unregister the feature-tap listener and drop the controller reference.
  /// The controller itself is owned and disposed by the map widget.
  void dispose() {
    _detachFeatureTapListener();
    _mapController = null;
    styleIsLoaded = false;
  }

  /// The current style is no longer usable (style change began or controller replaced).
  void markStyleUnavailable() {
    styleIsLoaded = false;
  }

  /// The current controller's style finished loading. Restoration of
  /// application-owned resources is orchestrated by MapPageNotifier.
  /// Returns false when there is no controller to restore onto.
  bool markStyleAvailable() {
    if (_mapController == null) {
      debugPrint('Map controller is null in onStyleLoaded');
      return false;
    }
    styleIsLoaded = true;
    return true;
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
