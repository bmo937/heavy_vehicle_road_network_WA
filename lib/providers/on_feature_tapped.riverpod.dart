import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'on_feature_tapped.riverpod.g.dart';

/// Model class to hold the tapped feature data
class TappedFeature {
  TappedFeature({
    required this.properties,
    required this.layerId,
    required this.featureId,
    this.position,
  });

  final String featureId;
  final String layerId;
  final LatLng? position;
  final Map<String, dynamic> properties;

  @override
  String toString() => 'TappedFeature(layerId: $layerId, featureId: $featureId, '
      'properties: $properties, position: $position)';
}

/// Provider to track the currently tapped feature
@riverpod
class FeatureTapState extends _$FeatureTapState {
  /// Update the currently tapped feature
  void setTappedFeature(TappedFeature? feature) {
    state = feature;
  }

  /// Clear the currently tapped feature
  void clearTappedFeature() {
    state = null;
  }

  @override
  TappedFeature? build() => null;
}

