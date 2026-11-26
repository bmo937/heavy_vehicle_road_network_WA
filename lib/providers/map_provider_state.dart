import 'package:equatable/equatable.dart';

/// Lifecycle of the map notifier's own startup (persisted settings + initial style).
///
/// Distinct from app bootstrap, controller creation, style load and
/// [MapProviderState.isMapFullyLoaded].
enum MapInitStatus { initialising, ready, failure }

class MapProviderState extends Equatable {
  const MapProviderState({
    required this.currentStyleUrl,
    required this.isSatelliteLayerVisible,
    required this.isTravelLayerVisible,
    this.isIncidentsLayerVisible = false,
    this.isTrafficLayersVisible = false,
    this.isMapFullyLoaded = false,
    this.isMapRestorationFailed = false,
    this.initStatus = MapInitStatus.initialising,
    this.initError,
  });

  final String currentStyleUrl;
  final bool isIncidentsLayerVisible;
  final bool isSatelliteLayerVisible;
  final bool isTravelLayerVisible;
  final bool isTrafficLayersVisible;
  final bool isMapFullyLoaded;
  final bool isMapRestorationFailed;
  final MapInitStatus initStatus;

  /// Short, non-sensitive description of an initialisation failure.
  final String? initError;
  @override
  List<Object?> get props => [currentStyleUrl, isSatelliteLayerVisible, isTravelLayerVisible, isMapFullyLoaded, isMapRestorationFailed, initStatus, initError];

  MapProviderState copyWith({
    String? currentStyleUrl,
    bool? isSatelliteLayerVisible,
    bool? isTravelLayerVisible,
    bool? isIncidentsLayerVisible,
    bool? isTrafficLayersVisible,
    bool? isMapFullyLoaded,
    bool? isMapRestorationFailed,
    MapInitStatus? initStatus,
    String? initError,
  }) {
    return MapProviderState(
      currentStyleUrl: currentStyleUrl ?? this.currentStyleUrl,
      isSatelliteLayerVisible: isSatelliteLayerVisible ?? this.isSatelliteLayerVisible,
      isTravelLayerVisible: isTravelLayerVisible ?? this.isTravelLayerVisible,
      isIncidentsLayerVisible: isIncidentsLayerVisible ?? this.isIncidentsLayerVisible,
      isTrafficLayersVisible: isTrafficLayersVisible ?? this.isTrafficLayersVisible,
      isMapFullyLoaded: isMapFullyLoaded ?? this.isMapFullyLoaded,
      isMapRestorationFailed: isMapRestorationFailed ?? this.isMapRestorationFailed,
      initStatus: initStatus ?? this.initStatus,
      initError: initError ?? this.initError,
    );
  }
}
