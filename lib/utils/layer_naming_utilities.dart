// ignore_for_file: constant_identifier_names

import 'package:roads_map/models/menu_assets.riverpod.dart';

/// Utility class to provide consistent layer naming across the app
class LayerNamingUtility {
  /// Source ID prefix for all map sources
  static const String SOURCE_PREFIX = 'source';

  /// Layer ID prefix for all map layers
  static const String LAYER_PREFIX = 'layer';

  /// Separator for parts of layer/source names
  static const String SEPARATOR = '-';

  // Layer type constants
  static const String TYPE_POINT = 'point';
  static const String TYPE_LINE = 'line';
  static const String TYPE_SYMBOL = 'symbol';
  static const String TYPE_FILL = 'fill';

  // Category prefixes for organizing layers
  static const String CATEGORY_NETWORK = 'network';
  static const String CATEGORY_POI = 'poi';
  static const String CATEGORY_TRAVEL = 'travel';
  static const String CATEGORY_INCIDENT = 'incident';

  // Network layer featureType-based naming (new simplified approach)
  static const String BRIDGES_SOURCE = 'bridgesSource';
  static const String BRIDGES_LAYER = 'bridgesLayer';
  static const String INTERSECTIONS_SOURCE = 'intersectionsSource';
  static const String INTERSECTIONS_LAYER = 'intersectionsLayer';
  static const String WITH_CONDITIONS_SOURCE = 'withConditionsSource';
  static const String WITH_CONDITIONS_LAYER = 'withConditionsLayer';
  static const String WITHOUT_CONDITIONS_SOURCE = 'withoutConditionsSource';
  static const String WITHOUT_CONDITIONS_LAYER = 'withoutConditionsLayer';
  static const String SINGLE_SOURCE = 'singleSource';
  static const String SINGLE_LAYER = 'singleLayer';

  // POI layer constants (for stopping places)
  static const String POI_HVS_INSPECTION = 'hvs_inspection_bays';
  static const String POI_ROAD_TRAIN_ASSEMBLY = 'road_train_assembly_area';
  static const String POI_HEAVY_VEHICLE_REST = 'heavy_vehicle_rest_area';
  static const String POI_MAJOR_REST = 'major_rest_area';
  static const String POI_MINOR_REST = 'minor_rest_area';
  static const String POI_ROADHOUSE = 'roadhouse';

  // Travel impact layer constants
  static const String TRAVEL_RAV_IMPACTS = 'rav_impacts';
  static const String TRAVEL_OSOM_IMPACTS = 'osom_impacts';
  static const String TRAVEL_ROAD_INCIDENTS = 'road_incidents';

  /// Get source ID for network layers based on featureType
  static String getNetworkSourceId(String featureType) {
    switch (featureType.toLowerCase()) {
      case 'bridges':
        return BRIDGES_SOURCE;
      case 'intersections':
        return INTERSECTIONS_SOURCE;
      case 'with_conditions':
      case 'withconditions':
        return WITH_CONDITIONS_SOURCE;
      case 'without_conditions':
      case 'withoutconditions':
        return WITHOUT_CONDITIONS_SOURCE;
      case 'single':
      default:
        return SINGLE_SOURCE;
    }
  }

  /// Get layer ID for network layers based on featureType
  static String getNetworkLayerId(String featureType) {
    switch (featureType.toLowerCase()) {
      case 'bridges':
        return BRIDGES_LAYER;
      case 'intersections':
        return INTERSECTIONS_LAYER;
      case 'with_conditions':
      case 'withconditions':
        return WITH_CONDITIONS_LAYER;
      case 'without_conditions':
      case 'withoutconditions':
        return WITHOUT_CONDITIONS_LAYER;
      case 'single':
      default:
        return SINGLE_LAYER;
    }
  }

  /// Get all network layer IDs for cleanup purposes
  static List<String> getAllNetworkLayerIds() {
    return [
      BRIDGES_LAYER,
      INTERSECTIONS_LAYER,
      WITH_CONDITIONS_LAYER,
      WITHOUT_CONDITIONS_LAYER,
      SINGLE_LAYER,
    ];
  }

