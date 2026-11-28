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
import 'package:roads_map/providers/map_style_restoration.dart';
import 'package:roads_map/providers/map_utilities.dart';
import 'package:roads_map/providers/network_refresh_coordinator.dart';
import 'package:roads_map/utils/map_style_service.riverpod.dart';
import 'package:roads_map/utils/marker_utilities.riverpod.dart';

/// Snapshot of what the notifier needs before it can report ready.
class MapInitialSettings {
  const MapInitialSettings(
      {required this.styleUrl,
      required this.isTravelLayerVisible,
      required this.isSatelliteLayerVisible});
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
  final settingsBox = Hive.isBoxOpen(HiveBoxes.settings)
      ? Hive.box(HiveBoxes.settings)
      : await Hive.openBox(HiveBoxes.settings);
  return MapInitialSettings(
    styleUrl: ref.read(mapThemeProvider),
    isTravelLayerVisible:
        settingsBox.get('isTravelLayerVisible', defaultValue: false) as bool,
    isSatelliteLayerVisible:
        settingsBox.get('isSatelliteLayerVisible', defaultValue: false) as bool,
  );
}

// The constructor does no work; initialize() is started explicitly here and its
// outcome is published through MapProviderState.initStatus.
final mapPageNotifierProvider =
    StateNotifierProvider<MapPageNotifier, MapProviderState>((ref) {
  final notifier = MapPageNotifier(() => _loadPersistedSettings(ref));
  unawaited(notifier.initialize());
  return notifier;
});

class MapPageNotifier extends StateNotifier<MapProviderState> {
  final MapInitialSettingsLoader _loadSettings;
  Future<void>? _initialization;

  // Component managers
  final MapControllerManager _controllerManager = MapControllerManager();
  final NetworkRefreshCoordinator _refreshCoordinator =
      NetworkRefreshCoordinator();
  late final MapCameraHandler _cameraHandler =
      MapCameraHandler(_refreshCoordinator);
  final MapFeatureHandler _featureHandler = MapFeatureHandler();
  late final MapLayerManager _layerManager =
      MapLayerManager(_refreshCoordinator);
  final MapStyleRestorationCoordinator _restoration =
      MapStyleRestorationCoordinator();

  @visibleForTesting
  NetworkRefreshCoordinator get refreshCoordinator => _refreshCoordinator;

