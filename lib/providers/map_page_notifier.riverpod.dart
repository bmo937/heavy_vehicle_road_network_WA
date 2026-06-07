// Main MapPageNotifier coordinating map functionality
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/providers/map_camera_handler.dart';
import 'package:roads_map/providers/map_controller_manager.dart';
import 'package:roads_map/providers/map_feature_handler.dart';
import 'package:roads_map/providers/map_layer_manager.dart';
import 'package:roads_map/providers/map_provider_state.dart';
import 'package:roads_map/providers/map_utilities.dart';
import 'package:roads_map/utils/map_style_service.riverpod.dart';

// Provider for the MapPageNotifier using traditional approach
final mapPageNotifierProvider = StateNotifierProvider<MapPageNotifier, MapProviderState>((ref) {
  return MapPageNotifier(ref);
});

class MapPageNotifier extends StateNotifier<MapProviderState> {
  final Ref _ref;

  // Component managers
  final MapControllerManager _controllerManager = MapControllerManager();
  final MapCameraHandler _cameraHandler = MapCameraHandler();
  final MapFeatureHandler _featureHandler = MapFeatureHandler();
  final MapLayerManager _layerManager = MapLayerManager();
  MapPageNotifier(this._ref) : super(const MapProviderState(currentStyleUrl: '', isSatelliteLayerVisible: false, isTravelLayerVisible: false, isMapFullyLoaded: false)) {
    _initialize();
  }
  Future<void> _initialize() async {
    debugPrint('MapPageProvider initializing...');

    _cameraHandler.dispose();

    // Initialize the state
    final settingsBox = Hive.isBoxOpen('settingsBox') ? Hive.box('settingsBox') : await Hive.openBox('settingsBox');

    final isTravelLayerVisible = settingsBox.get('isTravelLayerVisible', defaultValue: false) as bool;
    final isSatelliteLayerVisible = settingsBox.get('isSatelliteLayerVisible', defaultValue: false) as bool;

    final currentStyleUrl = _ref.read(mapThemeProvider);

    state = MapProviderState(
      currentStyleUrl: currentStyleUrl,
      isSatelliteLayerVisible: isSatelliteLayerVisible,
      isTravelLayerVisible: isTravelLayerVisible,
      isMapFullyLoaded: false,
    );

    debugPrint('MapPageProvider initialization complete');
  }

  // Getters that delegate to the controller manager
  bool get styleLoaded => _controllerManager.styleLoaded;
  MapLibreMapController? get mapController => _controllerManager.mapController;
  CameraPosition get initialCameraPosition => _controllerManager.initialCameraPosition;
  GlobalKey<ScaffoldState> get scaffoldKey => _controllerManager.scaffoldKey;
  double get currentZoomLevel => _controllerManager.currentZoomLevel;

  // Event handlers that delegate to specialized components
  Future<void> onMapCreated(MapLibreMapController controller, WidgetRef ref, BuildContext context) async {
    await _controllerManager.onMapCreated(
        controller, ref, (id, point, coordinates, layerId) => _featureHandler.onFeatureInteraction(id, point, coordinates, layerId, ref, controller));
  }

  Future<void> onStyleLoaded(BuildContext context, WidgetRef ref) async {
    debugPrint('🎨 Map style loaded');

    await _controllerManager.onStyleLoaded(
      ref,
      () async {
        debugPrint('🏪 Preloading POI layers...');
        await _layerManager.preloadPoiLayers(ref, mapController);
        debugPrint('✅ POI layers preloaded - marking map as fully loaded');
        markMapAsFullyLoaded();
      },
      () => forceLayerUpdate(mapController!, ref),
      () => _cameraHandler.markStyleLoaded(),
    );
  }

  Future<void> onCameraIdle(BuildContext context, WidgetRef ref) async {
    await _cameraHandler.onCameraIdle(
      context,
      mapController,
      ref,
      styleLoaded,
      (context, bounds) => _layerManager.updateVisibleLayers(context, bounds, ref, mapController),
    );
  }

  void onMapIdle(BuildContext context) {
    _cameraHandler.onMapIdle(context);
  }

  void onFeatureInteraction(
    String id,
    Point<double> point,
    LatLng coordinates,
    String layerId,
    MapLibreMapController mapController,
    WidgetRef ref,
  ) {
    _featureHandler.onFeatureInteraction(id, point, coordinates, layerId, ref, mapController);
  }

  Future<void> handleFeatureTap(
    BuildContext context,
    String id,
    Point<double> point,
    LatLng coordinates,
    String originalLayerId,
    WidgetRef ref,
  ) async {
    await _featureHandler.handleFeatureTap(context, id, point, coordinates, originalLayerId, ref, mapController!);
  }

  Future<void> forceLayerUpdate(MapLibreMapController mapController, WidgetRef ref) async {
    await _layerManager.forceLayerUpdate(
      mapController,
      styleLoaded,
      ref,
      (context, bounds) => _layerManager.updateVisibleLayers(context, bounds, ref, mapController),
    );
  }

  dynamic structuresIconSize(String sourceId) {
    return MapUtilities.structuresIconSize(sourceId);
  }

  String getIconImage(String layerName) {
    return MapUtilities.getIconImage(layerName);
  }

  /// Mark the map as fully loaded (called after POI layers are preloaded)
  void markMapAsFullyLoaded() {
    debugPrint('🎉 Map fully loaded - updating state');
    state = state.copyWith(isMapFullyLoaded: true);
  }

  /// Check if the map is fully loaded
  bool get isMapFullyLoaded => state.isMapFullyLoaded;
}
