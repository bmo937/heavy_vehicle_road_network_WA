import 'package:equatable/equatable.dart';

class MapProviderState extends Equatable {
  const MapProviderState({
    required this.currentStyleUrl,
    required this.isSatelliteLayerVisible,
    required this.isTravelLayerVisible,
    this.isIncidentsLayerVisible = false,
    this.isTrafficLayersVisible = false,
    this.isMapFullyLoaded = false,
  });

  final String currentStyleUrl;
  final bool isIncidentsLayerVisible;
  final bool isSatelliteLayerVisible;
  final bool isTravelLayerVisible;
  final bool isTrafficLayersVisible;
  final bool isMapFullyLoaded;
  @override
  List<Object?> get props => [currentStyleUrl, isSatelliteLayerVisible, isTravelLayerVisible, isMapFullyLoaded];

  MapProviderState copyWith({
    String? currentStyleUrl,
    bool? isSatelliteLayerVisible,
    bool? isTravelLayerVisible,
    bool? isIncidentsLayerVisible,
    bool? isTrafficLayersVisible,
    bool? isMapFullyLoaded,
  }) {
    return MapProviderState(
      currentStyleUrl: currentStyleUrl ?? this.currentStyleUrl,
      isSatelliteLayerVisible: isSatelliteLayerVisible ?? this.isSatelliteLayerVisible,
      isTravelLayerVisible: isTravelLayerVisible ?? this.isTravelLayerVisible,
      isIncidentsLayerVisible: isIncidentsLayerVisible ?? this.isIncidentsLayerVisible,
      isTrafficLayersVisible: isTrafficLayersVisible ?? this.isTrafficLayersVisible,
      isMapFullyLoaded: isMapFullyLoaded ?? this.isMapFullyLoaded,
    );
  }
}