  MapPageNotifier(this._loadSettings)
      : super(const MapProviderState(
            currentStyleUrl: '',
            isSatelliteLayerVisible: false,
            isTravelLayerVisible: false,
            isMapFullyLoaded: false));

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
      state = state.copyWith(
          initStatus: MapInitStatus.failure,
          initError: 'Map initialisation failed (${e.runtimeType})');
    }
  }

  // Getters that delegate to the controller manager
  bool get styleLoaded => _controllerManager.styleLoaded;
  MapLibreMapController? get mapController => _controllerManager.mapController;
  CameraPosition get initialCameraPosition =>
      _controllerManager.initialCameraPosition;
  GlobalKey<ScaffoldState> get scaffoldKey => _controllerManager.scaffoldKey;
  double get currentZoomLevel => _controllerManager.currentZoomLevel;

  // Event handlers that delegate to specialized components
  Future<void> onMapCreated(MapLibreMapController controller, WidgetRef ref,
      BuildContext context) async {
    // A new controller means a new style; anything bound to the old one is stale.
    onStyleChangeBegan();
    await _controllerManager.onMapCreated(
        controller,
        ref,
        (id, point, coordinates, layerId) =>
            _featureHandler.onFeatureInteraction(
                id, point, coordinates, layerId, ref, controller));
  }

  /// Style lifecycle, step 1: a style change has begun (theme change or a
  /// replaced controller). The old style's resources are going away, so
  /// in-flight network work and restoration become invalid and the map is no
  /// longer "fully loaded". Selections (providers/Hive) are deliberately untouched.
  void onStyleChangeBegan() {
    if (!mounted) return;
    _refreshCoordinator.invalidate('style change began');
    _restoration.invalidate();
    _controllerManager.markStyleUnavailable();
    if (state.isMapFullyLoaded || state.isMapRestorationFailed) {
      state = state.copyWith(
          isMapFullyLoaded: false, isMapRestorationFailed: false);
    }
  }

  /// Style lifecycle, steps 2-4: the base style loaded; restore everything the
  /// application added on top of it. This is the only onStyleLoaded entry point.
  Future<void> onStyleLoaded(BuildContext context, WidgetRef ref) async {
    if (!mounted) return;
    debugPrint('🎨 Map style loaded');

    // Anything fetched against the previous style must not touch the new one.
    _refreshCoordinator.invalidate('style reloaded');

    final controller = mapController;
    if (controller == null || !_controllerManager.markStyleAvailable()) return;
    // Mark the style load time to prevent double-loading from camera idle.
    _cameraHandler.markStyleLoaded();

    await restoreApplicationMapState(
        _applicationRestorationSteps(controller, ref));
  }

  /// Ordered steps that rebuild application-owned MapLibre state for [controller]
  /// from existing application state. New overlays (e.g. a future route layer)
  /// are restored by appending a step here; order follows dependencies.
  List<StyleRestorationStep> _applicationRestorationSteps(
      MapLibreMapController controller, WidgetRef ref) {
    return [
      // Symbol layers reference these images, so they come first. The decoded
      // images are cached; only registration with MapLibre is repeated.
      StyleRestorationStep(
          'marker images', (run) => MarkerUtilities.addImagesToMap(controller)),
      StyleRestorationStep(
          'POI layers',
          (run) => _layerManager.preloadPoiLayers(ref, controller,
              isCurrent: () => run.isCurrent)),
      // Applies persisted POI visibility and re-fetches the selected network.
      StyleRestorationStep('selected network and POI visibility',
          (run) => _applySelections(controller, ref, () => run.isCurrent)),
      StyleRestorationStep(
          'travel impact and incident overlays',
          (run) => _layerManager.restoreSelectedOverlays(ref, controller,
              isCurrent: () => run.isCurrent),
          required: false),
    ];
  }

  /// Runs a restoration of the current style. Marks the map fully loaded only
  /// if every required step succeeded and no newer style change superseded it.
  @visibleForTesting
  Future<StyleRestorationOutcome> restoreApplicationMapState(
      List<StyleRestorationStep> steps) async {
    if (!mounted) return StyleRestorationOutcome.superseded;
    final run = _restoration.begin();
    state =
        state.copyWith(isMapFullyLoaded: false, isMapRestorationFailed: false);

    final outcome = await _restoration.restore(run, steps);
    if (!mounted || !run.isCurrent) return StyleRestorationOutcome.superseded;
    if (outcome == StyleRestorationOutcome.completed) {
      debugPrint(
          '✅ Application map state restored - marking map as fully loaded');
      state =
          state.copyWith(isMapFullyLoaded: true, isMapRestorationFailed: false);
    } else if (outcome == StyleRestorationOutcome.failed) {
      state =
          state.copyWith(isMapFullyLoaded: false, isMapRestorationFailed: true);
    } else {
      debugPrint(
          '⚠️ Application map state restoration did not complete: $outcome');
    }
    return outcome;
  }

  Future<void> onCameraIdle(BuildContext context, WidgetRef ref) async {
    await _cameraHandler.onCameraIdle(
      context,
      mapController,
      ref,
      styleLoaded,
      (context, bounds) => _layerManager.updateVisibleLayers(
          context, bounds, ref, mapController),
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
    _featureHandler.onFeatureInteraction(
        id, point, coordinates, layerId, ref, mapController);
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
    await _featureHandler.handleFeatureTap(
        context, id, point, coordinates, originalLayerId, ref, controller);
  }

  /// Re-applies the current selections. Ignored for a controller that is no
  /// longer the current one.
  Future<void> forceLayerUpdate(
      MapLibreMapController mapController, WidgetRef ref) async {
    await _applySelections(mapController, ref, null);
    if (identical(mapController, this.mapController)) {
      await _layerManager.restoreSelectedOverlays(ref, mapController);
    }
  }

  Future<bool> _applySelections(MapLibreMapController controller, WidgetRef ref,
      bool Function()? isCurrent) async {
    bool current() =>
        mounted &&
        identical(controller, mapController) &&
        (isCurrent?.call() ?? true);
    if (!current()) return false;
    final updated = await _layerManager.forceLayerUpdate(
      controller,
      styleLoaded,
      ref,
      (context, bounds) => _layerManager.updateVisibleLayers(
          context, bounds, ref, controller,
          isCurrent: current),
    );
    return updated && current();
  }

  /// Retries required style restoration after a transient failure.
  Future<void> retryStyleRestoration(WidgetRef ref) async {
    final controller = mapController;
    if (!styleLoaded || controller == null) return;
    await restoreApplicationMapState(
        _applicationRestorationSteps(controller, ref));
  }

  dynamic structuresIconSize(String sourceId) {
    return MapUtilities.structuresIconSize(sourceId);
  }

  String getIconImage(String layerName) {
    return MapUtilities.getIconImage(layerName);
  }

  /// Marks the current MapLibre style as loaded with its required
  /// application-owned resources restored. Reset by [onStyleChangeBegan] and at
  /// the start of every restoration. Not [MapInitStatus.ready], which only
  /// means notifier settings/style initialisation finished.
  void markMapAsFullyLoaded() {
    if (!mounted) return;
    debugPrint('🎉 Map fully loaded - updating state');
    state =
        state.copyWith(isMapFullyLoaded: true, isMapRestorationFailed: false);
  }

  /// See [markMapAsFullyLoaded].
  bool get isMapFullyLoaded => state.isMapFullyLoaded;

  @override
  void dispose() {
    _restoration.invalidate();
    _cameraHandler.dispose();
    _refreshCoordinator.dispose();
    _controllerManager.dispose();
    super.dispose();
  }
}
