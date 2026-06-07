import 'package:flutter/material.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';

/// Utility class for determining the type of a tapped feature
class FeatureTypeDetector {
  /// Determines the feature type based on layer ID and properties
  static String determineFeatureType(TappedFeature feature) {
    final properties = feature.properties;
    String layerId = feature.layerId;

    debugPrint('Determining feature type for layer ID: $layerId with properties: $properties');

    // Handle SubLayerFeatureType enum values
    if (layerId.contains('SubLayerFeatureType')) {
      debugPrint('Converting enum layer ID: $layerId');
      layerId = layerId.split('.').last.toLowerCase();
      debugPrint('Converted to: $layerId');
    }

    // Network layers (using standardized naming from LayerNamingUtility)
    if (layerId == 'bridgesLayer') {
      return 'bridge';
    }

    if (layerId == 'intersectionsLayer') {
      return 'intersection';
    }

    if (layerId == 'withConditionsLayer') {
      return 'road_with_conditions';
    }

    if (layerId == 'withoutConditionsLayer') {
      return 'road_without_conditions';
    }

    if (layerId == 'singleLayer') {
      return 'road_with_conditions'; // Default for single layer
    }

    // POI layers (using standardized naming)
    if (layerId == 'layer-poi-hvs_inspection_bays-symbol') {
      return 'rest_area'; // HVS inspection bays are a type of rest area
    }

    if (layerId == 'layer-poi-road_train_assembly_area-symbol' || layerId.contains('road_train_assembly_area')) {
      return 'road_train_assembly';
    }

    if (layerId == 'layer-poi-heavy_vehicle_rest_area-symbol' ||
        layerId == 'layer-poi-major_rest_area-symbol' ||
        layerId == 'layer-poi-minor_rest_area-symbol' ||
        layerId.contains('heavy_vehicle_rest_area') ||
        layerId.contains('major_rest_area') ||
        layerId.contains('minor_rest_area')) {
      return 'rest_area';
    }

    if (layerId == 'layer-poi-roadhouse-symbol' || layerId.contains('roadhouse')) {
      return 'roadhouse';
    }

    // Travel impact layers (using standardized naming)
    if (layerId == 'layer-travel-rav_impacts-line' || layerId.contains('ravLayer')) {
      return 'travel_impact';
    }

    if (layerId == 'layer-travel-osom_impacts-line' || layerId.contains('osomLayer')) {
      return 'travel_impact';
    }

    if (layerId == 'layer-travel-road_incidents-symbol' || layerId.contains('incidentLayer')) {
      return 'traffic_incident';
    }

    // Legacy layer names for backward compatibility
    if (layerId.contains('road-incidents-symbol-layer') || layerId.contains('incidentLayer') || (properties.containsKey('ClosureTyp') && properties.containsKey('IncidentTy'))) {
      return 'traffic_incident';
    }

    if (layerId.contains('drive_over_structures-layer')) {
      return 'drive_over_structure';
    }

    if (layerId.contains('drive_under_structures-layer')) {
      return 'drive_under_structure';
    }

    // Check for traffic services - specifically for road surface damage incidents
    if (properties.containsKey('IncidentTy') &&
        (properties['IncidentTy']?.toString().contains('Pothole') == true || properties['IncidentTy']?.toString().contains('Surface') == true)) {
      return 'traffic_service';
    }

    // Check for search results from Google Places
    if (properties.containsKey('marker_type') && properties['marker_type'] == 'search_result') {
      return 'search_result';
    }

    // Check if we have a REST_AREA_TYPE in properties
    if (properties.containsKey('REST_AREA_TYPE')) {
      return 'rest_area';
    }

    // Default
    return 'generic';
  }
}