  /// Get queryable network layer IDs (excludes without conditions layer)
  static List<String> getQueryableNetworkLayerIds() {
    return [
      BRIDGES_LAYER,
      INTERSECTIONS_LAYER,
      WITH_CONDITIONS_LAYER,
      SINGLE_LAYER,
    ];
  }

  /// Get all network source IDs for cleanup purposes
  static List<String> getAllNetworkSourceIds() {
    return [
      BRIDGES_SOURCE,
      INTERSECTIONS_SOURCE,
      WITH_CONDITIONS_SOURCE,
      WITHOUT_CONDITIONS_SOURCE,
      SINGLE_SOURCE,
    ];
  }

  /// Generate a standardized source ID (for non-network layers)
  /// Example: source-poi-rav
  static String getSourceId(String category, String name) {
    return '$SOURCE_PREFIX$SEPARATOR$category$SEPARATOR${_normalizedName(name)}';
  }

  /// Generate a standardized layer ID for a specific type (for non-network layers)
  /// Example: layer-poi-rav-symbol
  static String getLayerId(String category, String name, String type) {
    return '$LAYER_PREFIX$SEPARATOR$category$SEPARATOR${_normalizedName(name)}$SEPARATOR$type';
  }

  /// Convert existing legacy layer names to standardized format
  static String standardizeLayerName(String originalLayerId) {
    // Handle POI layers
    if (originalLayerId.contains('road_train_assembly_area')) {
      return getLayerId(CATEGORY_POI, 'road_train_assembly_area', TYPE_SYMBOL);
    }
    if (originalLayerId.contains('heavy_vehicle_rest_area')) {
      return getLayerId(CATEGORY_POI, 'heavy_vehicle_rest_area', TYPE_SYMBOL);
    }
    if (originalLayerId.contains('major_rest_area')) {
      return getLayerId(CATEGORY_POI, 'major_rest_area', TYPE_SYMBOL);
    }
    if (originalLayerId.contains('minor_rest_area')) {
      return getLayerId(CATEGORY_POI, 'minor_rest_area', TYPE_SYMBOL);
    }
    if (originalLayerId.contains('roadhouse')) {
      return getLayerId(CATEGORY_POI, 'roadhouse', TYPE_SYMBOL);
    }
    if (originalLayerId.contains('drive_over_structures')) {
      return getLayerId(CATEGORY_POI, 'drive_over_structures', TYPE_SYMBOL);
    }
    if (originalLayerId.contains('drive_under_structures')) {
      return getLayerId(CATEGORY_POI, 'drive_under_structures', TYPE_SYMBOL);
    }

    // Handle travel impacts
    if (originalLayerId.contains('travel-impact') ||
        originalLayerId.contains('osomLayer') ||
        originalLayerId.contains('ravLayer')) {
      if (originalLayerId.contains('symbol')) {
        return getLayerId(CATEGORY_TRAVEL, 'travel_impact', TYPE_SYMBOL);
      } else {
        return getLayerId(CATEGORY_TRAVEL, 'travel_impact', TYPE_LINE);
      }
    }

    // Handle incidents
    if (originalLayerId.contains('incident') ||
        originalLayerId.contains('road-incidents')) {
      return getLayerId(CATEGORY_INCIDENT, 'road_incidents', TYPE_SYMBOL);
    }

    // For network layers, attempt best effort standardization
    if (originalLayerId == 'singleLayer' ||
        originalLayerId.startsWith('layer_') ||
        originalLayerId.contains('withConditionsLayer') ||
        originalLayerId.contains('withoutConditionsLayer')) {
      return getLayerId(CATEGORY_NETWORK, 'network', TYPE_LINE);
    }

    // When in doubt, return the original ID
    return originalLayerId;
  }

  /// Convert a layer object to a standard source ID
  static String getLayerSourceId(Layer layer) {
    String category = _getCategoryFromLayer(layer);
    return getSourceId(category, layer.name);
  }

