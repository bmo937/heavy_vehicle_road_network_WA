// Main MapPageNotifier coordinating map functionality
import 'package:roads_map/hive_boxes.dart';
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
import 'package:roads_map/providers/network_refresh_coordinator.dart';
import 'package:roads_map/utils/map_style_service.riverpod.dart';

/// Snapshot of what the notifier needs before it can report ready.
class MapInitialSettings {
  const MapInitialSettings({required this.styleUrl, required this.isTravelLayerVisible, required this.isSatelliteLayerVisible});
  final String styleUrl;
  final bool isTravelLayerVisible;
  final bool isSatelliteLayerVisible;
}

typedef MapInitialSettingsLoader = Future<MapInitialSettings> Function();

/// Loads persisted layer settings and the current map style.
///
/// settingsBox is opened by the app bootstrap, but the notifier may be created
/// before that finishes (e.g. watched from the app wrapper), so the box is only
/// opened here as a fallback.
Future<MapInitialSettings> _loadPersistedSettings(Ref ref) async {
  final settingsBox = Hive.isBoxOpen(HiveBoxes.settings) ? Hive.box(HiveBoxes.settings) : await Hive.openBox(HiveBoxes.settings);
  return MapInitialSettings(
    styleUrl: ref.read(mapThemeProvider),
    isTravelLayerVisible: settingsBox.get('isTravelLayerVisible', defaultValue: false) as bool,
    isSatelliteLayerVisible: settingsBox.get('isSatelliteLayerVisible', defaultValue: false) as bool,
  );
}

// The constructor does no work; initialize() is started explicitly here and its
// outcome is published through MapProviderState.initStatus.
final mapPageNotifierProvider = StateNotifierProvider<MapPageNotifier, MapProviderState>((ref) {
  final notifier = MapPageNotifier(() => _loadPersistedSettings(ref));
  unawaited(notifier.initialize());
  return notifier;
});

class MapPageNotifier extends StateNotifier<MapProviderState> {
  final MapInitialSettingsLoader _loadSettings;
  Future<void>? _initialization;

  // Component managers
  final MapControllerManager _controllerManager = MapControllerManager();
  final NetworkRefreshCoordinator _refreshCoordinator = NetworkRefreshCoordinator();
  late final MapCameraHandler _cameraHandler = MapCameraHandler(_refreshCoordinator);
  final MapFeatureHandler _featureHandler = MapFeatureHandler();
  late final MapLayerManager _layerManager = MapLayerManager(_refreshCoordinator);

  MapPageNotifier(this._loadSettings)
      : super(const MapProviderState(currentStyleUrl: '', isSatelliteLayerVisible: false, isTravelLayerVisible: false, isMapFullyLoaded: false));

  /// Loads settings and the initial style. Idempotent; never throws.
  /// Success -> [MapInitStatus.ready]; failure -> [MapInitStatus.failure]
  /// (style stays empty, so the splash screen does not complete).
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    debugPrint('MapPageProvider initializing...');
    try {
      final settings = await _loadSettings();
      if (!mounted) return;
      state = MapProviderState(
        currentStyleUrl: settings.styleUrl,
        isSatelliteLayerVisible: settings.isSatelliteLayerVisible,
        isTravelLayerVisible: settings.isTravelLayerVisible,
        isMapFullyLoaded: false,
        initStatus: MapInitStatus.ready,
      );
      debugPrint('MapPageProvider initialization complete');
    } catch (e) {
      debugPrint('MapPageProvider initialization failed: ${e.runtimeType}');
      if (!mounted) return;
      state = state.copyWith(initStatus: MapInitStatus.failure, initError: 'Map initialisation failed (${e.runtimeType})');
    }
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
    if (!mounted) return;
    debugPrint('🎨 Map style loaded');

    // Anything fetched against the previous style must not touch the new one.
    _refreshCoordinator.invalidate('style reloaded');

    await _controllerManager.onStyleLoaded(
      ref,
      () async {
        debugPrint('🏪 Preloading POI layers...');
        await _layerManager.preloadPoiLayers(ref, mapController);
        debugPrint('✅ POI layers preloaded - marking map as fully loaded');
        markMapAsFullyLoaded();
      },
      () async {
        final controller = mapController;
        if (!mounted || controller == null) return;
        await forceLayerUpdate(controller, ref);
      },
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
    final controller = mapController;
    if (controller == null) {
      debugPrint('handleFeatureTap ignored: map controller not created');
      return;
    }
    await _featureHandler.handleFeatureTap(context, id, point, coordinates, originalLayerId, ref, controller);
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
    if (!mounted) return;
    debugPrint('🎉 Map fully loaded - updating state');
    state = state.copyWith(isMapFullyLoaded: true);
  }

  /// Check if the map is fully loaded
  bool get isMapFullyLoaded => state.isMapFullyLoaded;

  @override
  void dispose() {
    _cameraHandler.dispose();
    _refreshCoordinator.dispose();
    _controllerManager.dispose();
    super.dispose();
  }
}
