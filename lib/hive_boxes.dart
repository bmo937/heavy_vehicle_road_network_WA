/// Single source of truth for Hive box names.
///
/// The literal values are persisted on user devices and MUST NOT change.
abstract final class HiveBoxes {
  // Opened during bootstrap (see initialization_provider.dart).
  static const layers = 'layersBox';
  static const settings = 'settingsBox';
  static const showAllLayers = 'showAllLayersBox';
  static const selectedPoiLayer = 'selectedPoiLayerBox';
  static const selectedLayer = 'selectedLayerBox';
  static const markerImages = 'marker_images';

  // Legacy/compatibility boxes, opened lazily by feature code only.
  static const pointsOfInterest = 'pointsOfInterestBox';
  static const roadNetworks = 'roadNetworksBox';

  /// Boxes that must open successfully before the app is ready.
  static const requiredAtStartup = <String>[
    layers,
    settings,
    showAllLayers,
    selectedPoiLayer,
    selectedLayer,
    markerImages,
  ];
}