  /// Convert a layer object to a standard layer ID with specified type
  static String getLayerLayerId(Layer layer, String type) {
    String category = _getCategoryFromLayer(layer);
    return getLayerId(category, layer.name, type);
  }

  /// Convert a group member to a standard source ID
  static String getGroupMemberSourceId(GroupMember member) {
    String category = _getCategoryFromGroupMember(member);
    return getSourceId(category, member.name);
  }

  /// Convert a group member to a standard layer ID with specified type
  static String getGroupMemberLayerId(GroupMember member, String type) {
    String category = _getCategoryFromGroupMember(member);
    return getLayerId(category, member.name, type);
  }

  /// Get all possible layer IDs to query for feature tapping
  /// Returns a list of standardized layer IDs to check when a user taps the map
  static List<String> getAllQueryableLayerIds() {
    final List<String> layerIds = [
      // Network layers (featureType-based naming) - excluding without conditions layer
      ...getQueryableNetworkLayerIds(),

      // POI category layers (stopping places)
      ...getAllPoiLayerIds(),

      // Travel impact layers
      ...getAllTravelImpactLayerIds(),

      // Generic types - for backward compatibility
      /* '$LAYER_PREFIX$SEPARATOR*', */
    ];

    // Also add legacy layer names for backwards compatibility
    final List<String> legacyLayerIds = [
      'road_train_assembly_area-layer',
      'heavy_vehicle_rest_area-layer',
      'major_rest_area-layer',
      'minor_rest_area-layer',
      'roadhouse-layer',
      'drive_over_structures-layer',
      'drive_under_structures-layer',
      'osomLayer',
      'ravLayer',
      'incidentLayer',
    ];

    return [...layerIds, ...legacyLayerIds];
  }

  /// Helper method to normalize a name for use in IDs
  static String _normalizedName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('/', '_');
  }

  /// Determine the category from a layer object
  static String _getCategoryFromLayer(Layer layer) {
    final name = layer.name.toLowerCase();

    if (name.contains('rest') ||
        name.contains('assembly') ||
        name.contains('roadhouse') ||
        name.contains('structures') ||
        name.contains('bridges') ||
        name.contains('intersections')) {
      return CATEGORY_POI;
    }

    if (name.contains('travel') || name.contains('impact')) {
      return CATEGORY_TRAVEL;
    }

    if (name.contains('incident') || name.contains('closure')) {
      return CATEGORY_INCIDENT;
    }

    // Default to network if no specific category identified
    return CATEGORY_NETWORK;
  }

  /// Determine the category from a group member object
  static String _getCategoryFromGroupMember(GroupMember member) {
    final name = member.name.toLowerCase();

    if (name.contains('rest') ||
        name.contains('assembly') ||
        name.contains('roadhouse') ||
        name.contains('structures') ||
        name.contains('bridges') ||
        name.contains('intersections')) {
      return CATEGORY_POI;
    }

    if (name.contains('travel') || name.contains('impact')) {
      return CATEGORY_TRAVEL;
    }

    if (name.contains('incident') || name.contains('closure')) {
      return CATEGORY_INCIDENT;
    }

    // Default to network if no specific category identified
    return CATEGORY_NETWORK;
  }

  /// Get standardized source ID for POI group member
  static String getPoiMemberSourceId(String memberName) {
    final normalizedName = _getPoiNormalizedName(memberName);
    return getSourceId(CATEGORY_POI, normalizedName);
  }

  /// Get standardized layer ID for POI group member
  static String getPoiMemberLayerId(String memberName) {
    final normalizedName = _getPoiNormalizedName(memberName);
    return getLayerId(CATEGORY_POI, normalizedName, TYPE_SYMBOL);
  }

  /// Get standardized source ID for travel impact member
  static String getTravelImpactSourceId(String memberName) {
    final normalizedName = _getTravelImpactNormalizedName(memberName);
    return getSourceId(CATEGORY_TRAVEL, normalizedName);
  }

  /// Get standardized layer ID for travel impact member
  static String getTravelImpactLayerId(String memberName) {
    final normalizedName = _getTravelImpactNormalizedName(memberName);
    final layerType =
        memberName.toLowerCase().contains('incident') ? TYPE_SYMBOL : TYPE_LINE;
    return getLayerId(CATEGORY_TRAVEL, normalizedName, layerType);
  }

  /// Get all POI layer IDs for stopping places
  static List<String> getAllPoiLayerIds() {
    return [
      getLayerId(CATEGORY_POI, POI_HVS_INSPECTION, TYPE_SYMBOL),
      getLayerId(CATEGORY_POI, POI_ROAD_TRAIN_ASSEMBLY, TYPE_SYMBOL),
      getLayerId(CATEGORY_POI, POI_HEAVY_VEHICLE_REST, TYPE_SYMBOL),
      getLayerId(CATEGORY_POI, POI_MAJOR_REST, TYPE_SYMBOL),
      getLayerId(CATEGORY_POI, POI_MINOR_REST, TYPE_SYMBOL),
      getLayerId(CATEGORY_POI, POI_ROADHOUSE, TYPE_SYMBOL),
    ];
  }

  /// Get all POI source IDs for stopping places
  static List<String> getAllPoiSourceIds() {
    return [
      getSourceId(CATEGORY_POI, POI_HVS_INSPECTION),
      getSourceId(CATEGORY_POI, POI_ROAD_TRAIN_ASSEMBLY),
      getSourceId(CATEGORY_POI, POI_HEAVY_VEHICLE_REST),
      getSourceId(CATEGORY_POI, POI_MAJOR_REST),
      getSourceId(CATEGORY_POI, POI_MINOR_REST),
      getSourceId(CATEGORY_POI, POI_ROADHOUSE),
    ];
  }

  /// Get all travel impact layer IDs
  static List<String> getAllTravelImpactLayerIds() {
    return [
      getLayerId(CATEGORY_TRAVEL, TRAVEL_RAV_IMPACTS, TYPE_LINE),
      getLayerId(CATEGORY_TRAVEL, TRAVEL_OSOM_IMPACTS, TYPE_LINE),
      getLayerId(CATEGORY_TRAVEL, TRAVEL_ROAD_INCIDENTS, TYPE_SYMBOL),
    ];
  }

  /// Get all travel impact source IDs
  static List<String> getAllTravelImpactSourceIds() {
    return [
      getSourceId(CATEGORY_TRAVEL, TRAVEL_RAV_IMPACTS),
      getSourceId(CATEGORY_TRAVEL, TRAVEL_OSOM_IMPACTS),
      getSourceId(CATEGORY_TRAVEL, TRAVEL_ROAD_INCIDENTS),
    ];
  }

  /// Helper method to normalize POI member names to constants
  static String _getPoiNormalizedName(String memberName) {
    final name = memberName.toLowerCase();
    if (name.contains('hvs inspection') || name.contains('inspection bay')) {
      return POI_HVS_INSPECTION;
    } else if (name.contains('road train assembly')) {
      return POI_ROAD_TRAIN_ASSEMBLY;
    } else if (name.contains('heavy vehicle rest')) {
      return POI_HEAVY_VEHICLE_REST;
    } else if (name.contains('major rest')) {
      return POI_MAJOR_REST;
    } else if (name.contains('minor rest')) {
      return POI_MINOR_REST;
    } else if (name.contains('roadhouse')) {
      return POI_ROADHOUSE;
    }
    // Fallback to normalized version of the original name
    return _normalizedName(memberName);
  }

  /// Helper method to normalize travel impact member names to constants
  static String _getTravelImpactNormalizedName(String memberName) {
    final name = memberName.toLowerCase();
    if (name.contains('rav impact')) {
      return TRAVEL_RAV_IMPACTS;
    } else if (name.contains('osom impact')) {
      return TRAVEL_OSOM_IMPACTS;
    } else if (name.contains('road incident') || name.contains('incident')) {
      return TRAVEL_ROAD_INCIDENTS;
    }
    // Fallback to normalized version of the original name
    return _normalizedName(memberName);
  }
}
